package handlers

import (
	"github.com/gofiber/fiber/v2"
	"github.com/jackc/pgx/v5/pgxpool"

	"bap-pulse/db"
	"bap-pulse/services"
)

// SyncRoster godoc
//
//	@Summary		Sync the club roster from the FFBAD API
//	@Description	Fetches the full club roster (scoped by the club token) and upserts it locally. Pending users whose licence now appears are auto-approved.
//	@Tags			admin
//	@Security		BearerAuth
//	@Produce		json
//	@Success		200	{object}	services.RosterSyncResult
//	@Failure		500	{object}	map[string]string
//	@Failure		503	{object}	map[string]string
//	@Router			/admin/roster/sync [post]
func SyncRoster(pool *pgxpool.Pool, client *services.FFBadClient) fiber.Handler {
	return func(c *fiber.Ctx) error {
		if !client.Enabled() {
			return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{
				"error": "FFBAD sync non configuré (FFBAD_CLUB_TOKEN manquant)",
			})
		}
		res, err := services.SyncRoster(c.Context(), pool, client)
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
				"error": "Échec de la synchronisation FFBAD: " + err.Error(),
			})
		}
		return c.JSON(res)
	}
}

type rosterResponse struct {
	Entries      []db.ClubRoster `json:"entries"`
	LastSyncedAt *string         `json:"last_synced_at"`
}

// GetRoster godoc
//
//	@Summary		List the synced club roster
//	@Tags			admin
//	@Security		BearerAuth
//	@Produce		json
//	@Success		200	{object}	rosterResponse
//	@Failure		500	{object}	map[string]string
//	@Router			/admin/roster [get]
func GetRoster(pool *pgxpool.Pool) fiber.Handler {
	return func(c *fiber.Ctx) error {
		q := db.New(pool)
		entries, err := q.ListRoster(c.Context())
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Internal server error"})
		}
		resp := rosterResponse{Entries: entries}
		if last, err := q.GetLastRosterSync(c.Context()); err == nil && last.Valid {
			s := last.Time.Format("2006-01-02T15:04:05Z07:00")
			resp.LastSyncedAt = &s
		}
		return c.JSON(resp)
	}
}

// ListPendingUsers godoc
//
//	@Summary		List users awaiting validation
//	@Tags			admin
//	@Security		BearerAuth
//	@Produce		json
//	@Success		200	{array}		db.User
//	@Failure		500	{object}	map[string]string
//	@Router			/admin/users/pending [get]
func ListPendingUsers(pool *pgxpool.Pool) fiber.Handler {
	return func(c *fiber.Ctx) error {
		q := db.New(pool)
		users, err := q.ListUsersByStatus(c.Context(), db.UserStatusPending)
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Internal server error"})
		}
		return c.JSON(users)
	}
}

type approveRequest struct {
	Gender    string `json:"gender"`     // optional correction, "" leaves unchanged
	FfbadRank string `json:"ffbad_rank"` // optional correction, "" leaves unchanged
}

// ApproveUser godoc
//
//	@Summary		Approve a pending user
//	@Description	Flips the user to approved. Optionally corrects gender/FFBAD rank (FFBAD data may be stale or missing). If the user hasn't played a match yet, the starting ELO is recomputed from the corrected rank/gender.
//	@Tags			admin
//	@Security		BearerAuth
//	@Accept			json
//	@Produce		json
//	@Param			uid		path		string			true	"Firebase UID of the target user"
//	@Param			body	body		approveRequest	false	"Optional profile corrections"
//	@Success		200		{object}	db.User
//	@Failure		404		{object}	map[string]string
//	@Failure		500		{object}	map[string]string
//	@Router			/admin/users/{uid}/approve [post]
func ApproveUser(pool *pgxpool.Pool) fiber.Handler {
	return func(c *fiber.Ctx) error {
		uid := c.Params("uid")
		if uid == "" {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Missing UID"})
		}

		var req approveRequest
		_ = c.BodyParser(&req)

		q := db.New(pool)

		if _, err := q.GetUserByID(c.Context(), uid); err != nil {
			return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "User not found"})
		}

		// Apply optional gender/rank corrections.
		if req.Gender != "" || req.FfbadRank != "" {
			if _, err := q.SetUserGenderAndRank(c.Context(), db.SetUserGenderAndRankParams{
				ID:        uid,
				Gender:    optionalText(req.Gender),
				FfbadRank: optionalText(req.FfbadRank),
			}); err != nil {
				return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to update profile"})
			}
			// Recompute starting ELO only if no match has been played yet.
			if played, err := q.GetUserEloHistory(c.Context(), uid); err == nil && len(played) == 0 {
				initial := int32(services.InitialEloFor(req.FfbadRank, req.Gender))
				_, _ = q.UpdateUserInitialElo(c.Context(), db.UpdateUserInitialEloParams{
					ID:         uid,
					EloSingles: initial,
					EloDoubles: initial,
					EloMixed:   initial,
				})
			}
		}

		user, err := q.UpdateUserStatus(c.Context(), db.UpdateUserStatusParams{
			ID:     uid,
			Status: db.UserStatusApproved,
		})
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to approve user"})
		}
		return c.JSON(user)
	}
}

// RejectUser godoc
//
//	@Summary		Reject a pending user
//	@Tags			admin
//	@Security		BearerAuth
//	@Produce		json
//	@Param			uid	path		string	true	"Firebase UID of the target user"
//	@Success		200	{object}	db.User
//	@Failure		404	{object}	map[string]string
//	@Failure		500	{object}	map[string]string
//	@Router			/admin/users/{uid}/reject [post]
func RejectUser(pool *pgxpool.Pool) fiber.Handler {
	return func(c *fiber.Ctx) error {
		uid := c.Params("uid")
		if uid == "" {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Missing UID"})
		}
		q := db.New(pool)
		if _, err := q.GetUserByID(c.Context(), uid); err != nil {
			return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "User not found"})
		}
		user, err := q.UpdateUserStatus(c.Context(), db.UpdateUserStatusParams{
			ID:     uid,
			Status: db.UserStatusRejected,
		})
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to reject user"})
		}
		return c.JSON(user)
	}
}
