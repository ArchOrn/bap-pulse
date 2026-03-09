package handlers

import (
	"github.com/gofiber/fiber/v2"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"

	"bap-pulse/db"
)

// GetUsers godoc
//
//	@Summary		List all users
//	@Tags			users
//	@Security		BearerAuth
//	@Produce		json
//	@Success		200	{array}		db.User
//	@Failure		500	{object}	map[string]string
//	@Router			/users [get]
func GetUsers(pool *pgxpool.Pool) fiber.Handler {
	return func(c *fiber.Ctx) error {
		q := db.New(pool)
		users, err := q.ListUsers(c.Context())
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Erreur interne"})
		}
		return c.JSON(users)
	}
}

// GetUser godoc
//
//	@Summary		Get a user
//	@Tags			users
//	@Security		BearerAuth
//	@Produce		json
//	@Param			id	path		string	true	"User ID (Firebase UID)"
//	@Success		200	{object}	db.User
//	@Failure		404	{object}	map[string]string
//	@Router			/users/{id} [get]
func GetUser(pool *pgxpool.Pool) fiber.Handler {
	return func(c *fiber.Ctx) error {
		q := db.New(pool)
		user, err := q.GetUserByID(c.Context(), c.Params("id"))
		if err != nil {
			return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Utilisateur introuvable"})
		}
		return c.JSON(user)
	}
}

type updateUserRequest struct {
	FirstName string `json:"first_name"`
	LastName  string `json:"last_name"`
	Email     string `json:"email"`
}

// UpdateUser godoc
//
//	@Summary		Update user profile
//	@Description	Only the authenticated user can update their own profile.
//	@Tags			users
//	@Security		BearerAuth
//	@Accept			json
//	@Produce		json
//	@Param			id		path		string				true	"User ID (Firebase UID)"
//	@Param			body	body		updateUserRequest	true	"Updated user data"
//	@Success		200		{object}	db.User
//	@Failure		400		{object}	map[string]string
//	@Failure		403		{object}	map[string]string
//	@Failure		500		{object}	map[string]string
//	@Router			/users/{id} [put]
func UpdateUser(pool *pgxpool.Pool) fiber.Handler {
	return func(c *fiber.Ctx) error {
		// The user ID is their Firebase UID: ownership check is a simple string comparison.
		if c.Params("id") != c.Locals("firebaseUID").(string) {
			return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"error": "Accès interdit"})
		}

		var req updateUserRequest
		if err := c.BodyParser(&req); err != nil {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Corps de la requête invalide"})
		}

		q := db.New(pool)
		user, err := q.UpdateUser(c.Context(), db.UpdateUserParams{
			ID:        c.Params("id"),
			FirstName: req.FirstName,
			LastName:  req.LastName,
			Email:     req.Email,
		})
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Erreur interne"})
		}
		return c.JSON(user)
	}
}

// DeleteUser godoc
//
//	@Summary		Delete user account
//	@Description	Only the authenticated user can delete their own account.
//	@Tags			users
//	@Security		BearerAuth
//	@Produce		json
//	@Param			id	path	string	true	"User ID (Firebase UID)"
//	@Success		204
//	@Failure		403	{object}	map[string]string
//	@Failure		500	{object}	map[string]string
//	@Router			/users/{id} [delete]
func DeleteUser(pool *pgxpool.Pool) fiber.Handler {
	return func(c *fiber.Ctx) error {
		if c.Params("id") != c.Locals("firebaseUID").(string) {
			return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"error": "Accès interdit"})
		}

		q := db.New(pool)
		if err := q.DeleteUser(c.Context(), c.Params("id")); err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Erreur interne"})
		}
		return c.SendStatus(fiber.StatusNoContent)
	}
}

// parseUUID converts a string to a pgtype.UUID (used by matches.go).
func parseUUID(s string) (pgtype.UUID, error) {
	var id pgtype.UUID
	err := id.Scan(s)
	return id, err
}
