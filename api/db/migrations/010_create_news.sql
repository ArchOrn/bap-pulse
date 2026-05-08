-- +goose Up

CREATE TABLE news (
    id          UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
    emoji       VARCHAR(16)  NOT NULL,
    title       TEXT         NOT NULL,
    body        TEXT,
    source      VARCHAR(32)  NOT NULL,
    match_id    UUID         REFERENCES matches(id) ON DELETE SET NULL,
    created_by  VARCHAR(128) REFERENCES users(id)   ON DELETE SET NULL,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_news_created_at ON news(created_at DESC);
CREATE INDEX idx_news_match_id   ON news(match_id);

-- +goose Down

DROP TABLE IF EXISTS news;
