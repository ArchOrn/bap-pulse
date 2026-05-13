-- +goose Up

CREATE TYPE notification_type AS ENUM (
    'CHALLENGE_RECEIVED',
    'CHALLENGE_ACCEPTED',
    'CHALLENGE_DECLINED',
    'MATCH_AWAITING_CONFIRMATION',
    'MATCH_CONFIRMED',
    'MATCH_CONTESTED'
);

CREATE TABLE notifications (
    id         UUID              PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id    VARCHAR(128)      NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type       notification_type NOT NULL,
    title      TEXT              NOT NULL,
    body       TEXT              NOT NULL,
    data       JSONB             NOT NULL DEFAULT '{}'::jsonb,
    read_at    TIMESTAMPTZ,
    created_at TIMESTAMPTZ       NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notifications_user_created ON notifications(user_id, created_at DESC);
CREATE INDEX idx_notifications_user_unread  ON notifications(user_id) WHERE read_at IS NULL;

-- +goose Down

DROP TABLE IF EXISTS notifications;
DROP TYPE  IF EXISTS notification_type;
