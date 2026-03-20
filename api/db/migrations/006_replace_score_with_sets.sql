-- +goose Up

ALTER TABLE matches
    ADD COLUMN set1_team1 INT NOT NULL DEFAULT 0,
    ADD COLUMN set1_team2 INT NOT NULL DEFAULT 0,
    ADD COLUMN set2_team1 INT NOT NULL DEFAULT 0,
    ADD COLUMN set2_team2 INT NOT NULL DEFAULT 0,
    ADD COLUMN set3_team1 INT,
    ADD COLUMN set3_team2 INT;

-- Migrate existing data: treat old scores as set 1 scores
UPDATE matches SET set1_team1 = score_team1, set1_team2 = score_team2;

ALTER TABLE matches
    DROP COLUMN score_team1,
    DROP COLUMN score_team2;

-- +goose Down

ALTER TABLE matches
    ADD COLUMN score_team1 INT NOT NULL DEFAULT 0,
    ADD COLUMN score_team2 INT NOT NULL DEFAULT 0;

UPDATE matches SET score_team1 = set1_team1, score_team2 = set1_team2;

ALTER TABLE matches
    DROP COLUMN set1_team1,
    DROP COLUMN set1_team2,
    DROP COLUMN set2_team1,
    DROP COLUMN set2_team2,
    DROP COLUMN set3_team1,
    DROP COLUMN set3_team2;
