// Depends on js/supabase-client.js (exposes global `supabaseClient`) and js/auth.js being loaded first.
//
// Topics are auto-approved (per spec) -- this goes straight to status='verified'
// with no admin step, unlike sessions/projects which require approval elsewhere.
//
// The matching xp_transactions row is NOT inserted here -- a DB trigger
// (award_xp_on_verification, see supabase/migrations/003_...) does that
// automatically whenever a completions row's status becomes 'verified',
// for topics, sessions, and projects alike. This keeps the "admin only has
// to flip one field" behavior consistent for every item type.

async function markTopicComplete(topicId) {
  const user = await getCurrentUser();
  if (!user) {
    throw new Error('Not logged in.');
  }

  const { data: existing, error: selectError } = await supabaseClient
    .from('completions')
    .select('id, status')
    .eq('user_id', user.id)
    .eq('item_type', 'topic')
    .eq('item_id', topicId)
    .maybeSingle();

  if (selectError) {
    throw new Error(`Failed to check existing completion: ${selectError.message}`);
  }

  if (existing && existing.status === 'verified') {
    return existing;
  }

  const now = new Date().toISOString();

  const { data: completion, error: upsertError } = await supabaseClient
    .from('completions')
    .upsert(
      {
        user_id: user.id,
        item_type: 'topic',
        item_id: topicId,
        status: 'verified',
        submitted_at: now,
        verified_at: now,
      },
      { onConflict: 'user_id,item_type,item_id' }
    )
    .select()
    .single();

  if (upsertError) {
    throw new Error(`Failed to save completion: ${upsertError.message}`);
  }

  return completion;
}

// Plain members need admin approval before XP is granted for a session/
// project -- this records status='pending' and the xp_transactions row is
// inserted later by an admin verifying it. Rookie and above are trusted to
// self-verify: their submission goes straight to status='verified' and XP
// is awarded immediately (the award_xp_on_verification DB trigger handles
// the xp_transactions insert either way -- this function never inserts one
// itself).
async function submitForApproval(itemType, itemId) {
  if (itemType !== 'session' && itemType !== 'project') {
    throw new Error(`submitForApproval() does not support item type "${itemType}".`);
  }

  const user = await getCurrentUser();
  if (!user) {
    throw new Error('Not logged in.');
  }

  const { data: existing, error: selectError } = await supabaseClient
    .from('completions')
    .select('id, status')
    .eq('user_id', user.id)
    .eq('item_type', itemType)
    .eq('item_id', itemId)
    .maybeSingle();

  if (selectError) {
    throw new Error(`Failed to check existing submission: ${selectError.message}`);
  }

  if (existing) {
    return existing;
  }

  const autoVerify = user.profile.role !== 'member';
  const now = new Date().toISOString();

  const { data: completion, error: insertError } = await supabaseClient
    .from('completions')
    .insert({
      user_id: user.id,
      item_type: itemType,
      item_id: itemId,
      status: autoVerify ? 'verified' : 'pending',
      submitted_at: now,
      verified_at: autoVerify ? now : null,
      verified_by: autoVerify ? user.id : null,
    })
    .select()
    .single();

  if (insertError) {
    throw new Error(`Failed to submit for approval: ${insertError.message}`);
  }

  return completion;
}
