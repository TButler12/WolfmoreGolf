-- Add missing unique constraint on wolf_hole_results(session_id, hole).
-- Prod has this constraint (created by hand); staging never had it, causing
-- every submitWolfHole upsert to fail with 42P10.
-- Idempotent: DO block skips if the constraint already exists.

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'public.wolf_hole_results'::regclass
      AND contype = 'u'
      AND conname = 'wolf_hole_results_session_hole_unique'
  ) THEN
    ALTER TABLE public.wolf_hole_results
      ADD CONSTRAINT wolf_hole_results_session_hole_unique UNIQUE (session_id, hole);
  END IF;
END $$;
