package handlers

import (
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"

	"bap-pulse/db"
	"bap-pulse/services"
)

type setScore struct {
	Team1 int32 `json:"team1"`
	Team2 int32 `json:"team2"`
}

type createMatchRequest struct {
	MatchType      string     `json:"match_type"`       // SINGLES | DOUBLES | MIXED
	Team1Player1ID string     `json:"team1_player1_id"` // always required
	Team1Player2ID string     `json:"team1_player2_id"` // required for DOUBLES / MIXED
	Team2Player1ID string     `json:"team2_player1_id"` // always required
	Team2Player2ID string     `json:"team2_player2_id"` // required for DOUBLES / MIXED
	Sets           []setScore `json:"sets"`             // 2 or 3 sets
}

// setsWon returns the number of sets won by each team.
func setsWon(sets []setScore) (int, int) {
	var t1, t2 int
	for _, s := range sets {
		if s.Team1 > s.Team2 {
			t1++
		} else if s.Team2 > s.Team1 {
			t2++
		}
	}
	return t1, t2
}

// validateSets checks that the sets follow badminton rules:
// - 2 or 3 sets, each played to 21 points max
// - match ends when a team wins 2 sets
func validateSets(sets []setScore) string {
	if len(sets) < 2 || len(sets) > 3 {
		return "A match must have 2 or 3 sets"
	}

	for i, s := range sets {
		if s.Team1 < 0 || s.Team2 < 0 {
			return "Set scores cannot be negative"
		}
		if s.Team1 > 30 || s.Team2 > 30 {
			return "Set scores cannot exceed 30"
		}
		if s.Team1 == s.Team2 {
			return "A set cannot end in a draw"
		}
		high, low := s.Team1, s.Team2
		if low > high {
			high, low = low, high
		}
		if high < 21 {
			return "A set must be won with at least 21 points"
		}
		if low < 20 && high != 21 {
			return "A set must be won 21 points when the opponent has less than 20"
		}
		if low >= 20 && high < 30 && (high-low) != 2 {
			return "From 20-20, a set must be won with 2 points difference"
		}
		if high == 30 && low != 28 && low != 29 {
			return "At 30, the opponent must have 28 or 29 points"
		}
		// After 2 sets, if someone already won 2, there shouldn't be a 3rd set
		if i == 2 {
			w1, w2 := setsWon(sets[:2])
			if w1 == 2 || w2 == 2 {
				return "Set 3 should not be played if a team already won 2 sets"
			}
		}
	}

	// The match must have a winner (someone with 2 sets)
	w1, w2 := setsWon(sets)
	if w1 < 2 && w2 < 2 {
		return "The match must have a winner (2 sets won)"
	}

	return ""
}

// GetMatches godoc
//
//	@Summary		List all matches
//	@Tags			matches
//	@Security		BearerAuth
//	@Produce		json
//	@Success		200	{array}		db.Match
//	@Failure		500	{object}	map[string]string
//	@Router			/matches [get]
func GetMatches(pool *pgxpool.Pool) fiber.Handler {
	return func(c *fiber.Ctx) error {
		q := db.New(pool)
		matches, err := q.ListMatches(c.Context())
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Internal server error"})
		}
		return c.JSON(matches)
	}
}

// GetMatch godoc
//
//	@Summary		Get a match
//	@Tags			matches
//	@Security		BearerAuth
//	@Produce		json
//	@Param			id	path		string	true	"Match ID (UUID)"
//	@Success		200	{object}	db.Match
//	@Failure		400	{object}	map[string]string
//	@Failure		404	{object}	map[string]string
//	@Router			/matches/{id} [get]
func GetMatch(pool *pgxpool.Pool) fiber.Handler {
	return func(c *fiber.Ctx) error {
		id, err := parseUUID(c.Params("id"))
		if err != nil {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid ID"})
		}

		q := db.New(pool)
		match, err := q.GetMatchByID(c.Context(), id)
		if err != nil {
			return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Match not found"})
		}
		return c.JSON(match)
	}
}

// CreateMatch godoc
//
//	@Summary		Create a match
//	@Description	Creates a match with set scores (best of 3, 21 points per set), recalculates ELO ratings, and records history.
//	@Tags			matches
//	@Security		BearerAuth
//	@Accept			json
//	@Produce		json
//	@Param			body	body		createMatchRequest	true	"Match details"
//	@Success		201		{object}	map[string]interface{}
//	@Failure		400		{object}	map[string]string
//	@Failure		404		{object}	map[string]string
//	@Failure		500		{object}	map[string]string
//	@Router			/matches [post]
func CreateMatch(pool *pgxpool.Pool) fiber.Handler {
	return func(c *fiber.Ctx) error {
		var req createMatchRequest
		if err := c.BodyParser(&req); err != nil {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid request body"})
		}

		// Validate sets
		if msg := validateSets(req.Sets); msg != "" {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": msg})
		}

		isDoubles := req.MatchType == string(db.MatchTypeDOUBLES) || req.MatchType == string(db.MatchTypeMIXED)

		if req.Team1Player1ID == "" || req.Team2Player1ID == "" {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "team1_player1_id and team2_player1_id are required"})
		}
		if isDoubles && (req.Team1Player2ID == "" || req.Team2Player2ID == "") {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "All 4 player IDs are required for doubles/mixed"})
		}

		// Check for duplicate players
		playerIDs := []string{req.Team1Player1ID, req.Team2Player1ID}
		if isDoubles {
			playerIDs = append(playerIDs, req.Team1Player2ID, req.Team2Player2ID)
		}
		seen := make(map[string]bool, len(playerIDs))
		for _, id := range playerIDs {
			if seen[id] {
				return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "A player cannot appear more than once in a match"})
			}
			seen[id] = true
		}

		q := db.New(pool)

		p1, err := q.GetUserByID(c.Context(), req.Team1Player1ID)
		if err != nil {
			return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Team 1 player 1 not found"})
		}
		p3, err := q.GetUserByID(c.Context(), req.Team2Player1ID)
		if err != nil {
			return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Team 2 player 1 not found"})
		}

		// Nullable fields for partner slots (singles leaves them empty).
		team1P2 := pgtype.Text{}
		team2P2 := pgtype.Text{}

		var p2, p4 db.User
		if isDoubles {
			p2, err = q.GetUserByID(c.Context(), req.Team1Player2ID)
			if err != nil {
				return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Team 1 player 2 not found"})
			}
			p4, err = q.GetUserByID(c.Context(), req.Team2Player2ID)
			if err != nil {
				return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Team 2 player 2 not found"})
			}
			team1P2 = pgtype.Text{String: req.Team1Player2ID, Valid: true}
			team2P2 = pgtype.Text{String: req.Team2Player2ID, Valid: true}
		}

		// Build set columns
		set3T1 := pgtype.Int4{}
		set3T2 := pgtype.Int4{}
		if len(req.Sets) == 3 {
			set3T1 = pgtype.Int4{Int32: req.Sets[2].Team1, Valid: true}
			set3T2 = pgtype.Int4{Int32: req.Sets[2].Team2, Valid: true}
		}

		match, err := q.CreateMatch(c.Context(), db.CreateMatchParams{
			MatchType:      db.MatchType(req.MatchType),
			Team1Player1ID: req.Team1Player1ID,
			Team1Player2ID: team1P2,
			Team2Player1ID: req.Team2Player1ID,
			Team2Player2ID: team2P2,
			Set1Team1:      req.Sets[0].Team1,
			Set1Team2:      req.Sets[0].Team2,
			Set2Team1:      req.Sets[1].Team1,
			Set2Team2:      req.Sets[1].Team2,
			Set3Team1:      set3T1,
			Set3Team2:      set3T2,
			PlayedAt:       pgtype.Timestamptz{Time: time.Now(), Valid: true},
		})
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to create match"})
		}

		eloChanges, err := applyEloChanges(c, q, match.ID, req, p1, p2, p3, p4, isDoubles)
		if err != nil {
			return err
		}

		return c.Status(fiber.StatusCreated).JSON(fiber.Map{
			"match": match,
			"elo":   eloChanges,
		})
	}
}

// applyEloChanges computes and persists new ELO ratings for all users in the match.
func applyEloChanges(
	c *fiber.Ctx,
	q *db.Queries,
	matchID pgtype.UUID,
	req createMatchRequest,
	p1, p2, p3, p4 db.User,
	isDoubles bool,
) (fiber.Map, error) {
	w1, w2 := setsWon(req.Sets)
	team1Wins := w1 > w2
	team2Wins := w2 > w1

	type eloChange struct {
		Before int32
		After  int32
	}

	changes := make(map[string]eloChange)

	if isDoubles {
		avgTeam1 := services.TeamAverageElo(int(p1.Elo), int(p2.Elo))
		avgTeam2 := services.TeamAverageElo(int(p3.Elo), int(p4.Elo))

		var deltaTeam1, deltaTeam2 int
		if team1Wins {
			deltaTeam1, deltaTeam2 = services.CalculateTeamEloDelta(avgTeam1, avgTeam2)
		} else if team2Wins {
			deltaTeam2, deltaTeam1 = services.CalculateTeamEloDelta(avgTeam2, avgTeam1)
		}

		for _, entry := range []struct {
			player db.User
			delta  int
		}{
			{p1, deltaTeam1}, {p2, deltaTeam1},
			{p3, deltaTeam2}, {p4, deltaTeam2},
		} {
			newElo := int32(int(entry.player.Elo) + entry.delta)
			changes[entry.player.ID] = eloChange{Before: entry.player.Elo, After: newElo}
		}
	} else {
		var newEloP1, newEloP3 int
		if team1Wins {
			newEloP1, newEloP3 = services.CalculateMatchElo(int(p1.Elo), int(p3.Elo))
		} else if team2Wins {
			newEloP3, newEloP1 = services.CalculateMatchElo(int(p3.Elo), int(p1.Elo))
		} else {
			newEloP1, newEloP3 = int(p1.Elo), int(p3.Elo)
		}
		changes[p1.ID] = eloChange{Before: p1.Elo, After: int32(newEloP1)}
		changes[p3.ID] = eloChange{Before: p3.Elo, After: int32(newEloP3)}
	}

	// Persist new ELOs and record history for each user.
	for playerID, ch := range changes {
		if _, err := q.UpdateUserElo(c.Context(), db.UpdateUserEloParams{
			ID:  playerID,
			Elo: ch.After,
		}); err != nil {
			return nil, c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to update ELO"})
		}
		if _, err := q.CreateEloHistory(c.Context(), db.CreateEloHistoryParams{
			PlayerID:  playerID,
			EloBefore: ch.Before,
			EloAfter:  ch.After,
			MatchID:   matchID,
		}); err != nil {
			return nil, c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to record ELO history"})
		}
	}

	// Build the ELO response map.
	result := fiber.Map{}
	for id, ch := range changes {
		result[id] = fiber.Map{"before": ch.Before, "after": ch.After}
	}
	return result, nil
}
