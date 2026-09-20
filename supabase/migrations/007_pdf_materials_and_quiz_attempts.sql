-- =========================================================
-- Migration: PDF-based study materials + persistent quiz
-- attempt history.
--
-- Content model change: topics/projects are now presented as
-- (1) a PDF study material, (2) a quiz, (3) a mark-complete
-- checkbox -- instead of the old structured text fields. The
-- old fields (concept, code_example, etc.) are left in place
-- (harmless, just unused by the new UI) so nothing is lost.
--
-- quiz_attempts stores every attempt (score, not just latest)
-- so a member can see "Attempt 1: 3/5, Attempt 2: 5/5" -- this
-- has no effect on XP/dashboard, it's purely informational, and
-- doubles as the signal that gates the mark-complete checkbox
-- ("attempted at least once", correctness doesn't matter).
-- =========================================================

alter table public.topics add column if not exists pdf_url text;
alter table public.projects add column if not exists pdf_url text;

create table if not exists public.quiz_attempts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  item_type text not null check (item_type in ('topic', 'project')),
  item_id uuid not null,
  score integer not null,
  total integer not null,
  attempted_at timestamptz not null default now()
);

create index if not exists quiz_attempts_user_item_idx on public.quiz_attempts(user_id, item_type, item_id);

alter table public.quiz_attempts enable row level security;

drop policy if exists quiz_attempts_select on public.quiz_attempts;
create policy quiz_attempts_select on public.quiz_attempts
  for select to authenticated
  using (user_id = auth.uid() or public.is_admin(auth.uid()));

drop policy if exists quiz_attempts_insert_self on public.quiz_attempts;
create policy quiz_attempts_insert_self on public.quiz_attempts
  for insert to authenticated
  with check (user_id = auth.uid());
