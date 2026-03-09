-- name: CreateUser :one
INSERT INTO users (id, first_name, last_name, email)
VALUES ($1, $2, $3, $4)
RETURNING *;

-- name: GetUserByID :one
SELECT * FROM users
WHERE id = $1;

-- name: GetUserByEmail :one
SELECT * FROM users
WHERE email = $1;

-- name: ListUsers :many
SELECT * FROM users
ORDER BY elo DESC, created_at ASC;

-- name: UpdateUser :one
UPDATE users
SET first_name = $2, last_name = $3, email = $4
WHERE id = $1
RETURNING *;

-- name: UpdateUserElo :one
UPDATE users
SET elo = $2
WHERE id = $1
RETURNING *;

-- name: UpdateUserRole :one
UPDATE users
SET role = $2
WHERE id = $1
RETURNING *;

-- name: DeleteUser :exec
DELETE FROM users
WHERE id = $1;
