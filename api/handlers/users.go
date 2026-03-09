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
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Internal server error"})
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
			return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "User not found"})
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
//	@Description	Users can only update their own profile. Admins can update any profile.
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
		requesterUID := c.Locals("firebaseUID").(string)
		targetUID := c.Params("id")

		q := db.New(pool)

		if requesterUID != targetUID {
			requester, err := q.GetUserByID(c.Context(), requesterUID)
			if err != nil {
				return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Internal server error"})
			}
			if requester.Role != "admin" {
				return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"error": "Forbidden"})
			}
		}

		var req updateUserRequest
		if err := c.BodyParser(&req); err != nil {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid request body"})
		}
		user, err := q.UpdateUser(c.Context(), db.UpdateUserParams{
			ID:        targetUID,
			FirstName: req.FirstName,
			LastName:  req.LastName,
			Email:     req.Email,
		})
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Internal server error"})
		}
		return c.JSON(user)
	}
}

// DeleteUser godoc
//
//	@Summary		Delete user account
//	@Description	Users can only delete their own account. Admins can delete any account.
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
		requesterUID := c.Locals("firebaseUID").(string)
		targetUID := c.Params("id")

		q := db.New(pool)

		if requesterUID != targetUID {
			requester, err := q.GetUserByID(c.Context(), requesterUID)
			if err != nil {
				return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Internal server error"})
			}
			if requester.Role != "admin" {
				return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"error": "Forbidden"})
			}
		}

		if err := q.DeleteUser(c.Context(), targetUID); err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Internal server error"})
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
