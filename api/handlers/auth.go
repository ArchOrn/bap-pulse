package handlers

import (
	"github.com/gofiber/fiber/v2"
	"github.com/jackc/pgx/v5/pgxpool"

	"bap-pulse/db"
	"bap-pulse/services"
)

type syncRequest struct {
	FirstName string `json:"first_name"`
	LastName  string `json:"last_name"`
	Gender    string `json:"gender"`     // optional, MALE | FEMALE
	FfbadRank string `json:"ffbad_rank"` // optional, NC | P12 | ... | N1
}

// Sync godoc
//
//	@Summary		Sync user profile
//	@Description	Called after a successful Firebase login. Creates the user profile on first login, or returns the existing one.
//	@Tags			auth
//	@Security		BearerAuth
//	@Accept			json
//	@Produce		json
//	@Param			body	body		syncRequest	true	"User first and last name (required on first login)"
//	@Success		200		{object}	db.User
//	@Success		201		{object}	db.User
//	@Failure		400		{object}	map[string]string
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

		// First login: create the user profile. first_name/last_name are optional here
		// and can be updated later via PUT /users/:id.
		var req syncRequest
		c.BodyParser(&req) //nolint:errcheck — empty body is valid

		initial := int32(services.InitialEloFor(req.FfbadRank, req.Gender))
		user, err = q.CreateUser(c.Context(), db.CreateUserParams{
			ID:         firebaseUID,
			FirstName:  req.FirstName,
			LastName:   req.LastName,
			Email:      firebaseEmail,
			Gender:     optionalText(req.Gender),
			FfbadRank:  optionalText(req.FfbadRank),
			EloSingles: initial,
			EloDoubles: initial,
			EloMixed:   initial,
		})
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
				"error": "Failed to create user profile",
			})
		}

		return c.Status(fiber.StatusCreated).JSON(user)
	}
}
