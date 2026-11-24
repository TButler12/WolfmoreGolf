-- Club Event Feature #2: allow a player on two teams
--
-- Adds allow_dual_team to tournament_rules (default false).
-- When false, the revised setup_club_event_group RPC rejects any player
-- assignment with more than one team.
-- Existing events are unaffected (column defaults to false).

ALTER TABLE tournament_rules
  ADD COLUMN IF NOT EXISTS allow_dual_team BOOLEAN NOT NULL DEFAULT false;
