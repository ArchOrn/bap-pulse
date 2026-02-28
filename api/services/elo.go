package services

import "math"

const (
	eloKFactor       = 32   // Maximum rating change per match
	eloDefaultRating = 1000
)

// ExpectedScore returns the expected win probability for player A against player B.
// Standard ELO formula: 1 / (1 + 10^((eloB - eloA) / 400))
func ExpectedScore(eloA, eloB int) float64 {
	return 1.0 / (1.0 + math.Pow(10, float64(eloB-eloA)/400.0))
}

// NewElo returns the updated ELO rating for a player after a match.
//
//	actualScore: 1.0 = win, 0.5 = draw, 0.0 = loss
func NewElo(eloPlayer, eloOpponent int, actualScore float64) int {
	expected := ExpectedScore(eloPlayer, eloOpponent)
	return int(math.Round(float64(eloPlayer) + eloKFactor*(actualScore-expected)))
}

// CalculateMatchElo returns the new ELO ratings after a singles match.
// Returns (newEloWinner, newEloLoser).
func CalculateMatchElo(eloWinner, eloLoser int) (int, int) {
	return NewElo(eloWinner, eloLoser, 1.0), NewElo(eloLoser, eloWinner, 0.0)
}

// TeamAverageElo returns the average ELO rating for a team.
func TeamAverageElo(elos ...int) int {
	sum := 0
	for _, e := range elos {
		sum += e
	}
	return sum / len(elos)
}

// CalculateTeamEloDelta returns the ELO delta to apply to each player in a doubles match.
//
// The delta is derived by comparing team average ELOs using the standard formula,
// then the same delta is applied individually to every player on each side.
// Returns (deltaWinners, deltaLosers), both signed.
func CalculateTeamEloDelta(avgEloWinners, avgEloLosers int) (int, int) {
	newWinnersAvg := NewElo(avgEloWinners, avgEloLosers, 1.0)
	newLosersAvg := NewElo(avgEloLosers, avgEloWinners, 0.0)
	return newWinnersAvg - avgEloWinners, newLosersAvg - avgEloLosers
}
