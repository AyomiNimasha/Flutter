-- Destructive rollback: removes all Phase 1 data. Run only intentionally.
BEGIN;
DROP TABLE auth_sessions;
DROP TABLE reminders;
DROP TABLE reminder_settings;
DROP TABLE pet_vaccines;
DROP TABLE vaccine_templates;
DROP TABLE pets;
DROP TABLE users;
DROP FUNCTION set_updated_at();
DROP TYPE reminder_type;
DROP TYPE vaccine_status;
COMMIT;
