-- name: CreateMatch :one
INSERT INTO matches (
    match_type,
    team1_player1_id, team1_player2_id,
    team2_player1_id, team2_player2_id,
    set1_team1, set1_team2,
    set2_team1, set2_team2,
    set3_team1, set3_team2,
    played_at
) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
RETURNING *;

-- name: GetMatchByID :one
SELECT * FROM matches
WHERE id = $1;

-- name: ListMatches :many
SELECT * FROM matches
ORDER BY played_at DESC;

-- name: GetPlayerMatches :many
SELECT * FROM matches
WHERE team1_player1_id = $1 OR team1_player2_id = $1
   OR team2_player1_id = $1 OR team2_player2_id = $1
ORDER BY played_at DESC;

-- name: ValidateMatch :one
UPDATE matches
SET validated = true
WHERE id = $1
RETURNING *;
