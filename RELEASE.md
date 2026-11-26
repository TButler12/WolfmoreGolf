# Release Checklist — custom-courses branch

## Step 1 — Code
- [ ] Merge `custom-courses` into `main`
- [ ] Archive the release build in Xcode (WolfmoreGolf scheme, Any iOS Device)
- [ ] All tests green before submit

## Step 2 — App Store
- [ ] Upload build via Xcode Organizer
- [ ] Submit for review

## Step 3 — Database (prod: WolfMoreGolf / gxkzhdnqihbdwbfqpepn)

> **WARNING — read before touching prod**
>
> * **Never use `--include-all`** on prod. It would attempt to run every local
>   migration file against prod, including the base schema migration, which
>   would try to recreate tables that already exist and have live data.
> * Before running `db push`, always run `--dry-run` first (see below).
>   If the dry-run lists anything other than the four migrations in Step 3c,
>   **stop** and investigate before proceeding.
> * Run the repair commands in Step 3b *before* `db push`. They must be
>   recorded in `schema_migrations` first so `db push` skips them.

### Why repairs are needed

Prod's migration history starts at `20260713163000` — the base schema was
hand-built before migration tracking was set up. Several later migrations
(`20261205000000`, `20261206000000`) also backfilled objects that were already
created on prod by hand. All three need to be marked applied so `db push`
doesn't try to run them.

### 3a — Link to prod

```bash
supabase link --project-ref gxkzhdnqihbdwbfqpepn --yes
```

Verify the linked project before every command:

```bash
supabase projects list
# wolfmore-staging should show linked:false
# WolfMoreGolf      should show linked:true
```

### 3b — Mark hand-applied migrations as already done

```bash
supabase migration repair --status applied 20200101000000 --linked
supabase migration repair --status applied 20261205000000 --linked
supabase migration repair --status applied 20261206000000 --linked
supabase migration repair --status applied 20261207000000 --linked
supabase migration repair --status applied 20261208000000 --linked
supabase migration repair --status applied 20261209000000 --linked
```

What each one covers:
- `20200101000000` base_schema — prod schema was created by hand before the
  migration system existed; also creates `ai_summary_conversion` and
  `ai_summary_daily` as VIEWS (the migration file creates them as tables
  to match the base schema; the view conversion is handled by 20261208000000).
- `20261205000000` backfill_prod_objects — functions, trigger, RLS policies
  that were already added to prod by hand during the Nov 2026 staging setup.
- `20261206000000` realtime_publication — replica identity and publication
  membership for `wolf_sessions`, `wolf_hole_results`,
  `remote_nassau_hole_scores`, already correct on prod.
- `20261207000000` wolf_hole_results_unique — adds `UNIQUE(session_id, hole)`
  to `wolf_hole_results`; prod has the equivalent as a bare unique index.
- `20261209000000` wolf_hole_results_rename_index — renames staging's
  constraint to the bare unique index `wolf_hole_results_session_hole_key`,
  matching prod's name and kind exactly.
- `20261208000000` base_schema_constraints — 14 UNIQUE/FK/PK constraints and
  1 performance index that prod had from hand-setup but the base_schema
  migration never captured; also converts `ai_summary_conversion` and
  `ai_summary_daily` from stub tables to the views prod has. All already
  present on prod.

### 3c — Dry-run: confirm exactly four migrations will push

```bash
supabase db push --dry-run --linked
```

Expected output — exactly these four, in this order:

```
 • 20261201000000_course_snapshot.sql
 • 20261202000000_create_club_event_snapshot_rpc.sql
 • 20261203000000_setup_group_version_gate.sql
 • 20261204000000_course_source.sql
```

**If anything else appears in the dry-run output, stop.** Do not push.
Investigate why the unexpected migration is listed before continuing.

### 3d — Push the four new-feature migrations

```bash
supabase db push --linked
```

What each migration does to prod's schema:

| Migration | Change |
|---|---|
| `20261201000000` | `ALTER TABLE tournament_events ADD COLUMN course_pars int[], course_handicaps int[]` |
| `20261202000000` | Drop 13-param `create_club_event`; replace with 15-param version (adds `p_course_pars`, `p_course_handicaps`) |
| `20261203000000` | Rewrite `setup_club_event_group` and `submit_club_event_card` with build-80 app-version gate on `course_pars IS NOT NULL` |
| `20261204000000` | `ADD COLUMN course_source TEXT NOT NULL DEFAULT 'builtin'`; replace with 16-param `create_club_event`; update version gate RPCs to check `course_source = 'imported'`; replace `group scorer insert/update score` RLS policies on `tournament_hole_scores` |

### 3e — Re-link to staging when done

```bash
supabase link --project-ref gzepjvibkcnmejizjmql --yes
```

## Step 4 — Smoke test on prod
- [ ] Create a Club Event with a built-in course — confirm old App Store builds can still join
- [ ] Create a Club Event with an imported course — confirm old builds are blocked with "Please update WolfMore Golf"
- [ ] Go Live / Watch: confirm Live tab updates in real time (wolf_sessions + wolf_hole_results in realtime publication)
- [ ] Event Board: confirm match_status appears correctly
