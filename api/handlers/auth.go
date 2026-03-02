package handlers

import (
	"github.com/gofiber/fiber/v2"
	"github.com/jackc/pgx/v5/pgxpool"

	"bap-pulse/db"
)

type syncRequest struct {
	Name string `json:"name"`
}

// Sync godoc
//
//	@Summary		Sync player profile
//	@Description	Called after a successful Firebase login. Creates the player profile on first login, or returns the existing one.
//	@Tags			auth
//	@Security		BearerAuth
//	@Accept			json
//	@Produce		json
//	@Param			body	body		syncRequest	true	"Player display name (required on first login)"
//	@Success		200		{object}	db.Player
//	@Success		201		{object}	db.Player
//	@Failure		400		{object}	map[string]string
//	@Failure		500		{object}	map[string]string
//	@Router			/auth/sync [post]
func Sync(pool *pgxpool.Pool) fiber.Handler {
	return func(c *fiber.Ctx) error {
		firebaseUID := c.Locals("firebaseUID").(string)
		firebaseEmail, _ := c.Locals("firebaseEmail").(string)

		q := db.New(pool)

		// Player already exists — return immediately.
		player, err := q.GetPlayerByID(c.Context(), firebaseUID)
		if err == nil {
			return c.JSON(player)
		}

		// First login: create the player profile.
		var req syncRequest
		if err := c.BodyParser(&req); err != nil || req.Name == "" {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
				"error": "Le champ 'name' est requis lors de la première connexion",
			})
		}

		player, err = q.CreatePlayer(c.Context(), db.CreatePlayerParams{
			ID:    firebaseUID,
			Name:  req.Name,
			Email: firebaseEmail,
		})
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
				"error": "Erreur lors de la création du profil",
			})
		}

		return c.Status(fiber.StatusCreated).JSON(player)
	}
}
