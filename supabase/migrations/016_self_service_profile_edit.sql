-- =========================================================
-- Migration: let every user edit their own profile (name,
-- mobile number, enrollment number, profile picture) from the
-- app -- gsuite_email stays fixed (it's how login is matched),
-- and role/total_xp/assigned_trainee_id stay admin/Veteran-only
-- regardless of what a self-edit request sends.
--
-- Every self-edit is logged into content_changes (item_type
-- 'user') so an admin can review what changed, the same way
-- session/topic/project edits already are -- viewable directly
-- in Supabase Studio, same as other admin-only data today.
-- =========================================================

-- Let content_changes record profile edits alongside content edits.
alter table public.content_changes
  drop constraint if exists content_changes_item_type_check,
  add constraint content_changes_item_type_check
    check (item_type in ('session', 'topic', 'project', 'user'));

-- A user may update their own row (previously only Veteran/Admin could
-- update any row at all -- there was no self-update policy).
drop policy if exists users_update_self on public.users;
create policy users_update_self on public.users
  for update to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- Pins the fields a self-edit must never be able to change back to their
-- current value, no matter what the update request contains. Only applies
-- to a genuine top-level self-edit (auth.uid() = old.id AND this is the
-- direct update, pg_trigger_depth() = 1) -- a Veteran/Admin editing
-- someone ELSE's row is a different editor and is unaffected either way,
-- but the depth check matters for e.g. apply_xp_transaction's own `update
-- public.users set total_xp = ...`, which happens *while already inside*
-- another trigger (nested update, depth > 1) for the acting user's own
-- row -- without the depth check this would wrongly look like a
-- self-edit and silently undo every XP award.
create or replace function public.enforce_profile_self_edit_limits()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() = old.id and pg_trigger_depth() = 1 then
    new.role := old.role;
    new.total_xp := old.total_xp;
    new.gsuite_email := old.gsuite_email;
    new.assigned_trainee_id := old.assigned_trainee_id;
    new.id := old.id;
    new.created_at := old.created_at;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_enforce_profile_self_edit_limits on public.users;
create trigger trg_enforce_profile_self_edit_limits
before update on public.users
for each row
execute function public.enforce_profile_self_edit_limits();

-- Logs a self-edit's before/after values for the 4 fields a user can
-- actually change, once the update above has been pinned/applied. Same
-- pg_trigger_depth() = 1 guard, so a nested update (e.g. an XP award)
-- can never be misread as a profile edit.
create or replace function public.log_profile_self_edit()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() = old.id and pg_trigger_depth() = 1 and (
    new.name is distinct from old.name
    or new.profile_picture_url is distinct from old.profile_picture_url
    or new.enrollment_number is distinct from old.enrollment_number
    or new.mobile_number is distinct from old.mobile_number
  ) then
    insert into public.content_changes (item_type, item_id, changed_by, change_type, previous_data, new_data)
    values (
      'user',
      new.id,
      new.id,
      'updated',
      jsonb_build_object(
        'name', old.name,
        'profile_picture_url', old.profile_picture_url,
        'enrollment_number', old.enrollment_number,
        'mobile_number', old.mobile_number
      ),
      jsonb_build_object(
        'name', new.name,
        'profile_picture_url', new.profile_picture_url,
        'enrollment_number', new.enrollment_number,
        'mobile_number', new.mobile_number
      )
    );
  end if;
  return new;
end;
$$;

drop trigger if exists trg_log_profile_self_edit on public.users;
create trigger trg_log_profile_self_edit
after update on public.users
for each row
execute function public.log_profile_self_edit();
