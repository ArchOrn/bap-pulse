-- name: CreateUser :one
INSERT INTO users (
    id, first_name, last_name, email,
    gender, ffbad_rank,
    elo_singles, elo_doubles, elo_mixed
)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
RETURNING *;

-- name: GetUserByID :one
SELECT * FROM users
WHERE id = $1;

-- name: GetUserByEmail :one
SELECT * FROM users
WHERE email = $1;

-- name: ListUsers :many
SELECT * FROM users
ORDER BY elo_singles DESC, created_at ASC;

-- name: UpdateUser :one
UPDATE users
SET first_name = $2,
    last_name  = $3,
    email      = $4,
    gender     = $5,
    ffbad_rank = $6
WHERE id = $1
RETURNING *;

-- name: UpdateUserInitialElo :one
-- Used when a user updates their FFBAD/gender BEFORE having played any match.
UPDATE users
SET elo_singles = $2,
    elo_doubles = $3,
    elo_mixed   = $4
WHERE id = $1
RETURNING *;

-- name: UpdateUserEloSingles :one
UPDATE users
SET elo_singles = $2
WHERE id = $1
RETURNING *;

-- name: UpdateUserEloDoubles :one
UPDATE users
SET elo_doubles = $2
WHERE id = $1
RETURNING *;

-- name: UpdateUserEloMixed :one
UPDATE users
SET elo_mixed = $2
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
