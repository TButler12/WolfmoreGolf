-- =============================================================
-- Player Changes (Replace / Withdraw / Remove) +
-- Event Settings editing with change log
-- File: 20261126000000_player_changes_and_settings.sql
-- =============================================================


-- ── 1. Schema additions ───────────────────────────────────────

-- Active/withdrawn flag on every player row; default keeps existing rows unchanged.
ALTER TABLE tournament_players
  ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'active'
  CHECK (status IN ('active', 'withdrawn'));

-- Separate tee-set field so course and tees can be edited independently.
-- Both are blocked if any score row exists for the event (see update_club_event_settings).
ALTER TABLE tournament_events
  ADD COLUMN IF NOT EXISTS tee_set TEXT;


-- ── 2. Change log table ───────────────────────────────────────

CREATE TABLE IF NOT EXISTS club_event_change_log (
    id              UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id   UUID         NOT NULL REFERENCES tournament_events(id) ON DELETE CASCADE,
    changed_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    changed_by      TEXT,        -- device_id of the actor
    change_type     TEXT         NOT NULL,
    -- 'replace_player' | 'withdraw_player' | 'remove_player'
    -- 'update_settings' | 'update_handicap'
    details         JSONB        NOT NULL DEFAULT '{}'
);

CREATE INDEX IF NOT EXISTS idx_change_log_tournament
    ON club_event_change_log(tournament_id, changed_at DESC);

-- RLS: anyone may read; no client may write directly (all inserts go via SECURITY DEFINER RPCs).
ALTER TABLE club_event_change_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "change_log_select"
    ON club_event_change_log
    FOR SELECT USING (true);

-- INSERT / UPDATE / DELETE intentionally omitted — no policy = blocked for all roles.

GRANT SELECT ON club_event_change_log TO anon, authenticated;


-- ── 3. replace_club_event_player ─────────────────────────────
-- Auth: scorer for their own group OR organizer.
-- Blocked when event status = 'finished'.
-- Moves all hole scores; reslots team membership keeping the same team + flight.
-- New player must be: in this event, not in any group, and have no existing scores.

CREATE OR REPLACE FUNCTION replace_club_event_player(
    p_tournament_id  UUID,
    p_old_player_id  UUID,
    p_new_player_id  UUID,
    p_group_code     TEXT DEFAULT NULL   -- required for scorer auth
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_device_id    TEXT := COALESCE((current_setting('request.headers', true)::JSONB)->>'x-device-id', '');
    v_hdr_group    TEXT := COALESCE((current_setting('request.headers', true)::JSONB)->>'x-group-code', '');
    v_organizer_id TEXT;
    v_ev_status    TEXT;
    v_old          tournament_players%ROWTYPE;
    v_new          tournament_players%ROWTYPE;
    v_scores_moved INT;
    v_is_organizer BOOL;
    v_is_scorer    BOOL;
BEGIN
    SELECT e.status, e.organizer_device_id
      INTO v_ev_status, v_organizer_id
      FROM tournament_events e
     WHERE e.id = p_tournament_id;

    IF NOT FOUND                THEN RAISE EXCEPTION 'Event not found'; END IF;
    IF v_ev_status = 'finished' THEN RAISE EXCEPTION 'Cannot change players after results are locked'; END IF;

    v_is_organizer := (v_organizer_id IS NOT NULL AND v_organizer_id = v_device_id);
    v_is_scorer    := (p_group_code IS NOT NULL AND v_hdr_group = p_group_code);

    IF NOT v_is_organizer AND NOT v_is_scorer THEN
        RAISE EXCEPTION 'Not authorized to replace players';
    END IF;

    -- Old player must exist in this event
    SELECT * INTO v_old FROM tournament_players
     WHERE id = p_old_player_id AND tournament_id = p_tournament_id;
    IF NOT FOUND THEN RAISE EXCEPTION 'Player being replaced not found in this event'; END IF;

    -- Scorer: may only replace within their own group
    IF v_is_scorer AND NOT v_is_organizer
       AND (v_old.group_code IS DISTINCT FROM p_group_code) THEN
        RAISE EXCEPTION 'Scorer can only replace players in their own group';
    END IF;

    -- New player must exist in the same event
    SELECT * INTO v_new FROM tournament_players
     WHERE id = p_new_player_id AND tournament_id = p_tournament_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Replacement player not found in this event';
    END IF;

    -- New player must be fully unclaimed
    IF v_new.group_code IS NOT NULL THEN
        RAISE EXCEPTION 'Replacement player (%) is already in group %',
                        v_new.player_name, v_new.group_code;
    END IF;

    -- New player must have no scores in this event
    IF EXISTS (
        SELECT 1 FROM tournament_hole_scores
         WHERE tournament_player_id = p_new_player_id
           AND tournament_id        = p_tournament_id
    ) THEN
        RAISE EXCEPTION 'Replacement player (%) already has scores in this event',
                        v_new.player_name;
    END IF;

    -- Move all hole scores (scoped to this event)
    UPDATE tournament_hole_scores
       SET tournament_player_id = p_new_player_id
     WHERE tournament_player_id = p_old_player_id
       AND tournament_id        = p_tournament_id;
    GET DIAGNOSTICS v_scores_moved = ROW_COUNT;

    -- Reslot team memberships; scoped via tournament_teams.tournament_id (not name)
    UPDATE tournament_team_players ttp
       SET tournament_player_id = p_new_player_id
      FROM tournament_teams tt
     WHERE ttp.team_id              = tt.id
       AND tt.tournament_id         = p_tournament_id
       AND ttp.tournament_player_id = p_old_player_id;

    -- Assign new player to old player's group slot
    UPDATE tournament_players
       SET group_code       = v_old.group_code,
           starting_hole    = v_old.starting_hole,
           player_device_id = NULL     -- scorer must re-claim
     WHERE id = p_new_player_id;

    -- Release old player back to unassigned roster
    UPDATE tournament_players
       SET group_code = NULL, player_device_id = NULL, status = 'active'
     WHERE id = p_old_player_id;

    INSERT INTO club_event_change_log (tournament_id, changed_by, change_type, details)
    VALUES (p_tournament_id, v_device_id, 'replace_player',
            jsonb_build_object(
                'old_player_id',   p_old_player_id,
                'old_player_name', v_old.player_name,
                'new_player_id',   p_new_player_id,
                'new_player_name', v_new.player_name,
                'group_code',      v_old.group_code,
                'scores_moved',    v_scores_moved
            ));

    RETURN jsonb_build_object('replaced', p_new_player_id, 'scores_moved', v_scores_moved);
END;
$$;

REVOKE ALL ON FUNCTION replace_club_event_player(UUID, UUID, UUID, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION replace_club_event_player(UUID, UUID, UUID, TEXT) TO anon, authenticated;


-- ── 4. withdraw_club_event_player ────────────────────────────
-- Organizer only. Sets status = 'withdrawn'; keeps scores on played holes.
-- Leaderboard will display "(WD)"; skins engine already excludes notEntered holes
-- (guard case .gross(let g) = player.scores[h] in FieldSkinsEngine.swift:98).

CREATE OR REPLACE FUNCTION withdraw_club_event_player(
    p_tournament_id UUID,
    p_player_id     UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_device_id    TEXT := COALESCE((current_setting('request.headers', true)::JSONB)->>'x-device-id', '');
    v_organizer_id TEXT;
    v_ev_status    TEXT;
    v_player       tournament_players%ROWTYPE;
    v_holes_played INT;
BEGIN
    SELECT e.status, e.organizer_device_id
      INTO v_ev_status, v_organizer_id
      FROM tournament_events e
     WHERE e.id = p_tournament_id;

    IF NOT FOUND                THEN RAISE EXCEPTION 'Event not found'; END IF;
    IF v_ev_status = 'finished' THEN RAISE EXCEPTION 'Cannot change players after results are locked'; END IF;
    IF v_organizer_id IS NULL OR v_organizer_id != v_device_id THEN
        RAISE EXCEPTION 'Organizer access required';
    END IF;

    SELECT * INTO v_player FROM tournament_players
     WHERE id = p_player_id AND tournament_id = p_tournament_id;
    IF NOT FOUND                     THEN RAISE EXCEPTION 'Player not found'; END IF;
    IF v_player.status = 'withdrawn' THEN RAISE EXCEPTION 'Player is already withdrawn'; END IF;

    SELECT COUNT(*) INTO v_holes_played
      FROM tournament_hole_scores
     WHERE tournament_player_id = p_player_id
       AND tournament_id        = p_tournament_id
       AND (gross_score > 0 OR net_score_type = 'picked_up');

    UPDATE tournament_players SET status = 'withdrawn' WHERE id = p_player_id;

    INSERT INTO club_event_change_log (tournament_id, changed_by, change_type, details)
    VALUES (p_tournament_id, v_device_id, 'withdraw_player',
            jsonb_build_object(
                'player_id',    p_player_id,
                'player_name',  v_player.player_name,
                'group_code',   v_player.group_code,
                'holes_played', v_holes_played
            ));

    RETURN jsonb_build_object('withdrawn', p_player_id, 'holes_played', v_holes_played);
END;
$$;

REVOKE ALL ON FUNCTION withdraw_club_event_player(UUID, UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION withdraw_club_event_player(UUID, UUID) TO anon, authenticated;


-- ── 5. remove_club_event_player_scores ───────────────────────
-- Organizer only. Deletes all hole scores + team slots; clears group_code and
-- player_device_id; returns player to unassigned roster with status = 'active'.
-- Client must show score count in confirm dialog before calling.

CREATE OR REPLACE FUNCTION remove_club_event_player_scores(
    p_tournament_id UUID,
    p_player_id     UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_device_id    TEXT := COALESCE((current_setting('request.headers', true)::JSONB)->>'x-device-id', '');
    v_organizer_id TEXT;
    v_ev_status    TEXT;
    v_player       tournament_players%ROWTYPE;
    v_score_count  INT;
BEGIN
    SELECT e.status, e.organizer_device_id
      INTO v_ev_status, v_organizer_id
      FROM tournament_events e
     WHERE e.id = p_tournament_id;

    IF NOT FOUND                THEN RAISE EXCEPTION 'Event not found'; END IF;
    IF v_ev_status = 'finished' THEN RAISE EXCEPTION 'Cannot change players after results are locked'; END IF;
    IF v_organizer_id IS NULL OR v_organizer_id != v_device_id THEN
        RAISE EXCEPTION 'Organizer access required';
    END IF;

    SELECT * INTO v_player FROM tournament_players
     WHERE id = p_player_id AND tournament_id = p_tournament_id;
    IF NOT FOUND THEN RAISE EXCEPTION 'Player not found'; END IF;

    SELECT COUNT(*) INTO v_score_count
      FROM tournament_hole_scores
     WHERE tournament_player_id = p_player_id
       AND tournament_id        = p_tournament_id;

    -- Delete scores
    DELETE FROM tournament_hole_scores
     WHERE tournament_player_id = p_player_id
       AND tournament_id        = p_tournament_id;

    -- Delete team slots (join via tournament_teams.tournament_id — not name-based)
    DELETE FROM tournament_team_players ttp
     USING tournament_teams tt
     WHERE ttp.team_id              = tt.id
       AND tt.tournament_id         = p_tournament_id
       AND ttp.tournament_player_id = p_player_id;

    -- Clear group assignment and device claim; reset status
    UPDATE tournament_players
       SET group_code = NULL, player_device_id = NULL, status = 'active'
     WHERE id = p_player_id;

    INSERT INTO club_event_change_log (tournament_id, changed_by, change_type, details)
    VALUES (p_tournament_id, v_device_id, 'remove_player',
            jsonb_build_object(
                'player_id',      p_player_id,
                'player_name',    v_player.player_name,
                'group_code',     v_player.group_code,
                'scores_deleted', v_score_count
            ));

    RETURN jsonb_build_object('removed', p_player_id, 'scores_deleted', v_score_count);
END;
$$;

REVOKE ALL ON FUNCTION remove_club_event_player_scores(UUID, UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION remove_club_event_player_scores(UUID, UUID) TO anon, authenticated;


-- ── 6. update_club_event_settings ────────────────────────────
-- Organizer only. Pass NULL to leave a field unchanged.
-- Guards:
--   • course_name or tee_set change: blocked if ANY row exists in
--     tournament_hole_scores for this event (picked-up rows have null gross).
--   • allow_dual_team = FALSE: blocked if any player appears in >1 team row
--     for this event (joined via tournament_teams.tournament_id — not name-based).
-- Logs every changed field under change_type = 'update_settings'.

CREATE OR REPLACE FUNCTION update_club_event_settings(
    p_tournament_id        UUID,
    p_name                 TEXT    DEFAULT NULL,
    p_course_name          TEXT    DEFAULT NULL,
    p_tee_set              TEXT    DEFAULT NULL,
    p_handicap_allowance   NUMERIC DEFAULT NULL,
    p_gross_leaderboard    BOOL    DEFAULT NULL,
    p_gross_skins_enabled  BOOL    DEFAULT NULL,
    p_net_skins_enabled    BOOL    DEFAULT NULL,
    p_skins_carryover      BOOL    DEFAULT NULL,
    p_entry_fee_per_player NUMERIC DEFAULT NULL,
    p_team_places_paid     INT     DEFAULT NULL,
    p_allow_dual_team      BOOL    DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_device_id    TEXT := COALESCE((current_setting('request.headers', true)::JSONB)->>'x-device-id', '');
    v_organizer_id TEXT;
    v_ev_status    TEXT;
    v_old_name     TEXT;
    v_old_course   TEXT;
    v_old_tee      TEXT;
    v_rules        tournament_rules%ROWTYPE;
    v_has_scores   BOOL;
    v_dual_count   INT;
    v_changes      JSONB := '[]'::JSONB;
    v_course_or_tee_changing BOOL;
BEGIN
    SELECT e.status, e.organizer_device_id, e.name, e.course_name, e.tee_set
      INTO v_ev_status, v_organizer_id, v_old_name, v_old_course, v_old_tee
      FROM tournament_events e
     WHERE e.id = p_tournament_id;

    IF NOT FOUND                THEN RAISE EXCEPTION 'Event not found'; END IF;
    IF v_ev_status = 'finished' THEN RAISE EXCEPTION 'Settings locked after results are locked'; END IF;
    IF v_organizer_id IS NULL OR v_organizer_id != v_device_id THEN
        RAISE EXCEPTION 'Organizer access required';
    END IF;

    SELECT * INTO v_rules FROM tournament_rules WHERE tournament_id = p_tournament_id;

    -- Guard: course_name or tee_set cannot change once ANY score row exists.
    -- Covers picked-up rows (gross IS NULL) as well as gross scores.
    v_course_or_tee_changing :=
        (p_course_name IS NOT NULL AND p_course_name IS DISTINCT FROM v_old_course)
        OR
        (p_tee_set IS NOT NULL AND p_tee_set IS DISTINCT FROM v_old_tee);

    IF v_course_or_tee_changing THEN
        SELECT EXISTS (
            SELECT 1
              FROM tournament_hole_scores hs
              JOIN tournament_players tp ON hs.tournament_player_id = tp.id
             WHERE tp.tournament_id = p_tournament_id
        ) INTO v_has_scores;
        IF v_has_scores THEN
            RAISE EXCEPTION 'Course/tees cannot be changed after any scores have been entered';
        END IF;
    END IF;

    -- Guard: cannot turn off allow_dual_team while any player holds >1 team slot.
    -- Counts via tournament_teams.tournament_id join — not name-based.
    IF p_allow_dual_team = FALSE AND v_rules.allow_dual_team = TRUE THEN
        SELECT COUNT(*) INTO v_dual_count
          FROM (
              SELECT ttp.tournament_player_id
                FROM tournament_team_players ttp
                JOIN tournament_teams tt ON ttp.team_id = tt.id
               WHERE tt.tournament_id = p_tournament_id
               GROUP BY ttp.tournament_player_id
              HAVING COUNT(*) > 1
          ) sub;
        IF v_dual_count > 0 THEN
            RAISE EXCEPTION
                'Cannot disable dual-team: % player(s) are on two teams. Remove dual assignment first.',
                v_dual_count;
        END IF;
    END IF;

    -- Apply tournament_events changes
    IF p_name IS NOT NULL AND p_name IS DISTINCT FROM v_old_name THEN
        UPDATE tournament_events SET name = p_name WHERE id = p_tournament_id;
        v_changes := v_changes || jsonb_build_array(
            jsonb_build_object('field', 'name', 'old', v_old_name, 'new', p_name));
    END IF;
    IF p_course_name IS NOT NULL AND p_course_name IS DISTINCT FROM v_old_course THEN
        UPDATE tournament_events SET course_name = p_course_name WHERE id = p_tournament_id;
        v_changes := v_changes || jsonb_build_array(
            jsonb_build_object('field', 'course', 'old', v_old_course, 'new', p_course_name));
    END IF;
    IF p_tee_set IS NOT NULL AND p_tee_set IS DISTINCT FROM v_old_tee THEN
        UPDATE tournament_events SET tee_set = p_tee_set WHERE id = p_tournament_id;
        v_changes := v_changes || jsonb_build_array(
            jsonb_build_object('field', 'tee_set', 'old', v_old_tee, 'new', p_tee_set));
    END IF;

    -- Upsert tournament_rules (preserves existing values for fields not passed)
    INSERT INTO tournament_rules (
        tournament_id, handicap_allowance, gross_leaderboard,
        gross_skins_enabled, net_skins_enabled, skins_carryover,
        entry_fee_per_player, team_places_paid, allow_dual_team
    ) VALUES (
        p_tournament_id,
        COALESCE(p_handicap_allowance,   v_rules.handicap_allowance,   1.0),
        COALESCE(p_gross_leaderboard,    v_rules.gross_leaderboard,    FALSE),
        COALESCE(p_gross_skins_enabled,  v_rules.gross_skins_enabled,  TRUE),
        COALESCE(p_net_skins_enabled,    v_rules.net_skins_enabled,    TRUE),
        COALESCE(p_skins_carryover,      v_rules.skins_carryover,      FALSE),
        COALESCE(p_entry_fee_per_player, v_rules.entry_fee_per_player, NULL),
        COALESCE(p_team_places_paid,     v_rules.team_places_paid,     3),
        COALESCE(p_allow_dual_team,      v_rules.allow_dual_team,      FALSE)
    )
    ON CONFLICT (tournament_id) DO UPDATE SET
        handicap_allowance   = EXCLUDED.handicap_allowance,
        gross_leaderboard    = EXCLUDED.gross_leaderboard,
        gross_skins_enabled  = EXCLUDED.gross_skins_enabled,
        net_skins_enabled    = EXCLUDED.net_skins_enabled,
        skins_carryover      = EXCLUDED.skins_carryover,
        entry_fee_per_player = EXCLUDED.entry_fee_per_player,
        team_places_paid     = EXCLUDED.team_places_paid,
        allow_dual_team      = EXCLUDED.allow_dual_team;

    -- Log individual rules changes
    IF p_handicap_allowance IS NOT NULL
       AND p_handicap_allowance IS DISTINCT FROM v_rules.handicap_allowance THEN
        v_changes := v_changes || jsonb_build_array(jsonb_build_object(
            'field', 'handicap_allowance',
            'old',   v_rules.handicap_allowance::TEXT,
            'new',   p_handicap_allowance::TEXT));
    END IF;
    IF p_gross_leaderboard IS NOT NULL
       AND p_gross_leaderboard IS DISTINCT FROM v_rules.gross_leaderboard THEN
        v_changes := v_changes || jsonb_build_array(jsonb_build_object(
            'field', 'gross_leaderboard',
            'old',   v_rules.gross_leaderboard::TEXT,
            'new',   p_gross_leaderboard::TEXT));
    END IF;
    IF p_gross_skins_enabled IS NOT NULL
       AND p_gross_skins_enabled IS DISTINCT FROM v_rules.gross_skins_enabled THEN
        v_changes := v_changes || jsonb_build_array(jsonb_build_object(
            'field', 'gross_skins',
            'old',   v_rules.gross_skins_enabled::TEXT,
            'new',   p_gross_skins_enabled::TEXT));
    END IF;
    IF p_net_skins_enabled IS NOT NULL
       AND p_net_skins_enabled IS DISTINCT FROM v_rules.net_skins_enabled THEN
        v_changes := v_changes || jsonb_build_array(jsonb_build_object(
            'field', 'net_skins',
            'old',   v_rules.net_skins_enabled::TEXT,
            'new',   p_net_skins_enabled::TEXT));
    END IF;
    IF p_skins_carryover IS NOT NULL
       AND p_skins_carryover IS DISTINCT FROM v_rules.skins_carryover THEN
        v_changes := v_changes || jsonb_build_array(jsonb_build_object(
            'field', 'skins_carryover',
            'old',   v_rules.skins_carryover::TEXT,
            'new',   p_skins_carryover::TEXT));
    END IF;
    IF p_entry_fee_per_player IS NOT NULL
       AND p_entry_fee_per_player IS DISTINCT FROM v_rules.entry_fee_per_player THEN
        v_changes := v_changes || jsonb_build_array(jsonb_build_object(
            'field', 'entry_fee',
            'old',   v_rules.entry_fee_per_player::TEXT,
            'new',   p_entry_fee_per_player::TEXT));
    END IF;
    IF p_team_places_paid IS NOT NULL
       AND p_team_places_paid IS DISTINCT FROM v_rules.team_places_paid THEN
        v_changes := v_changes || jsonb_build_array(jsonb_build_object(
            'field', 'places_paid',
            'old',   v_rules.team_places_paid::TEXT,
            'new',   p_team_places_paid::TEXT));
    END IF;
    IF p_allow_dual_team IS NOT NULL
       AND p_allow_dual_team IS DISTINCT FROM v_rules.allow_dual_team THEN
        v_changes := v_changes || jsonb_build_array(jsonb_build_object(
            'field', 'allow_dual_team',
            'old',   v_rules.allow_dual_team::TEXT,
            'new',   p_allow_dual_team::TEXT));
    END IF;

    IF jsonb_array_length(v_changes) > 0 THEN
        INSERT INTO club_event_change_log (tournament_id, changed_by, change_type, details)
        VALUES (p_tournament_id, v_device_id, 'update_settings',
                jsonb_build_object('changes', v_changes));
    END IF;

    RETURN jsonb_build_object('updated', jsonb_array_length(v_changes));
END;
$$;

REVOKE ALL ON FUNCTION update_club_event_settings(UUID,TEXT,TEXT,TEXT,NUMERIC,BOOL,BOOL,BOOL,BOOL,NUMERIC,INT,BOOL) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION update_club_event_settings(UUID,TEXT,TEXT,TEXT,NUMERIC,BOOL,BOOL,BOOL,BOOL,NUMERIC,INT,BOOL)
    TO anon, authenticated;


-- ── 7. update_club_event_player_handicap ─────────────────────
-- Organizer only. Validates -10..54. Updates handicap and writes a change-log entry.

CREATE OR REPLACE FUNCTION update_club_event_player_handicap(
    p_tournament_id UUID,
    p_player_id     UUID,
    p_new_handicap  NUMERIC
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_device_id    TEXT := COALESCE((current_setting('request.headers', true)::JSONB)->>'x-device-id', '');
    v_organizer_id TEXT;
    v_ev_status    TEXT;
    v_player       tournament_players%ROWTYPE;
BEGIN
    IF p_new_handicap < -10 OR p_new_handicap > 54 THEN
        RAISE EXCEPTION 'Handicap must be between -10 and 54 (got %)', p_new_handicap;
    END IF;

    SELECT e.status, e.organizer_device_id
      INTO v_ev_status, v_organizer_id
      FROM tournament_events e
     WHERE e.id = p_tournament_id;

    IF NOT FOUND                THEN RAISE EXCEPTION 'Event not found'; END IF;
    IF v_ev_status = 'finished' THEN RAISE EXCEPTION 'Settings locked after results are locked'; END IF;
    IF v_organizer_id IS NULL OR v_organizer_id != v_device_id THEN
        RAISE EXCEPTION 'Organizer access required';
    END IF;

    SELECT * INTO v_player FROM tournament_players
     WHERE id = p_player_id AND tournament_id = p_tournament_id;
    IF NOT FOUND THEN RAISE EXCEPTION 'Player not found'; END IF;

    UPDATE tournament_players SET handicap = p_new_handicap WHERE id = p_player_id;

    INSERT INTO club_event_change_log (tournament_id, changed_by, change_type, details)
    VALUES (p_tournament_id, v_device_id, 'update_handicap',
            jsonb_build_object(
                'player_id',   p_player_id,
                'player_name', v_player.player_name,
                'old_hc',      v_player.handicap,
                'new_hc',      p_new_handicap
            ));
END;
$$;

REVOKE ALL ON FUNCTION update_club_event_player_handicap(UUID, UUID, NUMERIC) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION update_club_event_player_handicap(UUID, UUID, NUMERIC) TO anon, authenticated;
