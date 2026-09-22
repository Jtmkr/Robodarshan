// Depends on js/supabase-client.js being loaded first (exposes global `supabaseClient`).
// Wires up the contact.html form to insert into the `contact_submissions` table.

(function () {
  const form = document.getElementById('email-form');
  if (!form) return;

  const formBlock = form.closest('.form-block');
  const successMessage = formBlock.querySelector('.success-message');
  const errorMessage = formBlock.querySelector('.error-message');
  const submitButton = form.querySelector('input[type="submit"]');
  const defaultButtonValue = submitButton.value;

  form.addEventListener('submit', async (event) => {
    event.preventDefault();
    // Also stops Webflow's own bundled form-AJAX handler (script_contact.js) from
    // running on this same submit event — it targets the same .w-form-done/
    // .w-form-fail classes and would flip the UI to "error" after we succeed,
    // since it tries (and fails) to POST to Webflow's own defunct form backend.
    event.stopPropagation();

    errorMessage.style.display = 'none';
    submitButton.disabled = true;
    submitButton.value = submitButton.getAttribute('data-wait') || defaultButtonValue;

    const name = form.querySelector('#name').value.trim();
    const email = form.querySelector('#email').value.trim();
    const message = form.querySelector('#Write-Us').value.trim();

    const { error } = await supabaseClient
      .from('contact_submissions')
      .insert({ name, email, message });

    submitButton.disabled = false;
    submitButton.value = defaultButtonValue;

    if (error) {
      console.error('Contact form submission failed:', error.message);
      errorMessage.style.display = 'block';
      return;
    }

    form.style.display = 'none';
    successMessage.style.display = 'block';
  });
})();
