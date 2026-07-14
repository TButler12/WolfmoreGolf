-- Analytics events — append-only, device-ID-keyed, no Auth dependency.
-- Inserts are open to the anon key (fire-and-forget from the app).
-- Reads require the service role key (dashboard / data pipeline only).

create table analytics_events (
  id           uuid primary key default gen_random_uuid(),
  event_name   text not null,
  user_id      text not null,
  properties   jsonb not null default '{}',
  app_version  text not null,
  created_at   timestamptz not null default now()
);

alter table analytics_events enable row level security;

-- App inserts with the anon key — no auth required.
create policy "anon insert analytics_events"
  on analytics_events for insert
  with check (true);

-- No select policy: only the service role key can read rows.
