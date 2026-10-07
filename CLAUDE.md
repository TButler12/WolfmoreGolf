# WolfmoreGolf — Claude Rules

## Supabase / Database

Never run SQL or schema changes against the linked production Supabase project without first showing me the exact SQL and getting my explicit OK. Read-only queries (SELECT) are fine.

## No Unrequested UI Changes

Do not change fonts, sizes, colors, spacing, layout, or any visual element unless I explicitly ask for it. If you notice something that looks off, mention it but do not touch it. This includes moving buttons or changing what a row contains. If a bug fix seems to need a visual change, describe it and ask first.

## Course Data Rules

Every 18-hole layout must have exactly 18 pars and 18 handicaps. Handicaps must be exactly the integers 1–18 with no duplicates. Never store per-nine 1–9 handicaps in an 18-hole array. If a club scorecard uses 1–9 on each nine, convert to a valid 1–18 set before saving (front nine rank → 2×rank−1, back nine rank → 2×rank). Show me the before and after arrays before making any changes.

- If the club publishes its own 18-hole handicaps for a combination, use those instead of converting.
- For 27- and 36-hole clubs, create one layout for every 18-hole combination the club plays, named "Club Name (Front Nine / Back Nine)".
- Never mix data from different nines. Each nine's pars and handicaps must come from the same nine on the scorecard, and each nine's par total must match the card.
- Women's handicaps often differ from men's. Women's tee sets use the women's row, converted the same way.
- When changing an existing course, keep its UUID so saved rounds and tee sets stay linked.
- Enter clean arrays with no subtotals or hole counts.
- Never invent placeholder values for yardage, rating, or slope. If real values aren't available, ask me.

## Where to Work

Work only in /Users/tombutler/Developer/WolfmoreGolf on the main branch. Never create or edit files in a worktree, a .claude/worktrees folder, or a /tmp copy.

## Building

Always build with the WolfmoreGolf scheme: `xcodebuild -scheme WolfmoreGolf`.

## Remote Nassau — Known Limitations / Next Steps

### Step 3 (planned, not started)
- Fixed rules: front/back/overall 1 unit each; results shown in units ("+2", "Up 2"), not dollars
- No presses in remote matches; press UI and logic hidden/disabled for remote only
- Store full 18-hole pars and HC arrays in the Supabase match record at create/join time — **SQL review required before any schema changes**
- Fallback: if full HC data for either course is missing, don't show pairings or results for a nine until both players finish it; show own scores with a note ("Results appear when both players finish the front 9")
- Joiner accept screen: shows both courses, handicap strokes, and fixed rules; Accept and Decline only, nothing editable

### Known limitations (current)
- **Stake not synced**: each device enters its own stake; if they differ the dollar amounts on each screen will disagree
- **Mid-round pairing shift**: if the opponent's course isn't in the local library and the received `HoleScoreRecord` rows have no `holeHc` data, slots fall back to physical hole order; pairings may appear different to each player until Step 3's stored HC arrays are in place
- **Course-loading TODO**: audit the Nassau start path and the case where `selectedCourseID` is nil — verify the correct course's pars/HCs are always loaded before a remote match is created or joined

## Backlog

### Press options (local Nassau only — remote stays no-presses)
- Auto-press trigger: 1, 2, or 3 down (currently hardcoded to 2)
- Rolling presses: option for a new press to fire when an existing press also goes X down
- Presses per nine: 1, 2, 3, or unlimited (default 1)
- Optional 18-hole overall press
- All of the above are local-only settings; remote Nassau has no presses by design
