# Rachio History

Rachio's own app serves only a rolling window of event history, roughly twelve
months, and offers no way to look back across seasons or across a replaced
controller. This app polls the [Rachio public API](https://rachio.readme.io),
stores every event it returns in SQLite, and keeps them after Rachio drops
them. What you get is a permanent watering record: a year heatmap, per zone and
per month totals, a month calendar, a day view, and a filterable event log.

## How it works

`Rachio` (`app/models/rachio.rb`) is a thin wrapper over the public API using
`httpx`. It sends the key as a bearer token and turns 404 and 429 responses
into `Rachio::NotFound` and `Rachio::RateLimited` so callers can react to a
rate limit rather than treating it as a generic failure.

Three jobs move data:

- `SyncAccountJob` runs hourly (`config/recurring.yml`). It upserts every
  device on the account along with its zones, then enqueues a per-controller
  sync. Controllers that have been merged into a successor are skipped, since
  their history now lives elsewhere.
- `SyncControllerJob` pulls events newer than the most recent one already
  stored. Rachio refuses any query wider than 28 days, so a long gap, from a
  month of downtime or a run of failing syncs, is walked forward one window at
  a time. Asking for the whole gap at once returns empty, which is
  indistinguishable from "nothing new" and would wedge the catch-up forever.
- `BackfillControllerJob` walks backwards instead, one window per run, and
  re-enqueues itself until it reaches `Rachio::HISTORY_RETENTION`. Rachio serves
  nothing older, and the daily budget is around 1700 calls, so each run stays
  small and a rate limit retries in an hour rather than failing the backfill.

Ingestion is idempotent: events are keyed on Rachio's own event id, so
overlapping windows and concurrent syncs cannot duplicate history.

Two things complicate the data, and both have first-class handling:

- **Renamed and deleted zones.** Events identify their zone only by the name
  embedded in the summary text, so renaming a zone strands its past runs. The
  manage page lists orphaned names and lets you attach one to a zone, which
  records a `ZoneAlias` and relinks every matching event.
- **Replaced controllers.** Swapping hardware splits one yard's history across
  two devices. A merge repoints the old controller's events and zones at its
  successor rather than teaching every query to span both, so the heatmap,
  stats, and calendar keep working unchanged. Each event remembers where it
  came from in `source_controller_id` and `source_zone_id`, so a merge can be
  undone.

## Data model

| Table | Holds |
| --- | --- |
| `controllers` | One Rachio device, plus backfill progress and an optional `merged_into` pointer |
| `zones` | A zone on a controller, with its number and enabled flag |
| `events` | One Rachio event, its parsed summary, matched zone, and the raw payload |
| `zone_aliases` | Former names a zone has been known by |
| `settings` | Singleton row holding the encrypted Rachio API key |

Durations are not returned as a field. They are parsed out of Rachio's summary
text (`Event#duration_seconds`), which is why the raw payload is kept.

## Configuration

The Rachio API key is entered in the running app under **Settings** and stored
encrypted at rest via Active Record Encryption. It is never read from the
repository or the environment, so nothing secret ships in a checkout. Get the
key from your Rachio account settings.

Encrypting it requires `active_record_encryption` keys in Rails credentials.
Generate them into a fresh credentials file with:

```sh
bin/rails db:encryption:init   # prints the keys
bin/rails credentials:edit     # paste them in
```

Credentials are decrypted with `config/master.key`, which is gitignored, or
with `RAILS_MASTER_KEY` in the environment.

The app has no authentication, and the Mission Control jobs dashboard at
`/jobs` has HTTP basic auth disabled. Run it on a trusted network only:
anything that can reach it can read the settings page and enqueue syncs.

## Running locally

```sh
bin/setup   # installs gems, prepares the databases
bin/dev     # Puma plus the Tailwind watcher
```

Storage is SQLite under `storage/`, split across databases: a primary and a
queue database in development, with cache and cable databases as well in
production. `SOLID_QUEUE_IN_PUMA` runs the Solid Queue supervisor inside the
web process, so one command covers both web and jobs. Set `JOB_CONCURRENCY` to
run more worker processes.

Once it is up, add your API key under Settings, then use **Sync from Rachio
account** to pull in controllers. Devices no longer attached to your account
can be added by device ID, which is how history for retired hardware gets in.

`bin/ci` runs the checks: RuboCop, `bundler-audit`, an importmap vulnerability
audit, and Brakeman.

## Deploying

Deployment is Kamal, configured in `config/deploy.yml`. `.kamal/secrets` reads
`RAILS_MASTER_KEY` from `config/master.key`, so `kamal deploy` carries the
credentials without any secret living in the repo. The SQLite databases sit on
a named Docker volume, and Solid Queue runs inside Puma, so a single container
serves web requests and works the queue.

The settings row lives in the database, so a fresh deployment starts with no
API key. Add it under Settings once the app is up.
