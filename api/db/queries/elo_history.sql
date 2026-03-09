-- name: CreateEloHistory :one
INSERT INTO elo_history (player_id, elo_before, elo_after, match_id)
VALUES ($1, $2, $3, $4)
RETURNING *;

-- name: GetUserEloHistory :many
SELECT * FROM elo_history
WHERE player_id = $1
ORDER BY created_at DESC;

-- name: GetMatchEloHistory :many
SELECT * FROM elo_history
WHERE match_id = $1;
