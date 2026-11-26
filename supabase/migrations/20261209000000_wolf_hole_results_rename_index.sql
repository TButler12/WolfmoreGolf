-- Rename the wolf_hole_results unique index to match prod.
-- Prod has a bare unique index named wolf_hole_results_session_hole_key.
-- Staging had a UNIQUE CONSTRAINT named wolf_hole_results_session_hole_unique
-- (added in 20261207000000). Drop the constraint and recreate as a bare index
-- so the name and kind match prod exactly.
-- On prod: mark this migration repair applied — prod already has the index.

ALTER TABLE public.wolf_hole_results
  DROP CONSTRAINT IF EXISTS wolf_hole_results_session_hole_unique;

CREATE UNIQUE INDEX IF NOT EXISTS wolf_hole_results_session_hole_key
  ON public.wolf_hole_results (session_id, hole);
