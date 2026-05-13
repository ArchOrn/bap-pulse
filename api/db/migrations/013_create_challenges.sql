-- +goose Up

CREATE TYPE challenge_status AS ENUM ('PENDING', 'ACCEPTED', 'DECLINED', 'EXPIRED', 'CANCELLED');

CREATE TABLE challenges (
    id            UUID             PRIMARY KEY DEFAULT uuid_generate_v4(),
    from_user_id  VARCHAR(128)     NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    to_user_id    VARCHAR(128)     NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    match_type    match_type       NOT NULL DEFAULT 'SINGLES',
    proposed_at   TIMESTAMPTZ,
    court         TEXT,
    note          TEXT,
    status        challenge_status NOT NULL DEFAULT 'PENDING',
    created_at    TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
    responded_at  TIMESTAMPTZ,
    CONSTRAINT challenges_different_users CHECK (from_user_id <> to_user_id)
);

CREATE INDEX idx_challenges_to_user   ON challenges(to_user_id, status);
CREATE INDEX idx_challenges_from_user ON challenges(from_user_id, status);

-- +goose Down

DROP TABLE IF EXISTS challenges;
DROP TYPE  IF EXISTS challenge_status;
