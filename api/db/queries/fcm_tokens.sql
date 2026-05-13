-- name: UpsertFcmToken :one
-- Stores or refreshes a device token. Same token across users is rebound
-- to the new user (a device can switch accounts).
INSERT INTO fcm_tokens (token, user_id, platform)
VALUES ($1, $2, $3)
ON CONFLICT (token) DO UPDATE
SET user_id      = EXCLUDED.user_id,
    platform     = EXCLUDED.platform,
    last_seen_at = NOW()
RETURNING *;

-- name: DeleteFcmToken :exec
DELETE FROM fcm_tokens
WHERE token = $1 AND user_id = $2;

-- name: DeleteFcmTokensByValue :exec
-- Used to purge tokens reported as unregistered/invalid by FCM.
DELETE FROM fcm_tokens
WHERE token = ANY($1::text[]);

-- name: ListFcmTokensForUser :many
SELECT * FROM fcm_tokens
WHERE user_id = $1;
