-- name: CreatePlayer :one
INSERT INTO players (id, name, email)
VALUES ($1, $2, $3)
RETURNING *;

-- name: GetPlayerByID :one
SELECT * FROM players
WHERE id = $1;

-- name: GetPlayerByEmail :one
SELECT * FROM players
WHERE email = $1;

-- name: ListPlayers :many
SELECT * FROM players
ORDER BY elo DESC, created_at ASC;

-- name: UpdatePlayer :one
UPDATE players
SET name = $2, email = $3
WHERE id = $1
RETURNING *;

-- name: UpdatePlayerElo :one
UPDATE players
SET elo = $2
WHERE id = $1
RETURNING *;

-- name: DeletePlayer :exec
DELETE FROM players
WHERE id = $1;
