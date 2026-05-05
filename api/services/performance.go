package services

import "math"

const (
	// PerfBase is the per-match base value for the performance ranking formula.
	PerfBase = 10
	// PerfFloor is the guaranteed minimum points awarded per played match.
	PerfFloor = 5
	// UpsetThreshold is the minimum opponent ELO advantage required for a win
	// to count toward the giant-killer ranking.
	UpsetThreshold = 100
)

// multPerf returns the performance multiplier for a sets outcome.
//
//	0-2 → 0.0   (loss without taking a set)
//	1-2 → 0.6
//	2-1 → 1.5
//	2-0 → 2.0
func multPerf(mySets, oppSets int) float64 {
	switch {
	case mySets == 0 && oppSets == 2:
		return 0.0
	case mySets == 1 && oppSets == 2:
		return 0.6
	case mySets == 2 && oppSets == 1:
		return 1.5
	case mySets == 2 && oppSets == 0:
		return 2.0
	}
	return 0
}

// multDifficulty returns the difficulty multiplier based on the ELO gap.
// `eloDiff` is opponent_elo - my_elo (positive ⇒ stronger opponent).
func multDifficulty(eloDiff int) float64 {
	switch {
	case eloDiff < -200:
		return 0.5
	case eloDiff < 0:
		return 0.8
	case eloDiff < 100:
		return 1.0
	case eloDiff < 200:
		return 1.4
	default:
		return 2.0
	}
}

// CalculatePerformancePoints computes the points awarded for the performance
// (yellow-jersey) ranking after a match. The minimum is PerfFloor — every
// played match guarantees at least that many points, even a 0-2 loss.
//
// In doubles/mixed, callers should pass team-average ELOs for myElo/oppElo so
// every member of a team receives the same award.
func CalculatePerformancePoints(myElo, oppElo, mySets, oppSets int) int {
	raw := math.Floor(PerfBase * multPerf(mySets, oppSets) * multDifficulty(oppElo-myElo))
	if int(raw) < PerfFloor {
		return PerfFloor
	}
	return int(raw)
}
