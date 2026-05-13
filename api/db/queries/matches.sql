-- name: CreateMatch :one
-- Creates a match. Caller decides the initial status: 'PENDING' when the score
-- is awaiting opponent confirmation (ELO not yet applied), 'CONFIRMED' for
-- already-validated entries (e.g. admin-imported or auto-confirmed flows).
INSERT INTO matches (
    match_type,
    team1_player1_id, team1_player2_id,
    team2_player1_id, team2_player2_id,
    set1_team1, set1_team2,
    set2_team1, set2_team2,
    set3_team1, set3_team2,
    played_at,
    status,
    submitted_by_id,
    confirmed_at
) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)
RETURNING *;

-- name: GetMatchByID :one
SELECT * FROM matches
WHERE id = $1;

-- name: ListMatches :many
-- Public lists (rankings, feeds, history) only show CONFIRMED matches.
SELECT * FROM matches
WHERE status = 'CONFIRMED'
ORDER BY played_at DESC;

-- name: GetPlayerMatches :many
-- Only CONFIRMED matches count for a player's history.
SELECT * FROM matches
WHERE status = 'CONFIRMED'
  AND (team1_player1_id = $1 OR team1_player2_id = $1
    OR team2_player1_id = $1 OR team2_player2_id = $1)
ORDER BY played_at DESC;

-- name: GetMatchesInPeriod :many
SELECT * FROM matches
WHERE status = 'CONFIRMED'
  AND match_type = $1
  AND played_at >= $2
  AND played_at <  $3
ORDER BY played_at DESC;

-- name: ConfirmMatch :one
UPDATE matches
SET status       = 'CONFIRMED',
    confirmed_at = NOW()
WHERE id = $1 AND status = 'PENDING'
RETURNING *;

-- name: ContestMatch :one
UPDATE matches
SET status = 'CONTESTED'
WHERE id = $1 AND status = 'PENDING'
RETURNING *;
