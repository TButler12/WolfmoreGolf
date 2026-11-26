-- Backfill objects that exist on prod but were created by hand and never saved as migrations.
-- Every statement is idempotent: safe to run on prod if repair is ever skipped.

-- ============================================================
-- 1. Functions
-- ============================================================

-- Trigger fn: blocks clients without pairing_v2 support from joining pairing_v2 matches.
CREATE OR REPLACE FUNCTION public.block_unversioned_nassau_join()
RETURNS trigger LANGUAGE plpgsql AS $function$
BEGIN
  IF ('pairing_v2' = ANY(OLD.games)
      AND NEW.opponent_names IS DISTINCT FROM OLD.opponent_names
      AND NEW.pairing IS NULL) THEN
    RAISE EXCEPTION 'Update WolfMore to join this match.';
  END IF;
  RETURN NEW;
END;
$function$;

-- Trigger fn: blocks clients without lone_wolf_double support from joining doubleScore tournaments.
CREATE OR REPLACE FUNCTION public.enforce_lone_wolf_double()
RETURNS trigger LANGUAGE plpgsql AS $function$
DECLARE
  required_mode TEXT;
BEGIN
  SELECT lone_wolf_team_score INTO required_mode
  FROM public.tournaments
  WHERE code = NEW.tournament_code;

  IF required_mode = 'doubleScore' THEN
    IF COALESCE(NEW.joiner_capability, '') <> 'lone_wolf_double_v1' THEN
      RAISE EXCEPTION 'Update WolfMore to join this tournament.';
    END IF;
  END IF;

  RETURN NEW;
END;
$function$;

-- RPC: creates a wolf_sessions row + its secret token; returns both IDs.
CREATE OR REPLACE FUNCTION public.create_wolf_session(
  p_code                   text,
  p_host_name              text,
  p_player_names           text[],
  p_course_name            text,
  p_player_handicaps       integer[],
  p_nine_hole_match        boolean,
  p_nine_hole_starting_hole integer,
  p_group_name             text DEFAULT NULL
)
RETURNS TABLE(session_id uuid, creator_token uuid)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_session_id    uuid;
  v_creator_token uuid := gen_random_uuid();
BEGIN
  INSERT INTO public.wolf_sessions (
    code, host_name, player_names, course_name, status,
    player_handicaps, nine_hole_match, nine_hole_starting_hole, group_name
  ) VALUES (
    p_code, p_host_name, p_player_names, p_course_name, 'active',
    to_jsonb(p_player_handicaps), p_nine_hole_match, p_nine_hole_starting_hole, p_group_name
  )
  RETURNING id INTO v_session_id;

  INSERT INTO public.wolf_session_secrets (session_id, creator_token)
  VALUES (v_session_id, v_creator_token);

  RETURN QUERY SELECT v_session_id, v_creator_token;
END;
$function$;

-- RPC: renames a wolf session's group_name; requires matching creator_token.
CREATE OR REPLACE FUNCTION public.rename_wolf_session(
  p_session_id   text,
  p_creator_token text,
  p_group_name   text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
  UPDATE public.wolf_sessions ws
  SET    group_name = p_group_name
  FROM   public.wolf_session_secrets s
  WHERE  ws.id           = p_session_id::uuid
    AND  s.session_id    = ws.id
    AND  s.creator_token = p_creator_token::uuid;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Invalid session or creator token.';
  END IF;
END;
$function$;

-- ============================================================
-- 2. Trigger
-- ============================================================

CREATE OR REPLACE TRIGGER nassau_join_version_check
BEFORE UPDATE ON public.matches
FOR EACH ROW EXECUTE FUNCTION public.block_unversioned_nassau_join();

-- ============================================================
-- 3. Enable RLS on tables that have it enabled on prod
-- ============================================================

ALTER TABLE public.hole_results              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.hole_scores               ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.matches                   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.player_offsets            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.players                   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.remote_nassau_hole_scores ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.remote_nassau_matches     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shared_games              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tournament_roster         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tournaments               ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.usage_telemetry           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wolf_hole_results         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wolf_sessions             ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- 4. RLS Policies  (DROP IF EXISTS + CREATE = idempotent)
-- ============================================================

-- hole_results
DROP POLICY IF EXISTS "public insert hole_results" ON public.hole_results;
CREATE POLICY "public insert hole_results"
  ON public.hole_results FOR INSERT TO public WITH CHECK (true);

DROP POLICY IF EXISTS "public read hole_results" ON public.hole_results;
CREATE POLICY "public read hole_results"
  ON public.hole_results FOR SELECT TO public USING (true);

-- hole_scores
DROP POLICY IF EXISTS "Allow all inserts on hole_scores" ON public.hole_scores;
CREATE POLICY "Allow all inserts on hole_scores"
  ON public.hole_scores FOR INSERT TO public WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all reads on hole_scores" ON public.hole_scores;
CREATE POLICY "Allow all reads on hole_scores"
  ON public.hole_scores FOR SELECT TO public USING (true);

DROP POLICY IF EXISTS "Allow all updates on hole_scores" ON public.hole_scores;
CREATE POLICY "Allow all updates on hole_scores"
  ON public.hole_scores FOR UPDATE TO public USING (true);

DROP POLICY IF EXISTS "public insert hole_scores" ON public.hole_scores;
CREATE POLICY "public insert hole_scores"
  ON public.hole_scores FOR INSERT TO public WITH CHECK (true);

DROP POLICY IF EXISTS "public read hole_scores" ON public.hole_scores;
CREATE POLICY "public read hole_scores"
  ON public.hole_scores FOR SELECT TO public USING (true);

-- matches
DROP POLICY IF EXISTS "Allow all reads on matches" ON public.matches;
CREATE POLICY "Allow all reads on matches"
  ON public.matches FOR SELECT TO public USING (true);

DROP POLICY IF EXISTS "Allow all updates on matches" ON public.matches;
CREATE POLICY "Allow all updates on matches"
  ON public.matches FOR UPDATE TO public USING (true);

DROP POLICY IF EXISTS "public insert matches" ON public.matches;
CREATE POLICY "public insert matches"
  ON public.matches FOR INSERT TO public WITH CHECK (true);

DROP POLICY IF EXISTS "public read matches" ON public.matches;
CREATE POLICY "public read matches"
  ON public.matches FOR SELECT TO public USING (true);

-- player_offsets
DROP POLICY IF EXISTS "Allow all operations on player_offsets" ON public.player_offsets;
CREATE POLICY "Allow all operations on player_offsets"
  ON public.player_offsets FOR ALL TO public USING (true) WITH CHECK (true);

-- players
DROP POLICY IF EXISTS "public insert players" ON public.players;
CREATE POLICY "public insert players"
  ON public.players FOR INSERT TO public WITH CHECK (true);

DROP POLICY IF EXISTS "public read players" ON public.players;
CREATE POLICY "public read players"
  ON public.players FOR SELECT TO public USING (true);

-- remote_nassau_hole_scores
DROP POLICY IF EXISTS "Allow all" ON public.remote_nassau_hole_scores;
CREATE POLICY "Allow all"
  ON public.remote_nassau_hole_scores FOR ALL TO public USING (true);

-- remote_nassau_matches
DROP POLICY IF EXISTS "Allow insert" ON public.remote_nassau_matches;
CREATE POLICY "Allow insert"
  ON public.remote_nassau_matches FOR INSERT TO public WITH CHECK (true);

DROP POLICY IF EXISTS "Allow select" ON public.remote_nassau_matches;
CREATE POLICY "Allow select"
  ON public.remote_nassau_matches FOR SELECT TO public USING (true);

DROP POLICY IF EXISTS "Allow update" ON public.remote_nassau_matches;
CREATE POLICY "Allow update"
  ON public.remote_nassau_matches FOR UPDATE TO public USING (true);

-- shared_games
DROP POLICY IF EXISTS "Public insert" ON public.shared_games;
CREATE POLICY "Public insert"
  ON public.shared_games FOR INSERT TO public WITH CHECK (true);

DROP POLICY IF EXISTS "Public select" ON public.shared_games;
CREATE POLICY "Public select"
  ON public.shared_games FOR SELECT TO public USING (true);

-- tournament_roster
DROP POLICY IF EXISTS "anon can delete roster" ON public.tournament_roster;
CREATE POLICY "anon can delete roster"
  ON public.tournament_roster FOR DELETE TO anon USING (true);

DROP POLICY IF EXISTS "anon can insert roster" ON public.tournament_roster;
CREATE POLICY "anon can insert roster"
  ON public.tournament_roster FOR INSERT TO anon WITH CHECK (true);

DROP POLICY IF EXISTS "anon can read roster" ON public.tournament_roster;
CREATE POLICY "anon can read roster"
  ON public.tournament_roster FOR SELECT TO anon USING (true);

DROP POLICY IF EXISTS "anon can update roster" ON public.tournament_roster;
CREATE POLICY "anon can update roster"
  ON public.tournament_roster FOR UPDATE TO anon USING (true) WITH CHECK (true);

-- tournaments
DROP POLICY IF EXISTS "Allow insert" ON public.tournaments;
CREATE POLICY "Allow insert"
  ON public.tournaments FOR INSERT TO public WITH CHECK (true);

DROP POLICY IF EXISTS "Allow select" ON public.tournaments;
CREATE POLICY "Allow select"
  ON public.tournaments FOR SELECT TO public USING (true);

DROP POLICY IF EXISTS "Allow update" ON public.tournaments;
CREATE POLICY "Allow update"
  ON public.tournaments FOR UPDATE TO public USING (true);

-- usage_telemetry
DROP POLICY IF EXISTS "Public insert" ON public.usage_telemetry;
CREATE POLICY "Public insert"
  ON public.usage_telemetry FOR INSERT TO public WITH CHECK (true);

-- wolf_hole_results
DROP POLICY IF EXISTS "Allow all inserts on wolf_hole_results" ON public.wolf_hole_results;
CREATE POLICY "Allow all inserts on wolf_hole_results"
  ON public.wolf_hole_results FOR INSERT TO public WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all reads on wolf_hole_results" ON public.wolf_hole_results;
CREATE POLICY "Allow all reads on wolf_hole_results"
  ON public.wolf_hole_results FOR SELECT TO public USING (true);

DROP POLICY IF EXISTS "Allow all updates on wolf_hole_results" ON public.wolf_hole_results;
CREATE POLICY "Allow all updates on wolf_hole_results"
  ON public.wolf_hole_results FOR UPDATE TO public USING (true) WITH CHECK (true);

-- wolf_sessions
DROP POLICY IF EXISTS "Allow all inserts on wolf_sessions" ON public.wolf_sessions;
CREATE POLICY "Allow all inserts on wolf_sessions"
  ON public.wolf_sessions FOR INSERT TO public WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all reads on wolf_sessions" ON public.wolf_sessions;
CREATE POLICY "Allow all reads on wolf_sessions"
  ON public.wolf_sessions FOR SELECT TO public USING (true);

DROP POLICY IF EXISTS "Allow all updates on wolf_sessions" ON public.wolf_sessions;
CREATE POLICY "Allow all updates on wolf_sessions"
  ON public.wolf_sessions FOR UPDATE TO public USING (true) WITH CHECK (true);

-- ============================================================
-- 5. Reload PostgREST schema cache
-- ============================================================

NOTIFY pgrst, 'reload schema';
