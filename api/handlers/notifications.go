package handlers

import (
	"encoding/json"
	"strconv"

	"github.com/gofiber/fiber/v2"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"

	"bap-pulse/db"
)

// notificationResponse is the wire shape returned by the API. The DB struct's
// Data field is []byte (JSONB), which Go would serialize as base64. We re-emit
// it as a raw JSON object so the mobile client can parse it as a map directly.
type notificationResponse struct {
	ID        pgtype.UUID        `json:"id"`
	UserID    string             `json:"user_id"`
	Type      db.NotificationType `json:"type"`
	Title     string             `json:"title"`
	Body      string             `json:"body"`
	Data      json.RawMessage    `json:"data"`
	ReadAt    pgtype.Timestamptz `json:"read_at"`
	CreatedAt pgtype.Timestamptz `json:"created_at"`
}

func toResponse(n db.Notification) notificationResponse {
	data := json.RawMessage(n.Data)
	if len(data) == 0 {
		data = json.RawMessage("{}")
	}
	return notificationResponse{
		ID:        n.ID,
		UserID:    n.UserID,
		Type:      n.Type,
		Title:     n.Title,
		Body:      n.Body,
		Data:      data,
		ReadAt:    n.ReadAt,
		CreatedAt: n.CreatedAt,
	}
}

// ListNotifications godoc
//
//	@Summary		List notifications for the authenticated user
//	@Description	Paginated, most recent first. Includes both read and unread.
//	@Tags			notifications
//	@Security		BearerAuth
//	@Produce		json
//	@Param			limit	query		int	false	"Max items to return (default 20, max 100)"
//	@Param			offset	query		int	false	"Pagination offset (default 0)"
//	@Success		200		{array}		db.Notification
//	@Failure		500		{object}	map[string]string
//	@Router			/notifications [get]
func ListNotifications(pool *pgxpool.Pool) fiber.Handler {
	return func(c *fiber.Ctx) error {
		uid := c.Locals("firebaseUID").(string)

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
		items, err := q.ListNotificationsForUser(c.Context(), db.ListNotificationsForUserParams{
			UserID: uid,
			Limit:  int32(limit),
			Offset: int32(offset),
		})
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Internal server error"})
		}
		out := make([]notificationResponse, len(items))
		for i, n := range items {
			out[i] = toResponse(n)
		}
		return c.JSON(out)
	}
}

// UnreadNotificationCount godoc
//
//	@Summary		Count unread notifications for the authenticated user
//	@Tags			notifications
//	@Security		BearerAuth
//	@Produce		json
//	@Success		200	{object}	map[string]int64
//	@Failure		500	{object}	map[string]string
//	@Router			/notifications/unread-count [get]
func UnreadNotificationCount(pool *pgxpool.Pool) fiber.Handler {
	return func(c *fiber.Ctx) error {
		uid := c.Locals("firebaseUID").(string)

		q := db.New(pool)
		count, err := q.CountUnreadNotifications(c.Context(), uid)
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Internal server error"})
		}
		return c.JSON(fiber.Map{"count": count})
	}
}

// MarkNotificationRead godoc
//
//	@Summary		Mark a notification as read
//	@Tags			notifications
//	@Security		BearerAuth
//	@Produce		json
//	@Param			id	path		string	true	"Notification ID (UUID)"
//	@Success		200	{object}	db.Notification
//	@Failure		400	{object}	map[string]string
//	@Failure		404	{object}	map[string]string
//	@Router			/notifications/{id}/read [post]
func MarkNotificationRead(pool *pgxpool.Pool) fiber.Handler {
	return func(c *fiber.Ctx) error {
		uid := c.Locals("firebaseUID").(string)

		id, err := parseUUID(c.Params("id"))
		if err != nil {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid ID"})
		}

		q := db.New(pool)
		notif, err := q.MarkNotificationRead(c.Context(), db.MarkNotificationReadParams{
			ID:     id,
			UserID: uid,
		})
		if err != nil {
			// Either the notification doesn't exist, doesn't belong to the
			// caller, or was already read — clients can treat any of these
			// as "already done" and don't need a granular error.
			return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Notification not found or already read"})
		}
		return c.JSON(toResponse(notif))
	}
}

// MarkAllNotificationsRead godoc
//
//	@Summary		Mark all the caller's notifications as read
//	@Tags			notifications
//	@Security		BearerAuth
//	@Success		204
//	@Failure		500	{object}	map[string]string
//	@Router			/notifications/read-all [post]
func MarkAllNotificationsRead(pool *pgxpool.Pool) fiber.Handler {
	return func(c *fiber.Ctx) error {
		uid := c.Locals("firebaseUID").(string)

		q := db.New(pool)
		if err := q.MarkAllNotificationsRead(c.Context(), uid); err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Internal server error"})
		}
		return c.SendStatus(fiber.StatusNoContent)
	}
}
