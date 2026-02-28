package handlers

import (
	"github.com/gofiber/fiber/v2"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"

	"bap-pulse/db"
)

// GetPlayers godoc
// GET /players
func GetPlayers(pool *pgxpool.Pool) fiber.Handler {
	return func(c *fiber.Ctx) error {
		q := db.New(pool)
		players, err := q.ListPlayers(c.Context())
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Erreur interne"})
		}
		return c.JSON(players)
	}
}

// GetPlayer godoc
// GET /players/:id
func GetPlayer(pool *pgxpool.Pool) fiber.Handler {
	return func(c *fiber.Ctx) error {
		q := db.New(pool)
		player, err := q.GetPlayerByID(c.Context(), c.Params("id"))
		if err != nil {
			return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Joueur introuvable"})
		}
		return c.JSON(player)
	}
}

type updatePlayerRequest struct {
	Name  string `json:"name"`
	Email string `json:"email"`
}

// UpdatePlayer godoc
// PUT /players/:id
func UpdatePlayer(pool *pgxpool.Pool) fiber.Handler {
	return func(c *fiber.Ctx) error {
		// The player ID is their Firebase UID: ownership check is a simple string comparison.
		if c.Params("id") != c.Locals("firebaseUID").(string) {
			return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"error": "Accès interdit"})
		}

		var req updatePlayerRequest
		if err := c.BodyParser(&req); err != nil {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Corps de la requête invalide"})
		}

		q := db.New(pool)
		player, err := q.UpdatePlayer(c.Context(), db.UpdatePlayerParams{
			ID:    c.Params("id"),
			Name:  req.Name,
			Email: req.Email,
		})
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Erreur interne"})
		}
		return c.JSON(player)
	}
}

// DeletePlayer godoc
// DELETE /players/:id
func DeletePlayer(pool *pgxpool.Pool) fiber.Handler {
	return func(c *fiber.Ctx) error {
		if c.Params("id") != c.Locals("firebaseUID").(string) {
			return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"error": "Accès interdit"})
		}

		q := db.New(pool)
		if err := q.DeletePlayer(c.Context(), c.Params("id")); err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Erreur interne"})
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
