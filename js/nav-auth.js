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

(async function updateNavForAuthState() {
  const {
    data: { session },
  } = await supabaseClient.auth.getSession();

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
})();
