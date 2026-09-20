-- =========================================================
-- Migration: auto-award XP the moment a completion becomes
-- 'verified' -- so an admin approving a session/project only
-- has to change ONE field (completions.status) instead of also
-- manually inserting the matching xp_transactions row by hand.
--
-- Looks up the correct xp_value from sessions/topics/projects
-- itself, so the admin doesn't need to know or enter the amount.
-- Runs as SECURITY DEFINER so it can insert into xp_transactions
-- regardless of the calling role's RLS permissions on that table.
-- =========================================================

create or replace function public.award_xp_on_verification()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_xp integer;
begin
  if new.status = 'verified' and (tg_op = 'INSERT' or old.status is distinct from 'verified') then
    if new.item_type = 'session' then
      select xp_value into v_xp from public.sessions where id = new.item_id;
    elsif new.item_type = 'topic' then
      select xp_value into v_xp from public.topics where id = new.item_id;
    elsif new.item_type = 'project' then
      select xp_value into v_xp from public.projects where id = new.item_id;
    end if;

    if v_xp is not null then
      insert into public.xp_transactions (user_id, activity_type, item_id, xp_amount, status, approved_by)
      values (new.user_id, new.item_type, new.item_id, v_xp, 'awarded', new.verified_by);
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_award_xp_on_verification on public.completions;
create trigger trg_award_xp_on_verification
after insert or update on public.completions
for each row execute function public.award_xp_on_verification();
