// Depends on js/supabase-client.js being loaded first (exposes global `supabaseClient`).

const ALLOWED_EMAIL_DOMAIN = 'students.iiests.ac.in';
const LOGIN_PAGE = 'login.html';
const REGISTER_PAGE = 'register.html';
const POST_LOGIN_REDIRECT = 'dashboard.html'; // update if your post-login page is named/located differently

function isAllowedEmail(email) {
  return typeof email === 'string' && email.toLowerCase().endsWith(`@${ALLOWED_EMAIL_DOMAIN}`);
}

async function login() {
  const { error } = await supabaseClient.auth.signInWithOAuth({
    provider: 'google',
    options: {
      redirectTo: `${window.location.origin}/${POST_LOGIN_REDIRECT}`,
      // `hd` only hints Google's account chooser toward this domain, it is not
      // a security boundary by itself — isAllowedEmail() below is what actually enforces it.
      queryParams: {
        hd: ALLOWED_EMAIL_DOMAIN,
      },
    },
  });

  if (error) {
    console.error('Login failed:', error.message);
  }

  return { error };
}

async function logout() {
  const { error } = await supabaseClient.auth.signOut();

  if (error) {
    console.error('Logout failed:', error.message);
  }

  window.location.href = LOGIN_PAGE;

  return { error };
}

supabaseClient.auth.onAuthStateChange(async (event, session) => {
  if (event !== 'SIGNED_IN' || !session?.user) return;

  if (!isAllowedEmail(session.user.email)) {
    console.warn(`Rejected login for ${session.user.email}: outside allowed domain.`);
    await supabaseClient.auth.signOut();
    window.location.href = `${LOGIN_PAGE}?error=domain`;
  }
});

// Session-only check: confirms the visitor is logged in via Supabase Auth,
// but does NOT require a completed `users` profile row. Used by register.html
// itself, which must not redirect back to itself in a loop.
async function getSessionUser() {
  const {
    data: { session },
    error,
  } = await supabaseClient.auth.getSession();

  if (error) {
    console.error('Failed to get session:', error.message);
  }

  if (!session?.user) {
    window.location.href = LOGIN_PAGE;
    return null;
  }

  return session.user;
}

// Full check used by every gated page (dashboard, learning portal, stage
// pages, etc.): requires both a session AND a completed registration row
// in `users`. Redirects to login.html or register.html as appropriate.
// Returns the session user merged with their `users` row as `.profile`.
async function getCurrentUser() {
  const user = await getSessionUser();
  if (!user) return null;

  const { data: profile, error } = await supabaseClient
    .from('users')
    .select('*')
    .eq('id', user.id)
    .maybeSingle();

  if (error) {
    console.error('Failed to load user profile:', error.message);
    return null;
  }

  if (!profile) {
    window.location.href = REGISTER_PAGE;
    return null;
  }

  return { ...user, profile };
}
