-- =========================================================
-- Migration: distinguish auto-synced "CORE MEMBER" rows from
-- manually-curated leadership rows in team_members, so someone
-- who holds a leadership position (Treasurer, Secretary, ...)
-- and is also a Veteran doesn't get listed twice on team.html,
-- and doesn't lose their real title if later demoted from Veteran.
--
-- Also moves the leadership cards that were hardcoded in
-- team.html into this table, so team.html can render everyone
-- (leadership + Veteran core members) from one query.
-- =========================================================

alter table public.team_members
  add column if not exists is_auto_synced boolean not null default false;

create or replace function public.sync_veteran_team_member()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  existing_id uuid;
begin
  if new.role = 'veteran' then
    select id into existing_id from public.team_members where user_id = new.id limit 1;

    if existing_id is null then
      -- Adopt a manually-seeded row with a matching name that has no
      -- linked account yet -- covers a leadership member who registers
      -- and becomes a Veteran after their row was seeded by name only,
      -- so they get linked instead of duplicated.
      select id into existing_id
      from public.team_members
      where user_id is null and lower(name) = lower(new.name)
      limit 1;
    end if;

    if existing_id is not null then
      -- Only let account edits overwrite name/photo for a pure
      -- auto-synced row. A manually-curated leadership row keeps its
      -- curated name/photo even after being linked to an account --
      -- linking just stops it from being duplicated, it doesn't hand
      -- control of the row over to the account.
      update public.team_members
      set user_id = new.id,
          name = case when is_auto_synced then new.name else name end,
          photo_url = case when is_auto_synced then new.profile_picture_url else photo_url end
      where id = existing_id;
    else
      insert into public.team_members (user_id, name, position, photo_url, display_order, is_auto_synced)
      values (new.id, new.name, 'CORE MEMBER', new.profile_picture_url, 100, true);
    end if;
  else
    -- Only remove rows that exist purely because of Veteran status --
    -- a manually-curated leadership row stays even if its Veteran role
    -- changes.
    delete from public.team_members where user_id = new.id and is_auto_synced = true;
  end if;
  return new;
end;
$$;

-- Fix the duplicate migration 013 created for Shourya: link his existing
-- auto-synced row to his real title instead of listing him twice.
update public.team_members
set position = 'Treasurer',
    is_auto_synced = false,
    display_order = 40,
    photo_url = '/images/treasurer.jpeg'
where user_id = (
  select id from public.users
  where trim(lower(name)) = 'shourya deep bera'
  limit 1
);

-- Seed the other static leadership cards from team.html into the table
-- (no user_id yet -- if one of them registers and becomes a Veteran
-- later, the trigger above links their account by name instead of
-- creating a duplicate). Guarded with NOT EXISTS so this migration can
-- be re-run safely.
insert into public.team_members (name, position, photo_url, display_order, is_auto_synced)
select v.name, v.position, v.photo_url, v.display_order, false
from (
  values
    ('Pratyush Dhital', 'Secretary', '/images/secretary.jpeg', 10),
    ('Anurag Chaurasia', 'Main Coordinator', '/images/Main C.jpeg', 20),
    ('Mandeep Narwade', 'Assistant Secretary', '/images/Ags.jpeg', 30),
    ('Rohan Kudtudkar', 'Design Lead', '/images/design lead.jpeg', 50),
    ('Sumeet Kumar', 'Social Media Manager', '/images/Social.jpeg', 60),
    ('Jit Malakar', 'WebD Lead', '/images/webD.jpg', 70)
) as v(name, position, photo_url, display_order)
where not exists (
  select 1 from public.team_members existing where existing.name = v.name
);
