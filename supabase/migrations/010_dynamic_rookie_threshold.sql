-- =========================================================
-- Migration: Member -> Rookie XP threshold is now computed,
-- not a flat 2000. Threshold = every session/topic/project XP
-- value in Stage 1 + Stage 2 (fully) + just the Session XP of
-- Stage 3 -- currently 350 (Stage 1) + 270 (Stage 2) + 50
-- (Stage 3 session) = 670, but computed live so it stays
-- correct if XP values or item counts change later.
-- =========================================================

create or replace function public.rookie_xp_threshold()
returns integer
language sql
security definer
set search_path = public
stable
as $$
  select
    coalesce((
      select sum(s.xp_value) from public.sessions s
      join public.stages st on st.id = s.stage_id
      where st.number in (1, 2)
    ), 0)
    + coalesce((
      select sum(t.xp_value) from public.topics t
      join public.stages st on st.id = t.stage_id
      where st.number in (1, 2)
    ), 0)
    + coalesce((
      select sum(p.xp_value) from public.projects p
      join public.stages st on st.id = p.stage_id
      where st.number in (1, 2)
    ), 0)
    + coalesce((
      select sum(s.xp_value) from public.sessions s
      join public.stages st on st.id = s.stage_id
      where st.number = 3
    ), 0);
$$;

create or replace function public.promote_role_by_xp()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.role = 'member' and new.total_xp >= public.rookie_xp_threshold() then
    new.role := 'rookie';
  end if;
  return new;
end;
$$;
