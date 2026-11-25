-- Base schema: tables that pre-date the Supabase migration tracking system.
-- These exist on prod from the app's original launch.
-- All statements use CREATE TABLE IF NOT EXISTS so this migration is safe
-- to apply on top of an already-bootstrapped database.
-- Subsequent tracked migrations use ADD COLUMN IF NOT EXISTS / DROP COLUMN IF EXISTS,
-- so running them after this file is idempotent.

CREATE TABLE IF NOT EXISTS matches (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code             text NOT NULL,
  created_at       timestamptz DEFAULT now(),
  course_a         text,
  course_b         text,
  stake            numeric DEFAULT 0,
  games            text[],
  status           text DEFAULT 'active',
  press_mode       text,
  trigger          int,
  player_included  boolean[],
  host_name        text,
  opponent_name    text,
  opponent_names   text[],
  tournament_code  text,
  group_code       text,
  pairing          jsonb,
  joiner_capability text
);

CREATE TABLE IF NOT EXISTS players (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id     uuid,
  name         text NOT NULL,
  handicap     int DEFAULT 0,
  slot         int NOT NULL,
  device_token text,
  created_at   timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS hole_scores (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id         uuid,
  player_slot      int NOT NULL,
  hole             int NOT NULL,
  gross_score      int NOT NULL,
  submitted_at     timestamptz DEFAULT now(),
  player_name      text,
  hole_hc          int,
  player_hc        int,
  tournament_code  text,
  group_code       text,
  hole_money       numeric,
  total_money      numeric,
  net_score        int,
  day              int DEFAULT 1 NOT NULL,
  game_type        text DEFAULT 'wolf' NOT NULL,
  skins_won        int DEFAULT 0 NOT NULL,
  joiner_capability text
);

CREATE TABLE IF NOT EXISTS hole_results (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id         uuid,
  hole             int NOT NULL,
  winner_slot      int,
  points_exchanged numeric DEFAULT 0,
  revealed_at      timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS wolf_sessions (
  id                    uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code                  text NOT NULL,
  status                text DEFAULT 'active',
  course_name           text,
  player_names          text[],
  stake                 double precision,
  created_at            timestamptz DEFAULT now(),
  host_name             text,
  player_handicaps      jsonb,
  nine_hole_match       boolean DEFAULT false NOT NULL,
  nine_hole_starting_hole int DEFAULT 1 NOT NULL,
  group_name            text,
  match_status          text,
  holes_played          int,
  event_code            text
);

CREATE TABLE IF NOT EXISTS wolf_session_secrets (
  session_id    uuid NOT NULL,
  creator_token uuid DEFAULT gen_random_uuid() NOT NULL
);

CREATE TABLE IF NOT EXISTS wolf_hole_results (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id         uuid,
  hole               int NOT NULL,
  wolf_name          text,
  decision           text,
  partner_name       text,
  hammer_multiplier  int DEFAULT 1,
  prox_winner        text,
  scores             jsonb,
  money_deltas       jsonb,
  created_at         timestamptz DEFAULT now(),
  payouts            jsonb,
  team_won           text,
  wolf_slot          int,
  partner_slot       int,
  hammer_holder      text,
  alone              boolean DEFAULT false,
  went_alone         boolean DEFAULT false,
  wolf_player        int,
  tournament_code    text,
  group_code         text,
  skin_winner        text,
  skin_value         numeric,
  nassau_status      jsonb,
  skin_count         int,
  skin_tied_seats    text,
  mp_seats           text
);

CREATE TABLE IF NOT EXISTS remote_nassau_matches (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id       text NOT NULL,
  creator_name   text,
  joiner_name    text,
  creator_course text,
  joiner_course  text,
  created_at     timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS remote_nassau_hole_scores (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id    text NOT NULL,
  side        text NOT NULL,
  hole        int NOT NULL,
  gross_score int NOT NULL,
  handicap    int DEFAULT 0,
  player_hc   int,
  player_name text,
  created_at  timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS remote_nassau_hole_scores_backup (
  id          uuid,
  match_id    text,
  side        text,
  hole        int,
  gross_score int,
  handicap    int,
  player_hc   int,
  player_name text,
  created_at  timestamptz
);

CREATE TABLE IF NOT EXISTS shared_games (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code       text NOT NULL,
  game_data  text NOT NULL,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS player_offsets (
  tournament_code text NOT NULL,
  day             int NOT NULL,
  player_name     text NOT NULL,
  offset_amount   double precision DEFAULT 0
);

CREATE TABLE IF NOT EXISTS tournaments (
  id                      uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code                    text NOT NULL,
  name                    text,
  course_name             text,
  game_type               text,
  scoring                 text,
  stake                   numeric,
  carry_ties              boolean DEFAULT true,
  created_by              text,
  results_published       boolean DEFAULT false,
  results                 jsonb,
  date                    date DEFAULT CURRENT_DATE,
  created_at              timestamptz DEFAULT now(),
  current_day             int DEFAULT 1 NOT NULL,
  pot_amount              numeric,
  co_organizer_code       text,
  co_organizer_devices    jsonb DEFAULT '[]',
  wolf_stake              numeric,
  stableford_baseline     text DEFAULT 'par',
  stableford_team_count   int DEFAULT 3,
  stableford_enabled      boolean DEFAULT false,
  wolf_variant            text,
  press_style             text,
  hammer_style            text,
  match_play_teams        jsonb,
  team_tee_enabled        boolean,
  team_tee_count_mode     text,
  team_tee_fixed_count    int,
  team_tee_par3_count     int,
  team_tee_par4_count     int,
  team_tee_par5_count     int,
  stableford_mode         text,
  modified_sf_double_eagle int,
  modified_sf_eagle        int,
  modified_sf_birdie       int,
  modified_sf_par          int,
  modified_sf_bogey        int,
  modified_sf_double_bogey int,
  finished_at              timestamptz,
  lone_wolf_team_score     text DEFAULT 'ghostPartner'
);

CREATE TABLE IF NOT EXISTS usage_telemetry (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  country      text,
  zip_code     text,
  app_version  text,
  submitted_at timestamptz DEFAULT now(),
  region       text,
  state        text
);

CREATE TABLE IF NOT EXISTS tournament_roster (
  id               uuid NOT NULL,
  tournament_code  text NOT NULL,
  canonical_name   text NOT NULL,
  handicap         int DEFAULT 0 NOT NULL,
  added_by         text DEFAULT 'organizer' NOT NULL,
  created_at       timestamptz DEFAULT now(),
  group_code       text
);

CREATE TABLE IF NOT EXISTS ai_summary_conversion (
  upgrades        bigint,
  limit_hits      bigint,
  conversion_pct  numeric
);

CREATE TABLE IF NOT EXISTS ai_summary_daily (
  day          timestamptz,
  event_name   text,
  events       bigint,
  unique_users bigint
);
