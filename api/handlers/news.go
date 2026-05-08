package handlers

import (
	"strconv"

	"github.com/gofiber/fiber/v2"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"

	"bap-pulse/db"
)

const (
	defaultListLimit = 20
	maxListLimit     = 100
)

type newsRequest struct {
	Emoji string `json:"emoji"`
	Title string `json:"title"`
	Body  string `json:"body"` // optional
}

func (r newsRequest) validate() string {
	if r.Emoji == "" {
		return "'emoji' is required"
	}
	if r.Title == "" {
		return "'title' is required"
	}
	return ""
}

// ListNews godoc
//
//	@Summary		List news
//	@Description	Latest first. Anyone authenticated can read.
//	@Tags			news
//	@Security		BearerAuth
//	@Produce		json
//	@Param			limit	query		int	false	"Max items to return (default 20, max 100)"
//	@Param			offset	query		int	false	"Pagination offset (default 0)"
//	@Success		200		{array}		db.News
//	@Failure		500		{object}	map[string]string
//	@Router			/news [get]
func ListNews(pool *pgxpool.Pool) fiber.Handler {
	return func(c *fiber.Ctx) error {
		limit, err := strconv.Atoi(c.Query("limit", strconv.Itoa(defaultListLimit)))
		if err != nil || limit <= 0 {
			limit = defaultListLimit
		}
		if limit > maxListLimit {
			limit = maxListLimit
		}
		offset, err := strconv.Atoi(c.Query("offset", "0"))
		if err != nil || offset < 0 {
			offset = 0
		}

		q := db.New(pool)
		items, err := q.ListNews(c.Context(), db.ListNewsParams{
			Limit:  int32(limit),
			Offset: int32(offset),
		})
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Internal server error"})
		}
		return c.JSON(items)
	}
}

// GetNews godoc
//
//	@Summary		Get a news item
//	@Tags			news
//	@Security		BearerAuth
//	@Produce		json
//	@Param			id	path		string	true	"News ID (UUID)"
//	@Success		200	{object}	db.News
//	@Failure		400	{object}	map[string]string
//	@Failure		404	{object}	map[string]string
//	@Router			/news/{id} [get]
func GetNews(pool *pgxpool.Pool) fiber.Handler {
	return func(c *fiber.Ctx) error {
		id, err := parseUUID(c.Params("id"))
		if err != nil {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid ID"})
		}

		q := db.New(pool)
		item, err := q.GetNewsByID(c.Context(), id)
		if err != nil {
			return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "News not found"})
		}
		return c.JSON(item)
	}
}

// CreateNews godoc
//
//	@Summary		Create a manual news item
//	@Description	Admin only. The created news has source = "MANUAL".
//	@Tags			news
//	@Security		BearerAuth
//	@Accept			json
//	@Produce		json
//	@Param			body	body		newsRequest	true	"News payload"
//	@Success		201		{object}	db.News
//	@Failure		400		{object}	map[string]string
//	@Failure		403		{object}	map[string]string
//	@Failure		500		{object}	map[string]string
//	@Router			/news [post]
func CreateNews(pool *pgxpool.Pool) fiber.Handler {
	return func(c *fiber.Ctx) error {
		var req newsRequest
		if err := c.BodyParser(&req); err != nil {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid request body"})
		}
		if msg := req.validate(); msg != "" {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": msg})
		}

		uid, _ := c.Locals("firebaseUID").(string)

		body := pgtype.Text{}
		if req.Body != "" {
			body = pgtype.Text{String: req.Body, Valid: true}
		}

		q := db.New(pool)
		item, err := q.CreateNews(c.Context(), db.CreateNewsParams{
			Emoji:     req.Emoji,
			Title:     req.Title,
			Body:      body,
			Source:    "MANUAL",
			MatchID:   pgtype.UUID{},
			CreatedBy: pgtype.Text{String: uid, Valid: uid != ""},
		})
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to create news"})
		}
		return c.Status(fiber.StatusCreated).JSON(item)
	}
}

// UpdateNews godoc
//
//	@Summary		Update a news item
//	@Description	Admin only. Updates emoji, title and body. Source and references are immutable.
//	@Tags			news
//	@Security		BearerAuth
//	@Accept			json
//	@Produce		json
//	@Param			id		path		string		true	"News ID (UUID)"
//	@Param			body	body		newsRequest	true	"News payload"
//	@Success		200		{object}	db.News
//	@Failure		400		{object}	map[string]string
//	@Failure		403		{object}	map[string]string
//	@Failure		404		{object}	map[string]string
//	@Failure		500		{object}	map[string]string
//	@Router			/news/{id} [put]
func UpdateNews(pool *pgxpool.Pool) fiber.Handler {
	return func(c *fiber.Ctx) error {
		id, err := parseUUID(c.Params("id"))
		if err != nil {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid ID"})
		}

		var req newsRequest
		if err := c.BodyParser(&req); err != nil {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid request body"})
		}
		if msg := req.validate(); msg != "" {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": msg})
		}

		body := pgtype.Text{}
		if req.Body != "" {
			body = pgtype.Text{String: req.Body, Valid: true}
		}

		q := db.New(pool)
		item, err := q.UpdateNews(c.Context(), db.UpdateNewsParams{
			ID:    id,
			Emoji: req.Emoji,
			Title: req.Title,
			Body:  body,
		})
		if err != nil {
			return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "News not found"})
		}
		return c.JSON(item)
	}
}

// DeleteNews godoc
//
//	@Summary		Delete a news item
//	@Description	Admin only.
//	@Tags			news
//	@Security		BearerAuth
//	@Produce		json
//	@Param			id	path	string	true	"News ID (UUID)"
//	@Success		204
//	@Failure		400	{object}	map[string]string
//	@Failure		403	{object}	map[string]string
//	@Failure		500	{object}	map[string]string
//	@Router			/news/{id} [delete]
func DeleteNews(pool *pgxpool.Pool) fiber.Handler {
	return func(c *fiber.Ctx) error {
		id, err := parseUUID(c.Params("id"))
		if err != nil {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid ID"})
		}

		q := db.New(pool)
		if err := q.DeleteNews(c.Context(), id); err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to delete news"})
		}
		return c.SendStatus(fiber.StatusNoContent)
	}
}
