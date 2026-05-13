package handlers

import (
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"

	"bap-pulse/db"
	"bap-pulse/services"
)

type createChallengeRequest struct {
	ToUserID   string `json:"to_user_id"`
	MatchType  string `json:"match_type"` // optional; defaults to SINGLES (v1 only accepts SINGLES)
	ProposedAt string `json:"proposed_at"` // optional ISO-8601
	Court      string `json:"court"`
	Note       string `json:"note"`
}

// CreateChallenge godoc
//
//	@Summary		Challenge another player
//	@Description	v1 only supports SINGLES (one challenger, one challenged). The recipient receives a push notification and can accept/decline.
//	@Tags			challenges
//	@Security		BearerAuth
//	@Accept			json
//	@Produce		json
//	@Param			body	body		createChallengeRequest	true	"Challenge payload"
//	@Success		201		{object}	db.Challenge
//	@Failure		400		{object}	map[string]string
//	@Failure		404		{object}	map[string]string
//	@Failure		500		{object}	map[string]string
//	@Router			/challenges [post]
func CreateChallenge(pool *pgxpool.Pool, notifier *services.Notifier) fiber.Handler {
	return func(c *fiber.Ctx) error {
		uid := c.Locals("firebaseUID").(string)

		var req createChallengeRequest
		if err := c.BodyParser(&req); err != nil {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid request body"})
		}
		if req.ToUserID == "" {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "'to_user_id' is required"})
		}
		if req.ToUserID == uid {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "You cannot challenge yourself"})
		}

		matchType := db.MatchTypeSINGLES
		if req.MatchType != "" && req.MatchType != string(db.MatchTypeSINGLES) {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Only SINGLES challenges are supported"})
		}

		q := db.New(pool)

		// Confirm both users exist (challenger must already, but cheap to verify).
		from, err := q.GetUserByID(c.Context(), uid)
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Caller not found"})
		}
		if _, err := q.GetUserByID(c.Context(), req.ToUserID); err != nil {
			return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Recipient not found"})
		}

		proposedAt := pgtype.Timestamptz{}
		if req.ProposedAt != "" {
			t, err := time.Parse(time.RFC3339, req.ProposedAt)
			if err != nil {
				return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "'proposed_at' must be ISO-8601"})
			}
			proposedAt = pgtype.Timestamptz{Time: t, Valid: true}
		}

		challenge, err := q.CreateChallenge(c.Context(), db.CreateChallengeParams{
			FromUserID: uid,
			ToUserID:   req.ToUserID,
			MatchType:  matchType,
			ProposedAt: proposedAt,
			Court:      optionalText(req.Court),
			Note:       optionalText(req.Note),
		})
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to create challenge"})
		}

		// Best-effort notification — never fail the request if FCM is down.
		_ = notifier.Send(
			c.Context(),
			req.ToUserID,
			db.NotificationTypeCHALLENGERECEIVED,
			"Nouveau défi 🏸",
			displayName(from)+" te lance un défi",
			map[string]string{
				"challenge_id": uuidString(challenge.ID),
				"from_user_id": uid,
			},
		)

		return c.Status(fiber.StatusCreated).JSON(challenge)
	}
}

// ListChallenges godoc
//
//	@Summary		List challenges involving the authenticated user
//	@Description	Returns both received and sent challenges, most recent first.
//	@Tags			challenges
//	@Security		BearerAuth
//	@Produce		json
//	@Success		200	{array}		db.Challenge
//	@Failure		500	{object}	map[string]string
//	@Router			/challenges [get]
func ListChallenges(pool *pgxpool.Pool) fiber.Handler {
	return func(c *fiber.Ctx) error {
		uid := c.Locals("firebaseUID").(string)

		q := db.New(pool)
		items, err := q.ListChallengesForUser(c.Context(), uid)
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Internal server error"})
		}
		return c.JSON(items)
	}
}

// AcceptChallenge godoc
//
//	@Summary		Accept a challenge
//	@Tags			challenges
//	@Security		BearerAuth
//	@Produce		json
//	@Param			id	path		string	true	"Challenge ID (UUID)"
//	@Success		200	{object}	db.Challenge
//	@Failure		400	{object}	map[string]string
//	@Failure		403	{object}	map[string]string
//	@Failure		404	{object}	map[string]string
//	@Router			/challenges/{id}/accept [post]
func AcceptChallenge(pool *pgxpool.Pool, notifier *services.Notifier) fiber.Handler {
	return respondToChallenge(pool, notifier, db.ChallengeStatusACCEPTED, db.NotificationTypeCHALLENGEACCEPTED, "accepté")
}

// DeclineChallenge godoc
//
//	@Summary		Decline a challenge
//	@Tags			challenges
//	@Security		BearerAuth
//	@Produce		json
//	@Param			id	path		string	true	"Challenge ID (UUID)"
//	@Success		200	{object}	db.Challenge
//	@Failure		400	{object}	map[string]string
//	@Failure		403	{object}	map[string]string
//	@Failure		404	{object}	map[string]string
//	@Router			/challenges/{id}/decline [post]
func DeclineChallenge(pool *pgxpool.Pool, notifier *services.Notifier) fiber.Handler {
	return respondToChallenge(pool, notifier, db.ChallengeStatusDECLINED, db.NotificationTypeCHALLENGEDECLINED, "décliné")
}

func respondToChallenge(
	pool *pgxpool.Pool,
	notifier *services.Notifier,
	newStatus db.ChallengeStatus,
	notifType db.NotificationType,
	verb string,
) fiber.Handler {
	return func(c *fiber.Ctx) error {
		uid := c.Locals("firebaseUID").(string)

		id, err := parseUUID(c.Params("id"))
		if err != nil {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid ID"})
		}

		q := db.New(pool)
		challenge, err := q.GetChallengeByID(c.Context(), id)
		if err != nil {
			return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Challenge not found"})
		}
		if challenge.ToUserID != uid {
			return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"error": "Only the recipient can respond"})
		}
		if challenge.Status != db.ChallengeStatusPENDING {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Challenge is no longer pending"})
		}

		updated, err := q.UpdateChallengeStatus(c.Context(), db.UpdateChallengeStatusParams{
			ID:     id,
			Status: newStatus,
		})
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to update challenge"})
		}

		responder, _ := q.GetUserByID(c.Context(), uid)
		_ = notifier.Send(
			c.Context(),
			challenge.FromUserID,
			notifType,
			"Défi "+verb,
			displayName(responder)+" a "+verb+" ton défi",
			map[string]string{
				"challenge_id": uuidString(updated.ID),
				"to_user_id":   uid,
			},
		)

		return c.JSON(updated)
	}
}

// CancelChallenge godoc
//
//	@Summary		Cancel a challenge you sent
//	@Tags			challenges
//	@Security		BearerAuth
//	@Produce		json
//	@Param			id	path		string	true	"Challenge ID (UUID)"
//	@Success		200	{object}	db.Challenge
//	@Failure		400	{object}	map[string]string
//	@Failure		403	{object}	map[string]string
//	@Failure		404	{object}	map[string]string
//	@Router			/challenges/{id}/cancel [post]
func CancelChallenge(pool *pgxpool.Pool) fiber.Handler {
	return func(c *fiber.Ctx) error {
		uid := c.Locals("firebaseUID").(string)

		id, err := parseUUID(c.Params("id"))
		if err != nil {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid ID"})
		}

		q := db.New(pool)
		challenge, err := q.GetChallengeByID(c.Context(), id)
		if err != nil {
			return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Challenge not found"})
		}
		if challenge.FromUserID != uid {
			return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"error": "Only the sender can cancel"})
		}
		if challenge.Status != db.ChallengeStatusPENDING {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Challenge is no longer pending"})
		}

		updated, err := q.UpdateChallengeStatus(c.Context(), db.UpdateChallengeStatusParams{
			ID:     id,
			Status: db.ChallengeStatusCANCELLED,
		})
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to cancel challenge"})
		}
		return c.JSON(updated)
	}
}
