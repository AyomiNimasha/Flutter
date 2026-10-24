# Docker development

Install Docker Desktop and run it with Linux containers. Run these commands in PowerShell from the repository root. No host PostgreSQL installation is required.

## Start and initialize

```powershell
# First setup only; preserve an existing .env.
if (-not (Test-Path .env)) { Copy-Item .env.example .env }
docker compose config --quiet
docker compose up -d --wait db

# Run once on a fresh database.
docker compose run --rm db-tools -f /sql/migrations/001_initial_schema.up.sql

# Sample data is rolled back by the smoke check.
docker compose run --rm db-tools -f /sql/tests/001_schema_smoke.sql
```

Compose loads `.env` automatically. The supplied password is for local development. The database is exposed on `127.0.0.1:5433` by default; edit `POSTGRES_PORT` if needed. Set `DATABASE_URL` consistently when changing connection settings. A containerized API will use `db:5432` on the Compose network; a host API will use `localhost:5433`.

SQL files are mounted read-only. Migrations run explicitly, so creating or restarting the database container does not apply SQL automatically. Run each numbered up migration once in order; do not run the initial migration again against an initialized schema. Automatic migration version tracking will be added with the backend.

The database data lives in a named volume. `docker compose down` preserves it. Changing `POSTGRES_USER`, `POSTGRES_DB`, or `POSTGRES_PASSWORD` in `.env` does not reconfigure an already initialized volume; change existing roles/databases explicitly or use a fresh volume when you deliberately want a new database.

## Daily commands

```powershell
docker compose up -d --wait db
docker compose ps
docker compose logs --tail 100 db
docker compose run --rm db-tools -c 'SHOW timezone;'
docker compose run --rm db-tools
docker compose stop db
docker compose down
```

The tools service defaults to printing the SQL client version. To open an interactive SQL session, use `docker compose run --rm db-tools -d pawshots` (replace the database name if configured differently).

## Explicit schema rollback

Only for disposable development data: the following removes all Phase 1 tables and their data. It preserves the PostgreSQL volume itself.

```powershell
docker compose run --rm db-tools -f /sql/migrations/001_initial_schema.down.sql
```

For an isolated development test database, you can validate up migration, smoke check, rollback, and reapplication in that order. Do not use rollback on data you intend to retain.

## Current scope

This Compose stack runs PostgreSQL, SQL tooling, a profile-gated Flutter SDK service, and an optional browser preview. Use `docker compose up -d preview`, then open `http://localhost:8080` after the build finishes. See [Flutter development](flutter_development.md) for full browser and Android commands. The API server has not been implemented yet.

Reference: [Compose health-check dependency ordering](https://docs.docker.com/compose/how-tos/startup-order/) and [official PostgreSQL image initialization behavior](https://hub.docker.com/_/postgres).
