package handlers

import (
	"github.com/gofiber/fiber/v2"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"

	"bap-pulse/db"
)

// GetPlayers godoc
//
//	@Summary		List all players
//	@Tags			players
//	@Security		BearerAuth
//	@Produce		json
//	@Success		200	{array}		db.Player
//	@Failure		500	{object}	map[string]string
//	@Router			/players [get]
func GetPlayers(pool *pgxpool.Pool) fiber.Handler {
	return func(c *fiber.Ctx) error {
		q := db.New(pool)
		players, err := q.ListPlayers(c.Context())
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Erreur interne"})
		}
		return c.JSON(players)
	}
}

// GetPlayer godoc
//
//	@Summary		Get a player
//	@Tags			players
//	@Security		BearerAuth
//	@Produce		json
//	@Param			id	path		string	true	"Player ID (Firebase UID)"
//	@Success		200	{object}	db.Player
//	@Failure		404	{object}	map[string]string
//	@Router			/players/{id} [get]
func GetPlayer(pool *pgxpool.Pool) fiber.Handler {
	return func(c *fiber.Ctx) error {
		q := db.New(pool)
		player, err := q.GetPlayerByID(c.Context(), c.Params("id"))
		if err != nil {
			return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Joueur introuvable"})
		}
		return c.JSON(player)
	}
}

type updatePlayerRequest struct {
	Name  string `json:"name"`
	Email string `json:"email"`
}

// UpdatePlayer godoc
//
//	@Summary		Update player profile
//	@Description	Only the authenticated player can update their own profile.
//	@Tags			players
//	@Security		BearerAuth
//	@Accept			json
//	@Produce		json
//	@Param			id		path		string				true	"Player ID (Firebase UID)"
//	@Param			body	body		updatePlayerRequest	true	"Updated player data"
//	@Success		200		{object}	db.Player
//	@Failure		400		{object}	map[string]string
//	@Failure		403		{object}	map[string]string
//	@Failure		500		{object}	map[string]string
//	@Router			/players/{id} [put]
func UpdatePlayer(pool *pgxpool.Pool) fiber.Handler {
	return func(c *fiber.Ctx) error {
		// The player ID is their Firebase UID: ownership check is a simple string comparison.
		if c.Params("id") != c.Locals("firebaseUID").(string) {
			return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"error": "Accès interdit"})
		}

		var req updatePlayerRequest
		if err := c.BodyParser(&req); err != nil {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Corps de la requête invalide"})
		}

		q := db.New(pool)
		player, err := q.UpdatePlayer(c.Context(), db.UpdatePlayerParams{
			ID:    c.Params("id"),
			Name:  req.Name,
			Email: req.Email,
		})
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Erreur interne"})
		}
		return c.JSON(player)
	}
}

// DeletePlayer godoc
//
//	@Summary		Delete player account
//	@Description	Only the authenticated player can delete their own account.
//	@Tags			players
//	@Security		BearerAuth
//	@Produce		json
//	@Param			id	path	string	true	"Player ID (Firebase UID)"
//	@Success		204
//	@Failure		403	{object}	map[string]string
//	@Failure		500	{object}	map[string]string
//	@Router			/players/{id} [delete]
func DeletePlayer(pool *pgxpool.Pool) fiber.Handler {
	return func(c *fiber.Ctx) error {
		if c.Params("id") != c.Locals("firebaseUID").(string) {
			return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"error": "Accès interdit"})
		}

		q := db.New(pool)
		if err := q.DeletePlayer(c.Context(), c.Params("id")); err != nil {
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
