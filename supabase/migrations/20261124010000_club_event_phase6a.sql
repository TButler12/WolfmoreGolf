-- Club Event Phase 6A: event start_date + extended create_club_event RPC
--
-- Drops the old 5-param create_club_event to avoid overload ambiguity, then
-- replaces it with a 13-param version that atomically creates the event,
-- inserts a tournament_rules row, and bulk-inserts players.
-- Input is validated: name non-empty, handicap_allowance 0–1, player
-- handicaps –10–54.

-- ─────────────────────────────────────────
-- 1. tournament_events.start_date
-- ─────────────────────────────────────────

ALTER TABLE tournament_events
  ADD COLUMN IF NOT EXISTS start_date DATE;

-- ─────────────────────────────────────────
-- 2. Drop old 5-param signature (avoid overload ambiguity)
-- ─────────────────────────────────────────

DROP FUNCTION IF EXISTS public.create_club_event(TEXT, TEXT, TEXT, INT, JSONB);

-- ─────────────────────────────────────────
-- 3. create_club_event — extended signature (sole definition)
-- ─────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.create_club_event(
    p_name                   TEXT,
    p_organizer_device_id    TEXT,
    p_course_name            TEXT    DEFAULT NULL,
    p_num_days               INT     DEFAULT 1,
    p_players                JSONB   DEFAULT '[]',
    p_start_date             DATE    DEFAULT NULL,
    p_handicap_allowance     FLOAT   DEFAULT NULL,
    p_gross_leaderboard      BOOLEAN DEFAULT NULL,
    p_gross_skins_enabled    BOOLEAN DEFAULT NULL,
    p_net_skins_enabled      BOOLEAN DEFAULT NULL,
    p_skins_carryover        BOOLEAN DEFAULT NULL,
    p_entry_fee              NUMERIC DEFAULT NULL,
    p_team_places_paid       INT     DEFAULT NULL
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
    v_hc       NUMERIC;
BEGIN
    -- Validate inputs
    IF trim(p_name) = '' THEN
        RAISE EXCEPTION 'Event name cannot be empty';
    END IF;

    IF p_handicap_allowance IS NOT NULL
       AND (p_handicap_allowance < 0 OR p_handicap_allowance > 1) THEN
        RAISE EXCEPTION 'Handicap allowance must be between 0 and 1 (got %)',
                        p_handicap_allowance;
    END IF;

    FOR v_item IN SELECT * FROM jsonb_array_elements(p_players) LOOP
        v_hc := (v_item->>'handicap')::NUMERIC;
        IF v_hc < -10 OR v_hc > 54 THEN
            RAISE EXCEPTION 'Player handicap must be between -10 and 54 (got %)', v_hc;
        END IF;
    END LOOP;

    -- Generate unique 6-char event code
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

    INSERT INTO tournament_events
        (code, name, organizer_device_id, course_name, num_days, status, start_date)
    VALUES
        (v_code, p_name, p_organizer_device_id, p_course_name, p_num_days, 'active', p_start_date)
    RETURNING id INTO v_event_id;

    INSERT INTO tournament_rules (
        tournament_id,
        handicap_allowance,
        gross_leaderboard,
        gross_skins_enabled,
        net_skins_enabled,
        skins_carryover,
        entry_fee_per_player,
        team_places_paid
    )
    VALUES (
        v_event_id,
        COALESCE(p_handicap_allowance,  1.0),
        COALESCE(p_gross_leaderboard,   FALSE),
        COALESCE(p_gross_skins_enabled, TRUE),
        COALESCE(p_net_skins_enabled,   TRUE),
        COALESCE(p_skins_carryover,     FALSE),
        p_entry_fee,
        COALESCE(p_team_places_paid,    3)
    );

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

REVOKE ALL    ON FUNCTION public.create_club_event(TEXT, TEXT, TEXT, INT, JSONB, DATE, FLOAT, BOOLEAN, BOOLEAN, BOOLEAN, BOOLEAN, NUMERIC, INT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_club_event(TEXT, TEXT, TEXT, INT, JSONB, DATE, FLOAT, BOOLEAN, BOOLEAN, BOOLEAN, BOOLEAN, NUMERIC, INT) TO anon, authenticated;
