package services

import (
	"context"
	"time"

	"github.com/jackc/pgx/v5/pgtype"

	"bap-pulse/db"
)

// MemberSummary is one row of GET /members — the payload powering the mobile
// "Membres" screen. Identity + ELO + monthly performance + monthly W/L/M +
// currently held jerseys. Same building blocks as GetUserProfile, but
// batched across all users instead of fetched per-user.
type MemberSummary struct {
	User        ProfileUser       `json:"user"`
	Tableau     db.MatchType      `json:"tableau"`
	Elo         int32             `json:"elo"`
	Performance MemberPerformance `json:"performance"`
	StatsMonth  MemberStatsMonth  `json:"stats_month"`
	Jerseys     []string          `json:"jerseys"`
}

type MemberPerformance struct {
	Score  int32 `json:"score"`
	Rank   int   `json:"rank"`
	Gain7d int32 `json:"gain_7d"`
}

type MemberStatsMonth struct {
	Matches int `json:"matches"`
	Wins    int `json:"wins"`
	Losses  int `json:"losses"`
}

// ListMembersWithStats returns the full member roster, each with monthly
// performance, monthly W/L/M and currently held jerseys. Reuses the four
// ranking services so the aggregation matches what /rankings/* exposes.
func ListMembersWithStats(
	ctx context.Context, q *db.Queries,
	tableau db.MatchType, from, to time.Time,
) ([]MemberSummary, error) {
	_, users, err := loadUsersByID(ctx, q)
	if err != nil {
		return nil, err
	}

	perfRankings, err := GetPerformanceRankings(ctx, q, tableau, from, to)
	if err != nil {
		return nil, err
	}
	leagueRankings, err := GetLeagueRankings(ctx, q, tableau, from, to)
	if err != nil {
		return nil, err
	}
	matchesPlayedRankings, err := GetMatchesPlayedRankings(ctx, q, tableau, from, to)
	if err != nil {
		return nil, err
	}
	giantKillerRankings, err := GetGiantKillerRankings(ctx, q, tableau, from, to)
	if err != nil {
		return nil, err
	}

	// 7-day perf gain in a single batched query — one row per player.
	now := time.Now()
	gain7dFrom := now.AddDate(0, 0, -7)
	gain7dRows, err := q.SumPerformancePointsByPlayer(ctx, db.SumPerformancePointsByPlayerParams{
		MatchType:   tableau,
		CreatedAt:   pgtype.Timestamptz{Time: gain7dFrom, Valid: true},
		CreatedAt_2: pgtype.Timestamptz{Time: now, Valid: true},
	})
	if err != nil {
		return nil, err
	}
	gain7dByID := make(map[string]int32, len(gain7dRows))
	for _, r := range gain7dRows {
		gain7dByID[r.PlayerID] = r.Points
	}

	out := make([]MemberSummary, 0, len(users))
	for _, u := range users {
		perf := pickPerformance(perfRankings, u.ID)
		league := pickLeague(leagueRankings, u.ID)
		matchesPlayed := pickMatchesPlayed(matchesPlayedRankings, u.ID)
		jerseys := computeJerseys(perfRankings, giantKillerRankings, matchesPlayedRankings, u.ID)

		gender := ""
		if u.Gender.Valid {
			gender = u.Gender.String
		}
		joinedYear := 0
		if u.CreatedAt.Valid {
			joinedYear = u.CreatedAt.Time.Year()
		}

		out = append(out, MemberSummary{
			User: ProfileUser{
				ID:         u.ID,
				FirstName:  u.FirstName,
				LastName:   u.LastName,
				Gender:     gender,
				JoinedYear: joinedYear,
			},
			Tableau: tableau,
			Elo:     EloFor(u, tableau),
			Performance: MemberPerformance{
				Score:  perf.points,
				Rank:   perf.rank,
				Gain7d: gain7dByID[u.ID],
			},
			StatsMonth: MemberStatsMonth{
				Matches: matchesPlayed,
				Wins:    league.wins,
				Losses:  league.losses,
			},
			Jerseys: jerseys,
		})
	}

	return out, nil
}
