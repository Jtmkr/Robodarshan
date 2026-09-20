// Display helper for the dashboard's XP bar + role badge.
//
// The actual role (member/rookie/trainee/veteran/admin) is authoritative in
// the DB -- member->rookie is auto-promoted by a trigger at 2000 XP, and
// trainee/veteran/admin are admin-assigned only. This file does NOT decide
// role; it only decides how to *display* the XP bar for a given role.
//
// For a plain member, the bar shows progress toward the next automatic
// promotion (Rookie). For rookie/trainee/veteran/admin, promotion is no
// longer XP-driven, so the bar is just a full, cosmetic "you're past that"
// display rather than implying another XP goal.
const XP_TO_ROOKIE = 2000;

function capitalize(word) {
  return word.charAt(0).toUpperCase() + word.slice(1);
}

function getXpDisplay(role, xp) {
  const badge = capitalize(role);

  if (role !== 'member') {
    return { badge, percent: 100, subLabel: 'Keep earning XP!' };
  }

  const percent = Math.min(100, Math.max(0, Math.round((xp / XP_TO_ROOKIE) * 100)));
  const remaining = Math.max(0, XP_TO_ROOKIE - xp);
  const subLabel = remaining > 0 ? `${remaining} XP to Rookie` : 'Promoting to Rookie...';

  return { badge, percent, subLabel };
}
