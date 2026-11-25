-- App version gate for events with a course snapshot.
--
-- Events that store course_pars require build 80+. Old builds silently score
-- with wrong pars if they're allowed in. Both entry points are gated:
--   • setup_club_event_group  — organiser path
--   • submit_club_event_card  — scorer/joiner path (bypasses setup_club_event_group)
--
-- Gate logic: if course_pars IS NOT NULL AND x-app-version header < 80 (or absent),
-- raise 'Please update WolfMore Golf to join this event'.
--
-- New builds send x-app-version: <CFBundleVersion> on every Supabase call.
-- Old App Store builds omit the header → treated as build 0 → gated out.

-- ════════════════════════════════════════════════════════════════════════════
-- 1. setup_club_event_group
-- ════════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.setup_club_event_group(
    p_tournament_id UUID,
    p_group_code    TEXT,
    p_starting_hole INT  DEFAULT 1,
    p_assignments   JSONB DEFAULT '[]',
    p_walkons       JSONB DEFAULT '[]'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_item              JSONB;
    v_player_id         UUID;
    v_teams             TEXT[];
    v_team              TEXT;
    v_name              TEXT;
    v_handicap          NUMERIC;
    v_new_id            UUID;
    v_claimed           UUID[] := '{}';
    v_team_id_a         UUID;
    v_team_id_b         UUID;
    v_count_a           INT := 0;
    v_count_b           INT := 0;
    v_pre_count_a       INT := 0;
    v_pre_count_b       INT := 0;
    v_allow_dual        BOOLEAN;
    v_scorer_device_id  TEXT;
    v_slot_tally        JSONB := '{}';
    v_tally             INT;
    v_app_version_str   TEXT;
    v_app_version       INT;
BEGIN

    -- ── Scorer device id ──────────────────────────────────────────────────────

    v_scorer_device_id := nullif(
        current_setting('request.headers', true)::jsonb->>'x-device-id', ''
    );

    -- ── Validate event ────────────────────────────────────────────────────────

    IF p_group_code !~ '^[2-9A-HJ-NP-Z]{6}$' THEN
        RAISE EXCEPTION 'Invalid group code: must be 6 chars, A–Z (no I/O) and 2–9 (no 0/1)';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM tournament_events WHERE id = p_tournament_id) THEN
        RAISE EXCEPTION 'Event not found';
    END IF;

    IF EXISTS (SELECT 1 FROM tournament_events
               WHERE id = p_tournament_id AND status = 'finished') THEN
        RAISE EXCEPTION 'Event is finished';
    END IF;

    -- ── App version gate ──────────────────────────────────────────────────────
    -- Events with course_pars require build 80+; old builds score with wrong pars.

    v_app_version_str := nullif(
        current_setting('request.headers', true)::jsonb->>'x-app-version', ''
    );
    v_app_version := CASE
        WHEN v_app_version_str ~ '^\d+$' THEN v_app_version_str::INT
        ELSE 0
    END;

    IF v_app_version < 80 AND EXISTS (
        SELECT 1 FROM tournament_events
         WHERE id = p_tournament_id AND course_pars IS NOT NULL
    ) THEN
        RAISE EXCEPTION 'Please update WolfMore Golf to join this event';
    END IF;

    -- ── Load settings ─────────────────────────────────────────────────────────

    SELECT COALESCE(allow_dual_team, false)
      INTO v_allow_dual
      FROM tournament_rules
     WHERE tournament_id = p_tournament_id
     LIMIT 1;

    v_allow_dual := COALESCE(v_allow_dual, false);

    -- ── Insert walk-ons ───────────────────────────────────────────────────────

    FOR v_item IN SELECT * FROM jsonb_array_elements(p_walkons) LOOP
        v_name     := v_item->>'name';
        v_handicap := (v_item->>'handicap')::NUMERIC;
        v_teams    := ARRAY(SELECT jsonb_array_elements_text(v_item->'teams'));

        IF array_length(v_teams, 1) IS NULL THEN
            RAISE EXCEPTION 'Walk-on "%" must have a non-empty teams array', v_name;
        END IF;

        INSERT INTO tournament_players
            (tournament_id, player_device_id, player_name, handicap)
        VALUES
            (p_tournament_id, v_scorer_device_id, v_name, v_handicap)
        RETURNING id INTO v_new_id;

        p_assignments := p_assignments || jsonb_build_array(
            jsonb_build_object('player_id', v_new_id, 'teams', to_jsonb(v_teams))
        );
    END LOOP;

    -- ── Pre-validate all assignments ──────────────────────────────────────────

    FOR v_item IN SELECT * FROM jsonb_array_elements(p_assignments) LOOP
        v_player_id := (v_item->>'player_id')::UUID;
        v_teams     := ARRAY(SELECT jsonb_array_elements_text(v_item->'teams'));

        IF array_length(v_teams, 1) IS NULL THEN
            RAISE EXCEPTION 'Player % must have a non-empty teams array', v_player_id;
        END IF;

        IF array_length(v_teams, 1) > 2 THEN
            RAISE EXCEPTION 'Player % cannot appear in more than 2 teams in one submission', v_player_id;
        END IF;

        IF array_length(v_teams, 1) = 2 AND NOT v_allow_dual THEN
            RAISE EXCEPTION 'Player %: dual-team assignment is not enabled for this event', v_player_id;
        END IF;

        FOREACH v_team IN ARRAY v_teams LOOP
            IF v_team NOT IN ('A', 'B') THEN
                RAISE EXCEPTION 'Invalid team "%" for player % — must be A or B', v_team, v_player_id;
            END IF;
            IF v_team = 'A' THEN
                v_pre_count_a := v_pre_count_a + 1;
                IF v_pre_count_a > 2 THEN
                    RAISE EXCEPTION 'Team A cannot have more than 2 players';
                END IF;
            ELSIF v_team = 'B' THEN
                v_pre_count_b := v_pre_count_b + 1;
                IF v_pre_count_b > 2 THEN
                    RAISE EXCEPTION 'Team B cannot have more than 2 players';
                END IF;
            END IF;
        END LOOP;

        v_tally := COALESCE((v_slot_tally->>v_player_id::TEXT)::INT, 0)
                   + array_length(v_teams, 1);
        IF v_tally > 2 THEN
            RAISE EXCEPTION 'Player % appears in more than 2 team slots across the submission', v_player_id;
        END IF;
        v_slot_tally := jsonb_set(v_slot_tally,
                                  ARRAY[v_player_id::TEXT],
                                  to_jsonb(v_tally));
    END LOOP;

    -- ── Idempotency ───────────────────────────────────────────────────────────

    IF EXISTS (
        SELECT 1 FROM tournament_teams
         WHERE tournament_id = p_tournament_id
           AND (team_name = p_group_code || '-A'
             OR team_name = p_group_code || '-B')
    ) THEN
        IF EXISTS (
            SELECT 1
              FROM tournament_hole_scores ths
              JOIN tournament_players     tp ON tp.id = ths.tournament_player_id
             WHERE tp.tournament_id = p_tournament_id
               AND tp.group_code    = p_group_code
        ) THEN
            RAISE EXCEPTION
                'Group % already has scores entered — ask the organiser to reset it before re-confirming',
                p_group_code;
        END IF;

        DELETE FROM tournament_teams
         WHERE tournament_id = p_tournament_id
           AND (team_name = p_group_code || '-A'
             OR team_name = p_group_code || '-B');

        UPDATE tournament_players
           SET group_code       = NULL,
               player_device_id = NULL
         WHERE tournament_id = p_tournament_id
           AND group_code    = p_group_code
           AND id NOT IN (
               SELECT (elem->>'player_id')::UUID
                 FROM jsonb_array_elements(p_assignments) AS elem
           );
    END IF;

    -- ── Claim players ─────────────────────────────────────────────────────────

    FOR v_item IN SELECT * FROM jsonb_array_elements(p_assignments) LOOP
        v_player_id := (v_item->>'player_id')::UUID;

        UPDATE tournament_players
           SET group_code       = p_group_code,
               starting_hole    = p_starting_hole,
               player_device_id = v_scorer_device_id
         WHERE id            = v_player_id
           AND tournament_id = p_tournament_id
           AND (group_code IS NULL OR group_code = p_group_code);

        IF FOUND THEN
            v_claimed := v_claimed || v_player_id;
        ELSE
            RAISE EXCEPTION 'Player % is already claimed by another group', v_player_id;
        END IF;
    END LOOP;

    -- ── Create teams and assign players ───────────────────────────────────────

    FOR v_item IN SELECT * FROM jsonb_array_elements(p_assignments) LOOP
        v_player_id := (v_item->>'player_id')::UUID;
        v_teams     := ARRAY(SELECT jsonb_array_elements_text(v_item->'teams'));

        IF NOT (v_player_id = ANY(v_claimed)) THEN
            RAISE EXCEPTION 'Player % was not claimed — cannot assign to a team', v_player_id;
        END IF;

        FOREACH v_team IN ARRAY v_teams LOOP
            IF v_team = 'A' THEN
                IF v_count_a >= 2 THEN
                    RAISE EXCEPTION 'Team A is full (max 2 players)';
                END IF;
                IF v_team_id_a IS NULL THEN
                    INSERT INTO tournament_teams (tournament_id, team_name)
                    VALUES (p_tournament_id, p_group_code || '-A')
                    RETURNING id INTO v_team_id_a;
                END IF;
                INSERT INTO tournament_team_players
                    (team_id, tournament_player_id, flight)
                VALUES
                    (v_team_id_a, v_player_id,
                     CASE WHEN v_count_a = 0 THEN 'A' ELSE 'B' END);
                v_count_a := v_count_a + 1;

            ELSIF v_team = 'B' THEN
                IF v_count_b >= 2 THEN
                    RAISE EXCEPTION 'Team B is full (max 2 players)';
                END IF;
                IF v_team_id_b IS NULL THEN
                    INSERT INTO tournament_teams (tournament_id, team_name)
                    VALUES (p_tournament_id, p_group_code || '-B')
                    RETURNING id INTO v_team_id_b;
                END IF;
                INSERT INTO tournament_team_players
                    (team_id, tournament_player_id, flight)
                VALUES
                    (v_team_id_b, v_player_id,
                     CASE WHEN v_count_b = 0 THEN 'A' ELSE 'B' END);
                v_count_b := v_count_b + 1;
            END IF;
        END LOOP;
    END LOOP;

    RETURN jsonb_build_object('claimed', to_jsonb(v_claimed));
END;
$$;

REVOKE ALL    ON FUNCTION public.setup_club_event_group(UUID, TEXT, INT, JSONB, JSONB) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.setup_club_event_group(UUID, TEXT, INT, JSONB, JSONB) TO anon, authenticated;

-- ════════════════════════════════════════════════════════════════════════════
-- 2. submit_club_event_card
-- ════════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.submit_club_event_card(
    p_tournament_id UUID,
    p_group_code    TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_device_id         TEXT;
    v_group_code        TEXT;
    v_app_version_str   TEXT;
    v_app_version       INT;
BEGIN
    v_device_id  := nullif(current_setting('request.headers', true)::jsonb->>'x-device-id',  '');
    v_group_code := nullif(current_setting('request.headers', true)::jsonb->>'x-group-code', '');

    IF EXISTS (
        SELECT 1 FROM tournament_events
        WHERE id = p_tournament_id AND status = 'finished'
    ) THEN
        RAISE EXCEPTION 'Event is locked — card cannot be submitted';
    END IF;

    -- ── App version gate ──────────────────────────────────────────────────────

    v_app_version_str := nullif(
        current_setting('request.headers', true)::jsonb->>'x-app-version', ''
    );
    v_app_version := CASE
        WHEN v_app_version_str ~ '^\d+$' THEN v_app_version_str::INT
        ELSE 0
    END;

    IF v_app_version < 80 AND EXISTS (
        SELECT 1 FROM tournament_events
         WHERE id = p_tournament_id AND course_pars IS NOT NULL
    ) THEN
        RAISE EXCEPTION 'Please update WolfMore Golf to join this event';
    END IF;

    -- ── Authorize and submit ──────────────────────────────────────────────────

    IF v_group_code = p_group_code THEN
        UPDATE tournament_players
        SET card_submitted    = TRUE,
            card_submitted_at = NOW()
        WHERE tournament_id = p_tournament_id
          AND group_code    = p_group_code;
    ELSIF EXISTS (
        SELECT 1 FROM tournament_events
        WHERE id = p_tournament_id
          AND organizer_device_id = v_device_id
    ) THEN
        UPDATE tournament_players
        SET card_submitted    = TRUE,
            card_submitted_at = NOW()
        WHERE tournament_id = p_tournament_id
          AND group_code    = p_group_code;
    ELSE
        RAISE EXCEPTION 'Not authorized';
    END IF;
END;
$$;

REVOKE ALL    ON FUNCTION public.submit_club_event_card(UUID, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.submit_club_event_card(UUID, TEXT) TO anon, authenticated;
