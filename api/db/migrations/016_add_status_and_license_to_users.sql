-- +goose Up

-- Self-service registration introduces an approval gate. A user whose FFBAD
-- licence matches the club roster is auto-approved; otherwise they wait for an
-- admin to validate (or reject) their account.
CREATE TYPE user_status AS ENUM ('pending', 'approved', 'rejected');

ALTER TABLE users
    ADD COLUMN status         user_status NOT NULL DEFAULT 'pending',
    ADD COLUMN license_number TEXT;

-- Existing accounts predate the approval flow → grandfather them in.
UPDATE users SET status = 'approved';

-- One Firebase account per FFBAD licence. Partial unique index so multiple
-- NULL licences (admin-invited users without a licence) can coexist.
CREATE UNIQUE INDEX idx_users_license_number
    ON users (license_number)
    WHERE license_number IS NOT NULL;

CREATE INDEX idx_users_status ON users (status);

-- +goose Down

DROP INDEX IF EXISTS idx_users_status;
DROP INDEX IF EXISTS idx_users_license_number;
ALTER TABLE users
    DROP COLUMN license_number,
    DROP COLUMN status;
DROP TYPE IF EXISTS user_status;
