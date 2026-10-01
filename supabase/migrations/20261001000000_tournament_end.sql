-- Adds finished_at to tournaments and an end_tournament RPC.
-- Organizer (created_by or co_organizer_devices) can call end_tournament to
-- mark a tournament finished; the app auto-hides the card once finished_at is set.
-- Reversible: UPDATE tournaments SET finished_at = NULL WHERE code = 'XXXX';

ALTER TABLE tournaments ADD COLUMN IF NOT EXISTS finished_at TIMESTAMPTZ;

CREATE OR REPLACE FUNCTION end_tournament(p_code TEXT, p_device_id TEXT)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE tournaments
  SET finished_at = NOW()
  WHERE code        = p_code
    AND finished_at IS NULL
    AND (
      created_by = p_device_id
      OR co_organizer_devices @> jsonb_build_array(p_device_id)
    );

  IF NOT FOUND THEN
    RAISE EXCEPTION 'not_authorized'
      USING HINT = 'Device is not an organizer or tournament already ended';
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION end_tournament(TEXT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION end_tournament(TEXT, TEXT) TO anon, authenticated;
