-- Club Event Phase 6D: explicit gross/net skins pot per player
--
-- Adds gross_skins_pot_per_player and net_skins_pot_per_player to
-- tournament_rules as separate organizer-set values (NULL = not configured).
-- entry_fee_per_player funds team (best-ball) payouts; skins pots are independent.
-- Existing events get NULL; the organiser sets these explicitly in event setup.

ALTER TABLE tournament_rules
  ADD COLUMN IF NOT EXISTS gross_skins_pot_per_player NUMERIC(10,2) DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS net_skins_pot_per_player   NUMERIC(10,2) DEFAULT NULL;
