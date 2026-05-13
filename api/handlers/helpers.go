package handlers

import (
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"

	"bap-pulse/db"
)

// uuidString converts a pgtype.UUID to its canonical 36-char form ("" if null).
func uuidString(id pgtype.UUID) string {
	if !id.Valid {
		return ""
	}
	return uuid.UUID(id.Bytes).String()
}

// displayName picks the best human-readable name for a user — nickname if set,
// otherwise "First Last" (trimmed).
func displayName(u db.User) string {
	if u.Nickname.Valid && u.Nickname.String != "" {
		return u.Nickname.String
	}
	if u.FirstName != "" && u.LastName != "" {
		return u.FirstName + " " + u.LastName
	}
	if u.FirstName != "" {
		return u.FirstName
	}
	return u.LastName
}
