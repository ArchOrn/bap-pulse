package handlers

import (
	"strconv"
	"strings"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/jackc/pgx/v5/pgxpool"

	"bap-pulse/db"
	"bap-pulse/services"
)

// parseTableau reads the `tableau` query string. Defaults to SINGLES.
// Accepted values: SINGLES, DOUBLES, MIXED (case-insensitive).
func parseTableau(c *fiber.Ctx) (db.MatchType, error) {
	raw := strings.ToUpper(strings.TrimSpace(c.Query("tableau")))
	if raw == "" {
		return db.MatchTypeSINGLES, nil
	}
	switch db.MatchType(raw) {
	case db.MatchTypeSINGLES, db.MatchTypeDOUBLES, db.MatchTypeMIXED:
		return db.MatchType(raw), nil
	}
	return "", fiber.NewError(fiber.StatusBadRequest, "invalid tableau (expected SINGLES|DOUBLES|MIXED)")
}

// parsePeriod reads the `period` query string in `YYYY-MM` format. When omitted,
// the current calendar month (UTC) is returned. Returns [from, to).
func parsePeriod(c *fiber.Ctx) (time.Time, time.Time, error) {
	raw := strings.TrimSpace(c.Query("period"))
	if raw == "" {
		from, to := services.CurrentMonthRange(time.Now())
		return from, to, nil
	}
	parts := strings.Split(raw, "-")
	if len(parts) != 2 {
		return time.Time{}, time.Time{}, fiber.NewError(fiber.StatusBadRequest, "invalid period (expected YYYY-MM)")
	}
	year, err := strconv.Atoi(parts[0])
	if err != nil || year < 1900 || year > 9999 {
		return time.Time{}, time.Time{}, fiber.NewError(fiber.StatusBadRequest, "invalid period year")
	}
	monthInt, err := strconv.Atoi(parts[1])
	if err != nil || monthInt < 1 || monthInt > 12 {
		return time.Time{}, time.Time{}, fiber.NewError(fiber.StatusBadRequest, "invalid period month")
	}
	from, to := services.MonthRange(year, time.Month(monthInt))
	return from, to, nil
}

// GetEloRanking godoc
//
//	@Summary		ELO leaderboard for a tableau
//	@Tags			rankings
//	@Produce		json
//	@Param			tableau	query		string	false	"SINGLES (default) | DOUBLES | MIXED"
//	@Success		200		{array}		services.EloRanking
//	@Failure		400		{object}	map[string]string
//	@Failure		500		{object}	map[string]string
//	@Router			/rankings/elo [get]
func GetEloRanking(pool *pgxpool.Pool) fiber.Handler {
	return func(c *fiber.Ctx) error {
		tableau, err := parseTableau(c)
		if err != nil {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": err.Error()})
		}
		q := db.New(pool)
		rankings, err := services.GetEloRankings(c.Context(), q, tableau)
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Erreur interne"})
		}
		return c.JSON(rankings)
	}
}

// GetPerformanceRanking godoc
//
//	@Summary		Performance ranking (yellow jersey)
//	@Description	Sum of performance points awarded during the period for the tableau.
//	@Tags			rankings
//	@Produce		json
//	@Param			tableau	query		string	false	"SINGLES (default) | DOUBLES | MIXED"
//	@Param			period	query		string	false	"YYYY-MM (default: current month)"
//	@Success		200		{array}		services.PerformanceRanking
//	@Failure		400		{object}	map[string]string
//	@Failure		500		{object}	map[string]string
//	@Router			/rankings/performance [get]
func GetPerformanceRanking(pool *pgxpool.Pool) fiber.Handler {
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
		rankings, err := services.GetPerformanceRankings(c.Context(), q, tableau, from, to)
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Erreur interne"})
		}
		return c.JSON(rankings)
	}
}

// GetLeagueRanking godoc
//
//	@Summary		League ranking (wins / losses / sets)
//	@Tags			rankings
//	@Produce		json
//	@Param			tableau	query		string	false	"SINGLES (default) | DOUBLES | MIXED"
//	@Param			period	query		string	false	"YYYY-MM (default: current month)"
//	@Success		200		{array}		services.LeagueRanking
//	@Failure		400		{object}	map[string]string
//	@Failure		500		{object}	map[string]string
//	@Router			/rankings/league [get]
func GetLeagueRanking(pool *pgxpool.Pool) fiber.Handler {
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
		rankings, err := services.GetLeagueRankings(c.Context(), q, tableau, from, to)
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Erreur interne"})
		}
		return c.JSON(rankings)
	}
}

// GetMatchesPlayedRanking godoc
//
//	@Summary		Matches-played ranking
//	@Tags			rankings
//	@Produce		json
//	@Param			tableau	query		string	false	"SINGLES (default) | DOUBLES | MIXED"
//	@Param			period	query		string	false	"YYYY-MM (default: current month)"
//	@Success		200		{array}		services.MatchesPlayedRanking
//	@Failure		400		{object}	map[string]string
//	@Failure		500		{object}	map[string]string
//	@Router			/rankings/matches-played [get]
func GetMatchesPlayedRanking(pool *pgxpool.Pool) fiber.Handler {
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
		rankings, err := services.GetMatchesPlayedRankings(c.Context(), q, tableau, from, to)
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Erreur interne"})
		}
		return c.JSON(rankings)
	}
}

// GetGiantKillerRanking godoc
//
//	@Summary		Giant-killer ranking
//	@Description	Wins against an opponent whose ELO at match time exceeded the player's by at least UpsetThreshold.
//	@Tags			rankings
//	@Produce		json
//	@Param			tableau	query		string	false	"SINGLES (default) | DOUBLES | MIXED"
//	@Param			period	query		string	false	"YYYY-MM (default: current month)"
//	@Success		200		{array}		services.GiantKillerRanking
//	@Failure		400		{object}	map[string]string
//	@Failure		500		{object}	map[string]string
//	@Router			/rankings/giant-killer [get]
func GetGiantKillerRanking(pool *pgxpool.Pool) fiber.Handler {
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
		rankings, err := services.GetGiantKillerRankings(c.Context(), q, tableau, from, to)
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Erreur interne"})
		}
		return c.JSON(rankings)
	}
}

// GetRankings is the legacy ELO-only endpoint. Kept for backwards-compat with
// existing clients (BO + Flutter app). Returns the SINGLES ELO ranking.
//
//	@Summary		ELO leaderboard (legacy — defaults to SINGLES)
//	@Description	Use /rankings/elo?tableau=... for new clients.
//	@Tags			rankings
//	@Produce		json
//	@Success		200	{array}		services.EloRanking
//	@Failure		500	{object}	map[string]string
//	@Router			/rankings [get]
func GetRankings(pool *pgxpool.Pool) fiber.Handler {
	return func(c *fiber.Ctx) error {
		q := db.New(pool)
		rankings, err := services.GetEloRankings(c.Context(), q, db.MatchTypeSINGLES)
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Erreur interne"})
		}
		return c.JSON(rankings)
	}
}
