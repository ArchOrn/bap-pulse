package services

import (
	"context"
	"errors"
	"fmt"
	"log"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"

	"bap-pulse/db"
)

// RosterSyncResult summarizes a roster sync run (returned to the admin UI).
type RosterSyncResult struct {
	Fetched          int      `json:"fetched"`
	Upserted         int      `json:"upserted"`
	AutoApproved     int      `json:"auto_approved"`
	SkippedAnonymous int      `json:"skipped_anonymous"`
	Errors           []string `json:"errors"`
}

// SyncRoster fetches the full club roster from the FFBAD API and upserts it into
// club_roster. Any pending user already holding a synced licence is auto-approved
// and seeded with the FFBAD cote-based ELO (back-match). The whole upsert runs in
// a single transaction so a mid-stream failure leaves the previous roster intact.
func SyncRoster(ctx context.Context, pool *pgxpool.Pool, client *FFBadClient) (RosterSyncResult, error) {
	var result RosterSyncResult

	players, err := client.FetchClubRoster(ctx)
	if err != nil {
		return result, err
	}
	result.Fetched = len(players)

	tx, err := pool.Begin(ctx)
	if err != nil {
		return result, err
	}
	defer tx.Rollback(ctx) //nolint:errcheck — no-op after a successful Commit

	qtx := db.New(tx)

	for _, p := range players {
		// Members who opted out of public FFBAD data are not stored. They can
		// still register: their licence won't match → pending → manual admin
		// validation. Clean up any stale entry from when they were public.
		if !p.IsDataPublic {
			result.SkippedAnonymous++
			if err := qtx.DeleteRosterEntry(ctx, p.License); err != nil {
				result.Errors = append(result.Errors, fmt.Sprintf("%s delete: %v", p.License, err))
			}
			continue
		}

		entry, err := qtx.UpsertRosterEntry(ctx, db.UpsertRosterEntryParams{
			LicenseNumber: p.License,
			PerID:         optText(p.PerID),
			FirstName:     p.FirstName,
			LastName:      p.LastName,
			Gender:        optText(p.Gender),
			RankSingles:   optText(p.RankSingles),
			RankDoubles:   optText(p.RankDoubles),
			RankMixed:     optText(p.RankMixed),
			CoteSingles:   optInt4(p.CoteSingles),
			CoteDoubles:   optInt4(p.CoteDoubles),
			CoteMixed:     optInt4(p.CoteMixed),
			IsDataPublic:  p.IsDataPublic,
		})
		if err != nil {
			result.Errors = append(result.Errors, fmt.Sprintf("%s: %v", p.License, err))
			continue
		}
		result.Upserted++

		// Back-match: a pending user who registered before this licence appeared
		// in the roster gets auto-approved now.
		user, err := qtx.GetUserByLicenseNumber(ctx, optText(p.License))
		if err != nil {
			if !errors.Is(err, pgx.ErrNoRows) {
				result.Errors = append(result.Errors, fmt.Sprintf("%s lookup: %v", p.License, err))
			}
			continue
		}
		if user.Status != db.UserStatusPending {
			continue
		}

		if _, err := qtx.ApproveUserFromRoster(ctx, db.ApproveUserFromRosterParams{
			ID:         user.ID,
			Gender:     optText(p.Gender),
			FfbadRank:  optText(p.RankSingles),
			EloSingles: int32(EloFromCote(p.CoteSingles, p.RankSingles, p.Gender)),
			EloDoubles: int32(EloFromCote(p.CoteDoubles, p.RankDoubles, p.Gender)),
			EloMixed:   int32(EloFromCote(p.CoteMixed, p.RankMixed, p.Gender)),
		}); err != nil {
			result.Errors = append(result.Errors, fmt.Sprintf("%s approve: %v", p.License, err))
			continue
		}
		if err := qtx.SetRosterMatchedUser(ctx, db.SetRosterMatchedUserParams{
			LicenseNumber: entry.LicenseNumber,
			MatchedUserID: optText(user.ID),
		}); err != nil {
			result.Errors = append(result.Errors, fmt.Sprintf("%s match: %v", p.License, err))
			continue
		}
		result.AutoApproved++
	}

	if err := tx.Commit(ctx); err != nil {
		return result, err
	}
	return result, nil
}

// StartWeeklyRosterSync launches a goroutine that runs SyncRoster every Thursday
// at 06:00 local time (FFBAD recomputes rankings on Thursdays). It is a no-op
// when the FFBAD client is disabled.
func StartWeeklyRosterSync(pool *pgxpool.Pool, client *FFBadClient) {
	if !client.Enabled() {
		log.Println("FFBAD roster sync disabled (FFBAD_CLUB_TOKEN unset)")
		return
	}
	go func() {
		for {
			wait := durationUntilNextThursday6am(time.Now())
			log.Printf("Next FFBAD roster sync in %s", wait.Truncate(time.Minute))
			time.Sleep(wait)

			ctx, cancel := context.WithTimeout(context.Background(), 2*time.Minute)
			res, err := SyncRoster(ctx, pool, client)
			cancel()
			if err != nil {
				log.Printf("Weekly FFBAD roster sync failed: %v", err)
			} else {
				log.Printf("Weekly FFBAD roster sync: fetched=%d upserted=%d auto_approved=%d skipped_anonymous=%d errors=%d",
					res.Fetched, res.Upserted, res.AutoApproved, res.SkippedAnonymous, len(res.Errors))
			}
		}
	}()
}

// durationUntilNextThursday6am returns the time until the next Thursday 06:00.
func durationUntilNextThursday6am(now time.Time) time.Duration {
	next := time.Date(now.Year(), now.Month(), now.Day(), 6, 0, 0, 0, now.Location())
	daysUntilThursday := (int(time.Thursday) - int(now.Weekday()) + 7) % 7
	next = next.AddDate(0, 0, daysUntilThursday)
	if !next.After(now) {
		next = next.AddDate(0, 0, 7)
	}
	return next.Sub(now)
}

func optText(s string) pgtype.Text {
	if s == "" {
		return pgtype.Text{}
	}
	return pgtype.Text{String: s, Valid: true}
}

func optInt4(n int) pgtype.Int4 {
	if n == 0 {
		return pgtype.Int4{}
	}
	return pgtype.Int4{Int32: int32(n), Valid: true}
}
