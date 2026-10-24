# Flutter development

PawShots has an Android Flutter application and a browser preview with local workspaces. Both run independently of PostgreSQL and the future API. Start with an empty pet list, add a dog or cat, choose their birth date, and add custom vaccine records using dates agreed with your veterinarian.

## Browser preview without a Windows administrator password

Use the Docker Desktop installation already running on this laptop:

```powershell
docker compose up -d preview
docker compose logs -f preview
```

The first start resolves dependencies, runs analysis and the 12-test suite, downloads the matching SQLite WebAssembly module, compiles its worker, and builds the web app inside Linux. Wait for `PawShots browser preview ready at http://localhost:8080`, then open that address in Chrome, Brave, or Edge. No Windows software installation or emulator is needed.

The preview serves CanvasKit, Manrope, and Flutter's default Roboto fallback font locally. It does not register a Flutter service worker. After updating an older preview, press **Ctrl+Shift+R** once to bypass previously cached startup scripts. Do not clear site data: that would remove your local pet records. A loading message and retry option now cover startup failures instead of leaving an empty white page.

For an optional real browser startup check using an installed Chromium browser and Node 20:

```powershell
node --experimental-websocket tool/check_browser.mjs 'C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe'
```

The check creates an isolated temporary browser profile, waits for Flutter and the welcome photo after database initialization, records runtime exceptions, and saves a screenshot under `build/browser-runtime/`. It does not read or change your normal browser profile.

The server is exposed only on the laptop's loopback interface. Use the same `http://localhost:8080` address each time. The browser stores its own records using Drift/SQLite WebAssembly with persistent browser storage. Android records and browser records are separate. Clearing site data removes browser records; private browsing can restrict persistence. The app rejects an in-memory-only database instead of silently losing records on refresh.

Pet/vaccine editing, status colours, and reminder preference editing are available in the preview. Android background notification scheduling is disabled in the browser and explicitly labelled. API sign-in/sync and PDF export remain pending on both targets.

```powershell
# Check the served app and SQLite worker/module responses.
docker compose exec preview python3 /workspace/tool/check_preview.py

# Restart with a fresh source snapshot after code changes.
docker compose up -d --force-recreate preview

# Stop the preview; browser records remain in the browser.
docker compose stop preview
```

The preview service mounts project source read-only and performs its builds in a temporary Linux directory. The preview server sets COOP/COEP headers and serves `.wasm` as `application/wasm`. Drift is pinned to 2.35.2 to match the downloaded WASM release; update the asset URL/cache version in `tool/preview_web.sh` when deliberately upgrading it. See [Drift's web setup](https://drift.simonbinder.eu/platforms/web/).

## Implemented

- Add, edit, and delete multiple pets with species, birth date, breed, and microchip number.
- Add/edit custom vaccines, record a date given and optional next due date, batch, vet, clinic, and notes. Deleting a vaccine preserves a local tombstone; deleting a pet removes its local vaccine records.
- Status labels and accessible icons/colours: upcoming, due soon (0–14 days inclusive), overdue, and done when given without a pending booster. Calendar calculations use Asia/Colombo regardless of the device timezone.
- Durable Drift/SQLite cache and an ordered mutation outbox written atomically. Data survives restarts. Current data belongs to this device's local workspace.
- Reminder settings with 14-, 3-, 1-day and on-day offsets, and a selectable Colombo notification time. Android local notifications use an inexact schedule, refresh on app resume and changes, and restore scheduled notifications after reboot. Enable notifications in the reminder screen and grant Android permission.
- English ARB strings and generated Flutter localization delegates. Add Sinhala and Tamil catalogs later.
- An HTTP API client with injected access tokens, timeouts, JSON/error handling, and validated PDF downloads. A certificate service saves PDF files and invokes the Android share sheet when connected by the future session layer.

The app schedules only the earliest 60 future reminders; reopen it regularly to refresh the queue. Android settings, device power management, permission denial, or force stopping the app can affect delivery. Notification scheduling requires testing on a physical Android device.

## Docker workflow

Docker Desktop must be running with Linux containers. The Flutter tooling service uses a pinned third-party SDK image, `ghcr.io/cirruslabs/flutter:3.44.0`, with Dart 3.12. SDK downloads are large on first use. Named volumes cache pub packages, Gradle downloads, and the Android SDK/NDK between commands. See the [image publisher](https://github.com/cirruslabs/docker-images-flutter/pkgs/container/flutter).

From the repository root in PowerShell:

For the full check and debug build on Windows, use the helper below. It copies source into a temporary Linux workspace inside Docker, runs analysis and tests, builds the APK, and copies the successful APK back to the host. This avoids repeated reads of the Windows bind mount during analysis and compilation.

```powershell
if (-not (Test-Path .env)) { Copy-Item .env.example .env }
docker compose run --rm --entrypoint sh flutter /workspace/tool/check_flutter.sh
```

Individual commands are also available, though they can be slower on Windows:

```powershell
if (-not (Test-Path .env)) { Copy-Item .env.example .env }
docker compose run --rm flutter pub get
docker compose run --rm flutter analyze
docker compose run --rm flutter test
docker compose run --rm flutter build apk --debug
```

The APK is generated at `build/app/outputs/flutter-apk/app-debug.apk`. Install it on an Android phone/emulator using Android platform tools:

Validation on 2026-10-24: static analysis passed with no issues, all 12 tests passed, and the Android debug APK built successfully. Physical-device behavior has not yet been verified.

```powershell
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

Docker provides compilation and automated checks, not a visible Android emulator. Use a host Flutter SDK plus Android Studio/emulator for interactive debugging and hot reload:

```powershell
flutter pub get
flutter devices
flutter run
```

After switching between host and Docker SDKs, run `flutter clean` followed by `flutter pub get` in the chosen environment; generated package paths are environment-specific. `pubspec.lock` belongs in source control. Android signing currently uses Flutter's development configuration; configure your own release signing before distribution.

Formatting with Docker:

```powershell
docker compose run --rm --entrypoint dart flutter format lib test
```

The browser target uses a conditional database connection and notification implementation. The PDF download/share service still uses native files and is not wired into the preview. PostgreSQL remains a backend service; neither app target connects to it or contains its credentials.

## Integration still required

The API server has not been implemented. The app clearly labels itself as a local workspace. There is no account sign-in, token refresh, network synchronization, conflict resolution, or outbox replay yet. **Queued mutations are not uploaded.** Do not attach them to a user account without implementing explicit local-data import/account scoping and an idempotent server sync protocol first.

Built-in plan generation is unavailable pending verified draft templates and the plan API. The PDF screen explains the missing authenticated certificate connection; it does not generate a substitute certificate. The download/share service is ready for that integration but is not wired to the local-only UI.

Photo selection, gender/weight fields, built-in booster calculations, and account-specific cache isolation remain for subsequent Flutter work. Existing custom vaccine dates are manually editable; recording administration currently uses the vaccine editor's Date given field.

## Code map

- `lib/main.dart`: startup, theme, localization, recovery UI.
- `lib/config/dependencies.dart`: database, repository, scheduler, and ViewModel wiring.
- `lib/data/database/local_database.dart`: native SQLite schema and parameterized document/outbox queries.
- `lib/data/repositories/pawshots_repository.dart`: atomic local changes and mutation recording.
- `lib/domain/models/records.dart`: API-shaped models, Colombo date handling, vaccine statuses.
- `lib/domain/use_cases/reminder_plan.dart`: provisional offline reminder calculations.
- `lib/data/services/notification/notification_service.dart`: Android notification scheduling.
- `lib/data/services/cloud_sync/api_client.dart`: REST transport; not a sync engine.
- `lib/data/services/pdf/certificate_service.dart`: authenticated PDF download, persistence, and sharing.
- `lib/ui/`: pet workspace, plan screen, validated editors, reminder preferences.
- `test/`: calendar/reminder boundaries, atomic SQLite writes and persistence, HTTP failures, and editor validation.

Localization follows [Flutter's ARB workflow](https://docs.flutter.dev/ui/internationalization); notification configuration follows the [plugin's Android setup](https://pub.dev/packages/flutter_local_notifications/versions/19.5.0).
