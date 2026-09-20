// Display helper for the dashboard's XP bar + role badge.
//
// The actual role (member/rookie/trainee/veteran/admin) is authoritative in
// the DB -- member->rookie is auto-promoted by a trigger once total_xp
// reaches rookie_xp_threshold() (see supabase/migrations/010_...), and
// trainee/veteran/admin are admin-assigned only. This file does NOT decide
// role; it only decides how to *display* the XP bar for a given role.
//
// For a plain member, the bar shows progress toward the next automatic
// promotion (Rookie). For rookie/trainee/veteran/admin, promotion is no
// longer XP-driven, so the bar is just a full, cosmetic "you're past that"
// display rather than implying another XP goal.
//
// Depends on js/supabase-client.js (exposes global `supabaseClient`).

function capitalize(word) {
  return word.charAt(0).toUpperCase() + word.slice(1);
}

// Mirrors the DB's rookie_xp_threshold() function via RPC, so the displayed
// "X XP to Rookie" always matches whatever the trigger will actually use --
// no hardcoded number to drift out of sync if XP values/item counts change.
async function getRookieXpThreshold() {
  const { data, error } = await supabaseClient.rpc('rookie_xp_threshold');

  if (error) {
    console.error('Failed to load rookie XP threshold:', error.message);
    return null;
  }

  return data;
}

function getXpDisplay(role, xp, rookieThreshold) {
  const badge = capitalize(role);

  if (role !== 'member') {
    return { badge, percent: 100, subLabel: 'Keep earning XP!' };
  }

  if (!rookieThreshold) {
    return { badge, percent: 0, subLabel: `${xp} XP` };
  }

  const percent = Math.min(100, Math.max(0, Math.round((xp / rookieThreshold) * 100)));
  const remaining = Math.max(0, rookieThreshold - xp);
  const subLabel = remaining > 0 ? `${remaining} XP to Rookie` : 'Promoting to Rookie...';

  return { badge, percent, subLabel };
}
