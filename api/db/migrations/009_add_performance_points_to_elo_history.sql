-- +goose Up

ALTER TABLE elo_history
    ADD COLUMN performance_points INT NOT NULL DEFAULT 0;

CREATE INDEX idx_elo_history_player_created ON elo_history(player_id, created_at);

-- +goose Down

DROP INDEX IF EXISTS idx_elo_history_player_created;

ALTER TABLE elo_history DROP COLUMN performance_points;
