package middleware

import (
	"strings"

	firebaseauth "firebase.google.com/go/v4/auth"
	"github.com/gofiber/fiber/v2"
	"github.com/jackc/pgx/v5/pgxpool"

	"bap-pulse/db"
)

// Except wraps a handler and skips it for requests whose path starts with one of the given prefixes.
func Except(prefixes []string, handler fiber.Handler) fiber.Handler {
	return func(c *fiber.Ctx) error {
		for _, prefix := range prefixes {
			if strings.HasPrefix(c.Path(), prefix) {
				return c.Next()
			}
		}
		return handler(c)
	}
}

// FirebaseAuth verifies the Firebase ID Token sent in the Authorization header.
// On success, it stores firebase_uid and firebase_email in the Fiber context.
//
// The client (Flutter/Nuxt) obtains this token via the Firebase client SDK
// and sends it with each request: Authorization: Bearer <id_token>
func FirebaseAuth(authClient *firebaseauth.Client) fiber.Handler {
	return func(c *fiber.Ctx) error {
		header := c.Get("Authorization")
		if header == "" {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
				"error": "Missing Authorization header",
			})
		}

		parts := strings.SplitN(header, " ", 2)
		if len(parts) != 2 || parts[0] != "Bearer" {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
				"error": "Invalid format (expected: Bearer <firebase_id_token>)",
			})
		}

		token, err := authClient.VerifyIDToken(c.Context(), parts[1])
		if err != nil {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
				"error": "Invalid or expired Firebase token",
			})
		}

		// Store Firebase info in the context for downstream handlers.
		c.Locals("firebaseUID", token.UID)

		// Email may be absent depending on the Firebase auth provider.
		if email, ok := token.Claims["email"].(string); ok {
			c.Locals("firebaseEmail", email)
		}

		return c.Next()
	}
}

// RequireAdmin rejects requests from users whose DB role is not 'admin'.
// Must be used after FirebaseAuth (depends on firebaseUID in context).
func RequireAdmin(pool *pgxpool.Pool) fiber.Handler {
	return func(c *fiber.Ctx) error {
		uid, ok := c.Locals("firebaseUID").(string)
		if !ok || uid == "" {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
				"error": "Unauthenticated",
			})
		}

		q := db.New(pool)
		user, err := q.GetUserByID(c.Context(), uid)
		if err != nil || user.Role != "admin" {
			return c.Status(fiber.StatusForbidden).JSON(fiber.Map{
				"error": "Admin access required",
			})
		}

		return c.Next()
	}
}
