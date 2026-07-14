-- Tournament Mode Phase 1: data model only
-- Auth model: Option A — device ID via x-device-id request header
-- Renamed from `tournaments` to `tournament_events` to avoid conflict with the
-- existing Tee Games `tournaments` table used by TeeGamesViewController.

-- ─────────────────────────────────────────
-- Tables
-- ─────────────────────────────────────────

create table tournament_events (
  id                  uuid primary key default gen_random_uuid(),
  code                text unique not null,
  name                text not null,
  organizer_device_id text not null,
  course_name         text,
  num_days            int not null default 2,
  status              text not null default 'setup',
  created_at          timestamptz default now()
);

create table tournament_rules (
  tournament_id               uuid primary key references tournament_events(id) on delete cascade,
  team_size                   int not null default 4,
  best_n_of_team              int not null default 3,
  team_pot_amount             numeric,
  individual_pot_amount       numeric,
  bow_enabled                 boolean not null default true,
  bow_percent                 numeric not null default 0.03,
  team_payout_schedule        jsonb not null default '{"<=20": [40,24,18,10,5], ">=21": [40,23,17,9,5,3]}',
  individual_payout_schedule  jsonb not null default '[40,25,20,10,5]'
);

create table tournament_players (
  id                uuid primary key default gen_random_uuid(),
  tournament_id     uuid references tournament_events(id) on delete cascade,
  player_device_id  text not null,
  player_name       text not null,
  handicap          numeric not null,
  flight            text check (flight in ('A','B','C','D')),
  created_at        timestamptz default now(),
  unique (tournament_id, player_device_id)
);

create table tournament_flights (
  id             uuid primary key default gen_random_uuid(),
  tournament_id  uuid references tournament_events(id) on delete cascade,
  flight_name    text not null check (flight_name in ('A','B','C','D')),
  handicap_low   numeric,
  handicap_high  numeric,
  computed_at    timestamptz default now()
);

create table tournament_teams (
  id             uuid primary key default gen_random_uuid(),
  tournament_id  uuid references tournament_events(id) on delete cascade,
  team_name      text,
  created_at     timestamptz default now()
);

create table tournament_team_players (
  id                     uuid primary key default gen_random_uuid(),
  team_id                uuid references tournament_teams(id) on delete cascade,
  tournament_player_id   uuid references tournament_players(id),
  flight                 text not null check (flight in ('A','B','C','D')),
  unique (team_id, flight)
);

-- Stores pre-calculated Stableford/net points per player per hole.
-- Unlike hole_scores (which stores raw gross scores), tournament scoring
-- calculates points client-side and submits the result here.
create table tournament_hole_scores (
  id                     uuid primary key default gen_random_uuid(),
  tournament_id          uuid references tournament_events(id) on delete cascade,
  team_id                uuid references tournament_teams(id),
  tournament_player_id   uuid references tournament_players(id),
  day                    int not null,
  hole_number            int not null,
  net_score_type         text,
  points                 int not null,
  created_at             timestamptz default now()
);

create table tournament_playoff_results (
  id                      uuid primary key default gen_random_uuid(),
  tournament_id           uuid references tournament_events(id) on delete cascade,
  category                text not null check (category in ('team','individual','bow')),
  flight                  text,
  tied_participant_ids    uuid[] not null,
  winner_id               uuid not null,
  recorded_by_device_id   text,
  recorded_at             timestamptz default now(),
  notes                   text
);

-- ─────────────────────────────────────────
-- Helper function
-- ─────────────────────────────────────────

create or replace function get_team_roster(p_team_id uuid)
returns json
language sql
stable
as $$
  select json_build_object(
    'team_id', t.id,
    'team_name', t.team_name,
    'players', json_agg(
      json_build_object(
        'player_device_id', tp.player_device_id,
        'player_name', tp.player_name,
        'flight', ttp.flight,
        'handicap', tp.handicap
      )
    )
  )
  from tournament_teams t
  join tournament_team_players ttp on ttp.team_id = t.id
  join tournament_players tp on tp.id = ttp.tournament_player_id
  where t.id = p_team_id
  group by t.id, t.team_name;
$$;

-- ─────────────────────────────────────────
-- Row Level Security
-- ─────────────────────────────────────────

alter table tournament_events         enable row level security;
alter table tournament_rules          enable row level security;
alter table tournament_players        enable row level security;
alter table tournament_flights        enable row level security;
alter table tournament_teams          enable row level security;
alter table tournament_team_players   enable row level security;
alter table tournament_hole_scores    enable row level security;
alter table tournament_playoff_results enable row level security;

-- Convenience: extract device ID from request header (null if not present)
-- Used inline in each policy below.

-- tournament_events
-- Anyone can read a tournament (open; they need the code to find it anyway)
create policy "public read tournament_events"
  on tournament_events for select
  using (true);

-- Only the organizer can create/update/delete
create policy "organizer write tournament_events"
  on tournament_events for all
  using (
    organizer_device_id = nullif(
      current_setting('request.headers', true)::jsonb->>'x-device-id', ''
    )
  )
  with check (
    organizer_device_id = nullif(
      current_setting('request.headers', true)::jsonb->>'x-device-id', ''
    )
  );

-- tournament_rules
create policy "public read tournament_rules"
  on tournament_rules for select
  using (true);

create policy "organizer write tournament_rules"
  on tournament_rules for all
  using (
    exists (
      select 1 from tournament_events e
      where e.id = tournament_id
        and e.organizer_device_id = nullif(
          current_setting('request.headers', true)::jsonb->>'x-device-id', ''
        )
    )
  )
  with check (
    exists (
      select 1 from tournament_events e
      where e.id = tournament_id
        and e.organizer_device_id = nullif(
          current_setting('request.headers', true)::jsonb->>'x-device-id', ''
        )
    )
  );

-- tournament_players
create policy "public read tournament_players"
  on tournament_players for select
  using (true);

create policy "organizer write tournament_players"
  on tournament_players for all
  using (
    exists (
      select 1 from tournament_events e
      where e.id = tournament_id
        and e.organizer_device_id = nullif(
          current_setting('request.headers', true)::jsonb->>'x-device-id', ''
        )
    )
  )
  with check (
    exists (
      select 1 from tournament_events e
      where e.id = tournament_id
        and e.organizer_device_id = nullif(
          current_setting('request.headers', true)::jsonb->>'x-device-id', ''
        )
    )
  );

-- tournament_flights
create policy "public read tournament_flights"
  on tournament_flights for select
  using (true);

create policy "organizer write tournament_flights"
  on tournament_flights for all
  using (
    exists (
      select 1 from tournament_events e
      where e.id = tournament_id
        and e.organizer_device_id = nullif(
          current_setting('request.headers', true)::jsonb->>'x-device-id', ''
        )
    )
  )
  with check (
    exists (
      select 1 from tournament_events e
      where e.id = tournament_id
        and e.organizer_device_id = nullif(
          current_setting('request.headers', true)::jsonb->>'x-device-id', ''
        )
    )
  );

-- tournament_teams
create policy "public read tournament_teams"
  on tournament_teams for select
  using (true);

create policy "organizer write tournament_teams"
  on tournament_teams for all
  using (
    exists (
      select 1 from tournament_events e
      where e.id = tournament_id
        and e.organizer_device_id = nullif(
          current_setting('request.headers', true)::jsonb->>'x-device-id', ''
        )
    )
  )
  with check (
    exists (
      select 1 from tournament_events e
      where e.id = tournament_id
        and e.organizer_device_id = nullif(
          current_setting('request.headers', true)::jsonb->>'x-device-id', ''
        )
    )
  );

-- tournament_team_players
create policy "public read tournament_team_players"
  on tournament_team_players for select
  using (true);

create policy "organizer write tournament_team_players"
  on tournament_team_players for all
  using (
    exists (
      select 1 from tournament_teams tt
      join tournament_events e on e.id = tt.tournament_id
      where tt.id = team_id
        and e.organizer_device_id = nullif(
          current_setting('request.headers', true)::jsonb->>'x-device-id', ''
        )
    )
  )
  with check (
    exists (
      select 1 from tournament_teams tt
      join tournament_events e on e.id = tt.tournament_id
      where tt.id = team_id
        and e.organizer_device_id = nullif(
          current_setting('request.headers', true)::jsonb->>'x-device-id', ''
        )
    )
  );

-- tournament_hole_scores
-- Open read for live leaderboard
create policy "public read tournament_hole_scores"
  on tournament_hole_scores for select
  using (true);

-- Player may insert their own scores (device must be registered in tournament_players)
create policy "player submit own score"
  on tournament_hole_scores for insert
  with check (
    exists (
      select 1 from tournament_players tp
      where tp.id = tournament_player_id
        and tp.player_device_id = nullif(
          current_setting('request.headers', true)::jsonb->>'x-device-id', ''
        )
    )
  );

-- Organizer may update/delete scores
create policy "organizer manage tournament_hole_scores"
  on tournament_hole_scores for all
  using (
    exists (
      select 1 from tournament_events e
      where e.id = tournament_id
        and e.organizer_device_id = nullif(
          current_setting('request.headers', true)::jsonb->>'x-device-id', ''
        )
    )
  )
  with check (
    exists (
      select 1 from tournament_events e
      where e.id = tournament_id
        and e.organizer_device_id = nullif(
          current_setting('request.headers', true)::jsonb->>'x-device-id', ''
        )
    )
  );

-- tournament_playoff_results
create policy "public read tournament_playoff_results"
  on tournament_playoff_results for select
  using (true);

create policy "organizer write tournament_playoff_results"
  on tournament_playoff_results for all
  using (
    exists (
      select 1 from tournament_events e
      where e.id = tournament_id
        and e.organizer_device_id = nullif(
          current_setting('request.headers', true)::jsonb->>'x-device-id', ''
        )
    )
  )
  with check (
    exists (
      select 1 from tournament_events e
      where e.id = tournament_id
        and e.organizer_device_id = nullif(
          current_setting('request.headers', true)::jsonb->>'x-device-id', ''
        )
    )
  );

-- ─────────────────────────────────────────
-- Realtime
-- ─────────────────────────────────────────

alter publication supabase_realtime add table tournament_hole_scores;
alter publication supabase_realtime add table tournament_team_players;
