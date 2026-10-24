# PawShots MVP summary and user flow

PawShots helps pet owners in Sri Lanka manage multiple pets, track vaccinations, receive local reminders, and export PDF vaccination records. Phase 1 supports dogs and cats, with species data designed to allow later expansion.

## Confirmed choices

- Personal project, Android first, built with Flutter.
- Node.js, TypeScript, and Express for the REST API, with PostgreSQL 15+ and node-pg plain SQL migrations. Email/password authentication uses bcrypt and JWT access tokens with rotating refresh sessions.
- Drift SQLite for local storage, with synchronization when online.
- English first, using localization files to support Sinhala and Tamil later.
- Asia/Colombo for calendar dates and reminder times.

## Phase 1 scope

1. Pet profiles: create, view, edit, and delete multiple pets, including their photo and optional microchip number. Confirm deletion before removing a pet and its vaccination records.
2. Vaccine plans: choose a built-in draft plan or a blank custom plan. Add, edit, or delete vaccine entries and record administered doses. Show Done, Due soon within 14 days, Overdue, and Upcoming using text and icons alongside colors.
3. Local reminders: enable reminders 14, 3, and 1 day before the due date and on the due day, defaulting to 9:00 AM Asia/Colombo. Update or cancel reminders when relevant records change or are deleted. Reminders work without internet access after setup and notification permission.
4. PDF vaccination record: export pet details, owner name, administered vaccines and next due dates, batch, vet and clinic, and generation date. Share through the device share sheet or save to the phone.

## User flow

```text
Open PawShots
  |
  +-- First use --> Create account / Sign in with email and password
  |                  --> Set owner name
  |
  +-- Returning user with local setup --> Pet list
                                           |
                  +------------------------+----------------------+
                  |                        |                      |
               Add pet              Select existing pet    Reminder settings
                  |                        |                Days and time
           Enter pet details               |
                  |                        |
           Choose vaccine plan             |
            +-----+-----+                  |
            |           |                  |
       Built-in draft  Blank custom        |
            |           |                  |
            +-----+-----+------------------+
                  |
          Pet details and vaccine plan
                  |
                  +-- View vaccine statuses
                  +-- Add / edit / delete vaccine
                  +-- Mark as given --> Confirm editable date
                  |                     --> Calculate next due where defined
                  |                     --> Update reminders
                  +-- Export PDF --> Share / save
                  +-- Edit pet
                  +-- Delete pet --> Confirm
                                      --> Remove records and cancel reminders

Local changes --> Saved in SQLite --> Sync to Express API/PostgreSQL when online
```

Account creation and initial sign-in require connectivity. After local setup, pet and vaccination management and local reminders remain available offline. Synchronization resumes when connectivity returns. Generating a new PDF requires the API; previously downloaded PDFs remain available offline.

## Vaccine plan safeguards

Store editable templates as data, separate from UI code. All sample vaccine entries must be labeled "DRAFT: pending veterinarian review". Verify the WSAVA 2024 and Sri Lankan DAPH/Public Health Veterinary Services references before creating sample schedules in deliverable 3.

Display this disclaimer on the plan screen and in exported PDFs:

"Built-in plans are general guidelines. Always follow your veterinarian's advice, as schedules vary by pet health, lifestyle and local law."

PDF exports are owner-maintained vaccination records; they do not imply veterinary verification.

## Next deliverable

Deliverable 1 is documented in [architecture summary and ER diagram](01_architecture_and_er.md). Deliverable 2 is complete PostgreSQL migrations. Continue only after the user's "continue".
