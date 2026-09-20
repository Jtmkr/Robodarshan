-- =========================================================
-- Robodarshan full schema + RLS
-- Run this in the Supabase SQL Editor.
--
-- WARNING: this drops and recreates the 7 existing tables
-- (completions, projects, sessions, stages, topics, users,
-- xp_transactions) which currently only have (id bigint,
-- created_at) placeholder columns -- confirmed empty scaffolds,
-- not the real application schema. It also creates 5 new
-- tables: content_changes, kit_assignments, announcements,
-- contact_submissions, team_members.
-- =========================================================

create extension if not exists pgcrypto;

-- ---------------------------------------------------------
-- Drop existing placeholder tables (reverse dependency order)
-- ---------------------------------------------------------
drop table if exists public.xp_transactions cascade;
drop table if exists public.completions cascade;
drop table if exists public.projects cascade;
drop table if exists public.topics cascade;
drop table if exists public.sessions cascade;
drop table if exists public.stages cascade;
drop table if exists public.users cascade;

-- ---------------------------------------------------------
-- users
-- ---------------------------------------------------------
create table public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  gsuite_email text not null unique,
  name text not null,
  mobile_number text not null,
  enrollment_number text not null,
  personal_email text not null,
  profile_picture_url text not null,
  role text not null default 'member' check (role in ('member', 'rookie', 'trainee', 'veteran', 'admin')),
  total_xp integer not null default 0,
  assigned_trainee_id uuid references public.users(id),
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------
-- stages
-- ---------------------------------------------------------
create table public.stages (
  id serial primary key,
  number integer not null unique,
  title text not null,
  theme text
);

-- ---------------------------------------------------------
-- sessions
-- ---------------------------------------------------------
create table public.sessions (
  id uuid primary key default gen_random_uuid(),
  stage_id integer not null references public.stages(id) on delete cascade,
  title text not null,
  content text,
  xp_value integer not null default 50,
  created_at timestamptz not null default now()
);

create index sessions_stage_id_idx on public.sessions(stage_id);

-- ---------------------------------------------------------
-- topics
-- ---------------------------------------------------------
create table public.topics (
  id uuid primary key default gen_random_uuid(),
  stage_id integer not null references public.stages(id) on delete cascade,
  title text not null,
  learning_objectives text,
  concept text,
  visuals text,
  hw_sw_requirements text,
  code_example text,
  practical_task text,
  challenge text,
  quiz jsonb,
  troubleshooting text,
  pdf_url text,
  order_index integer not null default 0,
  xp_value integer not null default 10,
  status text not null default 'draft' check (status in ('draft', 'pending_approval', 'published')),
  created_at timestamptz not null default now()
);

create index topics_stage_id_idx on public.topics(stage_id);

-- ---------------------------------------------------------
-- projects
-- ---------------------------------------------------------
create table public.projects (
  id uuid primary key default gen_random_uuid(),
  stage_id integer not null references public.stages(id) on delete cascade,
  title text not null,
  requirements text,
  instructions text,
  quiz jsonb,
  pdf_url text,
  order_index integer not null default 0,
  xp_value integer not null default 100,
  created_at timestamptz not null default now()
);

create index projects_stage_id_idx on public.projects(stage_id);

-- ---------------------------------------------------------
-- completions
-- ---------------------------------------------------------
create table public.completions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  item_type text not null check (item_type in ('session', 'topic', 'project')),
  item_id uuid not null,
  status text not null default 'incomplete' check (status in ('incomplete', 'pending', 'verified', 'rejected')),
  submitted_at timestamptz,
  verified_by uuid references public.users(id),
  verified_at timestamptz,
  unique (user_id, item_type, item_id)
);

create index completions_user_id_idx on public.completions(user_id);

-- ---------------------------------------------------------
-- xp_transactions
-- ---------------------------------------------------------
create table public.xp_transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  activity_type text not null check (activity_type in ('session', 'topic', 'project')),
  item_id uuid not null,
  xp_amount integer not null,
  status text not null default 'awarded' check (status in ('awarded', 'reversed')),
  approved_by uuid references public.users(id),
  created_at timestamptz not null default now()
);

create index xp_transactions_user_id_idx on public.xp_transactions(user_id);

-- ---------------------------------------------------------
-- content_changes (new) -- audit log for session/topic/project edits & approvals
-- ---------------------------------------------------------
create table public.content_changes (
  id uuid primary key default gen_random_uuid(),
  item_type text not null check (item_type in ('session', 'topic', 'project')),
  item_id uuid not null,
  changed_by uuid not null references public.users(id),
  change_type text not null check (change_type in ('created', 'updated', 'submitted_for_approval', 'approved', 'rejected')),
  previous_data jsonb,
  new_data jsonb,
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------
-- kit_assignments (new) -- hardware kit checkout tracking
-- ---------------------------------------------------------
create table public.kit_assignments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  kit_name text not null,
  assigned_at timestamptz not null default now(),
  returned_at timestamptz,
  assigned_by uuid references public.users(id),
  notes text
);

-- ---------------------------------------------------------
-- announcements (new)
-- ---------------------------------------------------------
create table public.announcements (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  body text not null,
  image_url text,
  posted_by uuid references public.users(id),
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------
-- quiz_attempts -- every attempt is kept (not just the latest),
-- so a member can see their history; has no effect on XP/
-- dashboard. Also doubles as the "attempted at least once"
-- signal that unlocks a topic/project's mark-complete checkbox.
-- ---------------------------------------------------------
create table public.quiz_attempts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  item_type text not null check (item_type in ('topic', 'project')),
  item_id uuid not null,
  score integer not null,
  total integer not null,
  attempted_at timestamptz not null default now()
);

create index quiz_attempts_user_item_idx on public.quiz_attempts(user_id, item_type, item_id);

-- ---------------------------------------------------------
-- contact_submissions (new) -- backs contact.html
-- ---------------------------------------------------------
create table public.contact_submissions (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  email text not null,
  message text not null,
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------
-- team_members (new) -- backs team.html
-- ---------------------------------------------------------
create table public.team_members (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  position text not null,
  photo_url text,
  display_order integer not null default 0,
  created_at timestamptz not null default now()
);

-- =========================================================
-- Helper: is_admin() -- SECURITY DEFINER to avoid RLS recursion
-- on the users table (a plain subquery against `users` inside a
-- policy on `users` would re-trigger RLS on itself).
-- =========================================================
create or replace function public.is_admin(uid uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1 from public.users where id = uid and role = 'admin'
  );
$$;

-- Helper: read a user's own role, bypassing RLS (used by policies that need
-- to know the requesting user's own tier, e.g. Rookie+ auto-verification).
create or replace function public.user_role(uid uuid)
returns text
language sql
security definer
set search_path = public
stable
as $$
  select role from public.users where id = uid;
$$;

-- Helper: read a user's assigned_trainee_id, bypassing RLS. Lets a Rookie's
-- SELECT policy check "is this row MY assigned trainee" and a Trainee's
-- write access to kit_assignments check "is this rookie assigned to me"
-- without a plain subquery on `users` re-triggering RLS on itself.
create or replace function public.assigned_trainee_of(uid uuid)
returns uuid
language sql
security definer
set search_path = public
stable
as $$
  select assigned_trainee_id from public.users where id = uid;
$$;

-- Computed Member -> Rookie XP threshold: every session/topic/
-- project XP value in Stage 1 + Stage 2 (fully) plus just the
-- Session XP of Stage 3. Computed live, not a flat number, so it
-- stays correct if XP values or item counts change later.
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

-- Auto-promote member -> rookie once total_xp reaches the
-- threshold above. Never touches trainee/veteran/admin (those
-- are admin-assigned only).
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

create trigger trg_promote_role_by_xp
before update of total_xp on public.users
for each row execute function public.promote_role_by_xp();

-- =========================================================
-- Completions -> xp_transactions sync trigger
-- Automatically inserts the xp_transactions row (looking up the
-- correct xp_value itself) the moment a completions row's status
-- becomes 'verified', for sessions, topics, and projects alike --
-- so approving something is just flipping one field, nothing else.
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

create trigger trg_award_xp_on_verification
after insert or update on public.completions
for each row execute function public.award_xp_on_verification();

-- =========================================================
-- XP -> users.total_xp sync trigger
-- Runs as SECURITY DEFINER (owner privileges), so it can update
-- users.total_xp even though members have no direct UPDATE
-- policy on that table.
-- =========================================================
create or replace function public.apply_xp_transaction()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'INSERT' and new.status = 'awarded' then
    update public.users set total_xp = total_xp + new.xp_amount where id = new.user_id;
  elsif tg_op = 'UPDATE' and old.status = 'awarded' and new.status = 'reversed' then
    update public.users set total_xp = total_xp - new.xp_amount where id = new.user_id;
  end if;
  return new;
end;
$$;

create trigger trg_apply_xp_transaction
after insert or update on public.xp_transactions
for each row execute function public.apply_xp_transaction();

-- =========================================================
-- Row Level Security
-- =========================================================
alter table public.users enable row level security;
alter table public.stages enable row level security;
alter table public.sessions enable row level security;
alter table public.topics enable row level security;
alter table public.projects enable row level security;
alter table public.completions enable row level security;
alter table public.xp_transactions enable row level security;
alter table public.content_changes enable row level security;
alter table public.kit_assignments enable row level security;
alter table public.announcements enable row level security;
alter table public.contact_submissions enable row level security;
alter table public.team_members enable row level security;
alter table public.quiz_attempts enable row level security;

-- users: read own row; a Rookie can also read their assigned Trainee's row
-- and vice versa (mentor pairing); Veteran/Admin read everyone. Insert own
-- row only (member role, 0 XP -- matches auth.js's ensureUserRow). Veteran
-- or Admin can update (total_xp is otherwise maintained by the trigger
-- above, which bypasses this restriction) -- Veteran needs this to set a
-- Rookie's assigned_trainee_id.
create policy users_select on public.users
  for select to authenticated
  using (
    auth.uid() = id
    or public.user_role(auth.uid()) in ('veteran', 'admin')
    or assigned_trainee_id = auth.uid()
    or id = public.assigned_trainee_of(auth.uid())
  );

create policy users_insert_self on public.users
  for insert to authenticated
  with check (auth.uid() = id and role = 'member' and total_xp = 0);

create policy users_update_privileged on public.users
  for update to authenticated
  using (public.user_role(auth.uid()) in ('veteran', 'admin'))
  with check (public.user_role(auth.uid()) in ('veteran', 'admin'));

-- stages: any logged-in user can read; only admins write
create policy stages_select on public.stages
  for select to authenticated
  using (true);

create policy stages_admin_write on public.stages
  for all to authenticated
  using (public.is_admin(auth.uid()))
  with check (public.is_admin(auth.uid()));

-- sessions: any logged-in user can read; only admins write
create policy sessions_select on public.sessions
  for select to authenticated
  using (true);

create policy sessions_admin_write on public.sessions
  for all to authenticated
  using (public.is_admin(auth.uid()))
  with check (public.is_admin(auth.uid()));

-- topics: members only see published topics, admins see everything
create policy topics_select on public.topics
  for select to authenticated
  using (status = 'published' or public.is_admin(auth.uid()));

create policy topics_admin_write on public.topics
  for all to authenticated
  using (public.is_admin(auth.uid()))
  with check (public.is_admin(auth.uid()));

-- projects: any logged-in user can read; only admins write
create policy projects_select on public.projects
  for select to authenticated
  using (true);

create policy projects_admin_write on public.projects
  for all to authenticated
  using (public.is_admin(auth.uid()))
  with check (public.is_admin(auth.uid()));

-- completions: users see/insert their own rows; topics are always
-- self-verified (auto-approve); Rookie+ can also self-verify their
-- own sessions/projects (no admin approval needed once promoted);
-- plain members cannot self-verify sessions/projects -- only admins
-- can update (i.e. verify/reject) those afterwards.
create policy completions_select on public.completions
  for select to authenticated
  using (user_id = auth.uid() or public.is_admin(auth.uid()));

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

create policy completions_update_admin on public.completions
  for update to authenticated
  using (public.is_admin(auth.uid()))
  with check (public.is_admin(auth.uid()));

-- xp_transactions: users see their own; users can only self-insert
-- 'awarded' topic XP (matches completions.js); admins can insert
-- any (e.g. for approved sessions/projects) and reverse XP later.
create policy xp_transactions_select on public.xp_transactions
  for select to authenticated
  using (user_id = auth.uid() or public.is_admin(auth.uid()));

create policy xp_transactions_insert on public.xp_transactions
  for insert to authenticated
  with check (
    (user_id = auth.uid() and activity_type = 'topic' and status = 'awarded')
    or public.is_admin(auth.uid())
  );

create policy xp_transactions_update_admin on public.xp_transactions
  for update to authenticated
  using (public.is_admin(auth.uid()))
  with check (public.is_admin(auth.uid()));

-- content_changes: admin/internal audit log only for now
create policy content_changes_admin_only on public.content_changes
  for all to authenticated
  using (public.is_admin(auth.uid()))
  with check (public.is_admin(auth.uid()));

-- kit_assignments: a Rookie sees their own; their assigned Trainee can
-- see + manage them; Veteran/Admin can see + manage all.
create policy kit_assignments_select on public.kit_assignments
  for select to authenticated
  using (
    user_id = auth.uid()
    or public.assigned_trainee_of(user_id) = auth.uid()
    or public.user_role(auth.uid()) in ('veteran', 'admin')
  );

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

-- announcements: anyone (including logged-out visitors -- shown on the
-- public Home page) can read; Veteran or Admin can manage.
create policy announcements_select on public.announcements
  for select to anon, authenticated
  using (true);

create policy announcements_write on public.announcements
  for all to authenticated
  using (public.user_role(auth.uid()) in ('veteran', 'admin'))
  with check (public.user_role(auth.uid()) in ('veteran', 'admin'));

-- contact_submissions: anyone (including logged-out visitors) can
-- submit the contact form; only admins can read submissions
create policy contact_submissions_insert_public on public.contact_submissions
  for insert to anon, authenticated
  with check (true);

create policy contact_submissions_select_admin on public.contact_submissions
  for select to authenticated
  using (public.is_admin(auth.uid()));

-- team_members: public page data, readable by anyone; admins write
create policy team_members_select_public on public.team_members
  for select to anon, authenticated
  using (true);

create policy team_members_admin_write on public.team_members
  for all to authenticated
  using (public.is_admin(auth.uid()))
  with check (public.is_admin(auth.uid()));

-- quiz_attempts: a user sees/inserts only their own attempts; admin sees all
create policy quiz_attempts_select on public.quiz_attempts
  for select to authenticated
  using (user_id = auth.uid() or public.is_admin(auth.uid()));

create policy quiz_attempts_insert_self on public.quiz_attempts
  for insert to authenticated
  with check (user_id = auth.uid());

-- =========================================================
-- Storage: profile pictures (registration)
-- Public bucket; each user may only write inside a folder
-- named after their own auth uid (profile-pictures/<uid>/...).
-- =========================================================
insert into storage.buckets (id, name, public)
values ('profile-pictures', 'profile-pictures', true)
on conflict (id) do nothing;

create policy profile_pictures_public_read on storage.objects
  for select to public
  using (bucket_id = 'profile-pictures');

create policy profile_pictures_owner_write on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'profile-pictures'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy profile_pictures_owner_update on storage.objects
  for update to authenticated
  using (
    bucket_id = 'profile-pictures'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'profile-pictures'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- =========================================================
-- Storage: announcement images -- public bucket; only Veteran/
-- Admin may upload.
-- =========================================================
insert into storage.buckets (id, name, public)
values ('announcement-images', 'announcement-images', true)
on conflict (id) do nothing;

create policy announcement_images_public_read on storage.objects
  for select to public
  using (bucket_id = 'announcement-images');

create policy announcement_images_write on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'announcement-images'
    and public.user_role(auth.uid()) in ('veteran', 'admin')
  );

create policy announcement_images_delete on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'announcement-images'
    and public.user_role(auth.uid()) in ('veteran', 'admin')
  );
