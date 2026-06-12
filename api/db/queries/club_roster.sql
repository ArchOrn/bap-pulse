-- name: UpsertRosterEntry :one
INSERT INTO club_roster (
    license_number, per_id, first_name, last_name, gender,
    rank_singles, rank_doubles, rank_mixed,
    cote_singles, cote_doubles, cote_mixed,
    is_data_public, synced_at
)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, NOW())
ON CONFLICT (license_number) DO UPDATE SET
    per_id         = EXCLUDED.per_id,
    first_name     = EXCLUDED.first_name,
    last_name      = EXCLUDED.last_name,
    gender         = EXCLUDED.gender,
    rank_singles   = EXCLUDED.rank_singles,
    rank_doubles   = EXCLUDED.rank_doubles,
    rank_mixed     = EXCLUDED.rank_mixed,
    cote_singles   = EXCLUDED.cote_singles,
    cote_doubles   = EXCLUDED.cote_doubles,
    cote_mixed     = EXCLUDED.cote_mixed,
    is_data_public = EXCLUDED.is_data_public,
    synced_at      = NOW()
RETURNING *;

-- name: GetRosterEntryByLicense :one
SELECT * FROM club_roster
WHERE license_number = $1;

-- name: SetRosterMatchedUser :exec
UPDATE club_roster
SET matched_user_id = $2
WHERE license_number = $1;

-- name: DeleteRosterEntry :exec
DELETE FROM club_roster
WHERE license_number = $1;

-- name: ListRoster :many
SELECT * FROM club_roster
ORDER BY last_name ASC, first_name ASC;

-- name: GetLastRosterSync :one
SELECT MAX(synced_at)::timestamptz AS last_synced_at FROM club_roster;
