# PawShots: Petrol & Ice UI

The supplied three-screen image is the visual reference for the Flutter app. The implementation uses the same dark petrol actions, icy blue surfaces, navy typography, rounded white cards, pet portraits, dose progress, five-button bottom navigation, and vaccine timeline. Native system bars and device frames are left to the device rather than drawn into the application.

## Screens

- Welcome: shield/paw wordmark, "Healthy pets. Brighter days.", bundled dog-and-cat photograph, Get started, account sign-in status, and an explicit Explore demo option.
- Pets dashboard: greeting, selectable pet chips, portrait card, recorded-dose ring, next-due strip, upcoming vaccine rows, and Pets/Reminders/Add/Records/Settings navigation.
- Vaccine plan: portrait summary and dose progress, draft notice in demo mode, linked status markers, compact status pills, administration action, expandable history, add vaccine, and the required disclaimer.
- Pet and vaccine forms: the same typography, icy background, rounded white fields, icon headers, date pickers, and petrol save buttons.
- Reminder preferences, records, and settings: shared colour tokens, white cards, rounded notices, and consistent navigation.

Shared tokens are in `lib/ui/core/theme/pawshots_theme.dart`. Reusable brand, photo, progress, and notice widgets are in `lib/ui/core/widgets/pawshots_widgets.dart`. All interface strings remain in the English ARB catalog.

## Demo and real records

Choose **Explore demo** on the welcome screen to see Bruno, Mimi, the "Hi, Nimal" greeting, and six of eight sample doses recorded. The sample dates are relative to today. These are fictional UI examples, not a medical schedule.

The demo repository overrides every mutation and has a notification scheduler that does not schedule device alarms. Sample edits and deletions stay in memory; they do not enter the real SQLite database or its outbox. Leaving the demo discards them. A widget test verifies this isolation through the actual Mark as given / Save flow.

Choose **Get started** to create real local records. Existing pet data goes directly to the dashboard. Real statistics are calculated from those records rather than the sample numbers. Built-in medical templates, account authentication/sync, owner photo uploads, and server-connected PDF export are still pending.

## Visual QA

```powershell
docker compose run --rm --entrypoint sh flutter /workspace/tool/check_ui.sh
```

The runner checks analysis and the automated suite, then renders real Flutter widgets at 430 × 900 with the bundled Manrope font and photo. It checks for layout errors and writes screen PNGs to `build/ui_preview/` for inspection. Screens cover welcome, dashboard, vaccine plan, vaccine editor, reminders, settings, pet editor, and records.

Final validation on 2026-10-24: analysis clean; 12 automated tests passed; all eight screens rendered without layout errors and were inspected. The updated debug APK built successfully. The localhost browser preview is healthy, and served app/worker/WASM resources passed HTTP and header checks. Browser interaction and physical-device notification delivery remain manual checks.

To also compile the Android package from that same checked source snapshot:

```powershell
docker compose run --rm -e BUILD_ANDROID=1 --entrypoint sh flutter /workspace/tool/check_ui.sh
```

Browser preview:

```powershell
docker compose up -d --force-recreate preview
```

Wait for the preview-ready log, open `http://localhost:8080`, and choose Explore demo. Browser preference editing is available; background notifications remain an Android feature. The Android SDK, Gradle, pub cache, and Android debug signing home are retained in Docker volumes.

## Assets and provenance

- Photo: `assets/images/welcome_pets.png`, generated with the built-in imagegen tool. It is illustrative, not an uploaded photograph of a real user's pets. Portrait widgets crop this same asset at layout time.
- Font: `assets/fonts/Manrope.ttf`, from Google Fonts' Manrope distribution, with `assets/fonts/OFL.txt` bundled alongside it.
- Shield/paw mark: drawn with Flutter paths and the Material paw icon, so it scales without an extra bitmap or icon dependency.

Final image-generation prompt:

> Create a photorealistic portrait photograph for the PawShots pet care app welcome screen. Reference style: soft icy cyan light, warm golden retriever dog on the RIGHT, brown grey tabby cat on the LEFT, both relaxed friendly and looking at camera together on a plush pale ice-blue blanket. Beautiful natural real fur and bright eyes. Composition: dog is larger and behind cat, their bodies fill the LOWER TWO THIRDS, upper third is soft pale icy blue wall with empty negative space for headline text. Portrait 2:3 composition. No text, no logos, no interface, no phones, no border. This is a production app photo asset, match the provided reference scene's gentle blue mood. Save the generated image to the local filesystem and return its path.
