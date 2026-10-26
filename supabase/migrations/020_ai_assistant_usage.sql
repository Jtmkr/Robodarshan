-- =========================================================
-- Migration: usage limits for the AI assistant (api/chat.js).
--
-- Rules
--   - 30 questions per member per "AI day", which runs 6:00 AM to the
--     next 6:00 AM Indian Standard Time (Asia/Kolkata). Unused questions
--     simply expire: the next AI day is a fresh row with a count of 0.
--   - At most 5 questions per rolling minute, to stop flooding.
--   - Only members (a row in public.users) can use it.
--
-- Security
--   The tables/functions below are callable ONLY by the server using the
--   service-role key. They take the user id as a parameter, so they must
--   never be executable by anon/authenticated -- otherwise a member could
--   call refund_ai_question() from the browser to reset their own count.
--   The limits are constants in the functions for the same reason.
--
-- Stores counts and timestamps only -- never the questions or answers.
-- Safe to re-run.
-- =========================================================

create table if not exists public.ai_usage (
  user_id uuid not null references public.users(id) on delete cascade,
  session_date date not null,
  question_count integer not null default 0,
  minute_start timestamptz,
  minute_count integer not null default 0,
  primary key (user_id, session_date)
);

-- RLS on with no policies: nobody reads/writes it directly through the API.
alter table public.ai_usage enable row level security;

-- ---------------------------------------------------------
-- The AI "day" (6 AM IST -> 6 AM IST) that `now()` falls in, and when
-- it ends.
-- ---------------------------------------------------------
create or replace function public.ai_session_date()
returns date
language sql
stable
as $$
  select ((now() at time zone 'Asia/Kolkata') - interval '6 hours')::date;
$$;

create or replace function public.ai_session_resets_at()
returns timestamptz
language sql
stable
as $$
  select ((public.ai_session_date() + 1)::timestamp + interval '6 hours') at time zone 'Asia/Kolkata';
$$;

-- ---------------------------------------------------------
-- Reserve one question. Atomic (row lock), so parallel requests can't
-- slip past the limit. Returns jsonb:
--   { ok, reason?, used, remaining, limit, resets_at, retry_after? }
--   reason: 'not_member' | 'daily' | 'minute'
-- A rejected request does not consume a question.
-- ---------------------------------------------------------
create or replace function public.consume_ai_question(p_user uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  daily_limit constant integer := 30;
  minute_limit constant integer := 5;
  today date := public.ai_session_date();
  resets timestamptz := public.ai_session_resets_at();
  row_ public.ai_usage%rowtype;
  wait_s integer;
begin
  if p_user is null or not exists (select 1 from public.users where id = p_user) then
    return jsonb_build_object('ok', false, 'reason', 'not_member');
  end if;

  insert into public.ai_usage (user_id, session_date)
  values (p_user, today)
  on conflict (user_id, session_date) do nothing;

  select * into row_ from public.ai_usage
  where user_id = p_user and session_date = today
  for update;

  if row_.minute_start is null or now() - row_.minute_start >= interval '60 seconds' then
    row_.minute_start := now();
    row_.minute_count := 0;
  end if;

  if row_.question_count >= daily_limit then
    return jsonb_build_object(
      'ok', false, 'reason', 'daily',
      'used', row_.question_count, 'remaining', 0, 'limit', daily_limit, 'resets_at', resets
    );
  end if;

  if row_.minute_count >= minute_limit then
    wait_s := greatest(1, ceil(60 - extract(epoch from (now() - row_.minute_start)))::integer);
    return jsonb_build_object(
      'ok', false, 'reason', 'minute', 'retry_after', wait_s,
      'used', row_.question_count, 'remaining', daily_limit - row_.question_count,
      'limit', daily_limit, 'resets_at', resets
    );
  end if;

  update public.ai_usage
  set question_count = row_.question_count + 1,
      minute_start = row_.minute_start,
      minute_count = row_.minute_count + 1
  where user_id = p_user and session_date = today;

  return jsonb_build_object(
    'ok', true,
    'used', row_.question_count + 1, 'remaining', daily_limit - row_.question_count - 1,
    'limit', daily_limit, 'resets_at', resets
  );
end;
$$;

-- Give back a question when the AI provider failed to answer.
create or replace function public.refund_ai_question(p_user uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  daily_limit constant integer := 30;
  today date := public.ai_session_date();
  row_ public.ai_usage%rowtype;
begin
  update public.ai_usage
  set question_count = greatest(question_count - 1, 0),
      minute_count = greatest(minute_count - 1, 0)
  where user_id = p_user and session_date = today
  returning * into row_;

  return jsonb_build_object(
    'used', coalesce(row_.question_count, 0),
    'remaining', daily_limit - coalesce(row_.question_count, 0),
    'limit', daily_limit,
    'resets_at', public.ai_session_resets_at()
  );
end;
$$;

-- Read-only counter for the chat window.
create or replace function public.get_ai_usage(p_user uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
stable
as $$
declare
  daily_limit constant integer := 30;
  used integer;
begin
  select question_count into used from public.ai_usage
  where user_id = p_user and session_date = public.ai_session_date();

  return jsonb_build_object(
    'used', coalesce(used, 0),
    'remaining', daily_limit - coalesce(used, 0),
    'limit', daily_limit,
    'resets_at', public.ai_session_resets_at()
  );
end;
$$;

-- Server-only: lock the functions down to the service role.
revoke all on function public.consume_ai_question(uuid) from public, anon, authenticated;
revoke all on function public.refund_ai_question(uuid) from public, anon, authenticated;
revoke all on function public.get_ai_usage(uuid) from public, anon, authenticated;
grant execute on function public.consume_ai_question(uuid) to service_role;
grant execute on function public.refund_ai_question(uuid) to service_role;
grant execute on function public.get_ai_usage(uuid) to service_role;
