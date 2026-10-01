-- ══════════════════════════════════════════════════════════
-- Live Event Summary — match play
-- Deployed 2026-09-30
-- ══════════════════════════════════════════════════════════

-- 1. Fix replica identity so UPDATE events carry the full row to realtime subscribers.
--    Without this, group rename and match-status updates never reach viewers.
ALTER TABLE public.wolf_sessions REPLICA IDENTITY FULL;

-- 2. New columns on wolf_sessions (all nullable — old INSERT paths unaffected)
ALTER TABLE public.wolf_sessions
  ADD COLUMN IF NOT EXISTS match_status text,    -- "2 UP", "All Square", "Dormie", "won 3&2", "Halved"
  ADD COLUMN IF NOT EXISTS holes_played integer, -- holes scored so far
  ADD COLUMN IF NOT EXISTS event_code   text;    -- code of the live_event this session is linked to

-- 3. live_events: public read, write only through SECURITY DEFINER create function
CREATE TABLE IF NOT EXISTS public.live_events (
  id         uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  code       text        UNIQUE NOT NULL,
  name       text        NOT NULL,
  status     text        NOT NULL DEFAULT 'active',
  created_at timestamptz DEFAULT now()
);
ALTER TABLE public.live_events ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  CREATE POLICY "public read live_events" ON public.live_events FOR SELECT USING (true);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- 4. live_event_secrets: zero policies — completely opaque to anon
CREATE TABLE IF NOT EXISTS public.live_event_secrets (
  event_id        uuid PRIMARY KEY REFERENCES public.live_events(id) ON DELETE CASCADE,
  organizer_token uuid NOT NULL DEFAULT gen_random_uuid()
);
ALTER TABLE public.live_event_secrets ENABLE ROW LEVEL SECURITY;

-- 5. Realtime
DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.live_events;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- 6. create_live_event: atomically inserts event + secret, returns id/code/token
--    Output names use r_ prefix to avoid shadowing column names inside the function body.
CREATE OR REPLACE FUNCTION public.create_live_event(
  p_name text,
  p_code text
)
RETURNS TABLE (r_event_id uuid, r_event_code text, r_organizer_token uuid)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_event_id  uuid;
  v_org_token uuid;
BEGIN
  INSERT INTO public.live_events (code, name)
  VALUES (upper(p_code), p_name)
  RETURNING id INTO v_event_id;

  INSERT INTO public.live_event_secrets (event_id)
  VALUES (v_event_id)
  RETURNING organizer_token INTO v_org_token;

  RETURN QUERY SELECT v_event_id, upper(p_code), v_org_token;
END;
$$;

REVOKE ALL ON FUNCTION public.create_live_event(text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_live_event(text, text) TO anon;
GRANT EXECUTE ON FUNCTION public.create_live_event(text, text) TO authenticated;

-- 7. link_session_to_event: verifies creator token + event exists, sets event_code
CREATE OR REPLACE FUNCTION public.link_session_to_event(
  p_session_id    text,
  p_creator_token text,
  p_event_code    text
)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.wolf_session_secrets
    WHERE session_id = p_session_id::uuid AND creator_token = p_creator_token::uuid
  ) THEN
    RAISE EXCEPTION 'Invalid session or creator token.';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.live_events
    WHERE code = upper(p_event_code) AND status = 'active'
  ) THEN
    RAISE EXCEPTION 'Event not found or not active.';
  END IF;

  UPDATE public.wolf_sessions SET event_code = upper(p_event_code)
  WHERE id = p_session_id::uuid;
END;
$$;

REVOKE ALL ON FUNCTION public.link_session_to_event(text, text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.link_session_to_event(text, text, text) TO anon;
GRANT EXECUTE ON FUNCTION public.link_session_to_event(text, text, text) TO authenticated;

-- 8. unlink_session_from_event: verifies creator token, clears event_code
CREATE OR REPLACE FUNCTION public.unlink_session_from_event(
  p_session_id    text,
  p_creator_token text
)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.wolf_session_secrets
    WHERE session_id = p_session_id::uuid AND creator_token = p_creator_token::uuid
  ) THEN
    RAISE EXCEPTION 'Invalid session or creator token.';
  END IF;

  UPDATE public.wolf_sessions SET event_code = NULL
  WHERE id = p_session_id::uuid;
END;
$$;

REVOKE ALL ON FUNCTION public.unlink_session_from_event(text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.unlink_session_from_event(text, text) TO anon;
GRANT EXECUTE ON FUNCTION public.unlink_session_from_event(text, text) TO authenticated;

-- 9. publish_match_status: verifies creator token via JOIN, updates match_status + holes_played
CREATE OR REPLACE FUNCTION public.publish_match_status(
  p_session_id    text,
  p_creator_token text,
  p_match_status  text,
  p_holes_played  integer
)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  UPDATE public.wolf_sessions ws
  SET    match_status = p_match_status,
         holes_played = p_holes_played
  FROM   public.wolf_session_secrets s
  WHERE  ws.id            = p_session_id::uuid
    AND  s.session_id     = ws.id
    AND  s.creator_token  = p_creator_token::uuid;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Invalid session or creator token.';
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.publish_match_status(text, text, text, integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.publish_match_status(text, text, text, integer) TO anon;
GRANT EXECUTE ON FUNCTION public.publish_match_status(text, text, text, integer) TO authenticated;
