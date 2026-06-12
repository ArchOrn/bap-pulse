package handlers

import (
	"errors"
	"strings"

	"github.com/gofiber/fiber/v2"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"

	"bap-pulse/db"
	"bap-pulse/services"
)

type syncRequest struct {
	FirstName     string `json:"first_name"`
	LastName      string `json:"last_name"`
	Nickname      string `json:"nickname"`       // optional handle
	Gender        string `json:"gender"`         // optional, MALE | FEMALE
	FfbadRank     string `json:"ffbad_rank"`     // optional, NC | P12 | ... | N1
	LicenseNumber string `json:"license_number"` // FFBAD licence; matched against the club roster
}

// Sync godoc
//
//	@Summary		Sync user profile
//	@Description	Called after a successful Firebase login. On first login it creates the profile: if the FFBAD licence matches the club roster the account is auto-approved and prefilled (name/gender/rank/ELO from FFBAD), otherwise it is left pending for admin validation. Returns the existing profile on subsequent calls.
//	@Tags			auth
//	@Security		BearerAuth
//	@Accept			json
//	@Produce		json
//	@Param			body	body		syncRequest	true	"Profile fields + FFBAD licence (first login)"
//	@Success		200		{object}	db.User
//	@Success		201		{object}	db.User
//	@Failure		400		{object}	map[string]string
//	@Failure		409		{object}	map[string]string
//	@Failure		500		{object}	map[string]string
//	@Router			/auth/sync [post]
func Sync(pool *pgxpool.Pool) fiber.Handler {
	return func(c *fiber.Ctx) error {
		firebaseUID := c.Locals("firebaseUID").(string)
		firebaseEmail, _ := c.Locals("firebaseEmail").(string)

		q := db.New(pool)

		// User already exists — return immediately.
		user, err := q.GetUserByID(c.Context(), firebaseUID)
		if err == nil {
			return c.JSON(user)
		}

		// First login: create the user profile.
		var req syncRequest
		c.BodyParser(&req) //nolint:errcheck — empty body is valid

		license := strings.TrimSpace(req.LicenseNumber)

		// One Firebase account per licence: reject if it's already claimed.
		if license != "" {
			if _, err := q.GetUserByLicenseNumber(c.Context(), pgtype.Text{String: license, Valid: true}); err == nil {
				return c.Status(fiber.StatusConflict).JSON(fiber.Map{
					"error": "Cette licence est déjà associée à un compte",
				})
			} else if !errors.Is(err, pgx.ErrNoRows) {
				return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
					"error": "Failed to verify licence",
				})
			}
		}

		// Default: self-declared fields, pending validation.
		status := db.UserStatusPending
		firstName, lastName := req.FirstName, req.LastName
		gender, rank := req.Gender, req.FfbadRank
		eloSingles := int32(services.InitialEloFor(rank, gender))
		eloDoubles, eloMixed := eloSingles, eloSingles
		matched := false

		// Match against the club roster synced from the FFBAD API. A hit means
		// the person is a club member → auto-approve and seed from FFBAD data.
		if license != "" {
			entry, err := q.GetRosterEntryByLicense(c.Context(), license)
			if err == nil {
				matched = true
				status = db.UserStatusApproved
				if entry.FirstName != "" {
					firstName = entry.FirstName
				}
				if entry.LastName != "" {
					lastName = entry.LastName
				}
				gender = entry.Gender.String
				rank = entry.RankSingles.String
				eloSingles = int32(services.EloFromCote(coteToInt(entry.CoteSingles), entry.RankSingles.String, gender))
				eloDoubles = int32(services.EloFromCote(coteToInt(entry.CoteDoubles), entry.RankDoubles.String, gender))
				eloMixed = int32(services.EloFromCote(coteToInt(entry.CoteMixed), entry.RankMixed.String, gender))
			} else if !errors.Is(err, pgx.ErrNoRows) {
				return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
					"error": "Failed to verify licence",
				})
			}
		}

		user, err = q.CreateUser(c.Context(), db.CreateUserParams{
			ID:            firebaseUID,
			FirstName:     firstName,
			LastName:      lastName,
			Email:         firebaseEmail,
			Gender:        optionalText(gender),
			FfbadRank:     optionalText(rank),
			EloSingles:    eloSingles,
			EloDoubles:    eloDoubles,
			EloMixed:      eloMixed,
			Status:        status,
			LicenseNumber: optionalText(license),
		})
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
				"error": "Failed to create user profile",
			})
		}

		// Set the nickname if provided (CreateUser doesn't take it).
		if nick := strings.TrimSpace(req.Nickname); nick != "" {
			if u2, err := q.UpdateUser(c.Context(), db.UpdateUserParams{
				ID:        user.ID,
				FirstName: user.FirstName,
				LastName:  user.LastName,
				Email:     user.Email,
				Gender:    user.Gender,
				FfbadRank: user.FfbadRank,
				Nickname:  pgtype.Text{String: nick, Valid: true},
			}); err == nil {
				user = u2
			}
		}

		if matched {
			_ = q.SetRosterMatchedUser(c.Context(), db.SetRosterMatchedUserParams{
				LicenseNumber: license,
				MatchedUserID: pgtype.Text{String: user.ID, Valid: true},
			})
		}

		return c.Status(fiber.StatusCreated).JSON(user)
	}
}

// coteToInt unwraps a nullable FFBAD cote, returning 0 when absent.
func coteToInt(v pgtype.Int4) int {
	if !v.Valid {
		return 0
	}
	return int(v.Int32)
}
