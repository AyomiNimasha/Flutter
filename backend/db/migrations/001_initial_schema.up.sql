-- PostgreSQL 15+. Run once with psql -v ON_ERROR_STOP=1.
BEGIN;
SET LOCAL TIME ZONE 'UTC';

CREATE TYPE vaccine_status AS ENUM ('upcoming', 'due_soon', 'overdue', 'done');
CREATE TYPE reminder_type AS ENUM ('14_days', '3_days', '1_day', 'on_day');

-- Calendar events use DATE; instants use TIMESTAMPTZ throughout.
CREATE TABLE users (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name text NOT NULL CHECK (btrim(name) <> ''),
    email text NOT NULL CHECK (btrim(email) <> '' AND email = lower(btrim(email))),
    phone text,
    password_hash text NOT NULL CHECK (btrim(password_hash) <> ''),
    language text NOT NULL DEFAULT 'en' CHECK (language IN ('en', 'si', 'ta')),
    timezone text NOT NULL DEFAULT 'Asia/Colombo' CHECK (timezone = 'Asia/Colombo'),
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT users_email_unique UNIQUE (email)
);

CREATE TABLE pets (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name text NOT NULL CHECK (btrim(name) <> ''),
    species text NOT NULL CHECK (species IN ('dog', 'cat')),
    breed text,
    gender text CHECK (gender IN ('male', 'female', 'unknown')),
    birth_date date NOT NULL CHECK (isfinite(birth_date)),
    weight_kg numeric(7,3) CHECK (weight_kg > 0 AND weight_kg < 1000),
    photo_url text,
    microchip_no text,
    is_active boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX pets_user_id_idx ON pets(user_id);

CREATE TABLE vaccine_templates (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    species text NOT NULL CHECK (species IN ('dog', 'cat')),
    vaccine_name text NOT NULL CHECK (btrim(vaccine_name) <> ''),
    disease_protected text NOT NULL CHECK (btrim(disease_protected) <> ''),
    dose_number integer NOT NULL CHECK (dose_number > 0),
    min_age_weeks integer NOT NULL CHECK (min_age_weeks >= 0),
    interval_weeks integer CHECK (interval_weeks > 0),
    booster_interval_months integer CHECK (booster_interval_months > 0),
    is_core boolean NOT NULL DEFAULT false,
    region text NOT NULL DEFAULT 'LK' CHECK (region ~ '^[A-Z]{2}$'),
    source_note text NOT NULL CHECK (btrim(source_note) <> ''),
    version integer NOT NULL DEFAULT 1 CHECK (version > 0),
    is_active boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT vaccine_templates_version_unique
        UNIQUE (species, region, vaccine_name, dose_number, version)
);
CREATE UNIQUE INDEX vaccine_templates_active_dose_unique
    ON vaccine_templates(species, region, vaccine_name, dose_number)
    WHERE is_active;

CREATE TABLE pet_vaccines (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    pet_id uuid NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
    -- Referenced templates are deactivated, not deleted, preserving provenance.
    template_id uuid REFERENCES vaccine_templates(id) ON DELETE RESTRICT,
    vaccine_name text NOT NULL CHECK (btrim(vaccine_name) <> ''),
    date_given date CHECK (isfinite(date_given)),
    next_due_date date CHECK (isfinite(next_due_date)),
    -- Compatibility cache only. Deliverable 4 adds authoritative calculated status.
    status vaccine_status NOT NULL DEFAULT 'upcoming',
    batch_number text,
    vet_name text,
    clinic text,
    notes text,
    is_custom boolean NOT NULL DEFAULT false,
    is_deleted boolean NOT NULL DEFAULT false,
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pet_vaccines_has_date CHECK (date_given IS NOT NULL OR next_due_date IS NOT NULL),
    CONSTRAINT pet_vaccines_due_after_given CHECK (next_due_date >= date_given),
    CONSTRAINT pet_vaccines_template_kind CHECK (
        (is_custom AND template_id IS NULL) OR
        (NOT is_custom AND template_id IS NOT NULL)
    )
);
CREATE INDEX pet_vaccines_pet_id_idx ON pet_vaccines(pet_id);
CREATE INDEX pet_vaccines_template_id_idx ON pet_vaccines(template_id);
CREATE INDEX pet_vaccines_due_date_idx ON pet_vaccines(next_due_date)
    WHERE NOT is_deleted AND next_due_date IS NOT NULL;
CREATE UNIQUE INDEX pet_vaccines_live_template_unique ON pet_vaccines(pet_id, template_id)
    WHERE NOT is_deleted AND template_id IS NOT NULL;

CREATE TABLE reminder_settings (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    remind_14_days boolean NOT NULL DEFAULT true,
    remind_3_days boolean NOT NULL DEFAULT true,
    remind_1_day boolean NOT NULL DEFAULT true,
    remind_on_day boolean NOT NULL DEFAULT true,
    notify_time time(0) without time zone NOT NULL DEFAULT '09:00:00'
        CHECK (notify_time < TIME '24:00:00'),
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE reminders (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    pet_vaccine_id uuid NOT NULL REFERENCES pet_vaccines(id) ON DELETE CASCADE,
    remind_at timestamptz NOT NULL CHECK (isfinite(remind_at)),
    type reminder_type NOT NULL,
    -- Reserved for server processing; this is not proof of device delivery.
    sent boolean NOT NULL DEFAULT false,
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT reminders_vaccine_type_unique UNIQUE (pet_vaccine_id, type)
);
CREATE INDEX reminders_pending_remind_at_idx ON reminders(remind_at) WHERE NOT sent;

CREATE TABLE auth_sessions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    -- SHA-256 hex digest of a high-entropy refresh token; never store the token.
    refresh_token_hash text NOT NULL UNIQUE CHECK (refresh_token_hash ~ '^[0-9a-f]{64}$'),
    expires_at timestamptz NOT NULL CHECK (isfinite(expires_at)),
    revoked_at timestamptz CHECK (isfinite(revoked_at)),
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT auth_sessions_expiry CHECK (expires_at > created_at),
    CONSTRAINT auth_sessions_revocation CHECK (revoked_at >= created_at)
);
CREATE INDEX auth_sessions_user_id_idx ON auth_sessions(user_id);
CREATE INDEX auth_sessions_expires_at_idx ON auth_sessions(expires_at);

-- Every update advances the server timestamp; clients must not supply this value.
CREATE FUNCTION set_updated_at() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at := clock_timestamp();
    RETURN NEW;
END;
$$;

CREATE TRIGGER users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER pets_updated_at BEFORE UPDATE ON pets
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER vaccine_templates_updated_at BEFORE UPDATE ON vaccine_templates
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER pet_vaccines_updated_at BEFORE UPDATE ON pet_vaccines
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER reminder_settings_updated_at BEFORE UPDATE ON reminder_settings
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER reminders_updated_at BEFORE UPDATE ON reminders
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER auth_sessions_updated_at BEFORE UPDATE ON auth_sessions
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

COMMENT ON COLUMN pet_vaccines.status IS
    'Compatibility cache. Read status through the calculated view introduced in deliverable 4.';
COMMENT ON COLUMN users.timezone IS
    'Phase 1 supports Asia/Colombo only; expand validation before allowing other zones.';
COMMIT;
