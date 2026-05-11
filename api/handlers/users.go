package handlers

import (
	"github.com/gofiber/fiber/v2"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"

	"bap-pulse/db"
	"bap-pulse/services"
)

// optionalText converts an optional JSON string into a pgtype.Text. Empty
// strings are stored as NULL so the DB CHECK constraint isn't triggered.
func optionalText(s string) pgtype.Text {
	if s == "" {
		return pgtype.Text{}
	}
	return pgtype.Text{String: s, Valid: true}
}

// GetUsers godoc
//
//	@Summary		List all users
//	@Tags			users
//	@Security		BearerAuth
//	@Produce		json
//	@Success		200	{array}		db.User
//	@Failure		500	{object}	map[string]string
//	@Router			/users [get]
func GetUsers(pool *pgxpool.Pool) fiber.Handler {
	return func(c *fiber.Ctx) error {
		q := db.New(pool)
		users, err := q.ListUsers(c.Context())
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Internal server error"})
		}
		return c.JSON(users)
	}
}

// GetUser godoc
//
//	@Summary		Get a user
//	@Tags			users
//	@Security		BearerAuth
//	@Produce		json
//	@Param			id	path		string	true	"User ID (Firebase UID)"
//	@Success		200	{object}	db.User
//	@Failure		404	{object}	map[string]string
//	@Router			/users/{id} [get]
func GetUser(pool *pgxpool.Pool) fiber.Handler {
	return func(c *fiber.Ctx) error {
		q := db.New(pool)
		user, err := q.GetUserByID(c.Context(), c.Params("id"))
		if err != nil {
			return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "User not found"})
		}
		return c.JSON(user)
	}
}

type updateUserRequest struct {
	FirstName string `json:"first_name"`
	LastName  string `json:"last_name"`
	Email     string `json:"email"`
	Gender    string `json:"gender"`     // "" | MALE | FEMALE
	FfbadRank string `json:"ffbad_rank"` // "" | NC | P12 | ... | N1
}

// UpdateUser godoc
//
//	@Summary		Update user profile
//	@Description	Users can only update their own profile. Admins can update any profile.
//	@Tags			users
//	@Security		BearerAuth
//	@Accept			json
//	@Produce		json
//	@Param			id		path		string				true	"User ID (Firebase UID)"
//	@Param			body	body		updateUserRequest	true	"Updated user data"
//	@Success		200		{object}	db.User
//	@Failure		400		{object}	map[string]string
//	@Failure		403		{object}	map[string]string
//	@Failure		500		{object}	map[string]string
//	@Router			/users/{id} [put]
func UpdateUser(pool *pgxpool.Pool) fiber.Handler {
	return func(c *fiber.Ctx) error {
		requesterUID := c.Locals("firebaseUID").(string)
		targetUID := c.Params("id")

		q := db.New(pool)

		if requesterUID != targetUID {
			requester, err := q.GetUserByID(c.Context(), requesterUID)
			if err != nil {
				return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Internal server error"})
			}
			if requester.Role != "admin" {
				return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"error": "Forbidden"})
			}
		}

		var req updateUserRequest
		if err := c.BodyParser(&req); err != nil {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid request body"})
		}
		user, err := q.UpdateUser(c.Context(), db.UpdateUserParams{
			ID:        targetUID,
			FirstName: req.FirstName,
			LastName:  req.LastName,
			Email:     req.Email,
			Gender:    optionalText(req.Gender),
			FfbadRank: optionalText(req.FfbadRank),
		})
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Internal server error"})
		}

		// If the user has not played any match yet and they (or an admin) just
		// set their FFBAD/gender, recompute the starting ELO across all
		// tableaux. Once a single match is recorded we keep the actual ratings
		// — tweaks to FFBAD/gender then become informational only.
		if req.FfbadRank != "" || req.Gender != "" {
			played, err := q.GetUserEloHistory(c.Context(), targetUID)
			if err == nil && len(played) == 0 {
				initial := int32(services.InitialEloFor(req.FfbadRank, req.Gender))
				if u2, err := q.UpdateUserInitialElo(c.Context(), db.UpdateUserInitialEloParams{
					ID:         targetUID,
					EloSingles: initial,
					EloDoubles: initial,
					EloMixed:   initial,
				}); err == nil {
					user = u2
				}
			}
		}

		return c.JSON(user)
	}
}

// DeleteUser godoc
//
//	@Summary		Delete user account
//	@Description	Users can only delete their own account. Admins can delete any account.
//	@Tags			users
//	@Security		BearerAuth
//	@Produce		json
//	@Param			id	path	string	true	"User ID (Firebase UID)"
//	@Success		204
//	@Failure		403	{object}	map[string]string
//	@Failure		500	{object}	map[string]string
//	@Router			/users/{id} [delete]
func DeleteUser(pool *pgxpool.Pool) fiber.Handler {
	return func(c *fiber.Ctx) error {
		requesterUID := c.Locals("firebaseUID").(string)
		targetUID := c.Params("id")

		q := db.New(pool)

		if requesterUID != targetUID {
			requester, err := q.GetUserByID(c.Context(), requesterUID)
			if err != nil {
				return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Internal server error"})
			}
			if requester.Role != "admin" {
				return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"error": "Forbidden"})
			}
		}

		if err := q.DeleteUser(c.Context(), targetUID); err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Internal server error"})
		}
		return c.SendStatus(fiber.StatusNoContent)
	}
}

// parseUUID converts a string to a pgtype.UUID (used by matches.go).
func parseUUID(s string) (pgtype.UUID, error) {
	var id pgtype.UUID
	err := id.Scan(s)
	return id, err
}

// GetUserProfile godoc
//
//	@Summary		Aggregated profile payload for the mobile profile screen
//	@Description	Singles-only for the MVP. Returns ELO, monthly perf score + rank, 7-day perf gain, monthly stats (matches/wins/losses/upsets/streak), held jerseys, yellow-jersey threshold, daily perf-history sparkline, and head-to-head (nemesis + favorite victim).
//	@Tags			users
//	@Security		BearerAuth
//	@Produce		json
//	@Param			id	path		string	true	"User ID (Firebase UID)"
//	@Success		200	{object}	services.UserProfile
//	@Failure		404	{object}	map[string]string
//	@Failure		500	{object}	map[string]string
//	@Router			/users/{id}/profile [get]
func GetUserProfile(pool *pgxpool.Pool) fiber.Handler {
	return func(c *fiber.Ctx) error {
		q := db.New(pool)
		profile, err := services.GetUserProfile(c.Context(), q, c.Params("id"), db.MatchTypeSINGLES)
		if err != nil {
			// GetUserByID returns an error when the row is missing; surface as 404.
			return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "User not found"})
		}
		return c.JSON(profile)
	}
}

// GetUserMatches godoc
//
//	@Summary		List a user's match history
//	@Description	Returns the user's SINGLES matches sorted DESC by played_at, reshaped from the user's perspective (sets as mine vs opp, signed ELO delta).
//	@Tags			users
//	@Security		BearerAuth
//	@Produce		json
//	@Param			id	path		string	true	"User ID (Firebase UID)"
//	@Success		200	{array}		services.UserMatchHistoryEntry
//	@Failure		500	{object}	map[string]string
//	@Router			/users/{id}/matches [get]
func GetUserMatches(pool *pgxpool.Pool) fiber.Handler {
	return func(c *fiber.Ctx) error {
		q := db.New(pool)
		matches, err := services.GetUserMatchHistory(c.Context(), q, c.Params("id"), db.MatchTypeSINGLES)
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to load match history"})
		}
		return c.JSON(matches)
	}
}
