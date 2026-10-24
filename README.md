# PawShots

Android-first pet vaccination tracker for owners in Sri Lanka.

## Test in your laptop browser

With Docker Desktop already running, no Android Studio or host Flutter installation is needed:

```powershell
docker compose up -d preview
docker compose logs -f preview
```

When the logs show `PawShots browser preview ready`, open **http://localhost:8080** in Chrome, Brave, or Edge. After updating an older preview, press **Ctrl+Shift+R** once. Test pets, custom vaccines, statuses, and reminder preferences. Records stay in that browser; background vaccine notifications are available in the Android app.

Stop the preview with `docker compose stop preview`. After editing source, rebuild/restart it with `docker compose up -d --force-recreate preview`.

Phase 1 covers multiple pet profiles, built-in draft and custom vaccine plans, local reminders, and PDF vaccination records.

The UI follows the supplied **PawShots · Petrol & Ice** reference. Choose **Explore demo** on the welcome screen to view Bruno and Mimi with sample records, or **Get started** to create your own local pet profiles. See [UI design and visual QA](docs/ui_reference.md).

## Deliverable 1: architecture

See [architecture summary and ER diagram](docs/01_architecture_and_er.md) and [user flow](docs/01_summary_and_user_flow.md).

Stack: Flutter with Drift/SQLite, Node.js with TypeScript and Express, PostgreSQL 15+, node-pg with plain SQL migrations, Zod, bcrypt/JWT authentication, and PDFKit.

## Docker development

Use [Docker setup and daily commands](docs/docker_development.md) to start PostgreSQL, apply migrations, and run SQL checks without installing PostgreSQL on the host.

```powershell
if (-not (Test-Path .env)) { Copy-Item .env.example .env }
docker compose up -d --wait db
docker compose run --rm db-tools -f /sql/migrations/001_initial_schema.up.sql
docker compose run --rm db-tools -f /sql/tests/001_schema_smoke.sql
```

Apply the initial migration once per fresh database. Subsequent container restarts retain your data.

## Deliverable 2: database migrations

See [migration instructions and schema decisions](docs/02_database_migrations.md). The initial PostgreSQL migration and destructive rollback are in `backend/db/migrations/`.

## Flutter app

The Android Flutter app supports a local pet workspace, custom vaccine records, status indicators, SQLite persistence, and reminder preferences with Android notifications. See [Flutter setup, Docker commands, and current integration limits](docs/flutter_development.md).

```powershell
docker compose run --rm flutter pub get
docker compose run --rm flutter analyze
docker compose run --rm flutter test
docker compose run --rm flutter build apk --debug
```

For faster full validation and packaging on Windows, run the checks in a temporary Linux workspace:

```powershell
docker compose run --rm --entrypoint sh flutter /workspace/tool/check_flutter.sh
```

The debug APK is copied to `build/app/outputs/flutter-apk/app-debug.apk` after a successful build.

The API server, account sync, built-in plan templates, and connected PDF export are still pending. PostgreSQL runs separately through the development stack.
