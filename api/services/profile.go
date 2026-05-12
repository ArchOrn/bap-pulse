package services

import (
	"context"
	"time"

	"github.com/jackc/pgx/v5/pgtype"

	"bap-pulse/db"
)

// ----- Types -----

// UserProfile is the aggregated payload powering the mobile profile screen.
// Singles-only for the MVP (the tableau is fixed by the caller).
type UserProfile struct {
	User                  ProfileUser           `json:"user"`
	Tableau               db.MatchType          `json:"tableau"`
	Elo                   int32                 `json:"elo"`
	Performance           ProfilePerformance    `json:"performance"`
	StatsMonth            ProfileStatsMonth     `json:"stats_month"`
	Jerseys               []string              `json:"jerseys"`
	YellowJerseyThreshold int32                 `json:"yellow_jersey_threshold"`
	PerfHistory           []ProfileHistoryPoint `json:"perf_history"`
	HeadToHead            ProfileHeadToHead     `json:"head_to_head"`
}

type ProfileUser struct {
	ID         string `json:"id"`
	FirstName  string `json:"first_name"`
	LastName   string `json:"last_name"`
	Nickname   string `json:"nickname,omitempty"`
	Gender     string `json:"gender,omitempty"`
	JoinedYear int    `json:"joined_year"`
}

type ProfilePerformance struct {
	Score  int32 `json:"score"`
	Rank   int   `json:"rank"`
	Gain7d int32 `json:"gain_7d"`
}

type ProfileStatsMonth struct {
	Matches   int `json:"matches"`
	Wins      int `json:"wins"`
	Losses    int `json:"losses"`
	UpsetWins int `json:"upset_wins"`
	Streak    int `json:"streak"`
}

type ProfileHistoryPoint struct {
	Date  string `json:"date"`
	Value int    `json:"value"`
}

type ProfileHeadToHead struct {
	Nemesis        *ProfileOpponent `json:"nemesis"`
	FavoriteVictim *ProfileOpponent `json:"favorite_victim"`
}

type ProfileOpponent struct {
	User   ProfileUser `json:"user"`
	Wins   int         `json:"wins"`
	Losses int         `json:"losses"`
}

// ----- Public API -----

// GetUserProfile builds the aggregated profile payload for one user. The MVP
// targets a single tableau (callers pass SINGLES); the structure is wide enough
// to support a tableau switcher later.
func GetUserProfile(
	ctx context.Context, q *db.Queries,
	userID string, tableau db.MatchType,
) (*UserProfile, error) {
	user, err := q.GetUserByID(ctx, userID)
	if err != nil {
		return nil, err
	}

	now := time.Now()
	monthStart, monthEnd := CurrentMonthRange(now)

	perfRankings, err := GetPerformanceRankings(ctx, q, tableau, monthStart, monthEnd)
	if err != nil {
		return nil, err
	}
	leagueRankings, err := GetLeagueRankings(ctx, q, tableau, monthStart, monthEnd)
	if err != nil {
		return nil, err
	}
	matchesPlayedRankings, err := GetMatchesPlayedRankings(ctx, q, tableau, monthStart, monthEnd)
	if err != nil {
		return nil, err
	}
	giantKillerRankings, err := GetGiantKillerRankings(ctx, q, tableau, monthStart, monthEnd)
	if err != nil {
		return nil, err
	}

	perf := pickPerformance(perfRankings, userID)
	league := pickLeague(leagueRankings, userID)
	matchesPlayed := pickMatchesPlayed(matchesPlayedRankings, userID)
	upset := pickGiantKiller(giantKillerRankings, userID)

	gain7dFrom := now.AddDate(0, 0, -7)
	gain7d, err := q.SumPerformancePointsByPlayerInRange(ctx, db.SumPerformancePointsByPlayerInRangeParams{
		PlayerID:    userID,
		MatchType:   tableau,
		CreatedAt:   pgtype.Timestamptz{Time: gain7dFrom, Valid: true},
		CreatedAt_2: pgtype.Timestamptz{Time: now, Valid: true},
	})
	if err != nil {
		return nil, err
	}

	history, err := buildPerfHistory(ctx, q, userID, tableau, monthStart, now)
	if err != nil {
		return nil, err
	}

	playerMatches, err := q.GetPlayerMatches(ctx, userID)
	if err != nil {
		return nil, err
	}
	tableauMatches := filterMatchesByTableau(playerMatches, tableau)

	// Streak is rendered alongside monthly W/L/M in the UI, so scope it to
	// the same window. Otherwise a lifetime win-streak can appear next to
	// "0/0 this month" — confusing.
	periodMatches := filterMatchesByPeriod(tableauMatches, monthStart, monthEnd)
	streak := computeStreak(periodMatches, userID)
	headToHead, err := computeHeadToHead(ctx, q, tableauMatches, userID)
	if err != nil {
		return nil, err
	}

	jerseys := computeJerseys(perfRankings, giantKillerRankings, matchesPlayedRankings, userID)

	yellowThreshold := int32(0)
	if len(perfRankings) > 0 {
		yellowThreshold = perfRankings[0].Points
	}

	gender := ""
	if user.Gender.Valid {
		gender = user.Gender.String
	}
	nickname := ""
	if user.Nickname.Valid {
		nickname = user.Nickname.String
	}
	joinedYear := 0
	if user.CreatedAt.Valid {
		joinedYear = user.CreatedAt.Time.Year()
	}

	return &UserProfile{
		User: ProfileUser{
			ID:         user.ID,
			FirstName:  user.FirstName,
			LastName:   user.LastName,
			Nickname:   nickname,
			Gender:     gender,
			JoinedYear: joinedYear,
		},
		Tableau: tableau,
		Elo:     EloFor(user, tableau),
		Performance: ProfilePerformance{
			Score:  perf.points,
			Rank:   perf.rank,
			Gain7d: gain7d,
		},
		StatsMonth: ProfileStatsMonth{
			Matches:   matchesPlayed,
			Wins:      league.wins,
			Losses:    league.losses,
			UpsetWins: upset,
			Streak:    streak,
		},
		Jerseys:               jerseys,
		YellowJerseyThreshold: yellowThreshold,
		PerfHistory:           history,
		HeadToHead:            headToHead,
	}, nil
}

// ----- Pickers from existing rankings -----

type perfPick struct {
	points int32
	rank   int
}

func pickPerformance(rankings []PerformanceRanking, userID string) perfPick {
	for _, r := range rankings {
		if r.User.ID == userID {
			return perfPick{points: r.Points, rank: r.Rank}
		}
	}
	return perfPick{}
}

type leaguePick struct {
	wins   int
	losses int
}

func pickLeague(rankings []LeagueRanking, userID string) leaguePick {
	for _, r := range rankings {
		if r.User.ID == userID {
			return leaguePick{wins: r.Wins, losses: r.Losses}
		}
	}
	return leaguePick{}
}

func pickMatchesPlayed(rankings []MatchesPlayedRanking, userID string) int {
	for _, r := range rankings {
		if r.User.ID == userID {
			return r.MatchesPlayed
		}
	}
	return 0
}

func pickGiantKiller(rankings []GiantKillerRanking, userID string) int {
	for _, r := range rankings {
		if r.User.ID == userID {
			return r.UpsetWins
		}
	}
	return 0
}

// ----- Jerseys held -----

// computeJerseys returns the slugs of jerseys the user holds right now. A user
// holds a jersey when they're rank #1 in the corresponding ranking AND the
// underlying metric is non-zero (otherwise the jersey "leader" is just an
// alphabetical/tie-breaker artifact, not a real holder).
//
// Green jersey ("dernière semaine du mois") is intentionally out of scope for
// the MVP — it requires its own date-window query.
func computeJerseys(
	perf []PerformanceRanking,
	giantKiller []GiantKillerRanking,
	matchesPlayed []MatchesPlayedRanking,
	userID string,
) []string {
	jerseys := []string{}
	if len(perf) > 0 && perf[0].User.ID == userID && perf[0].Points > 0 {
		jerseys = append(jerseys, "yellow")
	}
	if len(giantKiller) > 0 && giantKiller[0].User.ID == userID && giantKiller[0].UpsetWins > 0 {
		jerseys = append(jerseys, "polka")
	}
	if len(matchesPlayed) > 0 && matchesPlayed[0].User.ID == userID && matchesPlayed[0].MatchesPlayed > 0 {
		jerseys = append(jerseys, "fight")
	}
	return jerseys
}

// ----- Performance history (cumul quotidien) -----

// buildPerfHistory returns one point per day from monthStart (inclusive) to now
// (inclusive), with the running cumulative perf-points score for that day.
// Empty days repeat the previous day's cumul (the public score never decreases).
func buildPerfHistory(
	ctx context.Context, q *db.Queries,
	userID string, tableau db.MatchType,
	monthStart, now time.Time,
) ([]ProfileHistoryPoint, error) {
	rows, err := q.GetDailyPerformancePointsByPlayer(ctx, db.GetDailyPerformancePointsByPlayerParams{
		PlayerID:    userID,
		MatchType:   tableau,
		CreatedAt:   pgtype.Timestamptz{Time: monthStart, Valid: true},
		CreatedAt_2: pgtype.Timestamptz{Time: now.Add(24 * time.Hour), Valid: true},
	})
	if err != nil {
		return nil, err
	}

	pointsByDay := make(map[string]int, len(rows))
	for _, r := range rows {
		if !r.Day.Valid {
			continue
		}
		key := r.Day.Time.UTC().Format("2006-01-02")
		pointsByDay[key] = int(r.Points)
	}

	startUTC := time.Date(monthStart.Year(), monthStart.Month(), monthStart.Day(), 0, 0, 0, 0, time.UTC)
	endUTC := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, time.UTC)

	history := []ProfileHistoryPoint{}
	cumul := 0
	for d := startUTC; !d.After(endUTC); d = d.AddDate(0, 0, 1) {
		key := d.Format("2006-01-02")
		cumul += pointsByDay[key]
		history = append(history, ProfileHistoryPoint{Date: key, Value: cumul})
	}
	return history, nil
}

// ----- Streak -----

// filterMatchesByTableau keeps only the matches matching the requested tableau.
func filterMatchesByTableau(matches []db.Match, tableau db.MatchType) []db.Match {
	out := make([]db.Match, 0, len(matches))
	for _, m := range matches {
		if m.MatchType == tableau {
			out = append(out, m)
		}
	}
	return out
}

// filterMatchesByPeriod keeps only matches whose played_at falls in [from, to).
// Order is preserved (so a DESC input stays DESC).
func filterMatchesByPeriod(matches []db.Match, from, to time.Time) []db.Match {
	out := make([]db.Match, 0, len(matches))
	for _, m := range matches {
		if !m.PlayedAt.Valid {
			continue
		}
		t := m.PlayedAt.Time
		if !t.Before(from) && t.Before(to) {
			out = append(out, m)
		}
	}
	return out
}

// computeStreak counts the player's current consecutive wins, walking matches
// from the most recent backwards. `matches` is expected to already be sorted by
// played_at DESC (GetPlayerMatches guarantees that).
func computeStreak(matches []db.Match, userID string) int {
	streak := 0
	for _, m := range matches {
		userInTeam1 := m.Team1Player1ID == userID || (m.Team1Player2ID.Valid && m.Team1Player2ID.String == userID)
		userInTeam2 := m.Team2Player1ID == userID || (m.Team2Player2ID.Valid && m.Team2Player2ID.String == userID)
		if !userInTeam1 && !userInTeam2 {
			continue
		}
		t1, t2 := matchSetsWon(m)
		userWon := (userInTeam1 && t1 > t2) || (userInTeam2 && t2 > t1)
		if !userWon {
			break
		}
		streak++
	}
	return streak
}

// ----- Head-to-head -----

// computeHeadToHead aggregates per-opponent W/L lifetime over `matches` and
// returns the user's worst (nemesis) and best (favorite victim) opponents.
//
// Nemesis = lowest win rate (then most losses). Favorite victim = highest win
// rate (then most wins). We require ≥ 2 matchups against the same opponent to
// avoid noisy single-match outliers.
//
// Singles is the only supported tableau today, so each match has exactly one
// opponent. For doubles/mixed callers, we ignore matches with two opponents
// (the team1Player2 / team2Player2 slots) — they don't appear in singles.
func computeHeadToHead(
	ctx context.Context, q *db.Queries,
	matches []db.Match, userID string,
) (ProfileHeadToHead, error) {
	const minMatches = 2

	type record struct {
		wins   int
		losses int
	}
	stats := make(map[string]*record)

	for _, m := range matches {
		userInTeam1 := m.Team1Player1ID == userID || (m.Team1Player2ID.Valid && m.Team1Player2ID.String == userID)
		userInTeam2 := m.Team2Player1ID == userID || (m.Team2Player2ID.Valid && m.Team2Player2ID.String == userID)
		if !userInTeam1 && !userInTeam2 {
			continue
		}

		var opponentIDs []string
		if userInTeam1 {
			opponentIDs = append(opponentIDs, m.Team2Player1ID)
			if m.Team2Player2ID.Valid {
				opponentIDs = append(opponentIDs, m.Team2Player2ID.String)
			}
		} else {
			opponentIDs = append(opponentIDs, m.Team1Player1ID)
			if m.Team1Player2ID.Valid {
				opponentIDs = append(opponentIDs, m.Team1Player2ID.String)
			}
		}

		// MVP: only handle 1-vs-1. Skip doubles/mixed for head-to-head.
		if len(opponentIDs) != 1 {
			continue
		}

		t1, t2 := matchSetsWon(m)
		userWon := (userInTeam1 && t1 > t2) || (userInTeam2 && t2 > t1)

		oppID := opponentIDs[0]
		r, ok := stats[oppID]
		if !ok {
			r = &record{}
			stats[oppID] = r
		}
		if userWon {
			r.wins++
		} else {
			r.losses++
		}
	}

	type entry struct {
		opponentID string
		wins       int
		losses     int
		ratio      float64
	}
	var nemesis, favorite *entry
	for id, r := range stats {
		total := r.wins + r.losses
		if total < minMatches {
			continue
		}
		e := entry{
			opponentID: id,
			wins:       r.wins,
			losses:     r.losses,
			ratio:      float64(r.wins) / float64(total),
		}
		if nemesis == nil ||
			e.ratio < nemesis.ratio ||
			(e.ratio == nemesis.ratio && e.losses > nemesis.losses) {
			cp := e
			nemesis = &cp
		}
		if favorite == nil ||
			e.ratio > favorite.ratio ||
			(e.ratio == favorite.ratio && e.wins > favorite.wins) {
			cp := e
			favorite = &cp
		}
	}

	resolve := func(e *entry) (*ProfileOpponent, error) {
		u, err := q.GetUserByID(ctx, e.opponentID)
		if err != nil {
			return nil, err
		}
		joined := 0
		if u.CreatedAt.Valid {
			joined = u.CreatedAt.Time.Year()
		}
		gender := ""
		if u.Gender.Valid {
			gender = u.Gender.String
		}
		nickname := ""
		if u.Nickname.Valid {
			nickname = u.Nickname.String
		}
		return &ProfileOpponent{
			User: ProfileUser{
				ID:         u.ID,
				FirstName:  u.FirstName,
				LastName:   u.LastName,
				Nickname:   nickname,
				Gender:     gender,
				JoinedYear: joined,
			},
			Wins:   e.wins,
			Losses: e.losses,
		}, nil
	}

	out := ProfileHeadToHead{}
	if nemesis != nil {
		opp, err := resolve(nemesis)
		if err != nil {
			return ProfileHeadToHead{}, err
		}
		out.Nemesis = opp
	}
	// If nemesis and favorite are the same opponent, only show nemesis (the
	// negative read is more informative; favorite-victim stays nil).
	if favorite != nil && (nemesis == nil || favorite.opponentID != nemesis.opponentID) {
		opp, err := resolve(favorite)
		if err != nil {
			return ProfileHeadToHead{}, err
		}
		out.FavoriteVictim = opp
	}

	return out, nil
}
