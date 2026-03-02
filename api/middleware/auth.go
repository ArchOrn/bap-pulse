package middleware

import (
	"strings"

	firebaseauth "firebase.google.com/go/v4/auth"
	"github.com/gofiber/fiber/v2"
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
// On success, it stores the firebase_uid in the Fiber context.
//
// The client (Flutter/Nuxt) obtains this token via the Firebase client SDK
// and sends it with each request: Authorization: Bearer <id_token>
func FirebaseAuth(authClient *firebaseauth.Client) fiber.Handler {
	return func(c *fiber.Ctx) error {
		header := c.Get("Authorization")
		if header == "" {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
				"error": "Authorization header manquant",
			})
		}

		parts := strings.SplitN(header, " ", 2)
		if len(parts) != 2 || parts[0] != "Bearer" {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
				"error": "Format invalide (attendu: Bearer <firebase_id_token>)",
			})
		}

		token, err := authClient.VerifyIDToken(c.Context(), parts[1])
		if err != nil {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
				"error": "Token Firebase invalide ou expiré",
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
