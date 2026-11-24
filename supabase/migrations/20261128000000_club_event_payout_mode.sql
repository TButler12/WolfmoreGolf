-- =============================================================
-- Club Event Payout Mode
-- Adds per-event payout method selector (per_player or fixed_total)
-- and four fixed-total columns so the organizer can enter pot
-- totals directly instead of calculating them from player counts.
-- =============================================================


-- ── 1. Payout mode selector ──────────────────────────────────

ALTER TABLE tournament_rules
  ADD COLUMN IF NOT EXISTS payout_mode TEXT NOT NULL DEFAULT 'per_player'
      CONSTRAINT chk_payout_mode
          CHECK (payout_mode IN ('per_player', 'fixed_total'));


-- ── 2. Fixed-total pot columns ───────────────────────────────

ALTER TABLE tournament_rules
  ADD COLUMN IF NOT EXISTS team_net_total    NUMERIC(10,2) NOT NULL DEFAULT 0
      CONSTRAINT chk_team_net_total_nonneg    CHECK (team_net_total    >= 0),
  ADD COLUMN IF NOT EXISTS team_gross_total  NUMERIC(10,2) NOT NULL DEFAULT 0
      CONSTRAINT chk_team_gross_total_nonneg  CHECK (team_gross_total  >= 0),
  ADD COLUMN IF NOT EXISTS gross_skins_total NUMERIC(10,2) NOT NULL DEFAULT 0
      CONSTRAINT chk_gross_skins_total_nonneg CHECK (gross_skins_total >= 0),
  ADD COLUMN IF NOT EXISTS net_skins_total   NUMERIC(10,2) NOT NULL DEFAULT 0
      CONSTRAINT chk_net_skins_total_nonneg   CHECK (net_skins_total   >= 0);


-- ── 3. Replace update_club_event_settings ────────────────────

DROP FUNCTION IF EXISTS update_club_event_settings(
    UUID, TEXT, TEXT, TEXT, NUMERIC, BOOL, BOOL, BOOL, BOOL,
    NUMERIC, NUMERIC, NUMERIC, NUMERIC, INT, NUMERIC[], BOOL
);

CREATE OR REPLACE FUNCTION update_club_event_settings(
    p_tournament_id           UUID,
    p_name                    TEXT      DEFAULT NULL,
    p_course_name             TEXT      DEFAULT NULL,
    p_tee_set                 TEXT      DEFAULT NULL,
    p_handicap_allowance      NUMERIC   DEFAULT NULL,
    p_gross_leaderboard       BOOL      DEFAULT NULL,
    p_gross_skins_enabled     BOOL      DEFAULT NULL,
    p_net_skins_enabled       BOOL      DEFAULT NULL,
    p_skins_carryover         BOOL      DEFAULT NULL,
    p_team_net_per_player     NUMERIC   DEFAULT NULL,
    p_team_gross_per_player   NUMERIC   DEFAULT NULL,
    p_gross_skins_per_player  NUMERIC   DEFAULT NULL,
    p_net_skins_per_player    NUMERIC   DEFAULT NULL,
    p_team_places_paid        INT       DEFAULT NULL,
    p_place_pcts              NUMERIC[] DEFAULT NULL,
    p_allow_dual_team         BOOL      DEFAULT NULL,
    p_payout_mode             TEXT      DEFAULT NULL,
    p_team_net_total          NUMERIC   DEFAULT NULL,
    p_team_gross_total        NUMERIC   DEFAULT NULL,
    p_gross_skins_total       NUMERIC   DEFAULT NULL,
    p_net_skins_total         NUMERIC   DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_device_id    TEXT := COALESCE(
                               (current_setting('request.headers', true)::JSONB)->>'x-device-id',
                               '');
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
    v_effective_places INT;
    v_pcts_sum     NUMERIC;
BEGIN
    -- ── auth ──────────────────────────────────────────────────
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

    -- ── input guards ──────────────────────────────────────────

    IF p_payout_mode IS NOT NULL
       AND p_payout_mode NOT IN ('per_player', 'fixed_total') THEN
        RAISE EXCEPTION 'payout_mode must be ''per_player'' or ''fixed_total'' (got %)',
            p_payout_mode;
    END IF;

    IF p_team_places_paid IS NOT NULL
       AND (p_team_places_paid < 1 OR p_team_places_paid > 5) THEN
        RAISE EXCEPTION 'team_places_paid must be between 1 and 5 (got %)',
            p_team_places_paid;
    END IF;

    IF p_place_pcts IS NOT NULL THEN
        v_effective_places :=
            COALESCE(p_team_places_paid, v_rules.team_places_paid, 3);
        IF array_length(p_place_pcts, 1) IS DISTINCT FROM v_effective_places THEN
            RAISE EXCEPTION 'place_pcts has % element(s) but team_places_paid is %',
                array_length(p_place_pcts, 1), v_effective_places;
        END IF;
        SELECT SUM(v) INTO v_pcts_sum FROM unnest(p_place_pcts) v;
        IF ABS(v_pcts_sum - 100.0) > 0.01 THEN
            RAISE EXCEPTION 'place_pcts must sum to 100 (got %)', v_pcts_sum;
        END IF;
        IF EXISTS (SELECT 1 FROM unnest(p_place_pcts) v WHERE v <= 0) THEN
            RAISE EXCEPTION 'All place_pcts values must be greater than 0';
        END IF;
    END IF;

    IF p_team_net_per_player    IS NOT NULL AND p_team_net_per_player    < 0 THEN
        RAISE EXCEPTION 'team_net_per_player cannot be negative';
    END IF;
    IF p_team_gross_per_player  IS NOT NULL AND p_team_gross_per_player  < 0 THEN
        RAISE EXCEPTION 'team_gross_per_player cannot be negative';
    END IF;
    IF p_gross_skins_per_player IS NOT NULL AND p_gross_skins_per_player < 0 THEN
        RAISE EXCEPTION 'gross_skins_per_player cannot be negative';
    END IF;
    IF p_net_skins_per_player   IS NOT NULL AND p_net_skins_per_player   < 0 THEN
        RAISE EXCEPTION 'net_skins_per_player cannot be negative';
    END IF;
    IF p_team_net_total    IS NOT NULL AND p_team_net_total    < 0 THEN
        RAISE EXCEPTION 'team_net_total cannot be negative';
    END IF;
    IF p_team_gross_total  IS NOT NULL AND p_team_gross_total  < 0 THEN
        RAISE EXCEPTION 'team_gross_total cannot be negative';
    END IF;
    IF p_gross_skins_total IS NOT NULL AND p_gross_skins_total < 0 THEN
        RAISE EXCEPTION 'gross_skins_total cannot be negative';
    END IF;
    IF p_net_skins_total   IS NOT NULL AND p_net_skins_total   < 0 THEN
        RAISE EXCEPTION 'net_skins_total cannot be negative';
    END IF;

    -- ── course / tee guard ────────────────────────────────────
    v_course_or_tee_changing :=
        (p_course_name IS NOT NULL AND p_course_name IS DISTINCT FROM v_old_course)
        OR
        (p_tee_set     IS NOT NULL AND p_tee_set     IS DISTINCT FROM v_old_tee);

    IF v_course_or_tee_changing THEN
        SELECT EXISTS (
            SELECT 1
              FROM tournament_hole_scores hs
              JOIN tournament_players tp ON hs.tournament_player_id = tp.id
             WHERE tp.tournament_id = p_tournament_id
        ) INTO v_has_scores;
        IF v_has_scores THEN
            RAISE EXCEPTION
                'Course/tees cannot be changed after any scores have been entered';
        END IF;
    END IF;

    -- ── dual-team guard ───────────────────────────────────────
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
                'Cannot disable dual-team: % player(s) are on two teams. '
                'Remove dual assignment first.', v_dual_count;
        END IF;
    END IF;

    -- ── apply event-level changes ─────────────────────────────
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

    -- ── upsert rules ──────────────────────────────────────────
    INSERT INTO tournament_rules (
        tournament_id,
        handicap_allowance,    gross_leaderboard,
        gross_skins_enabled,   net_skins_enabled,   skins_carryover,
        team_net_per_player,   team_gross_per_player,
        gross_skins_per_player, net_skins_per_player,
        team_places_paid,      place_pcts,
        allow_dual_team,
        payout_mode,
        team_net_total,        team_gross_total,
        gross_skins_total,     net_skins_total
    ) VALUES (
        p_tournament_id,
        COALESCE(p_handicap_allowance,     v_rules.handicap_allowance,     1.0),
        COALESCE(p_gross_leaderboard,      v_rules.gross_leaderboard,      FALSE),
        COALESCE(p_gross_skins_enabled,    v_rules.gross_skins_enabled,    TRUE),
        COALESCE(p_net_skins_enabled,      v_rules.net_skins_enabled,      TRUE),
        COALESCE(p_skins_carryover,        v_rules.skins_carryover,        FALSE),
        COALESCE(p_team_net_per_player,    v_rules.team_net_per_player,    0),
        COALESCE(p_team_gross_per_player,  v_rules.team_gross_per_player,  0),
        COALESCE(p_gross_skins_per_player, v_rules.gross_skins_per_player, 0),
        COALESCE(p_net_skins_per_player,   v_rules.net_skins_per_player,   0),
        COALESCE(p_team_places_paid,       v_rules.team_places_paid,       3),
        COALESCE(p_place_pcts,             v_rules.place_pcts,
                 ARRAY[50, 30, 20]::NUMERIC[]),
        COALESCE(p_allow_dual_team,        v_rules.allow_dual_team,        FALSE),
        COALESCE(p_payout_mode,            v_rules.payout_mode,            'per_player'),
        COALESCE(p_team_net_total,         v_rules.team_net_total,         0),
        COALESCE(p_team_gross_total,       v_rules.team_gross_total,       0),
        COALESCE(p_gross_skins_total,      v_rules.gross_skins_total,      0),
        COALESCE(p_net_skins_total,        v_rules.net_skins_total,        0)
    )
    ON CONFLICT (tournament_id) DO UPDATE SET
        handicap_allowance     = EXCLUDED.handicap_allowance,
        gross_leaderboard      = EXCLUDED.gross_leaderboard,
        gross_skins_enabled    = EXCLUDED.gross_skins_enabled,
        net_skins_enabled      = EXCLUDED.net_skins_enabled,
        skins_carryover        = EXCLUDED.skins_carryover,
        team_net_per_player    = EXCLUDED.team_net_per_player,
        team_gross_per_player  = EXCLUDED.team_gross_per_player,
        gross_skins_per_player = EXCLUDED.gross_skins_per_player,
        net_skins_per_player   = EXCLUDED.net_skins_per_player,
        team_places_paid       = EXCLUDED.team_places_paid,
        place_pcts             = EXCLUDED.place_pcts,
        allow_dual_team        = EXCLUDED.allow_dual_team,
        payout_mode            = EXCLUDED.payout_mode,
        team_net_total         = EXCLUDED.team_net_total,
        team_gross_total       = EXCLUDED.team_gross_total,
        gross_skins_total      = EXCLUDED.gross_skins_total,
        net_skins_total        = EXCLUDED.net_skins_total;

    -- ── change log (abbreviated — per-player fields shown as before) ──
    IF p_handicap_allowance IS NOT NULL
       AND p_handicap_allowance IS DISTINCT FROM v_rules.handicap_allowance THEN
        v_changes := v_changes || jsonb_build_array(jsonb_build_object(
            'field', 'handicap_allowance',
            'old', v_rules.handicap_allowance, 'new', p_handicap_allowance));
    END IF;
    IF p_gross_leaderboard IS NOT NULL
       AND p_gross_leaderboard IS DISTINCT FROM v_rules.gross_leaderboard THEN
        v_changes := v_changes || jsonb_build_array(jsonb_build_object(
            'field', 'gross_leaderboard',
            'old', v_rules.gross_leaderboard, 'new', p_gross_leaderboard));
    END IF;
    IF p_gross_skins_enabled IS NOT NULL
       AND p_gross_skins_enabled IS DISTINCT FROM v_rules.gross_skins_enabled THEN
        v_changes := v_changes || jsonb_build_array(jsonb_build_object(
            'field', 'gross_skins',
            'old', v_rules.gross_skins_enabled, 'new', p_gross_skins_enabled));
    END IF;
    IF p_net_skins_enabled IS NOT NULL
       AND p_net_skins_enabled IS DISTINCT FROM v_rules.net_skins_enabled THEN
        v_changes := v_changes || jsonb_build_array(jsonb_build_object(
            'field', 'net_skins',
            'old', v_rules.net_skins_enabled, 'new', p_net_skins_enabled));
    END IF;
    IF p_skins_carryover IS NOT NULL
       AND p_skins_carryover IS DISTINCT FROM v_rules.skins_carryover THEN
        v_changes := v_changes || jsonb_build_array(jsonb_build_object(
            'field', 'skins_carryover',
            'old', v_rules.skins_carryover, 'new', p_skins_carryover));
    END IF;
    IF p_payout_mode IS NOT NULL
       AND p_payout_mode IS DISTINCT FROM v_rules.payout_mode THEN
        v_changes := v_changes || jsonb_build_array(jsonb_build_object(
            'field', 'payout_mode',
            'old', v_rules.payout_mode, 'new', p_payout_mode));
    END IF;
    IF p_team_net_per_player IS NOT NULL
       AND p_team_net_per_player IS DISTINCT FROM v_rules.team_net_per_player THEN
        v_changes := v_changes || jsonb_build_array(jsonb_build_object(
            'field', 'team_net_per_player',
            'old', v_rules.team_net_per_player, 'new', p_team_net_per_player));
    END IF;
    IF p_team_gross_per_player IS NOT NULL
       AND p_team_gross_per_player IS DISTINCT FROM v_rules.team_gross_per_player THEN
        v_changes := v_changes || jsonb_build_array(jsonb_build_object(
            'field', 'team_gross_per_player',
            'old', v_rules.team_gross_per_player, 'new', p_team_gross_per_player));
    END IF;
    IF p_gross_skins_per_player IS NOT NULL
       AND p_gross_skins_per_player IS DISTINCT FROM v_rules.gross_skins_per_player THEN
        v_changes := v_changes || jsonb_build_array(jsonb_build_object(
            'field', 'gross_skins_per_player',
            'old', v_rules.gross_skins_per_player, 'new', p_gross_skins_per_player));
    END IF;
    IF p_net_skins_per_player IS NOT NULL
       AND p_net_skins_per_player IS DISTINCT FROM v_rules.net_skins_per_player THEN
        v_changes := v_changes || jsonb_build_array(jsonb_build_object(
            'field', 'net_skins_per_player',
            'old', v_rules.net_skins_per_player, 'new', p_net_skins_per_player));
    END IF;
    IF p_team_net_total IS NOT NULL
       AND p_team_net_total IS DISTINCT FROM v_rules.team_net_total THEN
        v_changes := v_changes || jsonb_build_array(jsonb_build_object(
            'field', 'team_net_total',
            'old', v_rules.team_net_total, 'new', p_team_net_total));
    END IF;
    IF p_team_gross_total IS NOT NULL
       AND p_team_gross_total IS DISTINCT FROM v_rules.team_gross_total THEN
        v_changes := v_changes || jsonb_build_array(jsonb_build_object(
            'field', 'team_gross_total',
            'old', v_rules.team_gross_total, 'new', p_team_gross_total));
    END IF;
    IF p_gross_skins_total IS NOT NULL
       AND p_gross_skins_total IS DISTINCT FROM v_rules.gross_skins_total THEN
        v_changes := v_changes || jsonb_build_array(jsonb_build_object(
            'field', 'gross_skins_total',
            'old', v_rules.gross_skins_total, 'new', p_gross_skins_total));
    END IF;
    IF p_net_skins_total IS NOT NULL
       AND p_net_skins_total IS DISTINCT FROM v_rules.net_skins_total THEN
        v_changes := v_changes || jsonb_build_array(jsonb_build_object(
            'field', 'net_skins_total',
            'old', v_rules.net_skins_total, 'new', p_net_skins_total));
    END IF;
    IF p_team_places_paid IS NOT NULL
       AND p_team_places_paid IS DISTINCT FROM v_rules.team_places_paid THEN
        v_changes := v_changes || jsonb_build_array(jsonb_build_object(
            'field', 'places_paid',
            'old', v_rules.team_places_paid, 'new', p_team_places_paid));
    END IF;
    IF p_place_pcts IS NOT NULL
       AND p_place_pcts IS DISTINCT FROM v_rules.place_pcts THEN
        v_changes := v_changes || jsonb_build_array(jsonb_build_object(
            'field', 'place_pcts',
            'old', v_rules.place_pcts::TEXT, 'new', p_place_pcts::TEXT));
    END IF;
    IF p_allow_dual_team IS NOT NULL
       AND p_allow_dual_team IS DISTINCT FROM v_rules.allow_dual_team THEN
        v_changes := v_changes || jsonb_build_array(jsonb_build_object(
            'field', 'allow_dual_team',
            'old', v_rules.allow_dual_team, 'new', p_allow_dual_team));
    END IF;

    IF jsonb_array_length(v_changes) > 0 THEN
        INSERT INTO club_event_change_log
            (tournament_id, changed_by, change_type, details)
        VALUES (p_tournament_id, v_device_id, 'update_settings',
                jsonb_build_object('changes', v_changes));
    END IF;

    RETURN jsonb_build_object('updated', jsonb_array_length(v_changes));
END;
$$;

REVOKE ALL ON FUNCTION update_club_event_settings(
    UUID, TEXT, TEXT, TEXT, NUMERIC, BOOL, BOOL, BOOL, BOOL,
    NUMERIC, NUMERIC, NUMERIC, NUMERIC, INT, NUMERIC[], BOOL,
    TEXT, NUMERIC, NUMERIC, NUMERIC, NUMERIC
) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION update_club_event_settings(
    UUID, TEXT, TEXT, TEXT, NUMERIC, BOOL, BOOL, BOOL, BOOL,
    NUMERIC, NUMERIC, NUMERIC, NUMERIC, INT, NUMERIC[], BOOL,
    TEXT, NUMERIC, NUMERIC, NUMERIC, NUMERIC
) TO anon, authenticated;
