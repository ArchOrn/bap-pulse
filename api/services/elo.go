package services

import "math"

// KFactor returns the ELO K-factor for a player based on the number of matches
// they've already played in the relevant tableau (singles/doubles/mixed).
//
//	< 10  matches → 80 (newcomer, fast convergence)
//	< 30  matches → 40
//	otherwise     → 24
func KFactor(totalMatches int) int {
	switch {
	case totalMatches < 10:
		return 80
	case totalMatches < 30:
		return 40
	default:
		return 24
	}
}

// ExpectedScore returns the expected win probability for player A against player B.
// Standard ELO formula: 1 / (1 + 10^((eloB - eloA) / 400))
func ExpectedScore(eloA, eloB int) float64 {
	return 1.0 / (1.0 + math.Pow(10, float64(eloB-eloA)/400.0))
}

// MarginResult converts a sets score into a normalized result for player/team A.
// Possible inputs (winner has 2 sets):  2-0, 2-1, 1-2, 0-2.
// Outputs:                              1.0, 0.75, 0.25, 0.0.
func MarginResult(setsA, setsB int) float64 {
	margin := float64(setsA-setsB) / 2.0
	return (margin + 1) / 2.0
}

// CalculateEloDelta returns the signed ELO delta for each side after a singles match.
// totalMatchesA/B = matches already played by each player in this tableau (used for K-factor).
func CalculateEloDelta(eloA, eloB, setsA, setsB, totalMatchesA, totalMatchesB int) (int, int) {
	expectedA := ExpectedScore(eloA, eloB)
	expectedB := 1.0 - expectedA

	resultA := MarginResult(setsA, setsB)
	resultB := 1.0 - resultA

	deltaA := int(math.Round(float64(KFactor(totalMatchesA)) * (resultA - expectedA)))
	deltaB := int(math.Round(float64(KFactor(totalMatchesB)) * (resultB - expectedB)))
	return deltaA, deltaB
}

// TeamAverageElo returns the integer mean of the supplied ELO ratings.
func TeamAverageElo(elos ...int) int {
	if len(elos) == 0 {
		return 0
	}
	sum := 0
	for _, e := range elos {
		sum += e
	}
	return sum / len(elos)
}

// CalculateTeamEloDeltas returns one signed delta per player on each team for a
// doubles/mixed match. The expected/result pair is computed against the team
// average ELO; each player's delta then uses *their own* K-factor (based on
// their tableau-specific match count), so a doubles newcomer adjusts faster
// than a veteran teammate.
//
// Returns deltas in the order: team1Player1, team1Player2, team2Player1, team2Player2.
func CalculateTeamEloDeltas(
	avgTeam1, avgTeam2 int,
	setsTeam1, setsTeam2 int,
	t1p1Matches, t1p2Matches, t2p1Matches, t2p2Matches int,
) (int, int, int, int) {
	expectedTeam1 := ExpectedScore(avgTeam1, avgTeam2)
	expectedTeam2 := 1.0 - expectedTeam1

	resultTeam1 := MarginResult(setsTeam1, setsTeam2)
	resultTeam2 := 1.0 - resultTeam1

	diff1 := resultTeam1 - expectedTeam1
	diff2 := resultTeam2 - expectedTeam2

	return int(math.Round(float64(KFactor(t1p1Matches)) * diff1)),
		int(math.Round(float64(KFactor(t1p2Matches)) * diff1)),
		int(math.Round(float64(KFactor(t2p1Matches)) * diff2)),
		int(math.Round(float64(KFactor(t2p2Matches)) * diff2))
}
