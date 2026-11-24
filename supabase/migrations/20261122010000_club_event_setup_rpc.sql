-- Club Event Phase 3: setup_club_event_group RPC
--
-- Scorer devices cannot UPDATE tournament_players under current RLS (organizer-only).
-- This SECURITY DEFINER function runs with elevated privileges and handles:
--   1. Validating the group code format and uniqueness within the event.
--   2. Inserting walk-on players (name + handicap typed by scorer, not on roster).
--   3. Claiming roster players atomically (UPDATE WHERE group_code IS NULL).
--   4. Creating tournament_teams and tournament_team_players entries.
--   5. Returning which players were claimed vs. taken by a concurrent scorer.
--
-- Clients send a JSON array for p_assignments:
--   [{"player_id": "uuid", "team": "A"|"B"|"Solo"}, ...]
-- Walk-ons go in p_walkons:
--   [{"name": "text", "handicap": 14}, ...]
-- Walk-ons are inserted first, then included in the same claim + team logic.

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
    v_item        JSONB;
    v_player_id   UUID;
    v_team        TEXT;
    v_name        TEXT;
    v_handicap    NUMERIC;
    v_new_id      UUID;
    v_claimed     UUID[] := '{}';
    v_taken       UUID[] := '{}';
    v_team_id_a   UUID;
    v_team_id_b   UUID;
    v_flight_a    INT := 0;
    v_flight_b    INT := 0;
    v_flights     TEXT[] := ARRAY['A','B','C','D'];
    -- walk-on player IDs mapped to their team assignment
    v_walkons_map JSONB := '{}';
BEGIN

    -- ── Validate ──────────────────────────────────────────────────────────────

    IF p_group_code !~ '^[2-9A-HJ-NP-Z]{6}$' THEN
        RAISE EXCEPTION 'Invalid group code format: must be 6 chars, A–Z (no I/O) and 2–9 (no 0/1)';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM tournament_events WHERE id = p_tournament_id) THEN
        RAISE EXCEPTION 'Event not found';
    END IF;

    IF EXISTS (SELECT 1 FROM tournament_events WHERE id = p_tournament_id AND status = 'finished') THEN
        RAISE EXCEPTION 'Event is finished';
    END IF;

    IF EXISTS (
        SELECT 1 FROM tournament_players
        WHERE tournament_id = p_tournament_id AND group_code = p_group_code
    ) THEN
        RAISE EXCEPTION 'Group code % is already in use in this event', p_group_code;
    END IF;

    -- ── Insert walk-on players ─────────────────────────────────────────────────

    FOR v_item IN SELECT * FROM jsonb_array_elements(p_walkons) LOOP
        v_name     := v_item->>'name';
        v_handicap := (v_item->>'handicap')::NUMERIC;
        v_team     := COALESCE(v_item->>'team', 'Solo');

        INSERT INTO tournament_players (tournament_id, player_device_id, player_name, handicap)
        VALUES (p_tournament_id, gen_random_uuid()::TEXT, v_name, v_handicap)
        RETURNING id INTO v_new_id;

        v_walkons_map := v_walkons_map || jsonb_build_object(v_new_id::TEXT, v_team);
        p_assignments := p_assignments || jsonb_build_array(
            jsonb_build_object('player_id', v_new_id, 'team', v_team)
        );
    END LOOP;

    -- ── Claim players ─────────────────────────────────────────────────────────

    FOR v_item IN SELECT * FROM jsonb_array_elements(p_assignments) LOOP
        v_player_id := (v_item->>'player_id')::UUID;

        UPDATE tournament_players
        SET group_code    = p_group_code,
            starting_hole = p_starting_hole
        WHERE id            = v_player_id
          AND tournament_id = p_tournament_id
          AND group_code    IS NULL;

        IF FOUND THEN
            v_claimed := v_claimed || v_player_id;
        ELSE
            v_taken := v_taken || v_player_id;
        END IF;
    END LOOP;

    IF array_length(v_claimed, 1) IS NULL THEN
        RETURN jsonb_build_object('claimed', '[]'::jsonb, 'taken', to_jsonb(v_taken));
    END IF;

    -- ── Create teams and assign players ───────────────────────────────────────

    FOR v_item IN SELECT * FROM jsonb_array_elements(p_assignments) LOOP
        v_player_id := (v_item->>'player_id')::UUID;
        v_team      := v_item->>'team';

        CONTINUE WHEN NOT (v_player_id = ANY(v_claimed));
        CONTINUE WHEN v_team IS NULL OR v_team = 'Solo';

        IF v_team = 'A' THEN
            IF v_team_id_a IS NULL THEN
                INSERT INTO tournament_teams (tournament_id, team_name)
                VALUES (p_tournament_id, p_group_code || '-A')
                RETURNING id INTO v_team_id_a;
            END IF;
            IF v_flight_a < array_length(v_flights, 1) THEN
                INSERT INTO tournament_team_players (team_id, tournament_player_id, flight)
                VALUES (v_team_id_a, v_player_id, v_flights[v_flight_a + 1]);
                v_flight_a := v_flight_a + 1;
            END IF;

        ELSIF v_team = 'B' THEN
            IF v_team_id_b IS NULL THEN
                INSERT INTO tournament_teams (tournament_id, team_name)
                VALUES (p_tournament_id, p_group_code || '-B')
                RETURNING id INTO v_team_id_b;
            END IF;
            IF v_flight_b < array_length(v_flights, 1) THEN
                INSERT INTO tournament_team_players (team_id, tournament_player_id, flight)
                VALUES (v_team_id_b, v_player_id, v_flights[v_flight_b + 1]);
                v_flight_b := v_flight_b + 1;
            END IF;
        END IF;
    END LOOP;

    RETURN jsonb_build_object(
        'claimed', to_jsonb(v_claimed),
        'taken',   to_jsonb(v_taken)
    );
END;
$$;

REVOKE ALL  ON FUNCTION public.setup_club_event_group(UUID, TEXT, INT, JSONB, JSONB) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.setup_club_event_group(UUID, TEXT, INT, JSONB, JSONB) TO anon, authenticated;
