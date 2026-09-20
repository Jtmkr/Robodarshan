// Depends on js/supabase-client.js (exposes global `supabaseClient`), js/auth.js,
// and js/completions.js (markTopicComplete, submitForApproval) being loaded first.
//
// Targets two page types by looking for their container elements:
//   - Stages overview page: <div id="stages-grid"></div> (+ optional
//                            <div id="overall-progress"></div>)
//   - Stage detail page:    a container with [data-stage-id="<number>"] wrapping
//                            #sessions-list, #topics-list, #projects-list
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

function progressBar(done, total) {
  const percent = total ? Math.round((done / total) * 100) : 0;
  return `
    <div class="progress-bar"><div class="progress-bar-fill" style="width:${percent}%"></div></div>
    <div class="progress-label">${done}/${total} completed</div>
  `;
}

// Single, uniform card theme (light blue) -- no per-item color rotation.
const CARD_ICON = '📘';
const CARD_GRADIENT = 'linear-gradient(135deg, #2563eb, #60a5fa)';

function renderCardHeader(title, subtitle, sideContent) {
  return `
    <div class="lesson-card-header" style="background-image:${CARD_GRADIENT}">
      <div class="lesson-card-icon">${CARD_ICON}</div>
      <div class="lesson-card-text">
        <div class="lesson-card-title">${esc(title)}</div>
        ${subtitle ? `<div class="lesson-card-subtitle">${esc(subtitle)}</div>` : ''}
      </div>
      <div class="lesson-card-side">${sideContent}</div>
    </div>
  `;
}

function wireCardToggles(container) {
  container.querySelectorAll('.lesson-card-header').forEach((header) => {
    header.addEventListener('click', (event) => {
      if (event.target.closest('input, button, a, label')) return;
      const item = header.closest('.checklist-item');
      const body = item.querySelector('.checklist-item-body');
      body.hidden = !body.hidden;
      header.classList.toggle('expanded', !body.hidden);
    });
  });
}

function renderPdfLink(pdfUrl) {
  if (!pdfUrl) {
    return '<p class="pdf-missing">Study material PDF coming soon.</p>';
  }
  return `<a href="${esc(pdfUrl)}" target="_blank" rel="noopener noreferrer" class="pdf-link">&#128196; Open Study Material (PDF)</a>`;
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
// allowed.
function renderQuiz(quiz, itemType, itemId, attempts) {
  if (!quiz || !Array.isArray(quiz) || !quiz.length) return '';

  return `
    <div class="topic-quiz">
      <h5>Quiz</h5>
      <div class="quiz-history-container">${renderQuizHistory(attempts)}</div>
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
                          ${esc(opt)}
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
    ${progressBar(totalDone, totalItems)}
    <div class="progress-chips">
      <span class="progress-chip chip-session">Sessions ${sessionsDone}/${sessions.length}</span>
      <span class="progress-chip chip-topic">Topics ${topicsDone}/${topics.length}</span>
      <span class="progress-chip chip-project">Projects ${projectsDone}/${projects.length}</span>
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
          <div class="stage-card-number">Stage ${esc(stage.number)}</div>
          <h3 class="stage-card-title">${esc(stage.title)}</h3>
          <p class="stage-card-theme">${esc(stage.theme)}</p>
          ${progressBar(done, allItems.length)}
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

  setSectionProgress('sessions-progress', countVerified(sessions, 'session', completionMap), sessions.length);
  setSectionProgress('topics-progress', countVerified(topics, 'topic', completionMap), topics.length);
  setSectionProgress('projects-progress', countVerified(projects, 'project', completionMap), projects.length);

  renderSessions(sessions, sessionsError, completionMap);
  renderTopics(topics, topicsError, completionMap, attemptsMap, sessionsSubmitted);
  renderProjects(projects, projectsError, completionMap, attemptsMap);
}

function setSectionProgress(elementId, done, total) {
  const el = document.getElementById(elementId);
  if (el) el.innerHTML = progressBar(done, total);
}

function renderApprovalCheckbox(itemType, itemId, status, label, unlocked, lockedTitle) {
  if (status === 'verified') {
    return '<div class="approval-status approval-verified">&#10003; Verified</div>';
  }
  if (status === 'pending') {
    return '<div class="approval-status approval-pending">Pending admin approval</div>';
  }
  return `
    <label class="topic-complete-checkbox">
      <input type="checkbox" class="submit-approval-checkbox" data-item-type="${esc(itemType)}" data-item-id="${esc(itemId)}" ${unlocked ? '' : 'disabled'} title="${unlocked ? 'Mark Attendance' : esc(lockedTitle)}" />
      ${unlocked ? esc(label) : esc(lockedTitle)}
    </label>
  `;
}

function buildApprovalStatusElement(completion) {
  const status = document.createElement('div');
  const isVerified = completion?.status === 'verified';
  status.className = `approval-status ${isVerified ? 'approval-verified' : 'approval-pending'}`;
  status.innerHTML = isVerified ? '&#10003; Verified' : 'Pending admin approval';
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
      return `
        <div class="checklist-item ${isDone ? 'item-done' : ''}">
          ${renderCardHeader(session.title, `+${session.xp_value} XP · admin approval required`, '')}
          <div class="checklist-item-body" hidden>
            <div class="portal-card-body">${esc(session.content)}</div>
            ${renderApprovalCheckbox('session', session.id, status, 'Mark Attendance', true, '')}
          </div>
        </div>
      `;
    })
    .join('');

  wireCardToggles(container);
  wireApprovalCheckboxes(container);
}

// Topics render as light-blue, collapsible lesson cards. Expanding one shows
// exactly three things: the PDF study material link, the quiz, and the
// mark-complete checkbox.
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

      let checkboxTitle = 'Mark chapter complete';
      if (!sessionsSubmitted) checkboxTitle = 'Mark Session Attendance first to unlock';
      else if (!attempted) checkboxTitle = 'Attempt the quiz at least once to unlock';

      const checkbox = `
        <input type="checkbox" class="mark-complete-checkbox" data-topic-id="${esc(topic.id)}" ${isDone || !canMark ? 'disabled' : ''} ${isDone ? 'checked' : ''} title="${isDone ? 'Completed' : esc(checkboxTitle)}" />
      `;
      const side = `<span class="xp-chip">+${esc(topic.xp_value)} XP</span>${checkbox}`;

      return `
        <div class="checklist-item ${isDone ? 'item-done' : ''}">
          ${renderCardHeader(topic.title, topic.learning_objectives, side)}
          <div class="checklist-item-body" hidden>
            ${renderPdfLink(topic.pdf_url)}
            ${renderQuiz(topic.quiz, 'topic', topic.id, attempts)}
            <div class="checklist-item-footer">${isDone ? 'Completed' : esc(checkboxTitle)}</div>
          </div>
        </div>
      `;
    })
    .join('');

  wireCardToggles(container);
  wireQuizzes(container);

  container.querySelectorAll('.mark-complete-checkbox').forEach((checkbox) => {
    checkbox.addEventListener('click', (event) => event.stopPropagation());
    checkbox.addEventListener('change', async () => {
      if (!checkbox.checked) return;
      checkbox.disabled = true;
      const item = checkbox.closest('.checklist-item');
      try {
        await markTopicComplete(checkbox.dataset.topicId);
        item.classList.add('item-done');
        item.querySelector('.checklist-item-footer').textContent = 'Completed';
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

      return `
        <div class="checklist-item ${isDone ? 'item-done' : ''}">
          ${renderCardHeader(project.title, `+${project.xp_value} XP · admin approval required`, '')}
          <div class="checklist-item-body" hidden>
            ${renderPdfLink(project.pdf_url)}
            ${renderQuiz(project.quiz, 'project', project.id, attempts)}
            ${renderApprovalCheckbox('project', project.id, status, 'Submit for Review', attempted, 'Attempt the quiz at least once to unlock')}
          </div>
        </div>
      `;
    })
    .join('');

  wireCardToggles(container);
  wireApprovalCheckboxes(container);
  wireQuizzes(container);
}

renderStagesList();
renderStagePage();
