-- Club Event course snapshot — extend create_club_event RPC
--
-- Adds p_course_pars INT[] and p_course_handicaps INT[] (both optional) so
-- the Swift client can store a course snapshot at event creation time.
-- The columns were added to tournament_events in 20261201000000_course_snapshot.sql.

-- Drop the 13-param signature from phase6a
DROP FUNCTION IF EXISTS public.create_club_event(
    TEXT, TEXT, TEXT, INT, JSONB, DATE, FLOAT, BOOLEAN, BOOLEAN, BOOLEAN, BOOLEAN, NUMERIC, INT
);

-- New 15-param version
CREATE OR REPLACE FUNCTION public.create_club_event(
    p_name                   TEXT,
    p_organizer_device_id    TEXT,
    p_course_name            TEXT      DEFAULT NULL,
    p_num_days               INT       DEFAULT 1,
    p_players                JSONB     DEFAULT '[]',
    p_start_date             DATE      DEFAULT NULL,
    p_handicap_allowance     FLOAT     DEFAULT NULL,
    p_gross_leaderboard      BOOLEAN   DEFAULT NULL,
    p_gross_skins_enabled    BOOLEAN   DEFAULT NULL,
    p_net_skins_enabled      BOOLEAN   DEFAULT NULL,
    p_skins_carryover        BOOLEAN   DEFAULT NULL,
    p_entry_fee              NUMERIC   DEFAULT NULL,
    p_team_places_paid       INT       DEFAULT NULL,
    p_course_pars            INT[]     DEFAULT NULL,
    p_course_handicaps       INT[]     DEFAULT NULL
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
        (code, name, organizer_device_id, course_name, num_days, status, start_date,
         course_pars, course_handicaps)
    VALUES
        (v_code, p_name, p_organizer_device_id, p_course_name, p_num_days, 'active', p_start_date,
         p_course_pars, p_course_handicaps)
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

REVOKE ALL    ON FUNCTION public.create_club_event(TEXT, TEXT, TEXT, INT, JSONB, DATE, FLOAT, BOOLEAN, BOOLEAN, BOOLEAN, BOOLEAN, NUMERIC, INT, INT[], INT[]) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_club_event(TEXT, TEXT, TEXT, INT, JSONB, DATE, FLOAT, BOOLEAN, BOOLEAN, BOOLEAN, BOOLEAN, NUMERIC, INT, INT[], INT[]) TO anon, authenticated;
