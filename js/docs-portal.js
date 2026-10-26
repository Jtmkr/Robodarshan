// Docs-style learning portal (pages/learning-portal.html).
//
// Depends on js/supabase-client.js (global `supabaseClient`), js/auth.js
// (getCurrentUser) and js/completions.js (markTopicComplete, submitForApproval).
//
// One page, hash-routed:
//   #/                      all stages + overall progress
//   #/stage/<number>        a stage's sessions, topics and projects
//   #/session/<id>          session details + attendance
//   #/topic/<id>            lesson (HTML converted from the PDF) + quiz + completion
//   #/project/<id>          project guide + quiz + submit for review
//
// Business rules are unchanged from the previous portal:
//   - topic checkbox unlocks once the stage's session(s) are submitted AND
//     the topic quiz has been attempted at least once (auto-verified, XP via DB trigger)
//   - project checkbox unlocks after one quiz attempt; needs admin approval
//   - sessions need admin approval
//   - every quiz attempt is stored as history and never affects XP
//
// Lesson bodies live next to the PDFs: /study-materials/stage-1/3.pdf is
// rendered from /study-materials/stage-1/content/3.html. If that file is
// missing the PDF is embedded instead.

(function () {
  'use strict';

  const ICONS = {
    check:
      '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="9"/><path d="M8.5 12.5l2.2 2.2 5-5.2"/></svg>',
    chevron:
      '<svg class="nav-chevron" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="6 9 12 15 18 9"/></svg>',
    pdf:
      '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/></svg>',
    bolt:
      '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/></svg>',
  };

  const KIND_LABEL = { session: 'Session', topic: 'Topic', project: 'Project' };
  const GROUPS = [
    { kind: 'session', title: 'Sessions', key: 'sessions' },
    { kind: 'topic', title: 'Topics', key: 'topics' },
    { kind: 'project', title: 'Projects', key: 'projects' },
  ];

  const els = {
    nav: document.getElementById('docs-nav'),
    article: document.getElementById('docs-article'),
    toc: document.getElementById('docs-toc'),
    main: document.getElementById('docs-main'),
    sidebar: document.getElementById('docs-sidebar'),
    backdrop: document.getElementById('sidebar-backdrop'),
    sidebarToggle: document.getElementById('sidebar-toggle'),
    themeToggle: document.getElementById('theme-toggle'),
    backToTop: document.getElementById('back-to-top'),
    searchInput: document.getElementById('docs-search-input'),
    searchResults: document.getElementById('docs-search-results'),
  };

  const state = {
    user: null,
    stages: [], // [{ ...stage, sessions, topics, projects }]
    completions: new Map(), // "type:id" -> status
    attempts: new Map(), // "type:id" -> [{score,total,...}] oldest first
    openStages: new Set(),
    rootOpen: true,
  };

  const contentCache = new Map(); // url -> html | null
  const quizSubmissions = new Map(); // "type:id" -> { selections, score, total }
  let routeToken = 0;

  /* ----------------------------------------------------------
     Helpers
     ---------------------------------------------------------- */

  function esc(value) {
    const div = document.createElement('div');
    div.textContent = value ?? '';
    return div.innerHTML;
  }

  function escAttr(value) {
    return String(value).replace(/&/g, '&amp;').replace(/"/g, '&quot;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
  }

  function multiline(text) {
    return esc(text).replace(/\n/g, '<br>');
  }

  const keyOf = (kind, id) => `${kind}:${id}`;
  const statusOf = (kind, id) => state.completions.get(keyOf(kind, id));
  const isVerified = (kind, id) => statusOf(kind, id) === 'verified';
  const attemptsOf = (kind, id) => state.attempts.get(keyOf(kind, id)) || [];

  function progressBar(done, total) {
    const percent = total ? Math.round((done / total) * 100) : 0;
    return `<div class="progress-bar" role="progressbar" aria-valuenow="${percent}" aria-valuemin="0" aria-valuemax="100"><div class="progress-bar-fill" style="width:${percent}%"></div></div>`;
  }

  function stageItems(stage) {
    return [
      ...stage.sessions.map((item) => ({ kind: 'session', item })),
      ...stage.topics.map((item) => ({ kind: 'topic', item })),
      ...stage.projects.map((item) => ({ kind: 'project', item })),
    ];
  }

  function stageDone(stage) {
    const entries = stageItems(stage);
    return { done: entries.filter((e) => isVerified(e.kind, e.item.id)).length, total: entries.length };
  }

  function sessionsSubmitted(stage) {
    return stage.sessions.length === 0 || stage.sessions.every((s) => state.completions.has(keyOf('session', s.id)));
  }

  function findItem(kind, id) {
    for (const stage of state.stages) {
      const list = kind === 'session' ? stage.sessions : kind === 'topic' ? stage.topics : stage.projects;
      const item = list.find((x) => String(x.id) === String(id));
      if (item) return { stage, item, kind };
    }
    return null;
  }

  const hrefFor = (kind, id) => `#/${kind}/${id}`;

  function contentUrlFor(item) {
    if (!item.pdf_url) return null;
    return item.pdf_url.replace(/([^/]+)\.pdf$/i, 'content/$1.html');
  }

  /* ----------------------------------------------------------
     Data
     ---------------------------------------------------------- */

  async function loadStages() {
    const { data: stages, error } = await supabaseClient.from('stages').select('*').order('number', { ascending: true });
    if (error) throw new Error(`Could not load stages: ${error.message}`);

    state.stages = await Promise.all(
      (stages || []).map(async (stage) => {
        const [sessions, topics, projects] = await Promise.all([
          supabaseClient.from('sessions').select('*').eq('stage_id', stage.id).order('created_at', { ascending: true }),
          supabaseClient
            .from('topics')
            .select('*')
            .eq('stage_id', stage.id)
            .eq('status', 'published')
            .order('order_index', { ascending: true }),
          supabaseClient.from('projects').select('*').eq('stage_id', stage.id).order('order_index', { ascending: true }),
        ]);
        return {
          ...stage,
          sessions: sessions.data || [],
          topics: topics.data || [],
          projects: projects.data || [],
        };
      })
    );
  }

  async function loadProgress() {
    const all = state.stages.flatMap(stageItems);
    const ids = all.map((e) => e.item.id);
    state.completions = new Map();
    state.attempts = new Map();
    if (!ids.length) return;

    const [completions, attempts] = await Promise.all([
      supabaseClient.from('completions').select('item_type, item_id, status').eq('user_id', state.user.id).in('item_id', ids),
      supabaseClient
        .from('quiz_attempts')
        .select('item_type, item_id, score, total, attempted_at')
        .eq('user_id', state.user.id)
        .in('item_id', ids)
        .order('attempted_at', { ascending: true }),
    ]);

    if (completions.error) console.error('Failed to load completions:', completions.error.message);
    if (attempts.error) console.error('Failed to load quiz attempts:', attempts.error.message);

    (completions.data || []).forEach((row) => state.completions.set(keyOf(row.item_type, row.item_id), row.status));
    (attempts.data || []).forEach((row) => {
      const key = keyOf(row.item_type, row.item_id);
      if (!state.attempts.has(key)) state.attempts.set(key, []);
      state.attempts.get(key).push(row);
    });
  }

  async function fetchLessonHtml(url) {
    if (!url) return null;
    if (contentCache.has(url)) return contentCache.get(url);
    let html = null;
    try {
      const response = await fetch(url);
      if (response.ok) {
        const text = await response.text();
        // A host that falls back to index.html for unknown paths returns 200.
        if (!/<!doctype|<html/i.test(text)) html = text;
      }
    } catch (err) {
      console.error('Failed to load lesson content:', err.message);
    }
    contentCache.set(url, html);
    return html;
  }

  // The PDF is optional (a lesson can be HTML-only), so only offer it when
  // the file actually exists.
  const pdfCache = new Map(); // url -> boolean

  async function pdfExists(url) {
    if (!url) return false;
    if (pdfCache.has(url)) return pdfCache.get(url);
    let ok = false;
    try {
      const response = await fetch(url, { method: 'HEAD' });
      ok = response.ok && /pdf/i.test(response.headers.get('content-type') || '');
    } catch (err) {
      console.error('Failed to check PDF:', err.message);
    }
    pdfCache.set(url, ok);
    return ok;
  }

  /* ----------------------------------------------------------
     Sidebar
     ---------------------------------------------------------- */

  function navLink(kind, item, active) {
    const status = statusOf(kind, item.id);
    const marker =
      status === 'verified'
        ? `<span class="nav-done" aria-label="Completed">${ICONS.check}</span>`
        : status === 'pending'
          ? '<span class="nav-pending-dot" title="Pending approval"></span>'
          : '';
    return `<a class="nav-link${active ? ' is-active' : ''}" href="${hrefFor(kind, item.id)}"${active ? ' aria-current="page"' : ''}>
      <span class="nav-link-text">${esc(item.title)}</span>${marker}</a>`;
  }

  function renderSidebar(route) {
    const html = state.stages
      .map((stage) => {
        const open = state.openStages.has(stage.id);
        const { done, total } = stageDone(stage);
        const groups = GROUPS.map((group) => {
          const list = stage[group.key];
          if (!list.length) return '';
          return `<div class="nav-group-title">${group.title}</div>${list
            .map((item) => navLink(group.kind, item, route.kind === group.kind && String(route.id) === String(item.id)))
            .join('')}`;
        }).join('');

        return `
          <button type="button" class="nav-stage-toggle" data-stage="${stage.id}" aria-expanded="${open}">
            ${ICONS.chevron}<span>Stage ${esc(stage.number)}: ${esc(stage.title)}</span>
            <span class="nav-stage-meta">${done}/${total}</span>
          </button>
          <div class="nav-children"${open ? '' : ' hidden'}>
            <a class="nav-link${route.kind === 'stage' && Number(route.id) === stage.number ? ' is-active' : ''}" href="#/stage/${stage.number}"><span class="nav-link-text">Overview</span></a>
            ${groups}
          </div>`;
      })
      .join('');

    els.nav.innerHTML = `
      <button type="button" class="nav-root-toggle" aria-expanded="${state.rootOpen}" data-root>
        ${ICONS.chevron}<span>Learnings</span>
      </button>
      <div class="nav-children" style="margin-left:10px"${state.rootOpen ? '' : ' hidden'}>
        <a class="nav-link${route.kind === 'home' ? ' is-active' : ''}" href="#/"><span class="nav-link-text">All stages</span></a>
        ${html}
      </div>`;

    const active = els.nav.querySelector('.nav-link.is-active');
    if (active && !els.sidebar.dataset.scrolled) {
      active.scrollIntoView({ block: 'center' });
      els.sidebar.dataset.scrolled = '1';
    }
  }

  els.nav.addEventListener('click', (event) => {
    const stageBtn = event.target.closest('.nav-stage-toggle');
    if (stageBtn) {
      const id = Number(stageBtn.dataset.stage);
      if (state.openStages.has(id)) state.openStages.delete(id);
      else state.openStages.add(id);
      stageBtn.setAttribute('aria-expanded', String(state.openStages.has(id)));
      stageBtn.nextElementSibling.hidden = !state.openStages.has(id);
      return;
    }
    const rootBtn = event.target.closest('[data-root]');
    if (rootBtn) {
      state.rootOpen = !state.rootOpen;
      rootBtn.setAttribute('aria-expanded', String(state.rootOpen));
      rootBtn.nextElementSibling.hidden = !state.rootOpen;
      return;
    }
    if (event.target.closest('a.nav-link')) closeSidebar();
  });

  function openSidebar() {
    // Start at the top so the site links (Dashboard, Log out...) are visible,
    // not scrolled away to the current lesson.
    els.sidebar.scrollTop = 0;
    els.sidebar.classList.add('is-open');
    els.backdrop.hidden = false;
    els.sidebarToggle.setAttribute('aria-expanded', 'true');
  }

  function closeSidebar() {
    els.sidebar.classList.remove('is-open');
    els.backdrop.hidden = true;
    els.sidebarToggle.setAttribute('aria-expanded', 'false');
  }

  const drawerLogout = document.getElementById('drawer-logout');
  if (drawerLogout) {
    drawerLogout.addEventListener('click', () => {
      drawerLogout.disabled = true;
      logout(); // from js/auth.js: signs out, then goes to the login page
    });
  }

  els.sidebarToggle.addEventListener('click', () => (els.sidebar.classList.contains('is-open') ? closeSidebar() : openSidebar()));
  els.backdrop.addEventListener('click', closeSidebar);

  /* ----------------------------------------------------------
     "On this page"
     ---------------------------------------------------------- */

  let tocHeadings = [];

  function buildToc() {
    const headings = [...els.article.querySelectorAll('.prose h2, .doc-section-title, .prose h3')];
    const h2Count = headings.filter((h) => h.tagName === 'H2').length;
    const useSubs = headings.length - h2Count <= 14;
    const list = headings.filter((h) => h.tagName === 'H2' || useSubs);
    const used = new Set();

    // Headings get their own ids (prefixed so they never collide with the
    // converted lessons' <section id="..."> wrappers).
    list.forEach((heading, index) => {
      const base = heading.id || `h-${heading.closest('section[id]')?.id || 'sec'}`;
      let id = heading.tagName === 'H3' || used.has(base) ? `${base}-${index}` : base;
      while (used.has(id)) id += '-x';
      used.add(id);
      heading.id = id;
    });

    tocHeadings = list;
    if (!list.length) {
      els.toc.innerHTML = '';
      return;
    }
    els.toc.innerHTML = `<h2 class="toc-title">On this page</h2>${list
      .map((h) => `<a class="toc-link${h.tagName === 'H3' ? ' is-sub' : ''}" href="#${escAttr(h.id)}" data-target="${escAttr(h.id)}">${esc(h.textContent)}</a>`)
      .join('')}`;
    updateScrollState();
  }

  els.toc.addEventListener('click', (event) => {
    const link = event.target.closest('.toc-link');
    if (!link) return;
    event.preventDefault(); // the hash is reserved for routing
    document.getElementById(link.dataset.target)?.scrollIntoView({ behavior: 'smooth', block: 'start' });
  });

  function updateScrollState() {
    els.backToTop.hidden = window.scrollY < 500;
    if (!tocHeadings.length) return;
    let current = tocHeadings[0];
    for (const heading of tocHeadings) {
      if (heading.getBoundingClientRect().top <= 110) current = heading;
      else break;
    }
    els.toc.querySelectorAll('.toc-link').forEach((link) => {
      const on = link.dataset.target === current.id;
      link.classList.toggle('is-active', on);
      if (on) link.setAttribute('aria-current', 'location');
      else link.removeAttribute('aria-current');
    });
  }

  let scrollTicking = false;
  window.addEventListener(
    'scroll',
    () => {
      if (scrollTicking) return;
      scrollTicking = true;
      requestAnimationFrame(() => {
        updateScrollState();
        scrollTicking = false;
      });
    },
    { passive: true }
  );

  els.backToTop.addEventListener('click', () => window.scrollTo({ top: 0, behavior: 'smooth' }));

  /* ----------------------------------------------------------
     Views
     ---------------------------------------------------------- */

  function crumbs(parts) {
    return `<nav class="crumbs" aria-label="Breadcrumb">${parts
      .map((p, i) => (p.href && i < parts.length - 1 ? `<a href="${p.href}">${esc(p.label)}</a>` : `<span>${esc(p.label)}</span>`))
      .join('<span aria-hidden="true">/</span>')}</nav>`;
  }

  function statusChip(kind, id) {
    const status = statusOf(kind, id);
    if (status === 'verified') return `<span class="chip chip-done">${ICONS.check}Completed</span>`;
    if (status === 'pending') return '<span class="chip chip-pending">Pending approval</span>';
    return '';
  }

  function overviewCard(label, counts) {
    const done = counts.reduce((n, c) => n + c.done, 0);
    const total = counts.reduce((n, c) => n + c.total, 0);
    return `
      <div class="overview-card">
        <div class="overview-top"><span>${esc(label)}</span><span>${done}/${total} completed</span></div>
        ${progressBar(done, total)}
        <div class="stat-row">
          ${counts.map((c) => `<div class="stat"><small>${c.label}</small><strong>${c.done}/${c.total}</strong></div>`).join('')}
        </div>
      </div>`;
  }

  function countsFor(stages) {
    const sum = (key, kind) => {
      const items = stages.flatMap((s) => s[key]);
      return { done: items.filter((i) => isVerified(kind, i.id)).length, total: items.length };
    };
    return [
      { label: 'Sessions', ...sum('sessions', 'session') },
      { label: 'Topics', ...sum('topics', 'topic') },
      { label: 'Projects', ...sum('projects', 'project') },
    ];
  }

  function renderHome() {
    document.title = 'Learning Portal | Robodarshan';
    const cards = state.stages
      .map((stage) => {
        const { done, total } = stageDone(stage);
        return `
          <a class="stage-card" href="#/stage/${stage.number}">
            <span class="stage-card-num">Stage ${esc(stage.number)}</span>
            <h3>${esc(stage.title)}</h3>
            <p>${esc(stage.theme || '')}</p>
            ${progressBar(done, total)}
            <span class="progress-label">${done}/${total} completed</span>
          </a>`;
      })
      .join('');

    return `
      <h1 class="doc-title">Learning Portal</h1>
      <p class="doc-lead">Work through each stage: read the lessons, take the quizzes and complete the projects to earn XP.</p>
      ${overviewCard('Overall progress', countsFor(state.stages))}
      <h2 class="doc-section-title">Stages</h2>
      <div class="stage-grid">${cards || '<p class="content-note">No stages have been published yet.</p>'}</div>`;
  }

  function itemRow(kind, item, subtitle) {
    const status = statusOf(kind, item.id);
    const badge =
      status === 'verified'
        ? `<span class="status-ok">${ICONS.check}Completed</span>`
        : status === 'pending'
          ? '<span class="status-wait">Pending</span>'
          : '';
    return `
      <a class="item-row" href="${hrefFor(kind, item.id)}">
        <div class="item-row-main"><strong>${esc(item.title)}</strong>${subtitle ? `<span>${esc(subtitle)}</span>` : ''}</div>
        ${badge}
        <span class="chip chip-xp">+${esc(item.xp_value)} XP</span>
      </a>`;
  }

  function renderStage(number) {
    const stage = state.stages.find((s) => s.number === Number(number));
    if (!stage) return notFound();
    document.title = `Stage ${stage.number} | Robodarshan Learning Portal`;
    state.openStages.add(stage.id);

    const section = (title, kind, list, subtitle) =>
      `<h2 class="doc-section-title">${title}</h2>
       <div class="item-list">${list.length ? list.map((item) => itemRow(kind, item, subtitle(item))).join('') : '<p class="content-note">Nothing here yet.</p>'}</div>`;

    return `
      ${crumbs([{ label: 'Learnings', href: '#/' }, { label: `Stage ${stage.number}` }])}
      <h1 class="doc-title">Stage ${esc(stage.number)}: ${esc(stage.title)}</h1>
      ${stage.theme ? `<p class="doc-lead">${esc(stage.theme)}</p>` : ''}
      ${overviewCard('Stage progress', countsFor([stage]))}
      ${section('Sessions', 'session', stage.sessions, (s) => s.content)}
      ${section('Topics', 'topic', stage.topics, (t) => t.learning_objectives)}
      ${section('Projects', 'project', stage.projects, (p) => p.requirements || p.instructions)}`;
  }

  function notFound() {
    document.title = 'Not found | Robodarshan Learning Portal';
    return `<h1 class="doc-title">Page not found</h1><p class="doc-lead">That lesson doesn't exist (or isn't published yet).</p><a class="btn" href="#/">Back to all stages</a>`;
  }

  /* -------- quiz -------- */

  // Options are shown in a shuffled order so the stored answer position
  // (which is skewed in the seed data) can't be guessed. Radio values stay
  // the ORIGINAL option index, so scoring and q.answer are unaffected.
  // The order is remembered per quiz, so re-renders (after saving an
  // attempt, switching theme, etc.) keep the options where the learner saw
  // them, and "Attempt Again" reshuffles.
  const quizOrders = new Map(); // "type:id" -> number[][] (displayed -> original index, per question)
  const PINNED_LAST = /^\s*(all|none|both|neither)\b.*\b(above|these|them)\b/i;

  function shuffledOrder(options) {
    const free = [];
    const pinned = [];
    options.forEach((opt, i) => (PINNED_LAST.test(String(opt)) ? pinned : free).push(i));
    for (let i = free.length - 1; i > 0; i -= 1) {
      const j = Math.floor(Math.random() * (i + 1));
      [free[i], free[j]] = [free[j], free[i]];
    }
    return [...free, ...pinned];
  }

  function quizOrderFor(kind, id, quiz) {
    const key = keyOf(kind, id);
    let order = quizOrders.get(key);
    if (!order || order.length !== quiz.length || order.some((o, qi) => o.length !== (quiz[qi].options || []).length)) {
      order = quiz.map((q) => shuffledOrder(q.options || []));
      quizOrders.set(key, order);
    }
    return order;
  }

  function renderQuizHistory(attempts) {
    if (!attempts.length) return '<p class="quiz-history-empty">Not attempted yet.</p>';
    return `<div class="quiz-history">${attempts
      .map((a, i) => `<span class="quiz-history-item">Attempt ${i + 1}: ${a.score}/${a.total}</span>`)
      .join('')}</div>`;
  }

  function renderQuiz(quiz, kind, id) {
    if (!Array.isArray(quiz) || !quiz.length) {
      return '<p class="content-note">The quiz for this lesson is coming soon.</p>';
    }
    const attempts = attemptsOf(kind, id);
    const submission = quizSubmissions.get(keyOf(kind, id));
    const attemptNumber = submission ? attempts.length : attempts.length + 1;
    const order = quizOrderFor(kind, id, quiz);

    return `
      <div class="quiz-card">
        <div class="quiz-top">
          <span class="quiz-attempt-count">${quiz.length} question${quiz.length === 1 ? '' : 's'} &middot; Attempt #${attemptNumber}</span>
          ${renderQuizHistory(attempts)}
        </div>
        <form class="quiz-form" data-quiz="${escAttr(JSON.stringify(quiz))}" data-kind="${esc(kind)}" data-id="${esc(id)}" data-attempt-count="${attempts.length}">
          ${quiz
            .map((q, qi) => {
              const selected = submission ? submission.selections[qi] : null;
              return `
                <fieldset class="quiz-question">
                  <legend class="quiz-question-text">${qi + 1}. ${esc(q.question)}</legend>
                  <div class="quiz-options">
                    ${order[qi]
                      .map((oi) => {
                        const opt = q.options[oi];
                        let cls = '';
                        if (submission) {
                          if (oi === q.answer) cls = 'quiz-correct';
                          else if (oi === selected) cls = 'quiz-incorrect';
                        }
                        return `<label class="quiz-option ${cls}">
                          <input type="radio" name="q${qi}" value="${oi}" ${oi === selected ? 'checked' : ''} ${submission ? 'disabled' : ''}>
                          <span>${esc(opt)}</span></label>`;
                      })
                      .join('')}
                  </div>
                </fieldset>`;
            })
            .join('')}
          <button type="submit" class="btn quiz-submit-button" ${submission ? 'hidden' : ''}>Check Answers</button>
          <button type="button" class="btn btn-ghost quiz-retry-button" ${submission ? '' : 'hidden'}>Attempt Again</button>
          <div class="quiz-result" role="status" ${submission ? '' : 'hidden'}>${submission ? `You got ${submission.score}/${submission.total} correct.` : ''}</div>
        </form>
      </div>`;
  }

  async function recordQuizAttempt(kind, id, score, total) {
    const { error } = await supabaseClient
      .from('quiz_attempts')
      .insert({ user_id: state.user.id, item_type: kind, item_id: id, score, total });
    if (error) throw new Error(`Failed to record quiz attempt: ${error.message}`);
  }

  function wireQuizzes() {
    els.article.querySelectorAll('.quiz-form').forEach((form) => {
      form.addEventListener('submit', async (event) => {
        event.preventDefault();
        const quiz = JSON.parse(form.dataset.quiz);
        const { kind, id } = form.dataset;

        const unanswered = quiz.findIndex((_, qi) => !form.querySelector(`input[name="q${qi}"]:checked`));
        const result = form.querySelector('.quiz-result');
        if (unanswered !== -1) {
          result.hidden = false;
          result.textContent = `Please answer question ${unanswered + 1} before checking.`;
          return;
        }

        let score = 0;
        const selections = {};
        quiz.forEach((q, qi) => {
          const value = Number(form.querySelector(`input[name="q${qi}"]:checked`).value);
          selections[qi] = value;
          if (value === q.answer) score += 1;
        });

        // Stored before re-rendering so the redraw keeps showing the result.
        quizSubmissions.set(keyOf(kind, id), { selections, score, total: quiz.length });
        form.querySelector('.quiz-submit-button').disabled = true;

        try {
          await recordQuizAttempt(kind, id, score, quiz.length);
          await loadProgress();
        } catch (err) {
          console.error(err.message);
          quizSubmissions.delete(keyOf(kind, id));
          form.querySelector('.quiz-submit-button').disabled = false;
          result.hidden = false;
          result.textContent = 'Could not save your attempt. Please try again.';
          return;
        }
        await render({ keepScroll: true });
      });

      form.querySelector('.quiz-retry-button').addEventListener('click', async () => {
        quizSubmissions.delete(keyOf(form.dataset.kind, form.dataset.id));
        quizOrders.delete(keyOf(form.dataset.kind, form.dataset.id));
        await render({ keepScroll: true });
      });
    });
  }

  /* -------- completion -------- */

  function completionBox(kind, item, stage) {
    const status = statusOf(kind, item.id);
    if (status === 'verified') {
      return `<div class="complete-box is-done"><span class="status-ok">${ICONS.check}${kind === 'topic' ? 'Completed' : 'Verified'}</span></div>`;
    }
    if (status === 'pending') {
      return '<div class="complete-box"><span class="status-wait">Pending admin approval</span></div>';
    }

    let unlocked = true;
    let label = 'Mark Attendance';
    let hint = '';
    if (kind === 'topic') {
      label = 'Mark lesson complete';
      if (!sessionsSubmitted(stage)) {
        unlocked = false;
        hint = 'Mark Session Attendance first to unlock.';
      } else if (!attemptsOf(kind, item.id).length) {
        unlocked = false;
        hint = 'Attempt the quiz at least once to unlock.';
      }
    } else if (kind === 'project') {
      label = 'Submit for review';
      if (!attemptsOf(kind, item.id).length) {
        unlocked = false;
        hint = 'Attempt the quiz at least once to unlock.';
      }
    }

    return `
      <div class="complete-box">
        <label class="complete-check">
          <input type="checkbox" class="complete-input" data-kind="${esc(kind)}" data-id="${esc(item.id)}" ${unlocked ? '' : 'disabled'}>
          <span>${esc(label)}</span>
        </label>
        ${hint ? `<span class="complete-hint">${esc(hint)}</span>` : ''}
        ${kind === 'topic' ? '' : '<span class="complete-hint">Needs admin approval</span>'}
      </div>`;
  }

  function wireCompletion() {
    els.article.querySelectorAll('.complete-input').forEach((box) => {
      box.addEventListener('change', async () => {
        if (!box.checked) return;
        box.disabled = true;
        const { kind, id } = box.dataset;
        try {
          if (kind === 'topic') await markTopicComplete(id);
          else await submitForApproval(kind, id);
          await loadProgress();
          await render({ keepScroll: true });
        } catch (err) {
          console.error('Failed to update completion:', err.message);
          box.checked = false;
          box.disabled = false;
        }
      });
    });
  }

  /* -------- lesson / project / session pages -------- */

  function pagerFor(kind, item, stage) {
    const entries = stageItems(stage);
    const index = entries.findIndex((e) => e.kind === kind && e.item.id === item.id);
    const prev = entries[index - 1];
    const next = entries[index + 1];
    if (!prev && !next) return '';
    const link = (entry, cls, label) =>
      entry
        ? `<a class="${cls}" href="${hrefFor(entry.kind, entry.item.id)}"><small>${label}</small>${esc(entry.item.title)}</a>`
        : '';
    return `<div class="pager">${link(prev, 'pager-prev', '&larr; Previous')}${link(next, 'pager-next', 'Next &rarr;')}</div>`;
  }

  async function renderLesson(kind, id) {
    const found = findItem(kind, id);
    if (!found) return notFound();
    const { stage, item } = found;
    document.title = `${item.title} | Robodarshan Learning Portal`;
    state.openStages.add(stage.id);

    const crumbTrail = crumbs([
      { label: 'Learnings', href: '#/' },
      { label: `Stage ${stage.number}`, href: `#/stage/${stage.number}` },
      { label: item.title },
    ]);

    const hasPdf = kind !== 'session' && (await pdfExists(item.pdf_url));

    const chips = `
      <div class="chip-row">
        <span class="chip">${KIND_LABEL[kind]}</span>
        <span class="chip chip-xp">${ICONS.bolt}+${esc(item.xp_value)} XP</span>
        ${statusChip(kind, item.id)}
        ${hasPdf ? `<a class="chip chip-link" href="${escAttr(item.pdf_url)}" target="_blank" rel="noopener noreferrer">${ICONS.pdf}Download PDF</a>` : ''}
      </div>`;

    if (kind === 'session') {
      return `
        ${crumbTrail}
        <h1 class="doc-title">${esc(item.title)}</h1>
        ${chips}
        <div class="prose"><p>${multiline(item.content || 'Details will be shared soon.')}</p></div>
        <h2 class="doc-section-title" id="attendance">Attendance</h2>
        ${completionBox(kind, item, stage)}
        ${pagerFor(kind, item, stage)}`;
    }

    const lessonHtml = await fetchLessonHtml(contentUrlFor(item));
    let body;
    if (lessonHtml) {
      body = `<div class="prose" id="lesson-content">${lessonHtml}</div>`;
    } else if (hasPdf) {
      body = `<div class="prose"><h2>Study material</h2><p class="content-note">The web version of this lesson isn't available yet, so the PDF is shown below.</p>
        <iframe class="pdf-embed" src="${escAttr(item.pdf_url)}" title="${escAttr(item.title)} (PDF)"></iframe></div>`;
    } else {
      body = '<p class="content-note">Study material for this lesson is coming soon.</p>';
    }

    const projectIntro =
      kind === 'project'
        ? `${item.requirements ? `<div class="callout callout-key"><div class="callout-title">Requirements</div><p>${multiline(item.requirements)}</p></div>` : ''}
           ${item.instructions ? `<div class="callout callout-note"><div class="callout-title">Instructions</div><p>${multiline(item.instructions)}</p></div>` : ''}`
        : '';

    return `
      ${crumbTrail}
      <h1 class="doc-title">${esc(item.title)}</h1>
      ${kind === 'topic' && item.learning_objectives ? `<p class="doc-lead">${esc(item.learning_objectives)}</p>` : ''}
      ${chips}
      ${projectIntro}
      ${body}
      <h2 class="doc-section-title" id="quiz">Quiz</h2>
      ${renderQuiz(item.quiz, kind, item.id)}
      <h2 class="doc-section-title" id="complete">${kind === 'topic' ? 'Mark as complete' : 'Submit'}</h2>
      ${completionBox(kind, item, stage)}
      ${pagerFor(kind, item, stage)}`;
  }

  /* ----------------------------------------------------------
     Router
     ---------------------------------------------------------- */

  function parseRoute() {
    const parts = location.hash.replace(/^#\/?/, '').split('/').filter(Boolean);
    if (!parts.length) return { kind: 'home' };
    const [kind, id] = parts;
    if (kind === 'stage' || kind === 'session' || kind === 'topic' || kind === 'project') return { kind, id };
    return { kind: 'home' };
  }

  async function render({ keepScroll = false } = {}) {
    const token = ++routeToken;
    const route = parseRoute();
    const scrollY = window.scrollY;

    if (!keepScroll) els.article.innerHTML = '<p class="docs-loading">Loading...</p>';

    let html;
    if (route.kind === 'home') html = renderHome();
    else if (route.kind === 'stage') html = renderStage(route.id);
    else html = await renderLesson(route.kind, route.id);

    if (token !== routeToken) return; // a newer navigation superseded this one

    els.article.innerHTML = html;
    renderSidebar(route);
    wireQuizzes();
    wireCompletion();
    buildToc();

    if (keepScroll) window.scrollTo(0, scrollY);
    else {
      window.scrollTo(0, 0);
      els.main.focus({ preventScroll: true });
    }
    updateScrollState();
  }

  window.addEventListener('hashchange', () => render());

  /* ----------------------------------------------------------
     Search (Ctrl K)
     ---------------------------------------------------------- */

  function searchIndex() {
    return state.stages.flatMap((stage) =>
      stageItems(stage).map(({ kind, item }) => ({
        kind,
        id: item.id,
        title: item.title,
        where: `Stage ${stage.number} · ${KIND_LABEL[kind]}`,
      }))
    );
  }

  let searchActive = -1;

  function runSearch() {
    const query = els.searchInput.value.trim().toLowerCase();
    searchActive = -1;
    if (!query) {
      els.searchResults.hidden = true;
      return;
    }
    const hits = searchIndex()
      .filter((entry) => entry.title.toLowerCase().includes(query) || entry.where.toLowerCase().includes(query))
      .slice(0, 12);
    els.searchResults.innerHTML = hits.length
      ? hits.map((h) => `<a class="docs-search-result" href="${hrefFor(h.kind, h.id)}">${esc(h.title)}<small>${esc(h.where)}</small></a>`).join('')
      : '<div class="docs-search-empty">No matching lessons.</div>';
    els.searchResults.hidden = false;
  }

  function closeSearch() {
    els.searchResults.hidden = true;
    els.searchInput.value = '';
  }

  els.searchInput.addEventListener('input', runSearch);
  els.searchInput.addEventListener('focus', runSearch);
  els.searchInput.addEventListener('keydown', (event) => {
    const results = [...els.searchResults.querySelectorAll('.docs-search-result')];
    if (event.key === 'Escape') {
      closeSearch();
      els.searchInput.blur();
    } else if (event.key === 'ArrowDown' || event.key === 'ArrowUp') {
      if (!results.length) return;
      event.preventDefault();
      searchActive = (searchActive + (event.key === 'ArrowDown' ? 1 : -1) + results.length) % results.length;
      results.forEach((r, i) => r.classList.toggle('is-active', i === searchActive));
      results[searchActive].scrollIntoView({ block: 'nearest' });
    } else if (event.key === 'Enter' && results.length) {
      event.preventDefault();
      location.hash = results[Math.max(searchActive, 0)].getAttribute('href');
      closeSearch();
      els.searchInput.blur();
    }
  });
  els.searchResults.addEventListener('click', (event) => {
    if (event.target.closest('a')) closeSearch();
  });
  document.addEventListener('click', (event) => {
    if (!event.target.closest('.docs-search')) els.searchResults.hidden = true;
  });
  document.addEventListener('keydown', (event) => {
    if ((event.ctrlKey || event.metaKey) && event.key.toLowerCase() === 'k') {
      event.preventDefault();
      els.searchInput.focus();
      els.searchInput.select();
    }
  });

  /* ----------------------------------------------------------
     Theme
     ---------------------------------------------------------- */

  function syncThemeToggle() {
    els.themeToggle.setAttribute('aria-checked', String(document.documentElement.dataset.theme === 'light'));
  }

  els.themeToggle.addEventListener('click', () => {
    const next = document.documentElement.dataset.theme === 'light' ? 'dark' : 'light';
    document.documentElement.dataset.theme = next;
    try {
      localStorage.setItem('rd-docs-theme', next);
    } catch (err) {
      /* storage unavailable: theme just won't persist */
    }
    syncThemeToggle();
  });
  syncThemeToggle();

  /* ----------------------------------------------------------
     Boot
     ---------------------------------------------------------- */

  async function init() {
    const user = await getCurrentUser();
    if (!user) return; // getCurrentUser() already redirected to login/register
    state.user = user;

    try {
      await loadStages();
      await loadProgress();
    } catch (err) {
      console.error(err.message);
      els.nav.innerHTML = '';
      els.article.innerHTML = '<h1 class="doc-title">Something went wrong</h1><p class="doc-lead">We could not load the portal. Please refresh and try again.</p>';
      return;
    }

    const route = parseRoute();
    const current = route.kind === 'stage' ? state.stages.find((s) => s.number === Number(route.id)) : null;
    const owner = route.kind !== 'home' && route.kind !== 'stage' ? findItem(route.kind, route.id) : null;
    const open = current || owner?.stage || state.stages[0];
    if (open) state.openStages.add(open.id);

    await render();
  }

  init();
})();
