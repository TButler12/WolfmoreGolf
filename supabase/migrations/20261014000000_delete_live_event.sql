-- ══════════════════════════════════════════════════════════
-- delete_live_event RPC
-- Deployed 2026-10-14
-- ══════════════════════════════════════════════════════════
-- Lets the board creator hard-delete their live_event.
-- Verifies the organizer_token before deleting.
-- Unlinks any wolf_sessions still pointing to the event so
-- scorers don't end up with a dangling event_code.
-- ══════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.delete_live_event(
  p_code            text,
  p_organizer_token text
)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_event_id uuid;
BEGIN
  SELECT le.id INTO v_event_id
  FROM   public.live_events le
  JOIN   public.live_event_secrets les ON les.event_id = le.id
  WHERE  le.code               = upper(p_code)
    AND  les.organizer_token   = p_organizer_token::uuid;

  IF v_event_id IS NULL THEN
    RAISE EXCEPTION 'Invalid board code or organizer token.';
  END IF;

  -- Unlink any sessions still referencing this event
  UPDATE public.wolf_sessions
  SET    event_code = NULL
  WHERE  event_code = upper(p_code);

  -- Hard-delete (ON DELETE CASCADE removes live_event_secrets)
  DELETE FROM public.live_events WHERE id = v_event_id;
END;
$$;

REVOKE ALL ON FUNCTION public.delete_live_event(text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.delete_live_event(text, text) TO anon;
GRANT EXECUTE ON FUNCTION public.delete_live_event(text, text) TO authenticated;
