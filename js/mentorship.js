// Depends on js/supabase-client.js (exposes global `supabaseClient`) and
// js/auth.js being loaded first.
//
// Renders the role-specific section of the dashboard:
//   - Rookie:  their assigned Trainee (mentor) + their own kit list.
//   - Trainee: their assigned Rookies + kit management for each.
//   - Veteran (and Admin): every Rookie and Trainee, and lets them
//     (re)assign which Trainee mentors a given Rookie.
//
// Nothing here decides roles or promotions -- it only reads/writes the
// assigned_trainee_id pairing and kit_assignments, per the RLS policies in
// supabase/migrations/005_mentorship_and_kits.sql.

function escM(value) {
  const div = document.createElement('div');
  div.textContent = value ?? '';
  return div.innerHTML;
}

function renderKitList(kits) {
  if (!kits.length) return '<p class="paragraph">No kits assigned yet.</p>';
  return `
    <ul class="kit-list">
      ${kits
        .map(
          (kit) => `
            <li>
              ${escM(kit.kit_name)}
              <span class="kit-status ${kit.returned_at ? 'kit-returned' : 'kit-active'}">
                ${kit.returned_at ? 'Returned' : 'Assigned'}
              </span>
            </li>
          `
        )
        .join('')}
    </ul>
  `;
}

async function renderRoleSection(container, profile) {
  if (profile.role === 'rookie') {
    await renderRookieSection(container, profile);
  } else if (profile.role === 'trainee') {
    await renderTraineeSection(container, profile);
  } else if (profile.role === 'veteran' || profile.role === 'admin') {
    await renderVeteranSection(container, profile);
  }
}

async function renderRookieSection(container, profile) {
  let trainee = null;

  if (profile.assigned_trainee_id) {
    const { data, error } = await supabaseClient
      .from('users')
      .select('name, gsuite_email')
      .eq('id', profile.assigned_trainee_id)
      .maybeSingle();

    if (error) {
      console.error('Failed to load assigned trainee:', error.message);
    } else {
      trainee = data;
    }
  }

  const { data: kits, error: kitsError } = await supabaseClient
    .from('kit_assignments')
    .select('*')
    .eq('user_id', profile.id)
    .order('assigned_at', { ascending: false });

  if (kitsError) {
    console.error('Failed to load kits:', kitsError.message);
  }

  container.innerHTML = `
    <div class="dashboard-card role-section">
      <h3>My Mentor</h3>
      <p class="paragraph">${trainee ? `${escM(trainee.name)} (${escM(trainee.gsuite_email)})` : 'Not yet assigned.'}</p>
      <h3>My Kit</h3>
      ${renderKitList(kits || [])}
    </div>
  `;
}

async function renderTraineeSection(container, profile) {
  const { data: rookies, error } = await supabaseClient
    .from('users')
    .select('id, name, gsuite_email, total_xp')
    .eq('assigned_trainee_id', profile.id)
    .order('name', { ascending: true });

  if (error) {
    console.error('Failed to load assigned rookies:', error.message);
    container.innerHTML =
      '<div class="dashboard-card role-section"><p class="paragraph">Could not load your assigned Rookies.</p></div>';
    return;
  }

  const rookieIds = (rookies || []).map((r) => r.id);
  const kitsByRookie = new Map();

  if (rookieIds.length) {
    const { data: kits, error: kitsError } = await supabaseClient
      .from('kit_assignments')
      .select('*')
      .in('user_id', rookieIds)
      .order('assigned_at', { ascending: false });

    if (kitsError) {
      console.error('Failed to load kits:', kitsError.message);
    } else {
      (kits || []).forEach((kit) => {
        if (!kitsByRookie.has(kit.user_id)) kitsByRookie.set(kit.user_id, []);
        kitsByRookie.get(kit.user_id).push(kit);
      });
    }
  }

  container.innerHTML = `
    <div class="dashboard-card role-section">
      <h3>My Assigned Rookies</h3>
      ${
        (rookies || []).length
          ? rookies
              .map(
                (rookie) => `
                  <div class="rookie-row">
                    <div class="rookie-row-header">
                      <strong>${escM(rookie.name)}</strong> (${escM(rookie.gsuite_email)}) &mdash; ${escM(rookie.total_xp)} XP
                    </div>
                    ${renderKitList(kitsByRookie.get(rookie.id) || [])}
                    <form class="assign-kit-form" data-rookie-id="${escM(rookie.id)}">
                      <input type="text" class="kit-name-input" placeholder="Kit name" required maxlength="100" />
                      <button type="submit">Assign Kit</button>
                    </form>
                  </div>
                `
              )
              .join('')
          : '<p class="paragraph">No Rookies assigned to you yet.</p>'
      }
    </div>
  `;

  container.querySelectorAll('.assign-kit-form').forEach((form) => {
    form.addEventListener('submit', async (event) => {
      event.preventDefault();
      const input = form.querySelector('.kit-name-input');
      const kitName = input.value.trim();
      if (!kitName) return;

      const button = form.querySelector('button');
      button.disabled = true;

      const { error: insertError } = await supabaseClient.from('kit_assignments').insert({
        user_id: form.dataset.rookieId,
        kit_name: kitName,
        assigned_by: profile.id,
      });

      if (insertError) {
        console.error('Failed to assign kit:', insertError.message);
        button.disabled = false;
        return;
      }

      await renderTraineeSection(container, profile);
    });
  });
}

async function renderVeteranSection(container, profile) {
  const [{ data: rookies, error: rookiesError }, { data: trainees, error: traineesError }, { data: announcements, error: announcementsError }] =
    await Promise.all([
      supabaseClient
        .from('users')
        .select('id, name, gsuite_email, total_xp, assigned_trainee_id')
        .eq('role', 'rookie')
        .order('name', { ascending: true }),
      supabaseClient.from('users').select('id, name, gsuite_email').eq('role', 'trainee').order('name', { ascending: true }),
      supabaseClient.from('announcements').select('*').order('created_at', { ascending: false }),
    ]);

  if (rookiesError) console.error('Failed to load rookies:', rookiesError.message);
  if (traineesError) console.error('Failed to load trainees:', traineesError.message);
  if (announcementsError) console.error('Failed to load announcements:', announcementsError.message);

  const traineeOptions = (trainees || [])
    .map((trainee) => `<option value="${escM(trainee.id)}">${escM(trainee.name)}</option>`)
    .join('');

  container.innerHTML = `
    <div class="dashboard-card role-section">
      <h3>All Rookies</h3>
      ${
        (rookies || []).length
          ? rookies
              .map(
                (rookie) => `
                  <div class="rookie-row">
                    <div class="rookie-row-header">
                      <strong>${escM(rookie.name)}</strong> (${escM(rookie.gsuite_email)}) &mdash; ${escM(rookie.total_xp)} XP
                    </div>
                    <label class="assign-trainee-label">
                      Assigned Trainee:
                      <select class="assign-trainee-select" data-rookie-id="${escM(rookie.id)}">
                        <option value="">-- Unassigned --</option>
                        ${traineeOptions}
                      </select>
                    </label>
                  </div>
                `
              )
              .join('')
          : '<p class="paragraph">No Rookies yet.</p>'
      }

      <h3>All Trainees</h3>
      ${
        (trainees || []).length
          ? `<ul class="trainee-list">${trainees
              .map((trainee) => `<li>${escM(trainee.name)} (${escM(trainee.gsuite_email)})</li>`)
              .join('')}</ul>`
          : '<p class="paragraph">No Trainees yet.</p>'
      }
    </div>

    <div class="dashboard-card role-section">
      <h3>Manage Announcements</h3>
      <form id="announcement-form" class="announcement-form">
        <input type="text" id="announcement-title-input" placeholder="Title" required maxlength="200" />
        <textarea id="announcement-body-input" placeholder="Details" required rows="3"></textarea>
        <label class="announcement-image-label">Image (optional)</label>
        <input type="file" id="announcement-image-input" accept="image/*" />
        <button type="submit" class="announcement-submit-button">Post Announcement</button>
        <p id="announcement-form-error" class="announcement-form-error" hidden></p>
      </form>

      <h4 class="announcement-existing-heading">Existing Announcements</h4>
      ${
        (announcements || []).length
          ? `<ul class="announcement-existing-list">${announcements
              .map(
                (a) =>
                  `<li>${escM(a.title)} <span class="announcement-existing-date">(${new Date(a.created_at).toLocaleDateString()})</span></li>`
              )
              .join('')}</ul>`
          : '<p class="paragraph">No announcements yet.</p>'
      }
    </div>
  `;

  container.querySelectorAll('.assign-trainee-select').forEach((select) => {
    const rookie = (rookies || []).find((r) => r.id === select.dataset.rookieId);
    if (rookie && rookie.assigned_trainee_id) select.value = rookie.assigned_trainee_id;

    select.addEventListener('change', async () => {
      select.disabled = true;
      const { error: updateError } = await supabaseClient
        .from('users')
        .update({ assigned_trainee_id: select.value || null })
        .eq('id', select.dataset.rookieId);

      if (updateError) {
        console.error('Failed to assign trainee:', updateError.message);
      }
      select.disabled = false;
    });
  });

  const announcementForm = document.getElementById('announcement-form');
  const announcementError = document.getElementById('announcement-form-error');

  announcementForm.addEventListener('submit', async (event) => {
    event.preventDefault();
    announcementError.hidden = true;

    const title = document.getElementById('announcement-title-input').value.trim();
    const body = document.getElementById('announcement-body-input').value.trim();
    const file = document.getElementById('announcement-image-input').files[0];
    const submitButton = announcementForm.querySelector('.announcement-submit-button');

    submitButton.disabled = true;
    submitButton.textContent = 'Posting...';

    try {
      let imageUrl = null;

      if (file) {
        const safeName = file.name.replace(/[^a-zA-Z0-9.\-_]/g, '_');
        const path = `${Date.now()}-${safeName}`;

        const { error: uploadError } = await supabaseClient.storage.from('announcement-images').upload(path, file, {
          contentType: file.type,
        });

        if (uploadError) throw new Error(`Failed to upload image: ${uploadError.message}`);

        const {
          data: { publicUrl },
        } = supabaseClient.storage.from('announcement-images').getPublicUrl(path);
        imageUrl = publicUrl;
      }

      const { error: insertError } = await supabaseClient.from('announcements').insert({
        title,
        body,
        image_url: imageUrl,
        posted_by: profile.id,
      });

      if (insertError) throw new Error(`Failed to post announcement: ${insertError.message}`);

      await renderVeteranSection(container, profile);
    } catch (err) {
      console.error('Failed to post announcement:', err.message);
      announcementError.textContent = err.message;
      announcementError.hidden = false;
      submitButton.disabled = false;
      submitButton.textContent = 'Post Announcement';
    }
  });
}
