-- Fix staging/prod drift: add missing tables to supabase_realtime publication
-- and set replica identity to FULL where prod has it.
-- Every statement is idempotent: safe to run on prod if repair is ever skipped.

-- ============================================================
-- 1. Replica identity — set FULL on the three tables that need it.
--    Running ALTER TABLE ... REPLICA IDENTITY FULL is idempotent.
-- ============================================================

ALTER TABLE public.wolf_hole_results          REPLICA IDENTITY FULL;
ALTER TABLE public.wolf_sessions              REPLICA IDENTITY FULL;
ALTER TABLE public.remote_nassau_hole_scores  REPLICA IDENTITY FULL;

-- ============================================================
-- 2. Add missing tables to supabase_realtime publication.
--    Each block checks pg_publication_tables first so re-running
--    on a project that already has the table doesn't error.
-- ============================================================

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'wolf_hole_results'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.wolf_hole_results;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'wolf_sessions'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.wolf_sessions;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'remote_nassau_hole_scores'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.remote_nassau_hole_scores;
  END IF;
END $$;
