package handlers

import (
	"github.com/gofiber/fiber/v2"
	"github.com/jackc/pgx/v5/pgxpool"

	"bap-pulse/db"
	"bap-pulse/services"
)

// GetRankings godoc
// GET /api/v1/rankings
// Retourne le classement ELO de tous les joueurs.
func GetRankings(pool *pgxpool.Pool) fiber.Handler {
	return func(c *fiber.Ctx) error {
		q := db.New(pool)
		rankings, err := services.GetRankings(c.Context(), q)
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Erreur interne"})
		}
		return c.JSON(rankings)
	}
}
