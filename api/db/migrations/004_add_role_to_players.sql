-- +goose Up
ALTER TABLE players
    ADD COLUMN role TEXT NOT NULL DEFAULT 'player'
        CHECK (role IN ('player', 'admin'));

-- +goose Down
ALTER TABLE players DROP COLUMN role;
