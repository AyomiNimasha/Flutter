# PawShots Phase 1 architecture

## Architecture summary

PawShots is an Android-first Flutter app for pet owners in Sri Lanka. Phase 1 covers pet profiles, built-in and custom vaccine plans, local reminders, and PDF vaccination records. Dogs and cats are supported initially.

The mobile app uses Flutter with Dart. The backend is Node.js with TypeScript and Express, backed by PostgreSQL 15 or later. Use node-pg with parameterized queries and versioned plain SQL migrations consistently. Validate API inputs with Zod.

Use email/password authentication, retaining the previously confirmed login choice. Hash passwords with bcrypt. Use short-lived JWT access tokens and rotating refresh tokens; keep refresh tokens in secure device storage and store only their hashes on the server. Add an auth_sessions table to support revocation, rotation, and expiry.

## System flow

```text
Flutter screens and ViewModels
             |
             v
Repositories and sync coordinator
       |                  |
       v                  v
Drift SQLite cache   REST API client
                          |
                          v
               Express TypeScript API
                 |                |
                 v                v
             node-pg          PDFKit
                 |                |
                 v                v
           PostgreSQL       Certificate PDF

API reminder dates --> Flutter notification service
                    --> Device local notifications
```

Views display ViewModel state; repositories expose local data as the app's source of truth. A sync coordinator uploads queued changes and downloads server updates when online. UUIDs generated on the device allow new offline records to be referenced before upload. The API must accept those IDs and make retries idempotent.

Track pending mutations in a local outbox. Preserve vaccine deletion tombstones until synchronized; retain pet deletion events separately so other devices can remove cached pets after server cascade deletion. Define per-user sync cursors, version checks, deletion events, and conflict handling in the later API and data deliverables. The listed CRUD routes alone do not provide complete offline synchronization.

Initial registration and login require connectivity. After local setup, owners can manage cached pet and vaccine data offline. The server calculates reminder timestamps for synchronized records; Flutter also calculates provisional reminders after offline edits, then reconciles them with API results. Both use the same rules and Asia/Colombo calendar dates.

The app schedules device notifications locally and cancels or rebuilds them after edits, administration records, setting changes, and deletions. Notification permission and device scheduling limits must be handled. A reminder row's sent flag does not prove delivery by a device.

PDFKit generates certificates on the server. Creating a new PDF requires connectivity; previously downloaded PDFs can be opened or shared offline. Store display text as localization keys and catalogs for the app and server-generated PDFs. English is first; reserve font support for Sinhala and Tamil.

## Entity relationships

```text
users
  |-- 1 : many ---- pets
  |                  |-- 1 : many ---- pet_vaccines
  |                                      |-- 1 : many ---- reminders
  |                                      |
  |                                      +-- many : 0..1 -- vaccine_templates
  |
  |-- 1 : 0..1 ---- reminder_settings
  |
  +-- 1 : many ---- auth_sessions
```

- users owns account details, language, timezone, and password hash.
- pets belongs to one user. A user can own multiple pets.
- vaccine_templates contains versioned editable schedule data shared across accounts. Custom vaccine records have no template reference.
- pet_vaccines belongs to one pet, stores administration and next-due information, and is soft deleted. Pet deletion hard deletes its vaccine records and reminders through cascades.
- reminder_settings has at most one row per user, created with defaults during registration.
- reminders belongs to one vaccine record and stores the calculated UTC trigger time and reminder type.
- auth_sessions belongs to one user and stores refresh-token hashes, expiry, and revocation information.

Every pet, vaccine, reminder, and certificate request checks the authenticated owner in its database query. Never trust a client-supplied user ID as authorization.

## Date and status rules

Store timestamps as UTC timestamptz values. Store birth dates, administration dates, and next-due dates as PostgreSQL DATE values because they represent calendar dates. Combine the due date, reminder offset, chosen notification time, and Asia/Colombo timezone to calculate each UTC reminder timestamp.

Use a query-time SQL view or function for status so it changes as the Colombo calendar date advances. A stored status field, if retained to match the requested schema, is a cache and must not override the calculated result.

- Done: an administration date exists and no next dose or booster is pending.
- Overdue: the next due date is before today in Asia/Colombo.
- Due soon: the next due date is today through 14 days from today, inclusive.
- Upcoming: the next due date is more than 14 days away.

An administered record with a future booster remains Upcoming or Due soon according to its next due date. Require either an administration date or a next due date to avoid an undefined status. Show status text and an icon alongside green, orange, red, or grey.

## Vaccine templates and disclaimer

All sample templates must be marked "DRAFT: pending veterinarian review". Verify WSAVA 2024 and Sri Lankan DAPH/Public Health Veterinary Services sources before adding sample schedules in deliverable 3. Plan generation uses data templates and the pet's birth date; it does not encode medical rules in UI widgets.

Display the following on the plan screen and in PDF exports:

"Built-in plans are general guidelines. Always follow your veterinarian's advice, as schedules vary by pet health, lifestyle and local law."

## Delivery sequence

This is deliverable 1 only. Continue with complete PostgreSQL migrations after the user's "continue". No application code or database migrations are included in this step.
