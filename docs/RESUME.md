# PawShots resume checkpoint

Current work was resumed on 2026-10-24. The Flutter UI now follows the supplied PawShots · Petrol & Ice reference. All changes remain in the workspace; no commit or publication was requested.

## Implemented

- PostgreSQL migrations, rollback, SQL smoke checks, and Docker PostgreSQL development tooling.
- Android Flutter application with durable Drift/SQLite local records and an atomic mutation outbox.
- Pet/custom-vaccine editing, status calculations using Colombo dates, reminder preferences, and Android notification scheduling.
- Browser preview using persistent SQLite WebAssembly storage and conditional platform services. Browser alarms are disabled and labelled.
- Reference-style welcome screen, pet chips/photo card/dose ring, coming-up rows, bottom navigation, vaccine timeline, coordinated editors, reminders, records, and settings.
- Optional Explore demo with Bruno, Mimi, and eight fictional records. Every demo mutation is isolated in memory and does not enter the user's database/outbox or schedule device notifications.
- Shared Petrol & Ice theme, bundled Manrope font/license, generated pet photograph, English localization, reusable photo/brand/progress widgets.
- REST transport and native PDF download/share service scaffolding. These are not wired to an authenticated backend yet.

## Latest validation

- Static analysis: no issues.
- Automated suite: all 12 tests pass, including the real UI flow for custom vaccines and the demo administration isolation check.
- Visual QA runner: all eight main screens rendered at 430 × 900 without layout errors. PNGs in `build/ui_preview/` were inspected, including the final welcome photo fade, dashboard, timeline, forms, settings, and records.
- Updated Android debug APK built successfully at `build/app/outputs/flutter-apk/app-debug.apk`.
- Browser preview compiles using the same app source and is healthy at `http://localhost:8080`. HTTP checks passed for the app bundle, database worker, SQLite WASM module, MIME type, and isolation headers.
- Browser startup fix: CanvasKit and the engine's required Roboto fallback font are bundled locally; the preview no longer registers a Flutter service worker, and HTML provides a loading/retry state before the first Flutter frame.
- Headless Brave validation passed using a fresh isolated profile: SQLite initialized, the complete welcome screen/photo rendered, and no JavaScript runtime exceptions occurred. The screenshot at `build/browser-runtime/welcome.png` was visually inspected. Use `tool/check_browser.mjs` to repeat this check; this replaces the earlier HTTP-only startup verification. Physical-device notification delivery is still unverified.

## Run and review

```powershell
# Browser preview: start, wait for the preview-ready log, then open localhost:8080.
docker compose up -d preview
docker compose logs -f preview

# After changing app source, restart with a fresh source snapshot.
docker compose up -d --force-recreate preview

# Verify the served app, worker, SQLite module and browser isolation headers.
docker compose exec preview python3 /workspace/tool/check_preview.py

# Analyze, test, and render all main screens in a Linux workspace.
docker compose run --rm --entrypoint sh flutter /workspace/tool/check_ui.sh

# Also build/copy the Android APK from the checked source snapshot.
docker compose run --rm -e BUILD_ANDROID=1 --entrypoint sh flutter /workspace/tool/check_ui.sh
```

Windows bind-mounted analysis was slow; the helper scripts build in temporary Linux directories. SDK, Gradle, pub, and Android debug-signing home caches are Docker volumes. Do not edit a shell helper while it is running.

Choose **Explore demo** on the welcome screen for the reference dashboard, or **Get started** for real local records. Existing local pets bypass onboarding. See `docs/ui_reference.md` for screen paths, screenshots, photo prompt/provenance, and UI commands. See `docs/flutter_development.md` and `docs/docker_development.md` for the development environment.

## Remaining product work

The API server, account sign-in/token refresh, account-specific cache scoping, outbox replay, conflict handling, verified draft vaccine templates/built-in plans, owner photo uploads, gender/weight fields, and connected PDF export are still pending. Current custom vaccine dates are user-entered. Do not describe the complete Phase 1 MVP as finished.

The original task requested one deliverable at a time. The user subsequently requested Docker development, Flutter development, laptop browser testing without an administrator password, and then the reference-based UI redesign. Follow their next instruction when continuing.
