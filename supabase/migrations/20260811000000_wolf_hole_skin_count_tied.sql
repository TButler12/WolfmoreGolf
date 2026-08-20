alter table wolf_hole_results
  add column if not exists skin_count      integer,
  add column if not exists skin_tied_seats text;
