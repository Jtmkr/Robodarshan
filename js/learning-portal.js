// Depends on js/supabase-client.js (exposes global `supabaseClient`), js/auth.js,
// and js/completions.js (markTopicComplete, submitForApproval) being loaded first.
//
// Targets two page types by looking for their container elements:
//   - Stages overview page: <div id="stages-grid"></div> (+ optional
//                            <div id="overall-progress"></div>)
//   - Stage detail page:    a container with [data-stage-id="<number>"] wrapping
//                            #sessions-list, #topics-list, #projects-list, each
//                            paired with a #<section>-progress bar and a
//                            #<section>-count label (see setSectionProgress).
//
// Each topic/project shows exactly three things when expanded: a link to its
// PDF study material, a quiz, and a mark-complete checkbox. Quiz attempts are
// persisted (every attempt, not just the latest) purely as visible history --
// they never affect XP or the dashboard. A topic's checkbox only unlocks once
// its stage's session(s) have been submitted AND its quiz has been attempted
// at least once (correctness doesn't matter); a project's checkbox unlocks
// once its quiz has been attempted at least once.

function esc(value) {
  const div = document.createElement('div');
  div.textContent = value ?? '';
  return div.innerHTML;
}

// For embedding a JSON string inside an HTML attribute (double-quoted) --
// esc() alone isn't enough there since it doesn't escape `"`.
function escAttr(value) {
  return String(value)
    .replace(/&/g, '&amp;')
    .replace(/"/g, '&quot;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;');
}

function completionKey(itemType, itemId) {
  return `${itemType}:${itemId}`;
}

// Tracks which checklist items are currently expanded (by their
// completionKey) so that a re-render -- e.g. after a quiz submit refreshes
// attempt history and unlock state -- can restore the same items open
// instead of collapsing everything back down.
const expandedItems = new Set();

function applyExpansionState(container) {
  container.querySelectorAll('.checklist-item[data-key]').forEach((item) => {
    if (!expandedItems.has(item.dataset.key)) return;
    const header = item.querySelector('.lesson-header');
    const body = item.querySelector('.lesson-body');
    body.hidden = false;
    header.classList.add('expanded');
    const button = header.querySelector('.lesson-expand-button');
    if (button) button.setAttribute('aria-expanded', 'true');
  });
}

// Small, consistent line-icon set (stroke-based, 24x24 viewBox) used across
// the portal so every item type/action reads the same way at a glance.
const ICONS = {
  session:
    '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>',
  topic:
    '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M2 3h6a4 4 0 0 1 4 4v14a3 3 0 0 0-3-3H2z"/><path d="M22 3h-6a4 4 0 0 0-4 4v14a3 3 0 0 1 3-3h7z"/></svg>',
  project:
    '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="6" y="6" width="12" height="12" rx="2"/><line x1="9" y1="2" x2="9" y2="6"/><line x1="15" y1="2" x2="15" y2="6"/><line x1="9" y1="18" x2="9" y2="22"/><line x1="15" y1="18" x2="15" y2="22"/><line x1="2" y1="9" x2="6" y2="9"/><line x1="2" y1="15" x2="6" y2="15"/><line x1="18" y1="9" x2="22" y2="9"/><line x1="18" y1="15" x2="22" y2="15"/></svg>',
  pdf:
    '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="8" y1="13" x2="16" y2="13"/><line x1="8" y1="17" x2="16" y2="17"/></svg>',
  check:
    '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="9"/><path d="M8.5 12.5l2.2 2.2 5-5.2"/></svg>',
  chevron:
    '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="6 9 12 15 18 9"/></svg>',
};

function progressBar(done, total) {
  const percent = total ? Math.round((done / total) * 100) : 0;
  return `<div class="progress-bar"><div class="progress-bar-fill" style="width:${percent}%"></div></div>`;
}

function progressCount(done, total) {
  return `${done}/${total} completed`;
}

// The collapsed summary row shared by sessions/topics/projects: icon, title,
// a secondary description, and whatever controls (XP badge, checkbox/status)
// belong on the right, plus a dedicated expand button with a tap target
// larger than its visible chevron.
function renderCardHeader(iconKey, title, description, controlsHtml) {
  return `
    <div class="lesson-header">
      <div class="lesson-icon">${ICONS[iconKey] || ''}</div>
      <div class="lesson-text">
        <div class="lesson-title">${esc(title)}</div>
        ${description ? `<div class="lesson-desc">${esc(description)}</div>` : ''}
      </div>
      <div class="lesson-controls">
        ${controlsHtml}
        <button type="button" class="lesson-expand-button" aria-expanded="false" aria-label="Expand details">
          <span class="lesson-expand-icon">${ICONS.chevron}</span>
        </button>
      </div>
    </div>
  `;
}

function toggleChecklistItem(item) {
  const header = item.querySelector('.lesson-header');
  const body = item.querySelector('.lesson-body');
  body.hidden = !body.hidden;
  header.classList.toggle('expanded', !body.hidden);
  const button = header.querySelector('.lesson-expand-button');
  if (button) button.setAttribute('aria-expanded', String(!body.hidden));

  const key = item.dataset.key;
  if (key) {
    if (body.hidden) expandedItems.delete(key);
    else expandedItems.add(key);
  }
}

// Clicking anywhere on the header toggles it (except on real controls), and
// the expand button itself is a proper, larger, keyboard-accessible target
// that does the same thing -- both paths share toggleChecklistItem().
function wireCardToggles(container) {
  container.querySelectorAll('.lesson-header').forEach((header) => {
    header.addEventListener('click', (event) => {
      if (event.target.closest('input, .lesson-expand-button, a, label')) return;
      toggleChecklistItem(header.closest('.checklist-item'));
    });
  });

  container.querySelectorAll('.lesson-expand-button').forEach((button) => {
    button.addEventListener('click', (event) => {
      event.stopPropagation();
      toggleChecklistItem(button.closest('.checklist-item'));
    });
  });
}

function renderPdfLink(pdfUrl) {
  if (!pdfUrl) {
    return '<p class="pdf-missing">Study material PDF coming soon.</p>';
  }
  return `<a href="${esc(pdfUrl)}" target="_blank" rel="noopener noreferrer" class="pdf-link">${ICONS.pdf}<span>Open Study Material (PDF)</span></a>`;
}

function renderQuizHistory(attempts) {
  if (!attempts.length) {
    return '<p class="quiz-history-empty">Not attempted yet.</p>';
  }
  return `
    <div class="quiz-history">
      ${attempts.map((a, i) => `<span class="quiz-history-item">Attempt ${i + 1}: ${a.score}/${a.total}</span>`).join('')}
    </div>
  `;
}

// Renders a quiz as an interactive form (radio per question) with a "Check
// Answers" button. Scoring never affects XP -- every attempt is just saved
// as history (via wireQuizzes' submit handler) and multiple attempts are
// allowed (no cap).
function renderQuiz(quiz, itemType, itemId, attempts) {
  if (!quiz || !Array.isArray(quiz) || !quiz.length) return '';

  const nextAttemptNumber = attempts.length + 1;

  return `
    <div class="topic-quiz">
      <div class="quiz-top">
        <span class="quiz-attempt-count">${quiz.length} question${quiz.length === 1 ? '' : 's'} &middot; Attempt #${nextAttemptNumber}</span>
      </div>
      ${renderQuizHistory(attempts)}
      <form class="quiz-form" data-quiz="${escAttr(JSON.stringify(quiz))}" data-item-type="${esc(itemType)}" data-item-id="${esc(itemId)}">
        ${quiz
          .map(
            (q, qi) => `
              <div class="quiz-question">
                <p class="quiz-question-text">${qi + 1}. ${esc(q.question)}</p>
                <div class="quiz-options">
                  ${(q.options || [])
                    .map(
                      (opt, oi) => `
                        <label class="quiz-option">
                          <input type="radio" name="q${qi}" value="${oi}" />
                          <span>${esc(opt)}</span>
                        </label>
                      `
                    )
                    .join('')}
                </div>
              </div>
            `
          )
          .join('')}
        <button type="submit" class="quiz-submit-button">Check Answers</button>
        <div class="quiz-result" hidden></div>
      </form>
    </div>
  `;
}

async function recordQuizAttempt(itemType, itemId, score, total) {
  const user = await getCurrentUser();
  if (!user) throw new Error('Not logged in.');

  const { error } = await supabaseClient.from('quiz_attempts').insert({
    user_id: user.id,
    item_type: itemType,
    item_id: itemId,
    score,
    total,
  });

  if (error) throw new Error(`Failed to record quiz attempt: ${error.message}`);
}

function wireQuizzes(container) {
  container.querySelectorAll('.quiz-form').forEach((form) => {
    form.addEventListener('click', (event) => event.stopPropagation());
    form.addEventListener('submit', async (event) => {
      event.preventDefault();

      const quiz = JSON.parse(form.dataset.quiz);
      let score = 0;

      quiz.forEach((q, qi) => {
        const options = form.querySelectorAll(`input[name="q${qi}"]`);
        const selected = form.querySelector(`input[name="q${qi}"]:checked`);
        const selectedValue = selected ? Number(selected.value) : null;

        options.forEach((opt) => {
          const label = opt.closest('.quiz-option');
          label.classList.remove('quiz-correct', 'quiz-incorrect');
          const optValue = Number(opt.value);
          if (optValue === q.answer) {
            label.classList.add('quiz-correct');
          } else if (optValue === selectedValue) {
            label.classList.add('quiz-incorrect');
          }
        });

        if (selectedValue === q.answer) score += 1;
      });

      const result = form.querySelector('.quiz-result');
      result.hidden = false;
      result.textContent = `You got ${score}/${quiz.length} correct.`;

      const submitButton = form.querySelector('.quiz-submit-button');
      submitButton.disabled = true;

      try {
        await recordQuizAttempt(form.dataset.itemType, form.dataset.itemId, score, quiz.length);
        // Re-render the whole stage section so the attempt history and any
        // now-unlocked mark-complete checkbox reflect the fresh DB state.
        await renderStagePage();
      } catch (err) {
        console.error('Failed to record quiz attempt:', err.message);
        submitButton.disabled = false;
      }
    });
  });
}

async function fetchStageByNumber(stageNumber) {
  const { data, error } = await supabaseClient.from('stages').select('id').eq('number', stageNumber).maybeSingle();

  if (error) {
    console.error('Failed to resolve stage:', error.message);
    return null;
  }

  return data;
}

async function fetchStageItems(stageId) {
  const [sessionsResult, topicsResult, projectsResult] = await Promise.all([
    supabaseClient.from('sessions').select('*').eq('stage_id', stageId).order('created_at', { ascending: true }),
    supabaseClient
      .from('topics')
      .select('*')
      .eq('stage_id', stageId)
      .eq('status', 'published')
      .order('order_index', { ascending: true }),
    supabaseClient.from('projects').select('*').eq('stage_id', stageId).order('order_index', { ascending: true }),
  ]);

  return {
    sessions: sessionsResult.data || [],
    sessionsError: sessionsResult.error,
    topics: topicsResult.data || [],
    topicsError: topicsResult.error,
    projects: projectsResult.data || [],
    projectsError: projectsResult.error,
  };
}

async function fetchCompletionMap(userId, items) {
  const itemIds = items.map((item) => item.id);
  if (!itemIds.length) return new Map();

  const { data, error } = await supabaseClient
    .from('completions')
    .select('item_type, item_id, status')
    .eq('user_id', userId)
    .in('item_id', itemIds);

  if (error) {
    console.error('Failed to load completions:', error.message);
    return new Map();
  }

  const map = new Map();
  (data || []).forEach((row) => map.set(completionKey(row.item_type, row.item_id), row.status));
  return map;
}

// Map of "type:id" -> ordered array of {score, total} attempts (oldest first).
async function fetchQuizAttemptsMap(userId, items) {
  const itemIds = items.map((item) => item.id);
  if (!itemIds.length) return new Map();

  const { data, error } = await supabaseClient
    .from('quiz_attempts')
    .select('item_type, item_id, score, total, attempted_at')
    .eq('user_id', userId)
    .in('item_id', itemIds)
    .order('attempted_at', { ascending: true });

  if (error) {
    console.error('Failed to load quiz attempts:', error.message);
    return new Map();
  }

  const map = new Map();
  (data || []).forEach((row) => {
    const key = completionKey(row.item_type, row.item_id);
    if (!map.has(key)) map.set(key, []);
    map.get(key).push(row);
  });
  return map;
}

function countVerified(items, type, completionMap) {
  return items.filter((item) => completionMap.get(completionKey(type, item.id)) === 'verified').length;
}

async function renderOverallProgress(user) {
  const container = document.getElementById('overall-progress');
  if (!container) return;

  const [sessionsResult, topicsResult, projectsResult] = await Promise.all([
    supabaseClient.from('sessions').select('id'),
    supabaseClient.from('topics').select('id').eq('status', 'published'),
    supabaseClient.from('projects').select('id'),
  ]);

  const sessions = sessionsResult.data || [];
  const topics = topicsResult.data || [];
  const projects = projectsResult.data || [];
  const completionMap = await fetchCompletionMap(user.id, [...sessions, ...topics, ...projects]);

  const sessionsDone = countVerified(sessions, 'session', completionMap);
  const topicsDone = countVerified(topics, 'topic', completionMap);
  const projectsDone = countVerified(projects, 'project', completionMap);
  const totalDone = sessionsDone + topicsDone + projectsDone;
  const totalItems = sessions.length + topics.length + projects.length;

  container.innerHTML = `
    <div class="portal-overview-card">
      <div class="portal-overview-top">
        <span class="portal-overview-label">Overall Progress</span>
        <span class="progress-label">${progressCount(totalDone, totalItems)}</span>
      </div>
      ${progressBar(totalDone, totalItems)}
      <div class="stat-row">
        <div class="stat-item">
          <span class="stat-label">Sessions</span>
          <span class="stat-value">${sessionsDone}/${sessions.length}</span>
        </div>
        <div class="stat-item">
          <span class="stat-label">Topics</span>
          <span class="stat-value">${topicsDone}/${topics.length}</span>
        </div>
        <div class="stat-item">
          <span class="stat-label">Projects</span>
          <span class="stat-value">${projectsDone}/${projects.length}</span>
        </div>
      </div>
    </div>
  `;
}

async function renderStagesList() {
  const container = document.getElementById('stages-grid');
  if (!container) return;

  const user = await getCurrentUser();
  if (!user) return;

  await renderOverallProgress(user);

  const { data: stages, error } = await supabaseClient
    .from('stages')
    .select('*')
    .order('number', { ascending: true });

  if (error) {
    console.error('Failed to load stages:', error.message);
    container.innerHTML = '<p class="paragraph">Could not load stages. Please try again later.</p>';
    return;
  }

  const cards = await Promise.all(
    stages.map(async (stage) => {
      const { sessions, topics, projects } = await fetchStageItems(stage.id);
      const allItems = [
        ...sessions.map((s) => ({ ...s, _type: 'session' })),
        ...topics.map((t) => ({ ...t, _type: 'topic' })),
        ...projects.map((p) => ({ ...p, _type: 'project' })),
      ];
      const completionMap = await fetchCompletionMap(user.id, allItems);
      const done = allItems.filter((item) => completionMap.get(completionKey(item._type, item.id)) === 'verified').length;

      return `
        <a href="stage-${stage.number}.html" class="stage-card">
          <span class="stage-card-number">Stage ${esc(stage.number)}</span>
          <h3 class="stage-card-title">${esc(stage.title)}</h3>
          <span class="stage-card-theme">${esc(stage.theme)}</span>
          <div class="stage-card-progress">
            ${progressBar(done, allItems.length)}
            <span class="progress-label">${progressCount(done, allItems.length)}</span>
          </div>
        </a>
      `;
    })
  );

  container.innerHTML = cards.join('');
}

async function renderStagePage() {
  const stageContainer = document.querySelector('[data-stage-id]');
  if (!stageContainer) return;

  const user = await getCurrentUser();
  if (!user) return;

  const stageNumber = Number(stageContainer.dataset.stageId);

  const stage = await fetchStageByNumber(stageNumber);
  if (!stage) return;

  const { sessions, sessionsError, topics, topicsError, projects, projectsError } = await fetchStageItems(stage.id);
  const allItems = [...sessions, ...topics, ...projects];
  const completionMap = await fetchCompletionMap(user.id, allItems);
  const attemptsMap = await fetchQuizAttemptsMap(user.id, [...topics, ...projects]);

  const sessionsSubmitted =
    sessions.length === 0 || sessions.every((s) => completionMap.has(completionKey('session', s.id)));

  setSectionProgress('sessions-progress', 'sessions-count', countVerified(sessions, 'session', completionMap), sessions.length);
  setSectionProgress('topics-progress', 'topics-count', countVerified(topics, 'topic', completionMap), topics.length);
  setSectionProgress('projects-progress', 'projects-count', countVerified(projects, 'project', completionMap), projects.length);

  renderSessions(sessions, sessionsError, completionMap);
  renderTopics(topics, topicsError, completionMap, attemptsMap, sessionsSubmitted);
  renderProjects(projects, projectsError, completionMap, attemptsMap);
}

function setSectionProgress(barId, countId, done, total) {
  const barEl = document.getElementById(barId);
  if (barEl) barEl.innerHTML = progressBar(done, total);

  const countEl = document.getElementById(countId);
  if (countEl) countEl.textContent = progressCount(done, total);
}

function completionStatusHtml(isDone, pendingLabel) {
  if (isDone) {
    return `<div class="lesson-completion-status is-complete">${ICONS.check}<span>Completed</span></div>`;
  }
  return `<div class="lesson-completion-status">${esc(pendingLabel)}</div>`;
}

function renderApprovalCheckbox(itemType, itemId, status, label, unlocked, lockedTitle) {
  if (status === 'verified') {
    return `<div class="approval-status approval-verified">${ICONS.check}<span>Verified</span></div>`;
  }
  if (status === 'pending') {
    return '<div class="approval-status approval-pending"><span>Pending admin approval</span></div>';
  }
  return `
    <label class="topic-complete-checkbox">
      <input type="checkbox" class="submit-approval-checkbox" data-item-type="${esc(itemType)}" data-item-id="${esc(itemId)}" ${unlocked ? '' : 'disabled'} title="${unlocked ? 'Mark Attendance' : esc(lockedTitle)}" />
      <span>${unlocked ? esc(label) : esc(lockedTitle)}</span>
    </label>
  `;
}

function buildApprovalStatusElement(completion) {
  const status = document.createElement('div');
  const isVerified = completion?.status === 'verified';
  status.className = `approval-status ${isVerified ? 'approval-verified' : 'approval-pending'}`;
  status.innerHTML = isVerified ? `${ICONS.check}<span>Verified</span>` : '<span>Pending admin approval</span>';
  return status;
}

function wireApprovalCheckboxes(container) {
  container.querySelectorAll('.submit-approval-checkbox').forEach((checkbox) => {
    checkbox.addEventListener('click', (event) => event.stopPropagation());
    checkbox.addEventListener('change', async () => {
      if (!checkbox.checked) return;
      checkbox.disabled = true;
      try {
        const completion = await submitForApproval(checkbox.dataset.itemType, checkbox.dataset.itemId);
        checkbox.closest('.topic-complete-checkbox').replaceWith(buildApprovalStatusElement(completion));
      } catch (err) {
        console.error('Failed to submit for approval:', err.message);
        checkbox.checked = false;
        checkbox.disabled = false;
      }
    });
  });
}

function renderSessions(data, error, completionMap) {
  const container = document.getElementById('sessions-list');
  if (!container) return;

  if (error) {
    console.error('Failed to load sessions:', error.message);
    container.innerHTML = '<p class="paragraph">Could not load sessions.</p>';
    return;
  }

  if (!data.length) {
    container.innerHTML = '<p class="paragraph">No sessions yet.</p>';
    return;
  }

  container.innerHTML = data
    .map((session) => {
      const status = completionMap.get(completionKey('session', session.id));
      const isDone = status === 'verified';
      const controls = `
        <span class="xp-info">
          <span class="xp-badge">+${esc(session.xp_value)} XP</span>
          <span class="xp-badge-note">Admin approval</span>
        </span>
      `;

      return `
        <div class="checklist-item ${isDone ? 'item-done' : ''}" data-key="${esc(completionKey('session', session.id))}">
          ${renderCardHeader('session', session.title, session.content, controls)}
          <div class="lesson-body" hidden>
            <div class="lesson-body-section">
              <h5 class="lesson-body-heading">Details</h5>
              <p class="lesson-body-text">${esc(session.content)}</p>
            </div>
            <div class="lesson-body-section">
              ${renderApprovalCheckbox('session', session.id, status, 'Mark Attendance', true, '')}
            </div>
          </div>
        </div>
      `;
    })
    .join('');

  wireCardToggles(container);
  wireApprovalCheckboxes(container);
  applyExpansionState(container);
}

// Topics render as collapsible lesson cards. Expanding one shows exactly
// three things: the PDF study material link, the quiz, and the
// mark-complete checkbox/completion status.
function renderTopics(data, error, completionMap, attemptsMap, sessionsSubmitted) {
  const container = document.getElementById('topics-list');
  if (!container) return;

  if (error) {
    console.error('Failed to load topics:', error.message);
    container.innerHTML = '<p class="paragraph">Could not load topics.</p>';
    return;
  }

  if (!data.length) {
    container.innerHTML = '<p class="paragraph">No topics yet.</p>';
    return;
  }

  container.innerHTML = data
    .map((topic) => {
      const status = completionMap.get(completionKey('topic', topic.id));
      const isDone = status === 'verified';
      const attempts = attemptsMap.get(completionKey('topic', topic.id)) || [];
      const attempted = attempts.length > 0;
      const canMark = sessionsSubmitted && attempted;

      let pendingLabel = 'Mark chapter complete to finish';
      if (!sessionsSubmitted) pendingLabel = 'Mark Session Attendance first to unlock';
      else if (!attempted) pendingLabel = 'Attempt the quiz at least once to unlock';

      const checkboxTitle = isDone ? 'Completed' : pendingLabel;
      const checkbox = `
        <input type="checkbox" class="mark-complete-checkbox" data-topic-id="${esc(topic.id)}" ${isDone || !canMark ? 'disabled' : ''} ${isDone ? 'checked' : ''} aria-label="Mark chapter complete" title="${esc(checkboxTitle)}" />
      `;
      const controls = `
        <span class="xp-badge">+${esc(topic.xp_value)} XP</span>
        ${checkbox}
      `;

      return `
        <div class="checklist-item ${isDone ? 'item-done' : ''}" data-key="${esc(completionKey('topic', topic.id))}">
          ${renderCardHeader('topic', topic.title, topic.learning_objectives, controls)}
          <div class="lesson-body" hidden>
            <div class="lesson-body-section">
              <h5 class="lesson-body-heading">Study Material</h5>
              ${renderPdfLink(topic.pdf_url)}
            </div>
            <div class="lesson-body-section">
              <h5 class="lesson-body-heading">Quiz</h5>
              ${renderQuiz(topic.quiz, 'topic', topic.id, attempts)}
            </div>
            ${completionStatusHtml(isDone, pendingLabel)}
          </div>
        </div>
      `;
    })
    .join('');

  wireCardToggles(container);
  wireQuizzes(container);
  applyExpansionState(container);

  container.querySelectorAll('.mark-complete-checkbox').forEach((checkbox) => {
    checkbox.addEventListener('click', (event) => event.stopPropagation());
    checkbox.addEventListener('change', async () => {
      if (!checkbox.checked) return;
      checkbox.disabled = true;
      const item = checkbox.closest('.checklist-item');
      try {
        await markTopicComplete(checkbox.dataset.topicId);
        item.classList.add('item-done');
        const statusEl = item.querySelector('.lesson-completion-status');
        if (statusEl) {
          statusEl.classList.add('is-complete');
          statusEl.innerHTML = `${ICONS.check}<span>Completed</span>`;
        }
      } catch (err) {
        console.error('Failed to mark topic complete:', err.message);
        checkbox.checked = false;
        checkbox.disabled = false;
      }
    });
  });
}

function renderProjects(data, error, completionMap, attemptsMap) {
  const container = document.getElementById('projects-list');
  if (!container) return;

  if (error) {
    console.error('Failed to load projects:', error.message);
    container.innerHTML = '<p class="paragraph">Could not load projects.</p>';
    return;
  }

  if (!data.length) {
    container.innerHTML = '<p class="paragraph">No projects yet.</p>';
    return;
  }

  container.innerHTML = data
    .map((project) => {
      const status = completionMap.get(completionKey('project', project.id));
      const isDone = status === 'verified';
      const attempts = attemptsMap.get(completionKey('project', project.id)) || [];
      const attempted = attempts.length > 0;
      const description = project.requirements || project.instructions || '';

      const controls = `
        <span class="xp-info">
          <span class="xp-badge">+${esc(project.xp_value)} XP</span>
          <span class="xp-badge-note">Admin approval</span>
        </span>
      `;

      return `
        <div class="checklist-item ${isDone ? 'item-done' : ''}" data-key="${esc(completionKey('project', project.id))}">
          ${renderCardHeader('project', project.title, description, controls)}
          <div class="lesson-body" hidden>
            ${project.requirements ? `<div class="lesson-body-section"><h5 class="lesson-body-heading">Requirements</h5><p class="lesson-body-text">${esc(project.requirements)}</p></div>` : ''}
            ${project.instructions ? `<div class="lesson-body-section"><h5 class="lesson-body-heading">Instructions</h5><p class="lesson-body-text">${esc(project.instructions)}</p></div>` : ''}
            <div class="lesson-body-section">
              <h5 class="lesson-body-heading">Study Material</h5>
              ${renderPdfLink(project.pdf_url)}
            </div>
            <div class="lesson-body-section">
              <h5 class="lesson-body-heading">Quiz</h5>
              ${renderQuiz(project.quiz, 'project', project.id, attempts)}
            </div>
            <div class="lesson-body-section">
              ${renderApprovalCheckbox('project', project.id, status, 'Submit for Review', attempted, 'Attempt the quiz at least once to unlock')}
            </div>
          </div>
        </div>
      `;
    })
    .join('');

  wireCardToggles(container);
  wireApprovalCheckboxes(container);
  wireQuizzes(container);
  applyExpansionState(container);
}

renderStagesList();
renderStagePage();
