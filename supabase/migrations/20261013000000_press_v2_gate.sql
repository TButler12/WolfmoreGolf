-- press_v2 gate: block old clients from joining press_v2 matches
-- 2026-10-13

-- 1. New column that joiners write to signal press_v2 capability
ALTER TABLE public.matches ADD COLUMN IF NOT EXISTS joiner_capability TEXT;

-- 2. Function: raise if a joiner hasn't signalled press_v2 capability
CREATE OR REPLACE FUNCTION public.enforce_press_v2_capability()
RETURNS TRIGGER AS $$
BEGIN
  -- Fires only when someone is joining (opponent_names changed)
  IF OLD.opponent_names IS DISTINCT FROM NEW.opponent_names THEN
    -- Only relevant if the match requires press_v2
    IF 'press_v2' = ANY(NEW.games) THEN
      IF COALESCE(NEW.joiner_capability, '') <> 'press_v2' THEN
        RAISE EXCEPTION 'Update WolfMore to join this match.';
      END IF;
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Attach trigger (DROP IF EXISTS first)
DROP TRIGGER IF EXISTS trg_enforce_press_v2_join ON public.matches;
CREATE TRIGGER trg_enforce_press_v2_join
  BEFORE UPDATE ON public.matches
  FOR EACH ROW
  EXECUTE FUNCTION public.enforce_press_v2_capability();
