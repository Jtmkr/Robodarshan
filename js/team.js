// Renders team.html's whole team-grid (leadership + Veteran "CORE MEMBER"
// entries) from the team_members table. Both kinds of rows live in the
// same table now (see supabase/migrations/014_leadership_team_members_and_dedupe.sql):
// leadership rows are curated manually, Veteran rows are auto-synced from
// users, so this page needs no manual editing when someone is promoted.
(function () {
  async function renderTeam() {
    var grid = document.getElementById('team-grid') || document.querySelector('.team-grid');
    if (!grid || !window.supabaseClient) return;

    var result = await window.supabaseClient
      .from('team_members')
      .select('name, position, photo_url, display_order')
      .order('display_order', { ascending: true });

    if (result.error) {
      console.error('Failed to load team members:', result.error.message);
      grid.innerHTML = '<p class="paragraph">Could not load the team right now.</p>';
      return;
    }

    var members = result.data || [];
    grid.innerHTML = '';

    if (!members.length) {
      grid.innerHTML = '<p class="paragraph">No team members yet.</p>';
      return;
    }

    members.forEach(function (member) {
      var card = document.createElement('div');
      card.className = 'team-card';

      var photoWrapper = document.createElement('div');
      photoWrapper.className = 'member-photo-wrapper';

      var img = document.createElement('img');
      img.className = 'member-img';
      img.alt = member.name;
      if (member.photo_url) img.src = member.photo_url;
      photoWrapper.appendChild(img);

      var name = document.createElement('h3');
      name.className = 'member-name';
      name.textContent = member.name;

      var role = document.createElement('p');
      role.className = 'member-role';
      role.textContent = member.position;

      card.appendChild(photoWrapper);
      card.appendChild(name);
      card.appendChild(role);
      grid.appendChild(card);
    });
  }

  renderTeam();
})();
