package services

import (
	"context"

	"bap-pulse/db"
)

type UserRanking struct {
	Rank int
	User db.User
}

// GetRankings returns users sorted by descending ELO with their rank position.
func GetRankings(ctx context.Context, q *db.Queries) ([]UserRanking, error) {
	users, err := q.ListUsers(ctx)
	if err != nil {
		return nil, err
	}

	rankings := make([]UserRanking, len(users))
	for i, u := range users {
		rankings[i] = UserRanking{
			Rank: i + 1,
			User: u,
		}
	}
	return rankings, nil
}
