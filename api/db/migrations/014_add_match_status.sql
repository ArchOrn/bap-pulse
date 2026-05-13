-- +goose Up

CREATE TYPE match_status AS ENUM ('PENDING', 'CONFIRMED', 'CONTESTED', 'CANCELLED');

ALTER TABLE matches
    ADD COLUMN status          match_status NOT NULL DEFAULT 'CONFIRMED',
    ADD COLUMN submitted_by_id VARCHAR(128) REFERENCES users(id) ON DELETE SET NULL,
    ADD COLUMN confirmed_at    TIMESTAMPTZ;

-- Existing rows were created retroactively (already-played records) so they
-- are CONFIRMED and we backfill confirmed_at = played_at.
UPDATE matches SET confirmed_at = played_at;

-- The legacy `validated` boolean is replaced by `status`. It was never written
-- to true by any handler and never read in any meaningful way.
ALTER TABLE matches DROP COLUMN validated;

CREATE INDEX idx_matches_status ON matches(status);

-- +goose Down

ALTER TABLE matches
    ADD COLUMN validated BOOLEAN NOT NULL DEFAULT false;
UPDATE matches SET validated = (status = 'CONFIRMED');

DROP INDEX IF EXISTS idx_matches_status;
ALTER TABLE matches
    DROP COLUMN confirmed_at,
    DROP COLUMN submitted_by_id,
    DROP COLUMN status;

DROP TYPE IF EXISTS match_status;
