-- =========================================================
-- Migration: move the Bluetooth Controlled Car reference videos out of
-- the project's `instructions` text. They now live in the lesson itself
-- (study-materials/stage-1/content/project1.html, "Reference Videos").
--
-- Safe to re-run: only touches the row while it still contains the links.
-- =========================================================

update public.projects
set instructions = 'Build a small car chassis driven by DC motors through a motor driver, controlled wirelessly over Bluetooth from a phone app.'
where stage_id = (select id from public.stages where number = 1)
  and title = 'Bluetooth Controlled Car'
  and instructions like '%youtu.be/%';
