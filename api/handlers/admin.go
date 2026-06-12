package handlers

import (
	"crypto/rand"
	"encoding/base64"
	"fmt"

	firebaseauth "firebase.google.com/go/v4/auth"
	"github.com/gofiber/fiber/v2"
	"github.com/jackc/pgx/v5/pgxpool"

	"bap-pulse/db"
	"bap-pulse/services"
)

type inviteRequest struct {
	FirstName string `json:"first_name"`
	LastName  string `json:"last_name"`
	Email     string `json:"email"`
}

type inviteResponse struct {
	User         db.User `json:"user"`
	TempPassword string  `json:"temp_password"`
}

type setRoleRequest struct {
	Admin bool `json:"admin"`
}

// InviteUser godoc
//
//	@Summary		Invite a new user
//	@Description	Creates a Firebase user and their profile. Returns a temporary password to share with the new user.
//	@Tags			admin
//	@Security		BearerAuth
//	@Accept			json
//	@Produce		json
//	@Param			body	body		inviteRequest	true	"User first name, last name and email"
//	@Success		201		{object}	inviteResponse
//	@Failure		400		{object}	map[string]string
//	@Failure		500		{object}	map[string]string
//	@Router			/admin/invite [post]
func InviteUser(pool *pgxpool.Pool, authClient *firebaseauth.Client) fiber.Handler {
	return func(c *fiber.Ctx) error {
		var req inviteRequest
		if err := c.BodyParser(&req); err != nil || req.FirstName == "" || req.Email == "" {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
				"error": "'first_name' and 'email' are required",
			})
		}

		tempPassword := generateTempPassword()

		displayName := req.FirstName
		if req.LastName != "" {
			displayName += " " + req.LastName
		}

		// Create the Firebase user.
		params := (&firebaseauth.UserToCreate{}).
			Email(req.Email).
			DisplayName(displayName).
			Password(tempPassword)

		fbUser, err := authClient.CreateUser(c.Context(), params)
		if err != nil {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
				"error": fmt.Sprintf("Firebase error: %v", err),
			})
		}

		// Create the corresponding DB user profile (role defaults to 'player').
		// Admin-created accounts are approved immediately and have no licence.
		q := db.New(pool)
		user, err := q.CreateUser(c.Context(), db.CreateUserParams{
			ID:         fbUser.UID,
			FirstName:  req.FirstName,
			LastName:   req.LastName,
			Email:      req.Email,
			EloSingles: int32(services.InitialEloFor("", "")),
			EloDoubles: int32(services.InitialEloFor("", "")),
			EloMixed:   int32(services.InitialEloFor("", "")),
			Status:     db.UserStatusApproved,
		})
		if err != nil {
			// Best-effort rollback: remove the Firebase user.
			_ = authClient.DeleteUser(c.Context(), fbUser.UID)
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
				"error": "Failed to create user profile",
			})
		}

		return c.Status(fiber.StatusCreated).JSON(inviteResponse{
			User:         user,
			TempPassword: tempPassword,
		})
	}
}

// SetAdminRole godoc
//
//	@Summary		Grant or revoke admin role
//	@Description	Updates the user's role in the database. Takes effect immediately on the next request (no token refresh needed).
//	@Tags			admin
//	@Security		BearerAuth
//	@Accept			json
//	@Produce		json
//	@Param			uid		path		string			true	"Firebase UID of the target user"
//	@Param			body	body		setRoleRequest	true	"Role payload"
//	@Success		200		{object}	db.User
//	@Failure		400		{object}	map[string]string
//	@Failure		404		{object}	map[string]string
//	@Failure		500		{object}	map[string]string
//	@Router			/admin/users/{uid}/role [post]
func SetAdminRole(pool *pgxpool.Pool) fiber.Handler {
	return func(c *fiber.Ctx) error {
		uid := c.Params("uid")
		if uid == "" {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
				"error": "Missing UID",
			})
		}

		var req setRoleRequest
		if err := c.BodyParser(&req); err != nil {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
				"error": "Invalid request body",
			})
		}

		role := "player"
		if req.Admin {
			role = "admin"
		}

		q := db.New(pool)
		user, err := q.UpdateUserRole(c.Context(), db.UpdateUserRoleParams{
			ID:   uid,
			Role: role,
		})
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
				"error": "Failed to update role",
			})
		}

		return c.JSON(user)
	}
}

// generateTempPassword returns a cryptographically random 16-character password.
func generateTempPassword() string {
	b := make([]byte, 12)
	if _, err := rand.Read(b); err != nil {
		panic(err)
	}
	return base64.URLEncoding.EncodeToString(b)
}
