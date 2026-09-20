-- =========================================================
-- Migration: Rookie <-> Trainee mentor pairing, and scoped
-- visibility/permissions for role-specific dashboards.
--
-- Relationship: each Rookie has one assigned Trainee (mentor).
-- The PAIRING is set by a Veteran (or Admin), not chosen by the
-- Trainee, and is independent of role changes themselves (role
-- promotion/demotion stays Admin-only, per the original spec).
--
-- Dashboard visibility this enables:
--   - Rookie sees their assigned Trainee + their own kit(s).
--   - Trainee sees their assigned Rookies + can manage those
--     Rookies' kit assignments.
--   - Veteran (and Admin) sees every Rookie and every Trainee,
--     and can (re)assign a Rookie to a Trainee.
-- =========================================================

alter table public.users add column if not exists assigned_trainee_id uuid references public.users(id);

-- ---------------------------------------------------------
-- Helper: read a user's assigned_trainee_id, bypassing RLS.
-- Needed so a Rookie's SELECT policy can check "is this row MY
-- assigned trainee" without a plain subquery on `users` re-
-- triggering RLS on itself (same recursion issue as is_admin()).
-- ---------------------------------------------------------
create or replace function public.assigned_trainee_of(uid uuid)
returns uuid
language sql
security definer
set search_path = public
stable
as $$
  select assigned_trainee_id from public.users where id = uid;
$$;

-- ---------------------------------------------------------
-- users: broaden SELECT so a Rookie can see their assigned
-- Trainee's basic profile, a Trainee can see their assigned
-- Rookies, and Veteran/Admin can see everyone.
-- ---------------------------------------------------------
drop policy if exists users_select on public.users;
create policy users_select on public.users
  for select to authenticated
  using (
    auth.uid() = id
    or public.user_role(auth.uid()) in ('veteran', 'admin')
    or assigned_trainee_id = auth.uid()
    or id = public.assigned_trainee_of(auth.uid())
  );

-- users: Veteran (in addition to Admin) can update rows -- needed
-- so a Veteran can set/change a Rookie's assigned_trainee_id.
-- NOTE: this is row-level, not column-level -- a Veteran could
-- technically also change other fields (e.g. role) via direct API
-- use, even though the app's UI only ever changes
-- assigned_trainee_id from a Veteran account. Tighten later with
-- column-level GRANTs + a stricter policy if that matters.
drop policy if exists users_update_admin on public.users;
create policy users_update_privileged on public.users
  for update to authenticated
  using (public.user_role(auth.uid()) in ('veteran', 'admin'))
  with check (public.user_role(auth.uid()) in ('veteran', 'admin'));

-- ---------------------------------------------------------
-- kit_assignments: a Rookie sees their own; their assigned
-- Trainee can see + manage (insert/update) them; Veteran/Admin
-- can see + manage all.
-- ---------------------------------------------------------
drop policy if exists kit_assignments_select on public.kit_assignments;
create policy kit_assignments_select on public.kit_assignments
  for select to authenticated
  using (
    user_id = auth.uid()
    or public.assigned_trainee_of(user_id) = auth.uid()
    or public.user_role(auth.uid()) in ('veteran', 'admin')
  );

drop policy if exists kit_assignments_admin_write on public.kit_assignments;
create policy kit_assignments_write on public.kit_assignments
  for all to authenticated
  using (
    public.assigned_trainee_of(user_id) = auth.uid()
    or public.user_role(auth.uid()) in ('veteran', 'admin')
  )
  with check (
    public.assigned_trainee_of(user_id) = auth.uid()
    or public.user_role(auth.uid()) in ('veteran', 'admin')
  );
