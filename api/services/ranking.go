package services

import (
	"context"
	"sort"
	"time"

	"github.com/jackc/pgx/v5/pgtype"

	"bap-pulse/db"
)

// ----- Types -----

type EloRanking struct {
	Rank    int           `json:"rank"`
	User    db.User       `json:"user"`
	Elo     int32         `json:"elo"`
	Tableau db.MatchType  `json:"tableau"`
}

type PerformanceRanking struct {
	Rank   int     `json:"rank"`
	User   db.User `json:"user"`
	Points int32   `json:"points"`
}

type LeagueRanking struct {
	Rank     int     `json:"rank"`
	User     db.User `json:"user"`
	Wins     int     `json:"wins"`
	Losses   int     `json:"losses"`
	SetsWon  int     `json:"sets_won"`
	SetsLost int     `json:"sets_lost"`
	SetsDiff int     `json:"sets_diff"`
}

type MatchesPlayedRanking struct {
	Rank          int     `json:"rank"`
	User          db.User `json:"user"`
	MatchesPlayed int     `json:"matches_played"`
}

type GiantKillerRanking struct {
	Rank      int     `json:"rank"`
	User      db.User `json:"user"`
	UpsetWins int     `json:"upset_wins"`
}

// ----- Helpers -----

// EloFor returns the user's ELO for the requested tableau.
func EloFor(u db.User, tableau db.MatchType) int32 {
	switch tableau {
	case db.MatchTypeDOUBLES:
		return u.EloDoubles
	case db.MatchTypeMIXED:
		return u.EloMixed
	default:
		return u.EloSingles
	}
}

// matchPlayers returns the (team1, team2) lists of player IDs.
// For singles, each team has one entry. For doubles/mixed, two entries.
func matchPlayers(m db.Match) ([]string, []string) {
	team1 := []string{m.Team1Player1ID}
	if m.Team1Player2ID.Valid {
		team1 = append(team1, m.Team1Player2ID.String)
	}
	team2 := []string{m.Team2Player1ID}
	if m.Team2Player2ID.Valid {
		team2 = append(team2, m.Team2Player2ID.String)
	}
	return team1, team2
}

// matchSetsWon returns (team1Sets, team2Sets) won out of the match's sets.
func matchSetsWon(m db.Match) (int, int) {
	var t1, t2 int
	tally := func(a, b int32) {
		if a > b {
			t1++
		} else if b > a {
			t2++
		}
	}
	tally(m.Set1Team1, m.Set1Team2)
	tally(m.Set2Team1, m.Set2Team2)
	if m.Set3Team1.Valid && m.Set3Team2.Valid {
		tally(m.Set3Team1.Int32, m.Set3Team2.Int32)
	}
	return t1, t2
}

// CurrentMonthRange returns the [start, end) of the current calendar month in UTC.
func CurrentMonthRange(now time.Time) (time.Time, time.Time) {
	utc := now.UTC()
	start := time.Date(utc.Year(), utc.Month(), 1, 0, 0, 0, 0, time.UTC)
	end := start.AddDate(0, 1, 0)
	return start, end
}

// MonthRange returns the [start, end) of the given calendar month (YYYY-MM) in UTC.
func MonthRange(year int, month time.Month) (time.Time, time.Time) {
	start := time.Date(year, month, 1, 0, 0, 0, 0, time.UTC)
	end := start.AddDate(0, 1, 0)
	return start, end
}

// loadUsersByID fetches all users keyed by their ID for quick lookup.
func loadUsersByID(ctx context.Context, q *db.Queries) (map[string]db.User, []db.User, error) {
	users, err := q.ListUsers(ctx)
	if err != nil {
		return nil, nil, err
	}
	byID := make(map[string]db.User, len(users))
	for _, u := range users {
		byID[u.ID] = u
	}
	return byID, users, nil
}

func tsRange(from, to time.Time) (pgtype.Timestamptz, pgtype.Timestamptz) {
	return pgtype.Timestamptz{Time: from, Valid: true},
		pgtype.Timestamptz{Time: to, Valid: true}
}

// ----- ELO ranking -----

// GetEloRankings returns users sorted by descending ELO for the requested tableau.
func GetEloRankings(ctx context.Context, q *db.Queries, tableau db.MatchType) ([]EloRanking, error) {
	users, err := q.ListUsers(ctx)
	if err != nil {
		return nil, err
	}
	rankings := make([]EloRanking, len(users))
	for i, u := range users {
		rankings[i] = EloRanking{User: u, Elo: EloFor(u, tableau), Tableau: tableau}
	}
	sort.SliceStable(rankings, func(i, j int) bool {
		if rankings[i].Elo != rankings[j].Elo {
			return rankings[i].Elo > rankings[j].Elo
		}
		// Tie-break on creation date ascending (older user first, like ListUsers).
		return rankings[i].User.CreatedAt.Time.Before(rankings[j].User.CreatedAt.Time)
	})
	for i := range rankings {
		rankings[i].Rank = i + 1
	}
	return rankings, nil
}

// ----- Performance ranking -----

// GetPerformanceRankings returns players sorted by descending performance points
// awarded during the [from, to) window for the given tableau.
func GetPerformanceRankings(
	ctx context.Context, q *db.Queries,
	tableau db.MatchType, from, to time.Time,
) ([]PerformanceRanking, error) {
	_, users, err := loadUsersByID(ctx, q)
	if err != nil {
		return nil, err
	}

	tsFrom, tsTo := tsRange(from, to)
	rows, err := q.SumPerformancePointsByPlayer(ctx, db.SumPerformancePointsByPlayerParams{
		MatchType:   tableau,
		CreatedAt:   tsFrom,
		CreatedAt_2: tsTo,
	})
	if err != nil {
		return nil, err
	}

	pointsByID := make(map[string]int32, len(rows))
	for _, r := range rows {
		pointsByID[r.PlayerID] = r.Points
	}

	rankings := make([]PerformanceRanking, 0, len(users))
	for _, u := range users {
		rankings = append(rankings, PerformanceRanking{
			User:   u,
			Points: pointsByID[u.ID],
		})
	}

	sort.SliceStable(rankings, func(i, j int) bool {
		if rankings[i].Points != rankings[j].Points {
			return rankings[i].Points > rankings[j].Points
		}
		return EloFor(rankings[i].User, tableau) > EloFor(rankings[j].User, tableau)
	})
	for i := range rankings {
		rankings[i].Rank = i + 1
	}
	return rankings, nil
}

// ----- Matches-played, league, giant-killer (computed from matches) -----

type playerAgg struct {
	wins       int
	losses     int
	setsWon    int
	setsLost   int
	played     int
	upsetWins  int
}

// aggregateMatches walks every match in the period and accumulates per-player
// stats. For giant-killer, ELO gaps are read from elo_history at match time.
//
// Returns aggregates keyed by player ID.
func aggregateMatches(
	ctx context.Context, q *db.Queries,
	tableau db.MatchType, from, to time.Time,
) (map[string]*playerAgg, error) {
	tsFrom, tsTo := tsRange(from, to)
	matches, err := q.GetMatchesInPeriod(ctx, db.GetMatchesInPeriodParams{
		MatchType:   tableau,
		PlayedAt:   tsFrom,
		PlayedAt_2: tsTo,
	})
	if err != nil {
		return nil, err
	}

	agg := make(map[string]*playerAgg)
	get := func(id string) *playerAgg {
		a, ok := agg[id]
		if !ok {
			a = &playerAgg{}
			agg[id] = a
		}
		return a
	}

	for _, m := range matches {
		t1, t2 := matchPlayers(m)
		s1, s2 := matchSetsWon(m)

		team1Wins := s1 > s2

		// Pre-compute team-average ELOs at match time for giant-killer.
		var avgT1Before, avgT2Before int
		var hasEloHistory bool
		if eh, errh := q.GetMatchEloBefore(ctx, m.ID); errh == nil && len(eh) > 0 {
			eloByID := make(map[string]int32, len(eh))
			for _, r := range eh {
				eloByID[r.PlayerID] = r.EloBefore
			}
			team1Sum, team1Count := 0, 0
			for _, id := range t1 {
				if v, ok := eloByID[id]; ok {
					team1Sum += int(v)
					team1Count++
				}
			}
			team2Sum, team2Count := 0, 0
			for _, id := range t2 {
				if v, ok := eloByID[id]; ok {
					team2Sum += int(v)
					team2Count++
				}
			}
			if team1Count > 0 && team2Count > 0 {
				avgT1Before = team1Sum / team1Count
				avgT2Before = team2Sum / team2Count
				hasEloHistory = true
			}
		}

		for _, id := range t1 {
			a := get(id)
			a.played++
			a.setsWon += s1
			a.setsLost += s2
			if team1Wins {
				a.wins++
				if hasEloHistory && (avgT2Before-avgT1Before) >= UpsetThreshold {
					a.upsetWins++
				}
			} else {
				a.losses++
			}
		}
		for _, id := range t2 {
			a := get(id)
			a.played++
			a.setsWon += s2
			a.setsLost += s1
			if !team1Wins {
				a.wins++
				if hasEloHistory && (avgT1Before-avgT2Before) >= UpsetThreshold {
					a.upsetWins++
				}
			} else {
				a.losses++
			}
		}
	}

	return agg, nil
}

// GetLeagueRankings returns wins/losses/sets diff per player in the period.
func GetLeagueRankings(
	ctx context.Context, q *db.Queries,
	tableau db.MatchType, from, to time.Time,
) ([]LeagueRanking, error) {
	_, users, err := loadUsersByID(ctx, q)
	if err != nil {
		return nil, err
	}
	agg, err := aggregateMatches(ctx, q, tableau, from, to)
	if err != nil {
		return nil, err
	}

	rankings := make([]LeagueRanking, 0, len(users))
	for _, u := range users {
		a := agg[u.ID]
		if a == nil {
			a = &playerAgg{}
		}
		rankings = append(rankings, LeagueRanking{
			User:     u,
			Wins:     a.wins,
			Losses:   a.losses,
			SetsWon:  a.setsWon,
			SetsLost: a.setsLost,
			SetsDiff: a.setsWon - a.setsLost,
		})
	}

	sort.SliceStable(rankings, func(i, j int) bool {
		if rankings[i].Wins != rankings[j].Wins {
			return rankings[i].Wins > rankings[j].Wins
		}
		if rankings[i].SetsDiff != rankings[j].SetsDiff {
			return rankings[i].SetsDiff > rankings[j].SetsDiff
		}
		return EloFor(rankings[i].User, tableau) > EloFor(rankings[j].User, tableau)
	})
	for i := range rankings {
		rankings[i].Rank = i + 1
	}
	return rankings, nil
}

// GetMatchesPlayedRankings returns the count of matches played per player in the period.
func GetMatchesPlayedRankings(
	ctx context.Context, q *db.Queries,
	tableau db.MatchType, from, to time.Time,
) ([]MatchesPlayedRanking, error) {
	_, users, err := loadUsersByID(ctx, q)
	if err != nil {
		return nil, err
	}
	agg, err := aggregateMatches(ctx, q, tableau, from, to)
	if err != nil {
		return nil, err
	}

	rankings := make([]MatchesPlayedRanking, 0, len(users))
	for _, u := range users {
		a := agg[u.ID]
		played := 0
		if a != nil {
			played = a.played
		}
		rankings = append(rankings, MatchesPlayedRanking{
			User:          u,
			MatchesPlayed: played,
		})
	}

	sort.SliceStable(rankings, func(i, j int) bool {
		if rankings[i].MatchesPlayed != rankings[j].MatchesPlayed {
			return rankings[i].MatchesPlayed > rankings[j].MatchesPlayed
		}
		return EloFor(rankings[i].User, tableau) > EloFor(rankings[j].User, tableau)
	})
	for i := range rankings {
		rankings[i].Rank = i + 1
	}
	return rankings, nil
}

// GetGiantKillerRankings returns the count of upset wins (won against an
// opponent whose ELO at match time was at least UpsetThreshold above mine).
func GetGiantKillerRankings(
	ctx context.Context, q *db.Queries,
	tableau db.MatchType, from, to time.Time,
) ([]GiantKillerRanking, error) {
	_, users, err := loadUsersByID(ctx, q)
	if err != nil {
		return nil, err
	}
	agg, err := aggregateMatches(ctx, q, tableau, from, to)
	if err != nil {
		return nil, err
	}

	rankings := make([]GiantKillerRanking, 0, len(users))
	for _, u := range users {
		a := agg[u.ID]
		count := 0
		if a != nil {
			count = a.upsetWins
		}
		rankings = append(rankings, GiantKillerRanking{
			User:      u,
			UpsetWins: count,
		})
	}

	sort.SliceStable(rankings, func(i, j int) bool {
		if rankings[i].UpsetWins != rankings[j].UpsetWins {
			return rankings[i].UpsetWins > rankings[j].UpsetWins
		}
		return EloFor(rankings[i].User, tableau) > EloFor(rankings[j].User, tableau)
	})
	for i := range rankings {
		rankings[i].Rank = i + 1
	}
	return rankings, nil
}
