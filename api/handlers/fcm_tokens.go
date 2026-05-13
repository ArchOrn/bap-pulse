package handlers

import (
	"github.com/gofiber/fiber/v2"
	"github.com/jackc/pgx/v5/pgxpool"

	"bap-pulse/db"
)

type registerFcmTokenRequest struct {
	Token    string `json:"token"`
	Platform string `json:"platform"` // ios | android | web
}

// RegisterFcmToken godoc
//
//	@Summary		Register a device FCM token
//	@Description	Upserts the token, binding it to the authenticated user. Called by the mobile app at login and on FCM token refresh.
//	@Tags			fcm
//	@Security		BearerAuth
//	@Accept			json
//	@Produce		json
//	@Param			body	body		registerFcmTokenRequest	true	"Token payload"
//	@Success		200		{object}	db.FcmToken
//	@Failure		400		{object}	map[string]string
//	@Failure		500		{object}	map[string]string
//	@Router			/users/me/fcm-tokens [post]
func RegisterFcmToken(pool *pgxpool.Pool) fiber.Handler {
	return func(c *fiber.Ctx) error {
		uid := c.Locals("firebaseUID").(string)

		var req registerFcmTokenRequest
		if err := c.BodyParser(&req); err != nil {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid request body"})
		}
		if req.Token == "" {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "'token' is required"})
		}
		switch req.Platform {
		case "ios", "android", "web":
		default:
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "'platform' must be one of: ios, android, web"})
		}

		q := db.New(pool)
		token, err := q.UpsertFcmToken(c.Context(), db.UpsertFcmTokenParams{
			Token:    req.Token,
			UserID:   uid,
			Platform: req.Platform,
		})
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to register token"})
		}
		return c.JSON(token)
	}
}

// UnregisterFcmToken godoc
//
//	@Summary		Unregister a device FCM token
//	@Description	Called by the mobile app on logout. Only deletes the token if it belongs to the authenticated user.
//	@Tags			fcm
//	@Security		BearerAuth
//	@Produce		json
//	@Param			token	path	string	true	"FCM token"
//	@Success		204
//	@Failure		500	{object}	map[string]string
//	@Router			/users/me/fcm-tokens/{token} [delete]
func UnregisterFcmToken(pool *pgxpool.Pool) fiber.Handler {
	return func(c *fiber.Ctx) error {
		uid := c.Locals("firebaseUID").(string)

		q := db.New(pool)
		if err := q.DeleteFcmToken(c.Context(), db.DeleteFcmTokenParams{
			Token:  c.Params("token"),
			UserID: uid,
		}); err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to unregister token"})
		}
		return c.SendStatus(fiber.StatusNoContent)
	}
}
