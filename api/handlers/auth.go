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
// POST /auth/sync
//
// Called by the client right after a successful Firebase login.
// Creates the player profile in the database on first login,
// or returns the existing profile.
//
// The Firebase ID Token is already validated by the FirebaseAuth middleware.
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
