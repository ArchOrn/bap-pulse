package services

import (
	"context"

	"bap-pulse/db"
)

type PlayerRanking struct {
	Rank   int
	Player db.Player
}

// GetRankings returns players sorted by descending ELO with their rank position.
func GetRankings(ctx context.Context, q *db.Queries) ([]PlayerRanking, error) {
	players, err := q.ListPlayers(ctx)
	if err != nil {
		return nil, err
	}

	rankings := make([]PlayerRanking, len(players))
	for i, p := range players {
		rankings[i] = PlayerRanking{
			Rank:   i + 1,
			Player: p,
		}
	}
	return rankings, nil
}
