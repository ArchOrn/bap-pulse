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

		eloChanges, err := applyEloChanges(c, q, match.ID, db.MatchType(req.MatchType), req, p1, p2, p3, p4, isDoubles)
		if err != nil {
			return err
		}

		return c.Status(fiber.StatusCreated).JSON(fiber.Map{
			"match": match,
			"elo":   eloChanges,
		})
	}
}

// applyEloChanges computes and persists ELO + performance-points changes for
// the players involved in the match. The ELO column updated depends on the
// match's tableau (singles/doubles/mixed); the K-factor is per-player based on
// their match count in that tableau.
func applyEloChanges(
	c *fiber.Ctx,
	q *db.Queries,
	matchID pgtype.UUID,
	matchType db.MatchType,
	req createMatchRequest,
	p1, p2, p3, p4 db.User,
	isDoubles bool,
) (fiber.Map, error) {
	setsT1, setsT2 := setsWon(req.Sets)

	// ELO column to read & update for this tableau.
	eloOf := func(u db.User) int32 { return services.EloFor(u, matchType) }

	// Match count for K-factor — counts what the player has played BEFORE this
	// match (the new elo_history rows are inserted after we compute deltas).
	matchCount := func(playerID string) (int, error) {
		v, err := q.CountMatchesPlayedByPlayerInTableau(
			c.Context(),
			db.CountMatchesPlayedByPlayerInTableauParams{
				PlayerID:  playerID,
				MatchType: matchType,
			},
		)
		if err != nil {
			return 0, err
		}
		return int(v), nil
	}

	type playerOutcome struct {
		player db.User
		eloBefore int32
		eloAfter  int32
		perfPoints int32
	}

	outcomes := make([]playerOutcome, 0, 4)

	if isDoubles {
		t1p1Matches, err := matchCount(p1.ID)
		if err != nil {
			return nil, c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to read match count"})
		}
		t1p2Matches, err := matchCount(p2.ID)
		if err != nil {
			return nil, c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to read match count"})
		}
		t2p1Matches, err := matchCount(p3.ID)
		if err != nil {
			return nil, c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to read match count"})
		}
		t2p2Matches, err := matchCount(p4.ID)
		if err != nil {
			return nil, c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to read match count"})
		}

		avgT1 := services.TeamAverageElo(int(eloOf(p1)), int(eloOf(p2)))
		avgT2 := services.TeamAverageElo(int(eloOf(p3)), int(eloOf(p4)))

		d1, d2, d3, d4 := services.CalculateTeamEloDeltas(
			avgT1, avgT2, setsT1, setsT2,
			t1p1Matches, t1p2Matches, t2p1Matches, t2p2Matches,
		)

		// Performance points: team-average vs opponent-team-average; both
		// teammates receive the same award.
		perfT1 := int32(services.CalculatePerformancePoints(avgT1, avgT2, setsT1, setsT2))
		perfT2 := int32(services.CalculatePerformancePoints(avgT2, avgT1, setsT2, setsT1))

		for _, e := range []struct {
			user  db.User
			delta int
			perf  int32
		}{
			{p1, d1, perfT1}, {p2, d2, perfT1},
			{p3, d3, perfT2}, {p4, d4, perfT2},
		} {
			before := eloOf(e.user)
			outcomes = append(outcomes, playerOutcome{
				player:     e.user,
				eloBefore:  before,
				eloAfter:   before + int32(e.delta),
				perfPoints: e.perf,
			})
		}
	} else {
		p1Matches, err := matchCount(p1.ID)
		if err != nil {
			return nil, c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to read match count"})
		}
		p3Matches, err := matchCount(p3.ID)
		if err != nil {
			return nil, c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to read match count"})
		}

		eloP1Before := eloOf(p1)
		eloP3Before := eloOf(p3)

		d1, d3 := services.CalculateEloDelta(
			int(eloP1Before), int(eloP3Before),
			setsT1, setsT2,
			p1Matches, p3Matches,
		)

		perfP1 := int32(services.CalculatePerformancePoints(int(eloP1Before), int(eloP3Before), setsT1, setsT2))
		perfP3 := int32(services.CalculatePerformancePoints(int(eloP3Before), int(eloP1Before), setsT2, setsT1))

		outcomes = append(outcomes,
			playerOutcome{player: p1, eloBefore: eloP1Before, eloAfter: eloP1Before + int32(d1), perfPoints: perfP1},
			playerOutcome{player: p3, eloBefore: eloP3Before, eloAfter: eloP3Before + int32(d3), perfPoints: perfP3},
		)
	}

	// Persist: update the right ELO column and record the history row.
	for _, o := range outcomes {
		if err := updateEloByTableau(c, q, o.player.ID, matchType, o.eloAfter); err != nil {
			return nil, c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to update ELO"})
		}
		if _, err := q.CreateEloHistory(c.Context(), db.CreateEloHistoryParams{
			PlayerID:          o.player.ID,
			EloBefore:         o.eloBefore,
			EloAfter:          o.eloAfter,
			MatchID:           matchID,
			PerformancePoints: o.perfPoints,
		}); err != nil {
			return nil, c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to record ELO history"})
		}
	}

	result := fiber.Map{}
	for _, o := range outcomes {
		result[o.player.ID] = fiber.Map{
			"before":             o.eloBefore,
			"after":              o.eloAfter,
			"performance_points": o.perfPoints,
		}
	}
	return result, nil
}

// updateEloByTableau dispatches to the right per-tableau ELO update query.
func updateEloByTableau(c *fiber.Ctx, q *db.Queries, userID string, matchType db.MatchType, newElo int32) error {
	switch matchType {
	case db.MatchTypeDOUBLES:
		_, err := q.UpdateUserEloDoubles(c.Context(), db.UpdateUserEloDoublesParams{
			ID:         userID,
			EloDoubles: newElo,
		})
		return err
	case db.MatchTypeMIXED:
		_, err := q.UpdateUserEloMixed(c.Context(), db.UpdateUserEloMixedParams{
			ID:       userID,
			EloMixed: newElo,
		})
		return err
	default:
		_, err := q.UpdateUserEloSingles(c.Context(), db.UpdateUserEloSinglesParams{
			ID:         userID,
			EloSingles: newElo,
		})
		return err
	}
}
