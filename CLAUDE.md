# WolfmoreGolf — Claude Rules

## Supabase / Database

Never run SQL or schema changes against the linked production Supabase project without first showing me the exact SQL and getting my explicit OK. Read-only queries (SELECT) are fine.

## No Unrequested UI Changes

Do not change fonts, sizes, colors, spacing, layout, or any visual element unless I explicitly ask for it. If you notice something that looks off, mention it but do not touch it.

## Course Data Rules

Every 18-hole layout must have exactly 18 pars and 18 handicaps. Handicaps must be exactly the integers 1–18 with no duplicates. Never store per-nine 1–9 handicaps in an 18-hole array. If a club scorecard uses 1–9 on each nine, convert to a valid 1–18 set before saving (front nine rank → 2×rank−1, back nine rank → 2×rank). Show me the before and after arrays before making any changes.
