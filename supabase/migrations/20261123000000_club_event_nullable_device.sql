-- Club Event: nullable player_device_id + create_club_event RPC
--
-- Background
-- ----------
-- tournament_players.player_device_id was NOT NULL. Roster players inserted
-- by the organizer before any scorer joins have no device yet; NULL is the
-- correct sentinel value ("unclaimed").
--
-- RLS safety with NULL (no policy changes — existing text is correct)
-- -------------------------------------------------------------------
-- "player submit own score" (tournament_hole_scores INSERT):
--     tp.player_device_id = nullif(header->>'x-device-id', '')
--     NULL = <any non-null>  →  NULL  →  FALSE   ✓ unclaimed slots cannot submit
--     NULL = NULL            →  NULL  →  FALSE   ✓ header-less callers also blocked
-- All organizer policies check tournament_events.organizer_device_id, not
-- tournament_players.player_device_id — unaffected by this change.
-- "group scorer insert/update score" policies check x-group-code / group_code
-- — also unaffected.
--
-- Unique constraint removal
-- -------------------------
-- Old constraint: unique (tournament_id, player_device_id)
-- A scorer claims 2–4 players; all receive the scorer's device_id.
-- That would immediately violate the constraint. Must be dropped.
-- PostgreSQL treats NULL as distinct for UNIQUE, so multiple NULL rows
-- were always permitted — the constraint only became a problem once a
-- real device_id was stamped on more than one player in the same event.

-- ─────────────────────────────────────────
-- 1. Make player_device_id nullable
-- ─────────────────────────────────────────

ALTER TABLE tournament_players
  ALTER COLUMN player_device_id DROP NOT NULL;

-- ─────────────────────────────────────────
-- 2. Drop the per-event unique constraint on device_id
-- ─────────────────────────────────────────

ALTER TABLE tournament_players
  DROP CONSTRAINT IF EXISTS tournament_players_tournament_id_player_device_id_key;

-- ─────────────────────────────────────────
-- 3. create_club_event — atomic event + rules + roster
-- ─────────────────────────────────────────
-- Runs SECURITY DEFINER so the whole operation is one transaction and
-- partial failures leave nothing behind.
-- Caller passes p_organizer_device_id explicitly (the mobile app sends
-- DeviceID.id; the server stamps it into organizer_device_id).

CREATE OR REPLACE FUNCTION public.create_club_event(
    p_name                TEXT,
    p_organizer_device_id TEXT,
    p_course_name         TEXT  DEFAULT NULL,
    p_num_days            INT   DEFAULT 1,
    p_players             JSONB DEFAULT '[]'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_event_id UUID;
    v_code     TEXT;
    v_chars    CONSTANT TEXT := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    v_i        INT;
    v_item     JSONB;
BEGIN
    -- Generate a unique 6-char code from the same character set as the mobile
    -- app (excludes I, O, 0, 1 to avoid visual ambiguity).
    LOOP
        v_code := '';
        FOR v_i IN 1..6 LOOP
            v_code := v_code
                   || substr(v_chars,
                              (floor(random() * length(v_chars)))::INT + 1,
                              1);
        END LOOP;
        EXIT WHEN NOT EXISTS (
            SELECT 1 FROM tournament_events WHERE code = v_code
        );
    END LOOP;

    -- Insert the event record.
    INSERT INTO tournament_events
        (code, name, organizer_device_id, course_name, num_days, status)
    VALUES
        (v_code, p_name, p_organizer_device_id, p_course_name, p_num_days, 'active')
    RETURNING id INTO v_event_id;

    -- Insert a default rules row (all columns have sensible defaults).
    INSERT INTO tournament_rules (tournament_id) VALUES (v_event_id);

    -- Insert roster players; player_device_id stays NULL until a scorer
    -- claims them via setup_club_event_group.
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_players) LOOP
        INSERT INTO tournament_players (tournament_id, player_name, handicap)
        VALUES (
            v_event_id,
            v_item->>'name',
            (v_item->>'handicap')::NUMERIC
        );
    END LOOP;

    RETURN jsonb_build_object('id', v_event_id, 'code', v_code);
END;
$$;

REVOKE ALL    ON FUNCTION public.create_club_event(TEXT, TEXT, TEXT, INT, JSONB) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_club_event(TEXT, TEXT, TEXT, INT, JSONB) TO anon, authenticated;

-- ─────────────────────────────────────────
-- 4. Update setup_club_event_group
--    Stamp player_device_id = scorer's device on claim and walk-on insert.
--    Walk-ons previously used gen_random_uuid()::TEXT as a workaround for
--    the NOT NULL constraint; they now get the scorer's real device id.
--    If x-device-id is absent the value is NULL, which is safe (see policy
--    analysis above) and falls back to group-code–based score submission.
-- ─────────────────────────────────────────

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
    v_team              TEXT;
    v_name              TEXT;
    v_handicap          NUMERIC;
    v_new_id            UUID;
    v_claimed           UUID[] := '{}';
    v_taken             UUID[] := '{}';
    v_team_id_a         UUID;
    v_team_id_b         UUID;
    v_flight_a          INT := 0;
    v_flight_b          INT := 0;
    v_flights           TEXT[] := ARRAY['A','B','C','D'];
    v_walkons_map       JSONB := '{}';
    v_scorer_device_id  TEXT;
BEGIN

    -- Read the scorer's device id from the request header (may be NULL if
    -- the client did not send x-device-id).
    v_scorer_device_id := nullif(
        current_setting('request.headers', true)::jsonb->>'x-device-id', ''
    );

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
    -- player_device_id = scorer's device (not a random UUID as before).

    FOR v_item IN SELECT * FROM jsonb_array_elements(p_walkons) LOOP
        v_name     := v_item->>'name';
        v_handicap := (v_item->>'handicap')::NUMERIC;
        v_team     := COALESCE(v_item->>'team', 'Solo');

        INSERT INTO tournament_players
            (tournament_id, player_device_id, player_name, handicap)
        VALUES
            (p_tournament_id, v_scorer_device_id, v_name, v_handicap)
        RETURNING id INTO v_new_id;

        v_walkons_map := v_walkons_map || jsonb_build_object(v_new_id::TEXT, v_team);
        p_assignments := p_assignments || jsonb_build_array(
            jsonb_build_object('player_id', v_new_id, 'team', v_team)
        );
    END LOOP;

    -- ── Claim players ─────────────────────────────────────────────────────────
    -- Also stamp player_device_id so the scorer can submit hole scores via
    -- the "player submit own score" RLS policy.

    FOR v_item IN SELECT * FROM jsonb_array_elements(p_assignments) LOOP
        v_player_id := (v_item->>'player_id')::UUID;

        UPDATE tournament_players
        SET group_code       = p_group_code,
            starting_hole    = p_starting_hole,
            player_device_id = v_scorer_device_id
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

REVOKE ALL    ON FUNCTION public.setup_club_event_group(UUID, TEXT, INT, JSONB, JSONB) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.setup_club_event_group(UUID, TEXT, INT, JSONB, JSONB) TO anon, authenticated;
