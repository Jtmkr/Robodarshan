// Depends on js/supabase-client.js being loaded first (exposes global `supabaseClient`).
//
// Lightweight, read-only auth check for public marketing pages: swaps the
// static "Login" nav/footer links for "Dashboard" when a session already
// exists. Never redirects -- unlike getCurrentUser() in auth.js, this must
// leave anonymous visitors alone on public pages.
//
// The "Study Portal" nav link itself is a permanent, always-visible static
// link (see the nav markup) -- clicking it while logged out naturally lands
// on login.html (learning-portal.html's own getCurrentUser() check handles
// that), so this script doesn't need to touch it.

(function () {
  function applyAuthState(session) {
    if (!session) return;

    const navLoginLink = document.querySelector('.nav-menu a[href="/login.html"]');
    if (navLoginLink) {
      navLoginLink.href = '/dashboard.html';
      navLoginLink.textContent = 'Dashboard';
    }

    document.querySelectorAll('.footer a[href="/login.html"]').forEach((link) => {
      const text = link.textContent.trim();
      if (text === 'Login') {
        link.textContent = 'Dashboard';
        link.href = '/dashboard.html';
      } else if (text === 'Sign Up') {
        link.textContent = 'Learning Portal';
        link.href = '/learning-portal.html';
      }
    });
  }

  // Two paths to the same result, so a slow/stuck getSession() call on a
  // freshly loaded page can't leave the nav stuck on "Login": a direct
  // getSession() check, and onAuthStateChange, which also fires once with
  // the current session immediately on subscribe (not just on future
  // changes) -- whichever resolves first updates the nav.
  supabaseClient.auth
    .getSession()
    .then(({ data: { session } }) => applyAuthState(session))
    .catch((err) => console.error('Failed to read session for nav:', err.message));

  supabaseClient.auth.onAuthStateChange((_event, session) => applyAuthState(session));
})();
