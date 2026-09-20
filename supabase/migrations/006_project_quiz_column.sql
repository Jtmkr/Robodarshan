-- =========================================================
-- Migration: add a quiz column to projects (topics already
-- have one). Same jsonb shape as topics.quiz:
--   [{ "question": "...", "options": ["A","B","C","D"], "answer": 0 }, ...]
-- where "answer" is the 0-based index of the correct option.
-- =========================================================

alter table public.projects add column if not exists quiz jsonb;
