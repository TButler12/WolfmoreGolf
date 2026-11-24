-- Release a player from their group (clear group_code + player_device_id).
--
-- Authorization:
--   • Organizer (x-device-id = organizer's) can release any player before 'finished'.
--   • Scorer (p_group_code = player's current group_code) can release if that player
--     has no scores yet. If scores exist the scorer must ask the organizer.
--   Both are checked here because setup_club_event_group is SECURITY DEFINER and
--   PostgREST doesn't expose per-request headers on arbitrary table UPDATEs.
--
-- p_group_code is provided by the scorer; organizer callers pass NULL.

CREATE OR REPLACE FUNCTION public.release_club_event_player(
    p_player_id   UUID,
    p_group_code  TEXT  DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_device_id    TEXT;
    v_player       tournament_players%ROWTYPE;
    v_organizer_id TEXT;
    v_status       TEXT;
    v_is_organizer BOOLEAN;
    v_is_scorer    BOOLEAN;
BEGIN
    v_device_id := nullif(
        current_setting('request.headers', true)::jsonb->>'x-device-id', ''
    );

    SELECT tp.* INTO v_player
    FROM   tournament_players tp
    WHERE  tp.id = p_player_id;
    IF NOT FOUND THEN RAISE EXCEPTION 'Player not found'; END IF;

    SELECT e.organizer_device_id, e.status
    INTO   v_organizer_id, v_status
    FROM   tournament_events e
    WHERE  e.id = v_player.tournament_id;

    IF v_status = 'finished' THEN
        RAISE EXCEPTION 'Event is finished — scores are locked';
    END IF;

    v_is_organizer := (v_organizer_id IS NOT NULL AND v_organizer_id = v_device_id);
    v_is_scorer    := (
        p_group_code IS NOT NULL
        AND v_player.group_code IS NOT NULL
        AND v_player.group_code = p_group_code
    );

    IF NOT v_is_organizer AND NOT v_is_scorer THEN
        RAISE EXCEPTION 'Not authorized to release this player';
    END IF;

    -- Scorer can only release if no scores have been entered for this player yet.
    IF v_is_scorer AND NOT v_is_organizer THEN
        IF EXISTS (
            SELECT 1 FROM tournament_hole_scores
            WHERE tournament_player_id = p_player_id
            LIMIT 1
        ) THEN
            RAISE EXCEPTION
                'Scores have already been entered for this player. '
                'Ask the organizer to release them.';
        END IF;
    END IF;

    UPDATE tournament_players
    SET group_code       = NULL,
        player_device_id = NULL
    WHERE id = p_player_id;

    RETURN jsonb_build_object('released', p_player_id);
END;
$$;

REVOKE ALL    ON FUNCTION public.release_club_event_player(UUID, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.release_club_event_player(UUID, TEXT) TO anon, authenticated;
