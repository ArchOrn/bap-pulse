-- +goose Up

ALTER TABLE users
    ADD COLUMN elo_singles INT NOT NULL DEFAULT 1000,
    ADD COLUMN elo_doubles INT NOT NULL DEFAULT 1000,
    ADD COLUMN elo_mixed   INT NOT NULL DEFAULT 1000;

UPDATE users SET
    elo_singles = elo,
    elo_doubles = elo,
    elo_mixed   = elo;

ALTER TABLE users DROP COLUMN elo;

-- +goose Down

ALTER TABLE users ADD COLUMN elo INT NOT NULL DEFAULT 1000;

UPDATE users SET elo = elo_singles;

ALTER TABLE users
    DROP COLUMN elo_singles,
    DROP COLUMN elo_doubles,
    DROP COLUMN elo_mixed;
