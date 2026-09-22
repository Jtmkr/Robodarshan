// Depends on js/supabase-client.js (exposes global `supabaseClient`) and
// js/auth.js being loaded first.
//
// Renders the role-specific section of the dashboard:
//   - Rookie:  their assigned Trainee (mentor) + their own kit/project list.
//   - Trainee: their assigned Rookies + kit and project management for each.
//   - Veteran (and Admin): every Rookie and Trainee, and lets them
//     (re)assign which Trainee mentors a given Rookie, plus announcements.
//
// Nothing here decides roles or promotions -- it only reads/writes the
// assigned_trainee_id pairing, kit_assignments and project_assignments, per
// the RLS policies in supabase/migrations/005_mentorship_and_kits.sql and
// 018_project_assignments.sql. project_assignments is a lightweight Trainee
// -> Rookie project assignment (title/description/optional PDF), unrelated
// to the curriculum `projects` table used by the learning portal/XP system.

function escM(value) {
  const div = document.createElement('div');
  div.textContent = value ?? '';
  return div.innerHTML;
}

function initialsM(name) {
  return (name || '?').trim().charAt(0).toUpperCase() || '?';
}

const EMPTY_STATE_ICON =
  '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="9"/><line x1="12" y1="8" x2="12" y2="12.5"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>';

function emptyStateM(text) {
  return `<div class="empty-state">${EMPTY_STATE_ICON}<span>${escM(text)}</span></div>`;
}

function renderKitList(kits, interactive) {
  if (!kits.length) return emptyStateM('No kits assigned yet.');
  return `
    <div class="kit-list">
      ${kits
        .map(
          (kit) => `
            <div class="kit-row">
              <span class="kit-name">${escM(kit.kit_name)}</span>
              <span class="kit-status ${kit.returned_at ? 'kit-returned' : 'kit-active'}">
                ${kit.returned_at ? 'Returned' : 'Assigned'}
              </span>
              ${
                interactive && !kit.returned_at
                  ? `<button type="button" class="btn btn-outline btn-sm kit-return-button" data-kit-id="${escM(kit.id)}">Mark Returned</button>`
                  : ''
              }
            </div>
          `
        )
        .join('')}
    </div>
  `;
}

function renderProjectList(projects, interactive) {
  if (!projects.length) return emptyStateM('No projects assigned yet.');
  return `
    <div class="kit-list">
      ${projects
        .map(
          (project) => `
            <div class="kit-row project-row">
              <div class="project-row-info">
                <span class="kit-name">${escM(project.title)}</span>
                ${project.description ? `<span class="project-description">${escM(project.description)}</span>` : ''}
                ${
                  project.pdf_url
                    ? `<a href="${escM(project.pdf_url)}" target="_blank" rel="noopener" class="project-pdf-link">View PDF</a>`
                    : ''
                }
              </div>
              ${
                interactive
                  ? `<button type="button" class="btn btn-danger btn-sm project-remove-button" data-project-id="${escM(project.id)}" data-pdf-url="${escM(project.pdf_url || '')}">Remove</button>`
                  : ''
              }
            </div>
          `
        )
        .join('')}
    </div>
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

  const [{ data: kits, error: kitsError }, { data: projects, error: projectsError }] = await Promise.all([
    supabaseClient.from('kit_assignments').select('*').eq('user_id', profile.id).order('assigned_at', { ascending: false }),
    supabaseClient.from('project_assignments').select('*').eq('user_id', profile.id).order('assigned_at', { ascending: false }),
  ]);

  if (kitsError) {
    console.error('Failed to load kits:', kitsError.message);
  }
  if (projectsError) {
    console.error('Failed to load assigned projects:', projectsError.message);
  }

  container.innerHTML = `
    <div class="dashboard-card role-section">
      <h3 class="section-heading">My Mentor</h3>
      ${
        trainee
          ? `
            <div class="member-card">
              <div class="member-card-header">
                <div class="member-avatar-placeholder">${escM(initialsM(trainee.name))}</div>
                <div class="member-info">
                  <div class="member-name">${escM(trainee.name)}</div>
                  <div class="member-email">${escM(trainee.gsuite_email)}</div>
                </div>
              </div>
            </div>
          `
          : emptyStateM('Not yet assigned.')
      }

      <h3 class="section-heading section-heading-spaced">My Kit</h3>
      ${renderKitList(kits || [])}

      <h3 class="section-heading section-heading-spaced">My Projects</h3>
      ${renderProjectList(projects || [])}
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
    container.innerHTML = `<div class="dashboard-card role-section">${emptyStateM('Could not load your assigned Rookies.')}</div>`;
    return;
  }

  const rookieIds = (rookies || []).map((r) => r.id);
  const kitsByRookie = new Map();
  const projectsByRookie = new Map();

  if (rookieIds.length) {
    const [{ data: kits, error: kitsError }, { data: projects, error: projectsError }] = await Promise.all([
      supabaseClient.from('kit_assignments').select('*').in('user_id', rookieIds).order('assigned_at', { ascending: false }),
      supabaseClient.from('project_assignments').select('*').in('user_id', rookieIds).order('assigned_at', { ascending: false }),
    ]);

    if (kitsError) {
      console.error('Failed to load kits:', kitsError.message);
    } else {
      (kits || []).forEach((kit) => {
        if (!kitsByRookie.has(kit.user_id)) kitsByRookie.set(kit.user_id, []);
        kitsByRookie.get(kit.user_id).push(kit);
      });
    }

    if (projectsError) {
      console.error('Failed to load assigned projects:', projectsError.message);
    } else {
      (projects || []).forEach((project) => {
        if (!projectsByRookie.has(project.user_id)) projectsByRookie.set(project.user_id, []);
        projectsByRookie.get(project.user_id).push(project);
      });
    }
  }

  container.innerHTML = `
    <div class="dashboard-card role-section">
      <h3 class="section-heading">My Assigned Rookies</h3>
      ${
        (rookies || []).length
          ? rookies
              .map(
                (rookie) => `
                  <div class="member-card">
                    <div class="member-card-header">
                      <div class="member-avatar-placeholder">${escM(initialsM(rookie.name))}</div>
                      <div class="member-info">
                        <div class="member-name">${escM(rookie.name)}</div>
                        <div class="member-email">${escM(rookie.gsuite_email)}</div>
                      </div>
                      <span class="member-xp-chip">${escM(rookie.total_xp)} XP</span>
                    </div>
                    <div class="member-card-body">
                      <span class="field-label">Kit</span>
                      ${renderKitList(kitsByRookie.get(rookie.id) || [], true)}
                      <form class="assign-kit-form" data-rookie-id="${escM(rookie.id)}">
                        <input type="text" class="input kit-name-input" placeholder="Kit name" required maxlength="100" />
                        <button type="submit" class="btn btn-primary btn-sm">Assign Kit</button>
                      </form>

                      <span class="field-label section-heading-spaced">Projects</span>
                      ${renderProjectList(projectsByRookie.get(rookie.id) || [], true)}
                      <form class="assign-project-form" data-rookie-id="${escM(rookie.id)}">
                        <input type="text" class="input project-title-input" placeholder="Project title" required maxlength="200" />
                        <textarea class="textarea-input project-description-input" placeholder="Description (optional)" rows="2" maxlength="2000"></textarea>
                        <input type="file" class="file-input project-pdf-input" accept="application/pdf" />
                        <button type="submit" class="btn btn-primary btn-sm">Assign Project</button>
                        <p class="announcement-form-error project-form-error" hidden></p>
                      </form>
                    </div>
                  </div>
                `
              )
              .join('')
          : emptyStateM('No Rookies assigned to you yet.')
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

  container.querySelectorAll('.kit-return-button').forEach((button) => {
    button.addEventListener('click', async () => {
      button.disabled = true;
      button.textContent = 'Marking...';

      const { error: updateError } = await supabaseClient
        .from('kit_assignments')
        .update({ returned_at: new Date().toISOString() })
        .eq('id', button.dataset.kitId);

      if (updateError) {
        console.error('Failed to mark kit returned:', updateError.message);
        button.disabled = false;
        button.textContent = 'Mark Returned';
        return;
      }

      await renderTraineeSection(container, profile);
    });
  });

  container.querySelectorAll('.assign-project-form').forEach((form) => {
    form.addEventListener('submit', async (event) => {
      event.preventDefault();

      const title = form.querySelector('.project-title-input').value.trim();
      const description = form.querySelector('.project-description-input').value.trim();
      const file = form.querySelector('.project-pdf-input').files[0];
      const errorEl = form.querySelector('.project-form-error');
      const button = form.querySelector('button');

      if (!title) return;

      errorEl.hidden = true;
      button.disabled = true;
      button.textContent = 'Assigning...';

      try {
        let pdfUrl = null;

        if (file) {
          const safeName = file.name.replace(/[^a-zA-Z0-9.\-_]/g, '_');
          const path = `${Date.now()}-${safeName}`;

          const { error: uploadError } = await supabaseClient.storage.from('project-attachments').upload(path, file, {
            contentType: file.type,
          });

          if (uploadError) throw new Error(`Failed to upload PDF: ${uploadError.message}`);

          const {
            data: { publicUrl },
          } = supabaseClient.storage.from('project-attachments').getPublicUrl(path);
          pdfUrl = publicUrl;
        }

        const { error: insertError } = await supabaseClient.from('project_assignments').insert({
          user_id: form.dataset.rookieId,
          title,
          description: description || null,
          pdf_url: pdfUrl,
          assigned_by: profile.id,
        });

        if (insertError) throw new Error(`Failed to assign project: ${insertError.message}`);

        await renderTraineeSection(container, profile);
      } catch (err) {
        console.error('Failed to assign project:', err.message);
        errorEl.textContent = err.message;
        errorEl.hidden = false;
        button.disabled = false;
        button.textContent = 'Assign Project';
      }
    });
  });

  container.querySelectorAll('.project-remove-button').forEach((button) => {
    button.addEventListener('click', async () => {
      if (!confirm('Remove this project assignment? This cannot be undone.')) return;

      button.disabled = true;
      button.textContent = 'Removing...';

      try {
        const { error: deleteError } = await supabaseClient
          .from('project_assignments')
          .delete()
          .eq('id', button.dataset.projectId);

        if (deleteError) throw new Error(`Failed to remove project: ${deleteError.message}`);

        const pdfUrl = button.dataset.pdfUrl;
        if (pdfUrl) {
          const marker = '/project-attachments/';
          const markerIndex = pdfUrl.indexOf(marker);
          if (markerIndex !== -1) {
            const path = pdfUrl.slice(markerIndex + marker.length);
            const { error: removeError } = await supabaseClient.storage.from('project-attachments').remove([path]);
            if (removeError) console.error('Failed to remove project PDF:', removeError.message);
          }
        }

        await renderTraineeSection(container, profile);
      } catch (err) {
        console.error('Failed to remove project:', err.message);
        button.disabled = false;
        button.textContent = 'Remove';
      }
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
      <h3 class="section-heading">All Rookies</h3>
      ${
        (rookies || []).length
          ? rookies
              .map(
                (rookie) => `
                  <div class="member-card">
                    <div class="member-card-header">
                      <div class="member-avatar-placeholder">${escM(initialsM(rookie.name))}</div>
                      <div class="member-info">
                        <div class="member-name">${escM(rookie.name)}</div>
                        <div class="member-email">${escM(rookie.gsuite_email)}</div>
                      </div>
                      <span class="member-xp-chip">${escM(rookie.total_xp)} XP</span>
                    </div>
                    <div class="member-card-body">
                      <label class="field-label" for="assign-trainee-${escM(rookie.id)}">Assigned Trainee</label>
                      <select id="assign-trainee-${escM(rookie.id)}" class="select-input assign-trainee-select" data-rookie-id="${escM(rookie.id)}">
                        <option value="">-- Unassigned --</option>
                        ${traineeOptions}
                      </select>
                    </div>
                  </div>
                `
              )
              .join('')
          : emptyStateM('No Rookies yet.')
      }
    </div>

    <div class="dashboard-card role-section">
      <h3 class="section-heading">All Trainees</h3>
      ${
        (trainees || []).length
          ? trainees
              .map(
                (trainee) => `
                  <div class="member-card">
                    <div class="member-card-header">
                      <div class="member-avatar-placeholder">${escM(initialsM(trainee.name))}</div>
                      <div class="member-info">
                        <div class="member-name">${escM(trainee.name)}</div>
                        <div class="member-email">${escM(trainee.gsuite_email)}</div>
                      </div>
                    </div>
                  </div>
                `
              )
              .join('')
          : emptyStateM('No Trainees yet.')
      }
    </div>

    <div class="dashboard-card role-section">
      <h3 class="section-heading">Manage Announcements</h3>
      <form id="announcement-form" class="announcement-form">
        <div class="form-field">
          <label class="field-label" for="announcement-title-input">Title</label>
          <input type="text" id="announcement-title-input" class="input" placeholder="Announcement title" required maxlength="200" />
        </div>
        <div class="form-field">
          <label class="field-label" for="announcement-body-input">Details</label>
          <textarea id="announcement-body-input" class="textarea-input" placeholder="What's the announcement?" required rows="3"></textarea>
        </div>
        <div class="form-field">
          <label class="field-label" for="announcement-image-input">Image (optional)</label>
          <input type="file" id="announcement-image-input" class="file-input" accept="image/*" />
        </div>
        <button type="submit" class="btn btn-primary announcement-submit-button">Post Announcement</button>
        <p id="announcement-form-error" class="announcement-form-error" hidden></p>
      </form>

      <h4 class="section-heading section-heading-spaced">Existing Announcements</h4>
      ${
        (announcements || []).length
          ? `<div class="announcement-list">${announcements
              .map(
                (a) => `
                  <div class="announcement-list-item">
                    <span class="announcement-item-title">${escM(a.title)}</span>
                    <span class="announcement-item-date">${new Date(a.created_at).toLocaleDateString()}</span>
                    <button type="button" class="btn btn-danger btn-sm announcement-delete-button" data-announcement-id="${escM(a.id)}" data-image-url="${escM(a.image_url || '')}">Delete</button>
                  </div>
                `
              )
              .join('')}</div>`
          : emptyStateM('No announcements yet.')
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

  container.querySelectorAll('.announcement-delete-button').forEach((button) => {
    button.addEventListener('click', async () => {
      if (!confirm('Delete this announcement? This cannot be undone.')) return;

      button.disabled = true;
      button.textContent = 'Deleting...';

      try {
        const { error: deleteError } = await supabaseClient
          .from('announcements')
          .delete()
          .eq('id', button.dataset.announcementId);

        if (deleteError) throw new Error(`Failed to delete announcement: ${deleteError.message}`);

        const imageUrl = button.dataset.imageUrl;
        if (imageUrl) {
          const marker = '/announcement-images/';
          const markerIndex = imageUrl.indexOf(marker);
          if (markerIndex !== -1) {
            const path = imageUrl.slice(markerIndex + marker.length);
            const { error: removeError } = await supabaseClient.storage.from('announcement-images').remove([path]);
            if (removeError) console.error('Failed to remove announcement image:', removeError.message);
          }
        }

        await renderVeteranSection(container, profile);
      } catch (err) {
        console.error('Failed to delete announcement:', err.message);
        button.disabled = false;
        button.textContent = 'Delete';
      }
    });
  });
}
