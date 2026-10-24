# Deliverable 2: PostgreSQL migrations

Apply `backend/db/migrations/001_initial_schema.up.sql` once to an empty PostgreSQL 15+ database. It creates all six requested tables plus `auth_sessions`, the status and reminder enums, constraints, indexes, and automatic `updated_at` triggers in one transaction. UUIDs default to PostgreSQL's built-in `gen_random_uuid()`; clients may supply UUIDs for offline-created records.

Docker is the default development environment: follow [Docker development](docker_development.md) to run migrations and smoke checks using the containerized SQL client. The commands below are an alternative for an existing host PostgreSQL installation.

From the repository root in PowerShell, with `DATABASE_URL` set in the environment:

```powershell
psql --dbname=$env:DATABASE_URL -v ON_ERROR_STOP=1 -f backend/db/migrations/001_initial_schema.up.sql
```

`psql` does not load `.env` automatically. Use a development database and keep credentials out of source control. A migration runner with version tracking belongs to the backend deliverable; until then, record application manually and do not rerun the migration against an initialized database.

The matching `.down.sql` file is an explicit destructive rollback. It removes these tables and their data. Do not run it against data you intend to retain.

To check constraints, timestamps, soft deletion, and ownership cascades on an empty migrated test database, run:

```powershell
psql --dbname=$env:DATABASE_URL -v ON_ERROR_STOP=1 -f backend/db/tests/001_schema_smoke.sql
```

The smoke check wraps its sample data in a transaction and rolls it back.

## Schema decisions

- Normalize email to trimmed lowercase before inserting or looking up users; the database enforces normalized unique values. Password hashing and input validation belong in the API.
- Pet deletion cascades to vaccines and reminders. Account deletion cascades to owned data and sessions. Vaccine deletion is an application soft delete; ordinary API routes must never issue `DELETE` for vaccine rows.
- Template deletion is restricted while referenced. Deactivate templates instead. Only one version of a species/region/vaccine/dose may be active at once.
- Custom vaccines have no template; built-in vaccines require one. A partial unique index prevents duplicate live rows for the same pet/template. Soft-deleted rows do not block plan regeneration.
- A vaccine requires an administration date or a due date. A pending next dose may fall on or after its administration date. An administered record without a pending dose has a null due date.
- All seven tables have UUID keys and `created_at`/`updated_at` instants. Birth, administration, and due dates use finite `DATE` values. `timestamptz` stores instants independent of the database session's display timezone; configure API database sessions for UTC.
- Phase 1 restricts user timezone to `Asia/Colombo`. Notification time is a local wall time, defaulting to 09:00. The API will combine it with Colombo calendar dates to build UTC reminders.
- Each reminder type occurs at most once per vaccine; the unique index also covers the vaccine foreign key. Unique indexes similarly cover reminder settings' user key. Other foreign keys and pending due/trigger times have explicit indexes.
- Status is a compatibility cache. Do not treat it as authoritative: deliverable 4 supplies the date-based status view and built-in plan function. This migration deliberately contains no vaccine schedule data.
- Registration will create reminder settings in the same transaction as the user. Reminder rebuilding and cancellation on vaccine edits, soft deletion, or settings changes belong to the API transaction.
- Ownership must be checked in every API query. Foreign keys alone do not authorize access. Future sync cursors, conflict versions, and pet deletion events will require an additional migration before offline synchronization is complete.
- Refresh sessions store token digests and expiry/revocation instants. The auth implementation must rotate refresh tokens atomically and reject expired or revoked sessions.

Deliverable 3 is draft vaccine template seed data. Continue after the user's next instruction.
