-- Club Event course snapshot
--
-- Stores par and handicap-index arrays with every club event so all scorers
-- share the same card regardless of what courses are on their device.
-- Applied for both built-in and imported (OpenGolfAPI) courses.
--
-- Nullable: existing events (created before this migration) have NULL here;
-- the app falls back to CourseLibrary lookup for those rows only.

ALTER TABLE tournament_events
  ADD COLUMN IF NOT EXISTS course_pars       int[],
  ADD COLUMN IF NOT EXISTS course_handicaps  int[];
