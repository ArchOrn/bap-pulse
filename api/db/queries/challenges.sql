-- name: CreateChallenge :one
INSERT INTO challenges (
    from_user_id, to_user_id, match_type, proposed_at, court, note
) VALUES ($1, $2, $3, $4, $5, $6)
RETURNING *;

-- name: GetChallengeByID :one
SELECT * FROM challenges
WHERE id = $1;

-- name: ListChallengesForUser :many
-- Both sides — what the user received and what they sent.
SELECT * FROM challenges
WHERE from_user_id = $1 OR to_user_id = $1
ORDER BY created_at DESC;

-- name: UpdateChallengeStatus :one
UPDATE challenges
SET status       = $2,
    responded_at = NOW()
WHERE id = $1
RETURNING *;
