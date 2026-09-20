-- =========================================================
-- Migration: auto-sync Veteran users into team_members so they
-- show up on team.html as "CORE MEMBER" with no manual entry.
--
-- team_members already existed (public-read table backing
-- team.html) but was unused -- team.html was fully static HTML.
-- This links it to users via user_id and keeps it in sync:
--   - role becomes 'veteran'      -> insert/update a CORE MEMBER row
--   - role changes away from 'veteran' -> remove that row
--   - name/profile picture edited while still 'veteran' -> row updated
-- =========================================================

alter table public.team_members
  add column if not exists user_id uuid references public.users(id) on delete cascade;

-- Plain (non-partial) unique index: Postgres already lets NULLs repeat in a
-- unique index, so this still allows any number of manually-added members
-- with no user_id, while still being usable for ON CONFLICT (user_id) below
-- (a partial index isn't picked up by ON CONFLICT inference).
create unique index if not exists team_members_user_id_key
  on public.team_members (user_id);

create or replace function public.sync_veteran_team_member()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.role = 'veteran' then
    insert into public.team_members (user_id, name, position, photo_url, display_order)
    values (new.id, new.name, 'CORE MEMBER', new.profile_picture_url, 100)
    on conflict (user_id) do update
      set name = excluded.name,
          photo_url = excluded.photo_url,
          position = 'CORE MEMBER';
  else
    delete from public.team_members where user_id = new.id;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_sync_veteran_team_member on public.users;
create trigger trg_sync_veteran_team_member
after insert or update of role, name, profile_picture_url on public.users
for each row
execute function public.sync_veteran_team_member();

-- Backfill: pick up any user who is already a Veteran right now.
insert into public.team_members (user_id, name, position, photo_url, display_order)
select id, name, 'CORE MEMBER', profile_picture_url, 100
from public.users
where role = 'veteran'
on conflict (user_id) do update
  set name = excluded.name,
      photo_url = excluded.photo_url,
      position = 'CORE MEMBER';
