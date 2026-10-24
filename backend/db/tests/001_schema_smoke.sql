-- Run on an empty migrated development/test database. All test data rolls back.
BEGIN;
DO $$
DECLARE
    owner_id uuid;
    pet_key uuid;
    vaccine_key uuid;
    old_updated timestamptz;
BEGIN
    INSERT INTO users(name, email, password_hash)
        VALUES ('Schema test', 'schema-test@example.invalid', 'test-only-placeholder')
        RETURNING id INTO owner_id;
    BEGIN
        INSERT INTO users(name, email, password_hash)
            VALUES ('Duplicate', 'schema-test@example.invalid', 'test-only-placeholder');
        RAISE EXCEPTION 'Duplicate email accepted';
    EXCEPTION WHEN unique_violation THEN NULL;
    END;
    INSERT INTO pets(user_id, name, species, birth_date)
        VALUES (owner_id, 'Test pet', 'dog', DATE '2024-01-01') RETURNING id INTO pet_key;
    BEGIN
        INSERT INTO pets(user_id, name, species, birth_date)
            VALUES (owner_id, 'Invalid species', 'bird', DATE '2024-01-01');
        RAISE EXCEPTION 'Invalid species accepted';
    EXCEPTION WHEN check_violation THEN NULL;
    END;
    BEGIN
        INSERT INTO pet_vaccines(pet_id, vaccine_name, is_custom)
            VALUES (pet_key, 'Missing dates', true);
        RAISE EXCEPTION 'Dateless vaccine accepted';
    EXCEPTION WHEN check_violation THEN NULL;
    END;
    BEGIN
        INSERT INTO pet_vaccines(pet_id, vaccine_name, next_due_date)
            VALUES (pet_key, 'Missing template', DATE '2027-01-01');
        RAISE EXCEPTION 'Built-in vaccine without template accepted';
    EXCEPTION WHEN check_violation THEN NULL;
    END;
    INSERT INTO pet_vaccines(pet_id, vaccine_name, next_due_date, is_custom)
        VALUES (pet_key, 'Test vaccine', DATE '2027-01-01', true)
        RETURNING id, updated_at INTO vaccine_key, old_updated;
    UPDATE pet_vaccines SET notes = 'Updated' WHERE id = vaccine_key;
    IF NOT EXISTS (SELECT 1 FROM pet_vaccines WHERE id = vaccine_key AND updated_at > old_updated) THEN
        RAISE EXCEPTION 'Update timestamp did not advance';
    END IF;
    INSERT INTO reminders(pet_vaccine_id, remind_at, type)
        VALUES (vaccine_key, TIMESTAMPTZ '2027-01-01 03:30:00+00', 'on_day');
    BEGIN
        INSERT INTO reminders(pet_vaccine_id, remind_at, type)
            VALUES (vaccine_key, TIMESTAMPTZ '2027-01-01 03:30:00+00', 'on_day');
        RAISE EXCEPTION 'Duplicate reminder type accepted';
    EXCEPTION WHEN unique_violation THEN NULL;
    END;
    UPDATE pet_vaccines SET is_deleted = true WHERE id = vaccine_key;
    IF NOT EXISTS (SELECT 1 FROM pet_vaccines WHERE id = vaccine_key AND is_deleted) THEN
        RAISE EXCEPTION 'Soft deletion removed vaccine';
    END IF;
    DELETE FROM pets WHERE id = pet_key;
    IF EXISTS (SELECT 1 FROM pet_vaccines WHERE id = vaccine_key)
       OR EXISTS (SELECT 1 FROM reminders WHERE pet_vaccine_id = vaccine_key) THEN
        RAISE EXCEPTION 'Pet cascade failed';
    END IF;
    INSERT INTO reminder_settings(user_id) VALUES (owner_id);
    INSERT INTO auth_sessions(user_id, refresh_token_hash, expires_at)
        VALUES (owner_id, repeat('a', 64), CURRENT_TIMESTAMP + INTERVAL '1 day');
    DELETE FROM users WHERE id = owner_id;
    IF EXISTS (SELECT 1 FROM reminder_settings WHERE user_id = owner_id)
       OR EXISTS (SELECT 1 FROM auth_sessions WHERE user_id = owner_id) THEN
        RAISE EXCEPTION 'User cascade failed';
    END IF;
END;
$$;
ROLLBACK;
