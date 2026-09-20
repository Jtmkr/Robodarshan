-- =========================================================
-- Migration: real role tiers + XP-driven Member->Rookie
-- promotion + Rookie+ auto-verification for sessions/projects.
--
-- Role model:
--   member  -- default, sessions/projects need admin approval
--   rookie  -- auto-promoted from member at 2000 XP; sessions/
--             projects auto-verify (no admin approval needed)
--   trainee -- admin-assigned only (never automatic)
--   veteran -- admin-assigned only (never automatic)
--   admin   -- unchanged, full permissions
-- =========================================================

alter table public.users drop constraint if exists users_role_check;
alter table public.users add constraint users_role_check
  check (role in ('member', 'rookie', 'trainee', 'veteran', 'admin'));

-- ---------------------------------------------------------
-- Helper: read a user's own role, bypassing RLS (needed inside
-- policies -- a plain subquery against `users` from within a
-- policy on another table is fine, but we centralize it here
-- for reuse, same pattern as is_admin()).
-- ---------------------------------------------------------
create or replace function public.user_role(uid uuid)
returns text
language sql
security definer
set search_path = public
stable
as $$
  select role from public.users where id = uid;
$$;

-- ---------------------------------------------------------
-- Auto-promote member -> rookie at 2000 XP. Never touches
-- trainee/veteran/admin (those are admin-assigned only).
-- ---------------------------------------------------------
create or replace function public.promote_role_by_xp()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.role = 'member' and new.total_xp >= 2000 then
    new.role := 'rookie';
  end if;
  return new;
end;
$$;

drop trigger if exists trg_promote_role_by_xp on public.users;
create trigger trg_promote_role_by_xp
before update of total_xp on public.users
for each row execute function public.promote_role_by_xp();

-- ---------------------------------------------------------
-- Rookie and above can self-verify their own session/project
-- submissions (instant XP, no admin approval) -- members still
-- require admin approval, and topics remain auto-approved for
-- everyone as before.
-- ---------------------------------------------------------
drop policy if exists completions_insert_self on public.completions;
create policy completions_insert_self on public.completions
  for insert to authenticated
  with check (
    user_id = auth.uid()
    and (
      status <> 'verified'
      or item_type = 'topic'
      or public.user_role(auth.uid()) <> 'member'
    )
  );
