package services

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"

	"bap-pulse/db"
)

// uuidString converts a pgtype.UUID to its canonical 36-char form ("" if null).
func uuidString(id pgtype.UUID) string {
	if !id.Valid {
		return ""
	}
	return uuid.UUID(id.Bytes).String()
}

// UserMatchHistoryEntry is one row of the player's match history, already
// reshaped from the user's perspective (sets ordered mine-vs-opp, elo_change
// signed positive when the user won).
type UserMatchHistoryEntry struct {
	ID         string       `json:"id"`
	PlayedAt   time.Time    `json:"played_at"`
	Tableau    db.MatchType `json:"tableau"`
	Opponent   ProfileUser  `json:"opponent"`
	WonByUser  bool         `json:"won_by_user"`
	EloChange  int32        `json:"elo_change"`
	PerfPoints int32        `json:"perf_points"`
	Sets       []MatchSet   `json:"sets"`
	Validated  bool         `json:"validated"`
}

type MatchSet struct {
	Mine int32 `json:"mine"`
	Opp  int32 `json:"opp"`
}

// GetUserMatchHistory builds the match-history payload for one user, scoped to
// a single tableau (MVP: SINGLES). Sorted by played_at DESC.
func GetUserMatchHistory(
	ctx context.Context, q *db.Queries,
	userID string, tableau db.MatchType,
) ([]UserMatchHistoryEntry, error) {
	playerMatches, err := q.GetPlayerMatches(ctx, userID)
	if err != nil {
		return nil, err
	}
	matches := filterMatchesByTableau(playerMatches, tableau)

	if len(matches) == 0 {
		return []UserMatchHistoryEntry{}, nil
	}

	// elo_history indexed by match_id (UUID string). Walking the user's full
	// elo history once is cheaper than 1 query / match.
	eloRows, err := q.GetUserEloHistory(ctx, userID)
	if err != nil {
		return nil, err
	}
	eloByMatch := make(map[string]db.EloHistory, len(eloRows))
	for _, r := range eloRows {
		if !r.MatchID.Valid {
			continue
		}
		eloByMatch[uuidString(r.MatchID)] = r
	}

	// Resolve each unique opponent once.
	opponentCache := make(map[string]ProfileUser)
	getOpponent := func(id string) (ProfileUser, error) {
		if u, ok := opponentCache[id]; ok {
			return u, nil
		}
		u, err := q.GetUserByID(ctx, id)
		if err != nil {
			return ProfileUser{}, err
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
		opponent := ProfileUser{
			ID:         u.ID,
			FirstName:  u.FirstName,
			LastName:   u.LastName,
			Nickname:   nickname,
			Gender:     gender,
			JoinedYear: joined,
		}
		opponentCache[id] = opponent
		return opponent, nil
	}

	entries := make([]UserMatchHistoryEntry, 0, len(matches))
	for _, m := range matches {
		userInTeam1 := m.Team1Player1ID == userID ||
			(m.Team1Player2ID.Valid && m.Team1Player2ID.String == userID)

		// Singles only for MVP: one opponent per match.
		var opponentID string
		if userInTeam1 {
			opponentID = m.Team2Player1ID
		} else {
			opponentID = m.Team1Player1ID
		}
		opponent, err := getOpponent(opponentID)
		if err != nil {
			return nil, err
		}

		t1Won, t2Won := matchSetsWon(m)
		wonByUser := (userInTeam1 && t1Won > t2Won) || (!userInTeam1 && t2Won > t1Won)

		sets := buildSetsFromUserView(m, userInTeam1)

		var eloChange, perfPoints int32
		if eh, ok := eloByMatch[uuidString(m.ID)]; ok {
			eloChange = eh.EloAfter - eh.EloBefore
			perfPoints = eh.PerformancePoints
		}

		playedAt := time.Time{}
		if m.PlayedAt.Valid {
			playedAt = m.PlayedAt.Time
		}

		entries = append(entries, UserMatchHistoryEntry{
			ID:         uuidString(m.ID),
			PlayedAt:   playedAt,
			Tableau:    m.MatchType,
			Opponent:   opponent,
			WonByUser:  wonByUser,
			EloChange:  eloChange,
			PerfPoints: perfPoints,
			Sets:       sets,
			Validated:  m.Validated,
		})
	}

	return entries, nil
}

// buildSetsFromUserView returns the played sets from the user's perspective.
// Set 3 is only included when both team scores are present (Valid).
func buildSetsFromUserView(m db.Match, userInTeam1 bool) []MatchSet {
	sets := make([]MatchSet, 0, 3)
	add := func(team1, team2 int32) {
		if userInTeam1 {
			sets = append(sets, MatchSet{Mine: team1, Opp: team2})
		} else {
			sets = append(sets, MatchSet{Mine: team2, Opp: team1})
		}
	}
	add(m.Set1Team1, m.Set1Team2)
	add(m.Set2Team1, m.Set2Team2)
	if m.Set3Team1.Valid && m.Set3Team2.Valid {
		add(m.Set3Team1.Int32, m.Set3Team2.Int32)
	}
	return sets
}
