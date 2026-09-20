// Depends on js/supabase-client.js (exposes global `supabaseClient`) being
// loaded first. Public, read-only -- works for logged-out visitors too,
// since announcements show on the Home page for everyone.
//
// Targets <div id="announcements-list"></div>: renders each announcement as
// a clickable title that expands to show its image (if any), body, and
// posted date/time.

function escAnn(value) {
  const div = document.createElement('div');
  div.textContent = value ?? '';
  return div.innerHTML;
}

function formatAnnouncementDate(isoString) {
  const date = new Date(isoString);
  return date.toLocaleString(undefined, {
    dateStyle: 'medium',
    timeStyle: 'short',
  });
}

async function renderAnnouncementsList() {
  const container = document.getElementById('announcements-list');
  if (!container) return;

  const { data, error } = await supabaseClient
    .from('announcements')
    .select('*')
    .order('created_at', { ascending: false });

  if (error) {
    console.error('Failed to load announcements:', error.message);
    container.innerHTML = '<p class="paragraph">Could not load announcements.</p>';
    return;
  }

  if (!data.length) {
    container.innerHTML = '<p class="paragraph">No announcements yet.</p>';
    return;
  }

  container.innerHTML = data
    .map(
      (announcement) => `
        <div class="announcement-item">
          <div class="announcement-title-row">
            <span class="announcement-title">${escAnn(announcement.title)}</span>
            <span class="announcement-arrow">&rsaquo;</span>
          </div>
          <div class="announcement-body" hidden>
            ${announcement.image_url ? `<img class="announcement-image" src="${escAnn(announcement.image_url)}" alt="" />` : ''}
            <p class="announcement-details">${escAnn(announcement.body)}</p>
            <div class="announcement-date">${escAnn(formatAnnouncementDate(announcement.created_at))}</div>
          </div>
        </div>
      `
    )
    .join('');

  container.querySelectorAll('.announcement-title-row').forEach((row) => {
    row.addEventListener('click', () => {
      const item = row.closest('.announcement-item');
      const body = item.querySelector('.announcement-body');
      const arrow = row.querySelector('.announcement-arrow');
      body.hidden = !body.hidden;
      arrow.classList.toggle('expanded', !body.hidden);
    });
  });
}

renderAnnouncementsList();
