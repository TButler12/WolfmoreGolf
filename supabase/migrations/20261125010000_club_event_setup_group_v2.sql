-- Club Event Feature #2: multi-team player support — setup_club_event_group v3
--
-- p_assignments schema change (BREAKING):
--   Before: [{"player_id": "uuid", "team": "A"|"B"|"Solo"}, ...]
--   After:  [{"player_id": "uuid", "teams": ["A"]|["B"]|["A","B"]}, ...]
--
-- p_walkons schema change (BREAKING):
--   Before: [{"name": "text", "handicap": 14, "team": "A"}, ...]
--   After:  [{"name": "text", "handicap": 14, "teams": ["A"]}, ...]
--
-- Server-side invariants enforced:
--   • Every player must be on at least one team (A or B). Solo is removed.
--   • Max 2 players per team. Exceeding raises an error immediately.
--   • Max 2 team slots per player across the submission. Exceeding raises.
--   • Dual-team assignment (["A","B"]) rejected unless allow_dual_team = true.
--   • Players taken by another group raise immediately (no partial-success response).
--   • Idempotent: existing teams for this group are deleted and recreated
--     when no hole scores exist; hole scores present raises with a clear message.
--
-- Return value change:
--   Before: {"claimed": [...], "taken": [...]}
--   After:  {"claimed": [...]}   — taken raises instead of returning partial results

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
    v_item             JSONB;
    v_player_id        UUID;
    v_teams            TEXT[];
    v_team             TEXT;
    v_name             TEXT;
    v_handicap         NUMERIC;
    v_new_id           UUID;
    v_claimed          UUID[] := '{}';
    v_team_id_a        UUID;
    v_team_id_b        UUID;
    v_count_a          INT := 0;      -- running count during team assignment
    v_count_b          INT := 0;
    v_pre_count_a      INT := 0;      -- running count during pre-validation
    v_pre_count_b      INT := 0;
    v_allow_dual       BOOLEAN;
    v_scorer_device_id TEXT;
    v_slot_tally       JSONB := '{}'; -- per-player total slot count across submission
    v_tally            INT;
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
    -- Runs before any claiming or team creation so errors are clean and
    -- the transaction rolls back without partial state.

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

        -- Cross-entry slot tally: same player_id in multiple entries
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
    -- If this group already has teams (a previous successful call or a timed-out
    -- retry), delete and recreate them — but only when no hole scores exist yet.

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

        -- Safe to delete: no scores exist. ON DELETE CASCADE removes tournament_team_players rows.
        DELETE FROM tournament_teams
         WHERE tournament_id = p_tournament_id
           AND (team_name = p_group_code || '-A'
             OR team_name = p_group_code || '-B');

        -- Release players dropped from the new roster.
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
    -- The WHERE allows re-claiming players already in this group (idempotent retry).
    -- If FOUND is false the player belongs to a different group → raise immediately.

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

        -- Belt-and-suspenders: every assignment must have been claimed above.
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
