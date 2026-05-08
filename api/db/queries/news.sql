-- name: CreateNews :one
INSERT INTO news (
    emoji, title, body, source, match_id, created_by
) VALUES ($1, $2, $3, $4, $5, $6)
RETURNING *;

-- name: GetNewsByID :one
SELECT * FROM news
WHERE id = $1;

-- name: ListNews :many
SELECT * FROM news
ORDER BY created_at DESC
LIMIT $1 OFFSET $2;

-- name: ListLatestNews :many
SELECT * FROM news
ORDER BY created_at DESC
LIMIT $1;

-- name: UpdateNews :one
UPDATE news
SET emoji = $2,
    title = $3,
    body  = $4
WHERE id = $1
RETURNING *;

-- name: DeleteNews :exec
DELETE FROM news
WHERE id = $1;
