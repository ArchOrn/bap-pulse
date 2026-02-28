-- +goose Up
CREATE TYPE match_type AS ENUM ('SINGLES', 'DOUBLES', 'MIXED');

CREATE TABLE matches (
    id               UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    match_type       match_type  NOT NULL DEFAULT 'SINGLES',

    -- Équipe 1
    team1_player1_id VARCHAR(128) NOT NULL REFERENCES players(id),
    team1_player2_id VARCHAR(128)          REFERENCES players(id), -- NULL en simple

    -- Équipe 2
    team2_player1_id VARCHAR(128) NOT NULL REFERENCES players(id),
    team2_player2_id VARCHAR(128)          REFERENCES players(id), -- NULL en simple

    score_team1      INT         NOT NULL,
    score_team2      INT         NOT NULL,
    played_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    validated        BOOLEAN     NOT NULL DEFAULT false
);

CREATE INDEX idx_matches_team1_p1  ON matches(team1_player1_id);
CREATE INDEX idx_matches_team1_p2  ON matches(team1_player2_id);
CREATE INDEX idx_matches_team2_p1  ON matches(team2_player1_id);
CREATE INDEX idx_matches_team2_p2  ON matches(team2_player2_id);
CREATE INDEX idx_matches_played_at ON matches(played_at DESC);

-- +goose Down
DROP TABLE IF EXISTS matches;
DROP TYPE IF EXISTS match_type;
