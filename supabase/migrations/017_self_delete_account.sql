-- =========================================================
-- Migration: let a user delete their own account (their
-- `users` profile row) from the app. There was no DELETE
-- policy on `users` at all before this -- only Veteran/Admin
-- could update, and nobody but a raw SQL admin could delete.
--
-- Deleting the row cascades to everything that row *owns*
-- (completions, xp_transactions, kit_assignments, quiz_attempts
-- all have `on delete cascade` on user_id already), and
-- everywhere the row was referenced as an *actor* (assigned
-- Trainee, verified_by, approved_by, assigned_by, posted_by,
-- changed_by) is set to NULL instead of blocking the delete,
-- per migration 015.
--
-- Note: this only removes their Robodarshan profile/progress.
-- It does NOT delete the underlying Supabase Auth account itself
-- (auth.users) -- that requires the service-role key, which a
-- browser client must never hold. If they log in again afterward,
-- they'll just be sent back to the registration form.
-- =========================================================

drop policy if exists users_delete_self on public.users;
create policy users_delete_self on public.users
  for delete to authenticated
  using (auth.uid() = id);
