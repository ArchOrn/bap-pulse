package handlers

import (
	"github.com/gofiber/fiber/v2"
	"github.com/jackc/pgx/v5/pgxpool"

	"bap-pulse/db"
	"bap-pulse/services"
)

// GetRankings godoc
//
//	@Summary		ELO leaderboard
//	@Description	Returns all users sorted by descending ELO with their rank position.
//	@Tags			rankings
//	@Produce		json
//	@Success		200	{array}		services.UserRanking
//	@Failure		500	{object}	map[string]string
//	@Router			/rankings [get]
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
