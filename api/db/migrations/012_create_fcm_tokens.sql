-- +goose Up

CREATE TABLE fcm_tokens (
    token        TEXT         PRIMARY KEY,
    user_id      VARCHAR(128) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    platform     TEXT         NOT NULL CHECK (platform IN ('ios', 'android', 'web')),
    created_at   TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    last_seen_at TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_fcm_tokens_user_id ON fcm_tokens(user_id);

-- +goose Down

DROP TABLE IF EXISTS fcm_tokens;
