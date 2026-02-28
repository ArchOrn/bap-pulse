-- +goose Up
CREATE EXTENSION IF NOT EXISTS "uuid-ossp"; -- conservé pour les PKs des autres tables

CREATE TABLE players (
    id         VARCHAR(128) PRIMARY KEY,  -- Firebase UID directement
    name       VARCHAR(100) NOT NULL,
    email      VARCHAR(255) NOT NULL UNIQUE,
    elo        INT          NOT NULL DEFAULT 1000,
    created_at TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- +goose Down
DROP TABLE IF EXISTS players;
