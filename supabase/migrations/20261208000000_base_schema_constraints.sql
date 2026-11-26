-- Catch-up: add constraints and indexes present on prod but missing from staging.
-- The base_schema migration (20200101000000) only used CREATE TABLE statements;
-- it did not capture the UNIQUE, FK, and PK constraints that were created by hand
-- on prod before migration tracking was set up.
-- All statements are idempotent (DO blocks check pg_constraint / IF NOT EXISTS).
-- On prod: mark this migration as repair applied — prod already has everything here.

-- ============================================================
-- hole_results
-- ============================================================

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint
    WHERE conname = 'hole_results_match_id_fkey'
      AND conrelid = 'public.hole_results'::regclass)
  THEN
    ALTER TABLE public.hole_results
      ADD CONSTRAINT hole_results_match_id_fkey
        FOREIGN KEY (match_id) REFERENCES public.matches(id);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint
    WHERE conname = 'hole_results_match_id_hole_key'
      AND conrelid = 'public.hole_results'::regclass)
  THEN
    ALTER TABLE public.hole_results
      ADD CONSTRAINT hole_results_match_id_hole_key UNIQUE (match_id, hole);
  END IF;
END $$;

-- ============================================================
-- hole_scores
-- ============================================================

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint
    WHERE conname = 'hole_scores_upsert_unique'
      AND conrelid = 'public.hole_scores'::regclass)
  THEN
    ALTER TABLE public.hole_scores
      ADD CONSTRAINT hole_scores_upsert_unique
        UNIQUE (match_id, tournament_code, player_name, hole, day, game_type);
  END IF;
END $$;

-- ============================================================
-- matches
-- ============================================================

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint
    WHERE conname = 'matches_code_key'
      AND conrelid = 'public.matches'::regclass)
  THEN
    ALTER TABLE public.matches
      ADD CONSTRAINT matches_code_key UNIQUE (code);
  END IF;
END $$;

-- ============================================================
-- player_offsets  (base_schema defined no PK on this table)
-- ============================================================

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint
    WHERE conname = 'player_offsets_pkey'
      AND conrelid = 'public.player_offsets'::regclass)
  THEN
    ALTER TABLE public.player_offsets
      ADD CONSTRAINT player_offsets_pkey
        PRIMARY KEY (tournament_code, day, player_name);
  END IF;
END $$;

-- ============================================================
-- players
-- ============================================================

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint
    WHERE conname = 'players_match_id_fkey'
      AND conrelid = 'public.players'::regclass)
  THEN
    ALTER TABLE public.players
      ADD CONSTRAINT players_match_id_fkey
        FOREIGN KEY (match_id) REFERENCES public.matches(id);
  END IF;
END $$;

-- ============================================================
-- remote_nassau_hole_scores
-- Prod has two distinct unique constraints on the same (match_id, side, hole).
-- Replicate both so the constraint names match prod exactly.
-- ============================================================

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint
    WHERE conname = 'remote_nassau_hole_scores_match_id_side_hole_key'
      AND conrelid = 'public.remote_nassau_hole_scores'::regclass)
  THEN
    ALTER TABLE public.remote_nassau_hole_scores
      ADD CONSTRAINT remote_nassau_hole_scores_match_id_side_hole_key
        UNIQUE (match_id, side, hole);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint
    WHERE conname = 'remote_nassau_hole_scores_match_side_hole_key'
      AND conrelid = 'public.remote_nassau_hole_scores'::regclass)
  THEN
    ALTER TABLE public.remote_nassau_hole_scores
      ADD CONSTRAINT remote_nassau_hole_scores_match_side_hole_key
        UNIQUE (match_id, side, hole);
  END IF;
END $$;

-- ============================================================
-- remote_nassau_matches
-- ============================================================

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint
    WHERE conname = 'remote_nassau_matches_match_id_key'
      AND conrelid = 'public.remote_nassau_matches'::regclass)
  THEN
    ALTER TABLE public.remote_nassau_matches
      ADD CONSTRAINT remote_nassau_matches_match_id_key UNIQUE (match_id);
  END IF;
END $$;

-- ============================================================
-- shared_games
-- ============================================================

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint
    WHERE conname = 'shared_games_code_key'
      AND conrelid = 'public.shared_games'::regclass)
  THEN
    ALTER TABLE public.shared_games
      ADD CONSTRAINT shared_games_code_key UNIQUE (code);
  END IF;
END $$;

-- ============================================================
-- tournament_roster  (base_schema defined id as NOT NULL, not PRIMARY KEY)
-- ============================================================

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint
    WHERE conname = 'tournament_roster_pkey'
      AND conrelid = 'public.tournament_roster'::regclass)
  THEN
    ALTER TABLE public.tournament_roster
      ADD CONSTRAINT tournament_roster_pkey PRIMARY KEY (id);
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS tournament_roster_tournament_code_idx
  ON public.tournament_roster (tournament_code);

-- ============================================================
-- tournaments
-- ============================================================

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint
    WHERE conname = 'tournaments_code_key'
      AND conrelid = 'public.tournaments'::regclass)
  THEN
    ALTER TABLE public.tournaments
      ADD CONSTRAINT tournaments_code_key UNIQUE (code);
  END IF;
END $$;

-- ============================================================
-- wolf_hole_results  (session_id FK — the unique index was added separately
--                    in 20261207000000_wolf_hole_results_unique.sql)
-- ============================================================

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint
    WHERE conname = 'wolf_hole_results_session_id_fkey'
      AND conrelid = 'public.wolf_hole_results'::regclass)
  THEN
    ALTER TABLE public.wolf_hole_results
      ADD CONSTRAINT wolf_hole_results_session_id_fkey
        FOREIGN KEY (session_id) REFERENCES public.wolf_sessions(id);
  END IF;
END $$;

-- ============================================================
-- wolf_session_secrets  (base_schema defined no PK or FK)
-- ============================================================

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint
    WHERE conname = 'wolf_session_secrets_pkey'
      AND conrelid = 'public.wolf_session_secrets'::regclass)
  THEN
    ALTER TABLE public.wolf_session_secrets
      ADD CONSTRAINT wolf_session_secrets_pkey PRIMARY KEY (session_id);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint
    WHERE conname = 'wolf_session_secrets_session_id_fkey'
      AND conrelid = 'public.wolf_session_secrets'::regclass)
  THEN
    ALTER TABLE public.wolf_session_secrets
      ADD CONSTRAINT wolf_session_secrets_session_id_fkey
        FOREIGN KEY (session_id) REFERENCES public.wolf_sessions(id);
  END IF;
END $$;

-- ============================================================
-- wolf_sessions
-- ============================================================

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint
    WHERE conname = 'wolf_sessions_code_key'
      AND conrelid = 'public.wolf_sessions'::regclass)
  THEN
    ALTER TABLE public.wolf_sessions
      ADD CONSTRAINT wolf_sessions_code_key UNIQUE (code);
  END IF;
END $$;

-- ============================================================
-- ai_summary_conversion / ai_summary_daily
-- base_schema created these as tables; prod has them as views over analytics_events.
-- Drop the stub tables and replace with the correct view definitions.
-- ============================================================

DROP TABLE IF EXISTS public.ai_summary_conversion;
CREATE OR REPLACE VIEW public.ai_summary_conversion AS
  SELECT
    count(*) FILTER (WHERE event_name = 'ai_summary_upgrade_tapped') AS upgrades,
    count(*) FILTER (WHERE event_name = 'ai_summary_limit_hit')      AS limit_hits,
    round(
      (100.0 * count(*) FILTER (WHERE event_name = 'ai_summary_upgrade_tapped')::numeric)
      / NULLIF(count(*) FILTER (WHERE event_name = 'ai_summary_limit_hit'), 0)::numeric,
      1
    ) AS conversion_pct
  FROM public.analytics_events;

GRANT SELECT ON public.ai_summary_conversion TO anon, authenticated, service_role;

DROP TABLE IF EXISTS public.ai_summary_daily;
CREATE OR REPLACE VIEW public.ai_summary_daily AS
  SELECT
    date_trunc('day', created_at) AS day,
    event_name,
    count(*)                      AS events,
    count(DISTINCT user_id)       AS unique_users
  FROM public.analytics_events
  WHERE event_name LIKE 'ai_summary%'
  GROUP BY date_trunc('day', created_at), event_name
  ORDER BY date_trunc('day', created_at) DESC, event_name;

GRANT SELECT ON public.ai_summary_daily TO anon, authenticated, service_role;
