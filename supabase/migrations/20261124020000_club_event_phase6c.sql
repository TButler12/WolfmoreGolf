-- Club Event Phase 6C: card submission tracking + submit/reopen RPCs
--
-- Adds tournament_players.card_submitted and card_submitted_at columns so
-- the organizer home can show which groups have submitted their scorecard.
--
-- submit_club_event_card: marks all players in a group as submitted.
--   Auth: scorer (x-group-code matches) OR organizer (x-device-id matches).
--   Refused if event status = 'finished'.
--
-- reopen_club_event_card: organizer-only; clears submission so a group can
--   re-score before the organizer locks results.
--   Refused if event status = 'finished'.

-- ─────────────────────────────────────────
-- 1. tournament_players.card_submitted
-- ─────────────────────────────────────────

ALTER TABLE tournament_players
  ADD COLUMN IF NOT EXISTS card_submitted    BOOLEAN    NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS card_submitted_at TIMESTAMPTZ;

-- ─────────────────────────────────────────
-- 2. submit_club_event_card RPC
-- ─────────────────────────────────────────

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
    v_device_id  TEXT;
    v_group_code TEXT;
BEGIN
    v_device_id  := nullif(current_setting('request.headers', true)::jsonb->>'x-device-id',  '');
    v_group_code := nullif(current_setting('request.headers', true)::jsonb->>'x-group-code', '');

    IF EXISTS (
        SELECT 1 FROM tournament_events
        WHERE id = p_tournament_id AND status = 'finished'
    ) THEN
        RAISE EXCEPTION 'Event is locked — card cannot be submitted';
    END IF;

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

-- ─────────────────────────────────────────
-- 3. reopen_club_event_card RPC (organizer only)
-- ─────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.reopen_club_event_card(
    p_tournament_id UUID,
    p_group_code    TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_device_id TEXT;
BEGIN
    v_device_id := nullif(current_setting('request.headers', true)::jsonb->>'x-device-id', '');

    IF EXISTS (
        SELECT 1 FROM tournament_events
        WHERE id = p_tournament_id AND status = 'finished'
    ) THEN
        RAISE EXCEPTION 'Event is locked — card cannot be reopened';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM tournament_events
        WHERE id                 = p_tournament_id
          AND organizer_device_id = v_device_id
    ) THEN
        RAISE EXCEPTION 'Not authorized';
    END IF;

    UPDATE tournament_players
    SET card_submitted    = FALSE,
        card_submitted_at = NULL
    WHERE tournament_id = p_tournament_id
      AND group_code    = p_group_code;
END;
$$;

REVOKE ALL    ON FUNCTION public.reopen_club_event_card(UUID, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.reopen_club_event_card(UUID, TEXT) TO anon, authenticated;
