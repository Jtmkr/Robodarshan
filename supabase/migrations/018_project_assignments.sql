-- =========================================================
-- Migration: Trainee-assigned Projects, alongside kit_assignments.
--
-- A Trainee can assign a project (title + description + optional PDF
-- attachment) to one of their own assigned Rookies, and later remove
-- it (e.g. assigned by mistake, or no longer relevant). This is
-- unrelated to the curriculum public.projects table (stage-scoped,
-- admin-authored, tied into XP/completions) -- it's a separate,
-- lightweight mentor -> rookie assignment, same shape/RLS pattern as
-- kit_assignments (005_mentorship_and_kits.sql), minus a "returned"
-- concept -- removal here is a hard delete, not a status flip.
-- =========================================================

create table public.project_assignments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  title text not null,
  description text,
  pdf_url text,
  assigned_at timestamptz not null default now(),
  assigned_by uuid references public.users(id) on delete set null
);

alter table public.project_assignments enable row level security;

-- project_assignments: a Rookie sees their own; their assigned Trainee
-- can see + manage (assign/remove) them; Veteran/Admin can see + manage all.
create policy project_assignments_select on public.project_assignments
  for select to authenticated
  using (
    user_id = auth.uid()
    or public.assigned_trainee_of(user_id) = auth.uid()
    or public.user_role(auth.uid()) in ('veteran', 'admin')
  );

create policy project_assignments_write on public.project_assignments
  for all to authenticated
  using (
    public.assigned_trainee_of(user_id) = auth.uid()
    or public.user_role(auth.uid()) in ('veteran', 'admin')
  )
  with check (
    public.assigned_trainee_of(user_id) = auth.uid()
    or public.user_role(auth.uid()) in ('veteran', 'admin')
  );

-- ---------------------------------------------------------
-- Storage: project attachment PDFs -- public bucket (the Rookie just
-- needs to open the link); Trainee/Veteran/Admin may upload/delete,
-- same role-scoped write pattern as announcement-images.
-- ---------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('project-attachments', 'project-attachments', true)
on conflict (id) do nothing;

create policy project_attachments_public_read on storage.objects
  for select to public
  using (bucket_id = 'project-attachments');

create policy project_attachments_write on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'project-attachments'
    and public.user_role(auth.uid()) in ('trainee', 'veteran', 'admin')
  );

create policy project_attachments_delete on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'project-attachments'
    and public.user_role(auth.uid()) in ('trainee', 'veteran', 'admin')
  );
