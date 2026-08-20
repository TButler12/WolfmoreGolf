-- Add live-summary fields to wolf_hole_results so the spectator screen
-- can display skin winner and Nassau status per hole without any extra queries.

alter table wolf_hole_results
  add column if not exists skin_winner  text,
  add column if not exists skin_value   double precision,
  add column if not exists nassau_status text;
