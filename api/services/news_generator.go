package services

import (
	"context"
	"fmt"
	"strings"

	"github.com/jackc/pgx/v5/pgtype"

	"bap-pulse/db"
)

// matchPlayer aggregates everything we need from a match participant to write
// a news item: identity (for the first-name shown in the title) and per-match
// ELO + performance points (for the body).
type matchPlayer struct {
	user      db.User
	eloBefore int32
	eloAfter  int32
	perfPts   int32
}

// GenerateMatchNews creates a news item summarizing a freshly recorded match.
// It reads the elo_history rows tied to the match to know each player's
// before/after ratings, then formats a Markdown title (and body for the detail
// page) that mirrors the inline rich-text style used in the home pulse feed.
//
// Best-effort: callers should log errors but not fail the match flow.
func GenerateMatchNews(ctx context.Context, q *db.Queries, match db.Match) error {
	historyRows, err := q.GetMatchEloHistory(ctx, match.ID)
	if err != nil {
		return fmt.Errorf("read elo history: %w", err)
	}
	if len(historyRows) == 0 {
		return fmt.Errorf("no elo history for match")
	}

	infoByID := make(map[string]matchPlayer, len(historyRows))
	for _, row := range historyRows {
		user, err := q.GetUserByID(ctx, row.PlayerID)
		if err != nil {
			return fmt.Errorf("get user %s: %w", row.PlayerID, err)
		}
		infoByID[row.PlayerID] = matchPlayer{
			user:      user,
			eloBefore: row.EloBefore,
			eloAfter:  row.EloAfter,
			perfPts:   row.PerformancePoints,
		}
	}

	team1IDs := []string{match.Team1Player1ID}
	if match.Team1Player2ID.Valid {
		team1IDs = append(team1IDs, match.Team1Player2ID.String)
	}
	team2IDs := []string{match.Team2Player1ID}
	if match.Team2Player2ID.Valid {
		team2IDs = append(team2IDs, match.Team2Player2ID.String)
	}

	team1, team2 := []matchPlayer{}, []matchPlayer{}
	for _, id := range team1IDs {
		if p, ok := infoByID[id]; ok {
			team1 = append(team1, p)
		}
	}
	for _, id := range team2IDs {
		if p, ok := infoByID[id]; ok {
			team2 = append(team2, p)
		}
	}
	if len(team1) == 0 || len(team2) == 0 {
		return fmt.Errorf("missing elo history for one team")
	}

	setsT1, setsT2 := matchSetsWon(match)
	winners, losers := team1, team2
	team1Won := setsT1 > setsT2
	if !team1Won {
		winners, losers = team2, team1
	}

	avgWinnersBefore := averageEloBefore(winners)
	avgLosersBefore := averageEloBefore(losers)
	isUpset := avgWinnersBefore < avgLosersBefore

	scoreLine := formatScore(match, team1Won)

	winnersLabel := joinPlayers(winners)
	losersLabel := joinPlayers(losers)

	emoji := "🏆"
	verb := "bat"
	if len(winners) > 1 {
		verb = "battent"
	}
	title := fmt.Sprintf("%s %s %s %s", winnersLabel, verb, losersLabel, scoreLine)

	if isUpset {
		emoji = "🎯"
		surpriseVerb := "crée la surprise"
		if len(winners) > 1 {
			surpriseVerb = "créent la surprise"
		}
		title = fmt.Sprintf("%s %s face à %s", winnersLabel, surpriseVerb, losersLabel)
	}

	body := buildBody(match, winners, losers, scoreLine, isUpset)

	_, err = q.CreateNews(ctx, db.CreateNewsParams{
		Emoji:     emoji,
		Title:     title,
		Body:      pgtype.Text{String: body, Valid: true},
		Source:    "AUTO_MATCH",
		MatchID:   match.ID,
		CreatedBy: pgtype.Text{},
	})
	if err != nil {
		return fmt.Errorf("create news: %w", err)
	}
	return nil
}

func formatScore(m db.Match, team1Won bool) string {
	type set struct{ a, b int32 }
	sets := []set{
		{m.Set1Team1, m.Set1Team2},
		{m.Set2Team1, m.Set2Team2},
	}
	if m.Set3Team1.Valid && m.Set3Team2.Valid {
		sets = append(sets, set{m.Set3Team1.Int32, m.Set3Team2.Int32})
	}
	parts := make([]string, 0, len(sets))
	for _, s := range sets {
		// Render from the winners' perspective so the bigger number is always first.
		left, right := s.a, s.b
		if !team1Won {
			left, right = s.b, s.a
		}
		parts = append(parts, fmt.Sprintf("%d-%d", left, right))
	}
	return strings.Join(parts, ", ")
}

func averageEloBefore(team []matchPlayer) float64 {
	if len(team) == 0 {
		return 0
	}
	var sum int32
	for _, p := range team {
		sum += p.eloBefore
	}
	return float64(sum) / float64(len(team))
}

func joinPlayers(team []matchPlayer) string {
	names := make([]string, 0, len(team))
	for _, p := range team {
		names = append(names, fmt.Sprintf("**%s**", p.user.FirstName))
	}
	switch len(names) {
	case 0:
		return ""
	case 1:
		return names[0]
	case 2:
		return names[0] + " & " + names[1]
	default:
		return strings.Join(names, ", ")
	}
}

func buildBody(m db.Match, winners, losers []matchPlayer, scoreLine string, isUpset bool) string {
	var b strings.Builder

	if isUpset {
		fmt.Fprintf(&b, "Score : **%s**\n\n", scoreLine)
	} else {
		fmt.Fprintf(&b, "Score final : **%s**\n\n", scoreLine)
	}

	b.WriteString("ELO :\n")
	for _, p := range winners {
		fmt.Fprintf(&b, "- **%s** %s%d\n", p.user.FirstName, signed(p.eloAfter-p.eloBefore), p.eloAfter-p.eloBefore)
	}
	for _, p := range losers {
		fmt.Fprintf(&b, "- **%s** %s%d\n", p.user.FirstName, signed(p.eloAfter-p.eloBefore), p.eloAfter-p.eloBefore)
	}

	totalPerf := int32(0)
	for _, p := range winners {
		totalPerf += p.perfPts
	}
	if totalPerf > 0 {
		b.WriteString("\nPerformance gagnée :\n")
		for _, p := range winners {
			fmt.Fprintf(&b, "- **%s** +%d pts\n", p.user.FirstName, p.perfPts)
		}
	}

	tableau := strings.ToLower(string(m.MatchType))
	switch m.MatchType {
	case db.MatchTypeSINGLES:
		tableau = "simple"
	case db.MatchTypeDOUBLES:
		tableau = "double"
	case db.MatchTypeMIXED:
		tableau = "mixte"
	}
	fmt.Fprintf(&b, "\n*Match en %s.*", tableau)

	return b.String()
}

// signed returns the leading character for a signed delta. We always print the
// number too — Go's %+d would also work, but we wrap for the negative case
// where we don't want an extra minus.
func signed(v int32) string {
	if v >= 0 {
		return "+"
	}
	return ""
}
