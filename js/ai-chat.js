// Floating AI assistant for logged-in members.
//
// Needs js/supabase-client.js (global `supabaseClient`) loaded first, and
// css/ai-chat.css. Talks to the serverless function at /api/chat, which holds
// the Gemini key and enforces the limits (30 questions per 6 AM - 6 AM IST day,
// 5 per minute, 1000 words per question). The button only appears once a
// Supabase session exists, so visitors who are not logged in never see it.
//
// Two modes share one window:
//   club      - questions about Robodarshan / the website (answers come from a
//               knowledge file kept on the server)
//   robotics  - a robotics tutor

(function () {
  'use strict';

  if (window.__rdAiChat || typeof supabaseClient === 'undefined') return;
  window.__rdAiChat = true;

  const API_URL = '/api/chat';
  const MAX_WORDS = 1000;
  const HISTORY_SENT = 6;
  const STORE_KEY = 'rd-ai-chat-v1';
  const RETRYABLE = ['gemini_timeout', 'gemini_empty', 'gemini_network', 'gemini_500', 'gemini_502', 'gemini_503', 'gemini_504'];
  const MAX_STORED = 40;
  const IN_PORTAL = location.pathname.indexOf('learning-portal') !== -1;

  const MODES = {
    club: {
      label: 'Club help',
      sub: 'Merch, joining, events, contact',
      placeholder: 'Ask about the club or this website...',
      welcome:
        "Hi! I can answer questions about Robodarshan and this website: merchandise, how to contact us, roles like Rookie, events and the Study Portal.",
      chips: ['How much is the T-shirt?', 'How can I contact the club?', 'How do I become a Rookie?'],
    },
    robotics: {
      label: 'Robotics help',
      sub: 'Electronics, Arduino, sensors, motors',
      placeholder: 'Ask any robotics question...',
      welcome:
        "Hi! Ask me anything about robotics: electronics, Arduino and ESP32, sensors, motors, control and programming. I'll explain step by step.",
      chips: ['What is PWM?', 'Arduino vs ESP32: which one should I use?', 'How does an H-bridge work?'],
    },
  };

  const ICON = {
    chat: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15a2 2 0 0 1-2 2H8l-5 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg>',
    close:
      '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>',
    send: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="22" y1="2" x2="11" y2="13"/><polygon points="22 2 15 22 11 13 2 9 22 2"/></svg>',
    trash:
      '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6"/><path d="M10 11v6M14 11v6M9 6V4a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2"/></svg>',
  };

  const state = {
    open: false,
    mode: 'club',
    messages: { club: [], robotics: [] }, // [{ role: 'user' | 'model', text }]
    usage: null, // { used, remaining, limit, resetsAt }
    busy: false,
    coolUntil: 0, // ms timestamp: per-minute limit
    root: null,
  };
  const el = {};
  let lockTimer = null;

  /* ---------- helpers ---------- */

  function esc(text) {
    return String(text).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
  }

  function wordCount(text) {
    const t = text.trim();
    return t ? t.split(/\s+/).length : 0;
  }

  function loadStored() {
    try {
      const saved = JSON.parse(sessionStorage.getItem(STORE_KEY) || 'null');
      if (saved && saved.messages) {
        ['club', 'robotics'].forEach((m) => {
          if (Array.isArray(saved.messages[m])) state.messages[m] = saved.messages[m].slice(-MAX_STORED);
        });
        if (saved.mode === 'club' || saved.mode === 'robotics') state.mode = saved.mode;
      }
    } catch (err) {
      /* storage unavailable or corrupt: start fresh */
    }
  }

  function saveStored() {
    try {
      sessionStorage.setItem(
        STORE_KEY,
        JSON.stringify({
          mode: state.mode,
          messages: {
            club: state.messages.club.slice(-MAX_STORED),
            robotics: state.messages.robotics.slice(-MAX_STORED),
          },
        })
      );
    } catch (err) {
      /* ignore */
    }
  }

  // Minimal, safe Markdown: everything is escaped first, then a few patterns
  // (code blocks, inline code, bold, lists, links) are turned back into tags.
  function inline(text) {
    return esc(text)
      .replace(/`([^`\n]+)`/g, '<code>$1</code>')
      .replace(/\*\*([^*\n]+)\*\*/g, '<strong>$1</strong>')
      .replace(/\[([^\]\n]+)\]\(((?:https?:\/\/|\/)[^\s)]+)\)/g, (m, label, url) => {
        const external = /^https?:/.test(url);
        return `<a href="${url}"${external ? ' target="_blank" rel="noopener noreferrer"' : ''}>${label}</a>`;
      });
  }

  function markdown(source) {
    const parts = String(source).split(/```/);
    return parts
      .map((part, i) => {
        if (i % 2 === 1) {
          const code = part.replace(/^[a-zA-Z0-9+#-]*\n/, '').replace(/\n$/, '');
          return `<pre><code>${esc(code)}</code></pre>`;
        }
        const out = [];
        let list = null;
        const flush = () => {
          if (list) out.push(`<${list.tag}>${list.items.join('')}</${list.tag}>`);
          list = null;
        };
        part.split('\n').forEach((raw) => {
          const line = raw.trimEnd();
          const bullet = line.match(/^\s*[-*]\s+(.*)/);
          const numbered = line.match(/^\s*\d+[.)]\s+(.*)/);
          if (bullet || numbered) {
            const tag = bullet ? 'ul' : 'ol';
            if (!list || list.tag !== tag) {
              flush();
              list = { tag, items: [] };
            }
            list.items.push(`<li>${inline((bullet || numbered)[1])}</li>`);
          } else if (!line.trim()) {
            flush();
          } else {
            flush();
            const heading = line.match(/^#{1,4}\s+(.*)/);
            out.push(`<p>${heading ? `<strong>${inline(heading[1])}</strong>` : inline(line)}</p>`);
          }
        });
        flush();
        return out.join('');
      })
      .join('');
  }

  function formatWait(ms) {
    const totalMinutes = Math.max(1, Math.ceil(ms / 60000));
    const h = Math.floor(totalMinutes / 60);
    const m = totalMinutes % 60;
    return h ? `${h}h ${m}m` : `${m}m`;
  }

  /* ---------- UI ---------- */

  function build() {
    const root = document.createElement('div');
    root.className = 'rdai';
    root.innerHTML = `
      <button type="button" class="rdai-fab" aria-expanded="false" aria-controls="rdai-panel">${ICON.chat}<span>Ask AI</span></button>
      <section class="rdai-panel" id="rdai-panel" role="dialog" aria-label="AI assistant" hidden>
        <header class="rdai-head">
          <h2 class="rdai-title">Robodarshan Assistant<small data-sub></small></h2>
          <button type="button" class="rdai-icon-btn" data-clear aria-label="Clear this chat" title="Clear this chat">${ICON.trash}</button>
          <button type="button" class="rdai-icon-btn" data-close aria-label="Close assistant">${ICON.close}</button>
        </header>
        <div class="rdai-tabs" role="tablist" aria-label="Assistant mode">
          <button type="button" class="rdai-tab" role="tab" data-mode="club"></button>
          <button type="button" class="rdai-tab" role="tab" data-mode="robotics"></button>
        </div>
        <div class="rdai-log" role="log" aria-live="polite" aria-relevant="additions"></div>
        <footer class="rdai-foot">
          <p class="rdai-lock" role="status" hidden></p>
          <div class="rdai-meta"><span data-left></span><span data-words></span></div>
          <form class="rdai-form">
            <textarea class="rdai-input" rows="1" aria-label="Your question" maxlength="12000"></textarea>
            <button type="submit" class="rdai-send" aria-label="Send question">${ICON.send}</button>
          </form>
          <p class="rdai-fine">AI can make mistakes. Please don't share personal information.</p>
        </footer>
      </section>`;
    document.body.appendChild(root);

    state.root = root;
    el.fab = root.querySelector('.rdai-fab');
    el.panel = root.querySelector('.rdai-panel');
    el.sub = root.querySelector('[data-sub]');
    el.log = root.querySelector('.rdai-log');
    el.lock = root.querySelector('.rdai-lock');
    el.left = root.querySelector('[data-left]');
    el.words = root.querySelector('[data-words]');
    el.form = root.querySelector('.rdai-form');
    el.input = root.querySelector('.rdai-input');
    el.send = root.querySelector('.rdai-send');
    el.tabs = [...root.querySelectorAll('.rdai-tab')];

    el.tabs.forEach((tab) => {
      tab.textContent = MODES[tab.dataset.mode].label;
      tab.addEventListener('click', () => setMode(tab.dataset.mode));
    });
    el.fab.addEventListener('click', openPanel);
    root.querySelector('[data-close]').addEventListener('click', closePanel);
    root.querySelector('[data-clear]').addEventListener('click', clearChat);
    el.form.addEventListener('submit', (event) => {
      event.preventDefault();
      submitInput();
    });
    el.input.addEventListener('input', () => {
      autosize();
      refreshControls();
    });
    el.input.addEventListener('keydown', (event) => {
      if (event.key === 'Enter' && !event.shiftKey && !event.isComposing) {
        event.preventDefault();
        submitInput();
      }
    });
    root.addEventListener('keydown', (event) => {
      if (event.key === 'Escape' && state.open) closePanel();
    });
    // Suggestion chips (rendered into the log)
    el.log.addEventListener('click', (event) => {
      const chip = event.target.closest('.rdai-chip');
      if (chip) ask(chip.dataset.q);
    });
  }

  function autosize() {
    el.input.style.height = 'auto';
    el.input.style.height = `${Math.min(el.input.scrollHeight, 130)}px`;
  }

  function currentPageTitle() {
    if (!IN_PORTAL) return '';
    return document.title.replace(/\s*\|\s*Robodarshan Learning Portal\s*$/, '').replace(/\s*\|\s*Robodarshan\s*$/, '');
  }

  function render() {
    const cfg = MODES[state.mode];
    el.sub.textContent = cfg.sub;
    el.input.placeholder = cfg.placeholder;
    el.tabs.forEach((tab) => tab.setAttribute('aria-selected', String(tab.dataset.mode === state.mode)));

    const items = state.messages[state.mode];
    const parts = [`<div class="rdai-msg is-bot"><div class="rdai-bubble"><p>${esc(cfg.welcome)}</p></div></div>`];
    items.forEach((m) => {
      if (m.role === 'user') {
        parts.push(`<div class="rdai-msg is-user"><div class="rdai-bubble">${esc(m.text)}</div></div>`);
      } else {
        parts.push(`<div class="rdai-msg is-bot"><div class="rdai-bubble">${markdown(m.text)}</div></div>`);
      }
    });
    if (!items.length) {
      const chips = cfg.chips.slice();
      const title = currentPageTitle();
      if (state.mode === 'robotics' && title && title !== 'Learning Portal') {
        chips.unshift(`Explain "${title}" in simple words`);
      }
      parts.push(
        `<div class="rdai-chips">${chips.map((c) => `<button type="button" class="rdai-chip" data-q="${esc(c)}">${esc(c)}</button>`).join('')}</div>`
      );
    }
    if (state.busy) {
      parts.push('<div class="rdai-msg is-bot" data-typing><div class="rdai-bubble"><span class="rdai-typing" aria-label="Thinking"><span></span><span></span><span></span></span></div></div>');
    }
    el.log.innerHTML = parts.join('');
    el.log.scrollTop = el.log.scrollHeight;
    refreshControls();
  }

  function note(text, isError) {
    const div = document.createElement('div');
    div.className = `rdai-note${isError ? ' is-error' : ''}`;
    div.textContent = text;
    el.log.appendChild(div);
    el.log.scrollTop = el.log.scrollHeight;
  }

  function locked() {
    return Boolean(state.usage && state.usage.remaining <= 0 && new Date(state.usage.resetsAt).getTime() > Date.now());
  }

  function refreshControls() {
    const words = wordCount(el.input.value);
    const over = words > MAX_WORDS;
    const isLocked = locked();
    const cooling = state.coolUntil > Date.now();

    el.words.textContent = words ? `${words}/${MAX_WORDS} words` : '';
    el.words.className = over ? 'is-over' : '';

    if (state.usage) {
      const low = state.usage.remaining <= 5;
      el.left.innerHTML = `<span class="${low ? 'is-low' : ''}">${state.usage.remaining}/${state.usage.limit} questions left</span> &middot; resets 6:00 AM IST`;
    } else {
      el.left.textContent = '';
    }

    if (isLocked) {
      el.lock.hidden = false;
      el.lock.textContent = `You've used all ${state.usage.limit} questions for this session. You can ask again in ${formatWait(
        new Date(state.usage.resetsAt).getTime() - Date.now()
      )}.`;
    } else {
      el.lock.hidden = true;
    }

    el.input.disabled = isLocked;
    el.send.disabled = isLocked || state.busy || cooling || over || !el.input.value.trim();
  }

  // While locked, tick the countdown and unlock (by re-reading usage) once the
  // 6 AM reset passes. Also clears the short per-minute cool-down.
  function startTicker() {
    if (lockTimer) return;
    lockTimer = setInterval(() => {
      if (!state.open) return;
      const wasLocked = state.usage && state.usage.remaining <= 0;
      if (wasLocked && !locked()) fetchUsage();
      else refreshControls();
    }, 15000);
  }

  function openPanel() {
    state.open = true;
    el.panel.hidden = false;
    el.fab.setAttribute('aria-expanded', 'true');
    render();
    fetchUsage();
    startTicker();
    setTimeout(() => el.input.focus(), 0);
  }

  function closePanel() {
    state.open = false;
    el.panel.hidden = true;
    el.fab.setAttribute('aria-expanded', 'false');
    el.fab.focus();
  }

  function setMode(mode) {
    if (state.mode === mode) return;
    state.mode = mode;
    saveStored();
    render();
    el.input.focus();
  }

  function clearChat() {
    state.messages[state.mode] = [];
    saveStored();
    render();
  }

  /* ---------- API ---------- */

  async function accessToken() {
    const { data } = await supabaseClient.auth.getSession();
    return data && data.session ? data.session.access_token : null;
  }

  async function callApi(payload) {
    const token = await accessToken();
    if (!token) return { status: 401, data: { error: 'Please log in again to use the assistant.', reason: 'auth' } };
    const response = await fetch(API_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
      body: JSON.stringify(payload),
    });
    let data = {};
    try {
      data = await response.json();
    } catch (err) {
      /* non-JSON (e.g. the function isn't deployed) */
    }
    return { status: response.status, data };
  }

  async function fetchUsage() {
    try {
      const { status, data } = await callApi({ action: 'usage' });
      if (status === 200 && data.usage) state.usage = data.usage;
    } catch (err) {
      /* the counter is a nicety; the server still enforces the limits */
    }
    refreshControls();
  }

  function submitInput() {
    const text = el.input.value.trim();
    if (!text || el.send.disabled) return;
    ask(text, true);
  }

  async function ask(text, fromInput) {
    if (state.busy || locked() || state.coolUntil > Date.now()) return;
    if (wordCount(text) > MAX_WORDS) return;

    const mode = state.mode;
    const history = state.messages[mode].slice(-HISTORY_SENT);
    state.messages[mode].push({ role: 'user', text });
    state.busy = true;
    if (fromInput) {
      el.input.value = '';
      autosize();
    }
    render();

    const send = async () => {
      try {
        return await callApi({ mode, message: text, history, page: currentPageTitle() });
      } catch (err) {
        return { status: 0, data: { error: "Can't reach the assistant. Please check your connection and try again.", reason: 'network' } };
      }
    };

    let outcome = await send();
    // A slow or empty answer from the AI is refunded by the server (it does not
    // use up one of the member's questions), so retry once automatically.
    if (outcome.status === 503 && RETRYABLE.indexOf(outcome.data.code) !== -1) {
      outcome = await send();
    }

    state.busy = false;
    const { status, data } = outcome;
    if (data.usage) state.usage = data.usage;

    if (status === 200 && data.reply) {
      state.messages[mode].push({ role: 'model', text: data.reply });
      saveStored();
      render();
      return;
    }

    // Not answered: take the question back out so it can be edited and resent.
    state.messages[mode].pop();
    saveStored();
    if (fromInput) el.input.value = text;
    render();
    autosize();

    if (data.reason === 'minute') {
      const wait = Number(data.retryAfter) || 30;
      state.coolUntil = Date.now() + wait * 1000;
      setTimeout(refreshControls, wait * 1000 + 100);
    }
    const message =
      data.reason === 'daily'
        ? 'You have used all your questions for this session.'
        : data.error || 'Something went wrong. Please try again.';
    note(data.code ? `${message} (code: ${data.code})` : message, data.reason !== 'minute' && data.reason !== 'daily');
    refreshControls();
  }

  /* ---------- boot ---------- */

  function mount() {
    if (state.root) return;
    loadStored();
    build();
    render();
  }

  function unmount() {
    if (!state.root) return;
    state.root.remove();
    state.root = null;
    state.open = false;
    state.usage = null;
    if (lockTimer) clearInterval(lockTimer);
    lockTimer = null;
    try {
      sessionStorage.removeItem(STORE_KEY);
    } catch (err) {
      /* ignore */
    }
  }

  async function init() {
    const { data } = await supabaseClient.auth.getSession();
    if (data && data.session) mount();
    supabaseClient.auth.onAuthStateChange((event, session) => {
      if (session) mount();
      else unmount();
    });
  }

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init);
  else init();
})();
