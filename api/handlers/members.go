package handlers

import (
	"github.com/gofiber/fiber/v2"
	"github.com/jackc/pgx/v5/pgxpool"

	"bap-pulse/db"
	"bap-pulse/services"
)

// ListMembers godoc
//
//	@Summary		Members roster with monthly stats and jerseys
//	@Description	Returns the full membership, each enriched with monthly performance (score, rank, 7-day gain), monthly W/L/M and currently held jerseys. Same aggregation window/tableau as the /rankings/* family.
//	@Tags			members
//	@Security		BearerAuth
//	@Produce		json
//	@Param			tableau	query		string	false	"SINGLES (default) | DOUBLES | MIXED"
//	@Param			period	query		string	false	"YYYY-MM (default: current month)"
//	@Success		200		{array}		services.MemberSummary
//	@Failure		400		{object}	map[string]string
//	@Failure		500		{object}	map[string]string
//	@Router			/members [get]
func ListMembers(pool *pgxpool.Pool) fiber.Handler {
	return func(c *fiber.Ctx) error {
		tableau, err := parseTableau(c)
		if err != nil {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": err.Error()})
		}
		from, to, err := parsePeriod(c)
		if err != nil {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": err.Error()})
		}
		q := db.New(pool)
		members, err := services.ListMembersWithStats(c.Context(), q, tableau, from, to)
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Erreur interne"})
		}
		return c.JSON(members)
	}
}
