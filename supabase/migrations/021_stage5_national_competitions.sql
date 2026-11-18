-- =========================================================
-- Migration: Stage 5 -- NATIONAL LEVEL COMPETITIONS.
--
-- A learning-only stage: six topics, no XP (xp_value = 0), no sessions, no projects.
-- The Study Portal reads stages/topics from the database, so this appears on its own;
-- the XP chip is hidden for 0-XP items (see js/docs-portal.js). Study material and
-- quizzes show "coming soon" until they are added -- add them later with an UPDATE on
-- the topic (pdf_url and quiz), the same way as the other stages.
--
-- Run in the Supabase SQL editor of the WEBSITE project. Safe to re-run: it never
-- duplicates the stage or its topics.
-- =========================================================

insert into public.stages (number, title, theme)
values (5, 'NATIONAL LEVEL COMPETITIONS', null)
on conflict (number) do update set title = excluded.title;

insert into public.topics (stage_id, title, xp_value, status, order_index)
select (select id from public.stages where number = 5), t.title, 0, 'published', t.pos
from (values
  (1, 'Solidworks - Designing'),
  (2, 'ROS-2'),
  (3, 'Electronics and PCB Designing'),
  (4, 'OpenCV - Image Processing'),
  (5, 'Path Planning'),
  (6, 'Python and Machine Learning')
) as t(pos, title)
where not exists (
  select 1 from public.topics
  where stage_id = (select id from public.stages where number = 5) and title = t.title
);
