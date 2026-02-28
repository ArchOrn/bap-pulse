-- +goose Up
CREATE TABLE elo_history (
    id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    player_id  VARCHAR(128) NOT NULL REFERENCES players(id),
    elo_before INT  NOT NULL,
    elo_after  INT  NOT NULL,
    match_id   UUID NOT NULL REFERENCES matches(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_elo_history_player ON elo_history(player_id);
CREATE INDEX idx_elo_history_match  ON elo_history(match_id);

-- +goose Down
DROP TABLE IF EXISTS elo_history;
