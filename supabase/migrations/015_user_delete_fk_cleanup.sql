-- =========================================================
-- Migration: let a user row be deleted even after they've been
-- someone's assigned Trainee, verified/approved someone else's
-- work, assigned a kit, posted an announcement, or edited
-- content -- none of those "actor" columns should block deleting
-- the actor, they should just fall back to NULL (unknown/former
-- user), the same way user_id columns already cascade-delete the
-- rows that person actually owns.
--
-- Postgres's default constraint name is "<table>_<column>_fkey"
-- since schema.sql never named these explicitly, which is what
-- the "users_assigned_trainee_id_fkey" error refers to.
-- =========================================================

alter table public.users
  drop constraint if exists users_assigned_trainee_id_fkey,
  add constraint users_assigned_trainee_id_fkey
    foreign key (assigned_trainee_id) references public.users(id) on delete set null;

alter table public.completions
  drop constraint if exists completions_verified_by_fkey,
  add constraint completions_verified_by_fkey
    foreign key (verified_by) references public.users(id) on delete set null;

alter table public.xp_transactions
  drop constraint if exists xp_transactions_approved_by_fkey,
  add constraint xp_transactions_approved_by_fkey
    foreign key (approved_by) references public.users(id) on delete set null;

alter table public.kit_assignments
  drop constraint if exists kit_assignments_assigned_by_fkey,
  add constraint kit_assignments_assigned_by_fkey
    foreign key (assigned_by) references public.users(id) on delete set null;

alter table public.announcements
  drop constraint if exists announcements_posted_by_fkey,
  add constraint announcements_posted_by_fkey
    foreign key (posted_by) references public.users(id) on delete set null;

-- content_changes.changed_by was NOT NULL (it's an audit log of who made a
-- content edit) -- relax that so deleting the actor doesn't get blocked or
-- require deleting audit history; the row itself, and what it recorded,
-- still stays.
alter table public.content_changes
  alter column changed_by drop not null,
  drop constraint if exists content_changes_changed_by_fkey,
  add constraint content_changes_changed_by_fkey
    foreign key (changed_by) references public.users(id) on delete set null;
