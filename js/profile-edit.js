// Depends on js/supabase-client.js (exposes global `supabaseClient`).
//
// Renders a self-service "Edit Profile" card: every user (any role) can
// update their own name, mobile number, enrollment number and profile
// picture. gsuite_email is shown but never editable (it's how login is
// matched), and role/total_xp/assigned_trainee_id can't be changed here at
// all -- see supabase/migrations/016_self_service_profile_edit.sql, which
// enforces that server-side regardless of what this form sends, and logs
// every change into content_changes (item_type 'user') for admin review.

function escPE(value) {
  const div = document.createElement('div');
  div.textContent = value ?? '';
  return div.innerHTML;
}

function renderProfileEditSection(container, profile, onSaved) {
  container.innerHTML = `
    <div class="dashboard-card profile-edit-card">
      <div class="profile-edit-header">
        <h3 class="section-heading">Edit Profile</h3>
        <button type="button" id="profile-edit-toggle" class="btn btn-outline btn-sm">Edit</button>
      </div>
      <form id="profile-edit-form" class="profile-edit-form" hidden>
        <div class="form-field">
          <label class="field-label" for="profile-edit-name">Full Name</label>
          <input type="text" id="profile-edit-name" class="input" required maxlength="256" value="${escPE(profile.name)}" />
        </div>
        <div class="form-field">
          <label class="field-label" for="profile-edit-mobile">Mobile Number</label>
          <input type="tel" id="profile-edit-mobile" class="input" required maxlength="20" value="${escPE(profile.mobile_number)}" />
        </div>
        <div class="form-field">
          <label class="field-label" for="profile-edit-enrollment">Enrollment Number</label>
          <input type="text" id="profile-edit-enrollment" class="input" required maxlength="50" value="${escPE(profile.enrollment_number)}" />
        </div>
        <div class="form-field">
          <label class="field-label" for="profile-edit-picture">Profile Picture</label>
          <input type="file" id="profile-edit-picture" class="file-input" accept="image/*" />
        </div>
        <div class="form-field">
          <label class="field-label" for="profile-edit-email">Institute Email (not editable)</label>
          <input type="email" id="profile-edit-email" class="input" value="${escPE(profile.gsuite_email)}" disabled />
        </div>
        <div class="profile-edit-actions">
          <button type="submit" id="profile-edit-save" class="btn btn-primary btn-sm">Save Changes</button>
          <button type="button" id="profile-edit-cancel" class="btn btn-outline btn-sm">Cancel</button>
        </div>
        <p id="profile-edit-error" class="announcement-form-error" hidden></p>
        <p id="profile-edit-success" class="profile-edit-success" hidden>Profile updated.</p>

        <div class="profile-edit-danger-zone">
          <span class="field-label">Danger Zone</span>
          <p class="profile-edit-danger-text">Permanently deletes your Robodarshan profile and all progress (completions, XP history, kit records, quiz attempts). This cannot be undone.</p>
          <button type="button" id="profile-delete-account" class="btn btn-danger btn-sm">Delete Account</button>
          <p id="profile-delete-error" class="announcement-form-error" hidden></p>
        </div>
      </form>
    </div>
  `;

  const toggleButton = document.getElementById('profile-edit-toggle');
  const form = document.getElementById('profile-edit-form');
  const cancelButton = document.getElementById('profile-edit-cancel');
  const errorEl = document.getElementById('profile-edit-error');
  const successEl = document.getElementById('profile-edit-success');

  function closeForm() {
    form.hidden = true;
    toggleButton.textContent = 'Edit';
    errorEl.hidden = true;
    successEl.hidden = true;
  }

  toggleButton.addEventListener('click', () => {
    if (form.hidden) {
      form.hidden = false;
      toggleButton.textContent = 'Close';
    } else {
      closeForm();
    }
  });

  cancelButton.addEventListener('click', closeForm);

  form.addEventListener('submit', async (event) => {
    event.preventDefault();
    errorEl.hidden = true;
    successEl.hidden = true;

    const saveButton = document.getElementById('profile-edit-save');
    saveButton.disabled = true;
    saveButton.textContent = 'Saving...';

    try {
      const updates = {
        name: document.getElementById('profile-edit-name').value.trim(),
        mobile_number: document.getElementById('profile-edit-mobile').value.trim(),
        enrollment_number: document.getElementById('profile-edit-enrollment').value.trim(),
      };

      const file = document.getElementById('profile-edit-picture').files[0];
      if (file) {
        const extension = (file.name.split('.').pop() || 'png').toLowerCase();
        const path = `${profile.id}/avatar.${extension}`;

        const { error: uploadError } = await supabaseClient.storage
          .from('profile-pictures')
          .upload(path, file, { upsert: true, contentType: file.type });

        if (uploadError) throw new Error(`Failed to upload profile picture: ${uploadError.message}`);

        const {
          data: { publicUrl },
        } = supabaseClient.storage.from('profile-pictures').getPublicUrl(path);
        // Cache-bust: the URL is otherwise identical (same fixed filename)
        // after re-uploading with the same extension, so the browser/CDN
        // would keep showing the old cached image.
        updates.profile_picture_url = `${publicUrl}?v=${Date.now()}`;
      }

      const { data: updated, error: updateError } = await supabaseClient
        .from('users')
        .update(updates)
        .eq('id', profile.id)
        .select()
        .single();

      if (updateError) throw new Error(`Failed to save changes: ${updateError.message}`);

      Object.assign(profile, updated);
      successEl.hidden = false;
      if (typeof onSaved === 'function') onSaved(updated);
    } catch (err) {
      console.error('Failed to update profile:', err.message);
      errorEl.textContent = err.message;
      errorEl.hidden = false;
    } finally {
      saveButton.disabled = false;
      saveButton.textContent = 'Save Changes';
    }
  });

  const deleteButton = document.getElementById('profile-delete-account');
  const deleteErrorEl = document.getElementById('profile-delete-error');

  deleteButton.addEventListener('click', async () => {
    deleteErrorEl.hidden = true;

    const confirmed = confirm(
      'Delete your Robodarshan account? This permanently removes your profile, XP, and progress, and cannot be undone.'
    );
    if (!confirmed) return;

    deleteButton.disabled = true;
    deleteButton.textContent = 'Deleting...';

    try {
      const { error: deleteError } = await supabaseClient.from('users').delete().eq('id', profile.id);

      if (deleteError) throw new Error(`Failed to delete account: ${deleteError.message}`);

      // Nothing left to show -- sign out and send them to the login page,
      // same as the Logout link (logout() is defined in js/auth.js).
      await logout();
    } catch (err) {
      console.error('Failed to delete account:', err.message);
      deleteErrorEl.textContent = err.message;
      deleteErrorEl.hidden = false;
      deleteButton.disabled = false;
      deleteButton.textContent = 'Delete Account';
    }
  });
}
