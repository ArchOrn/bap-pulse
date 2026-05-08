//	@title			BAP Pulse API
//	@version		1.0
//	@description	REST API for the BAP Pulse badminton club app — Bad A Paname.
//
//	@host		localhost:8080
//	@BasePath	/
//
//	@securityDefinitions.apikey	BearerAuth
//	@in							header
//	@name						Authorization
//	@description				Firebase ID Token — format: Bearer <token>

package main

import (
	"context"
	_ "embed"
	"log"

	firebase "firebase.google.com/go/v4"
	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/gofiber/fiber/v2/middleware/logger"
	"github.com/gofiber/fiber/v2/middleware/recover"
	"github.com/jackc/pgx/v5/pgxpool"
	"google.golang.org/api/option"

	"bap-pulse/config"
	_ "bap-pulse/docs"
	"bap-pulse/handlers"
	"bap-pulse/middleware"
)

//go:embed docs/swagger.json
var swaggerJSON []byte

const swaggerUI = `<!DOCTYPE html>
<html>
<head>
  <title>BAP Pulse API</title>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link rel="stylesheet" type="text/css" href="https://unpkg.com/swagger-ui-dist@5/swagger-ui.css">
</head>
<body>
  <div id="swagger-ui"></div>
  <script src="https://unpkg.com/swagger-ui-dist@5/swagger-ui-bundle.js"></script>
  <script>
    SwaggerUIBundle({
      url: "/swagger/doc.json",
      dom_id: '#swagger-ui',
      presets: [SwaggerUIBundle.presets.apis, SwaggerUIBundle.SwaggerUIStandalonePreset],
      layout: "BaseLayout",
      deepLinking: true,
    })
  </script>
</body>
</html>`

func main() {
	ctx := context.Background()

	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("Config: %v", err)
	}

	// --- PostgreSQL ---
	pool, err := pgxpool.New(ctx, cfg.DatabaseURL)
	if err != nil {
		log.Fatalf("DB connection: %v", err)
	}
	defer pool.Close()

	if err := pool.Ping(ctx); err != nil {
		log.Fatalf("DB ping: %v", err)
	}
	log.Println("Connected to PostgreSQL")

	// --- Firebase Admin SDK ---
	// Local dev : FIREBASE_CREDENTIALS_FILE points to a service account JSON file.
	// Production (Cloud Run): ADC (Application Default Credentials) is used automatically.
	var firebaseOpts []option.ClientOption
	if cfg.FirebaseCredentialsFile != "" {
		firebaseOpts = append(firebaseOpts, option.WithCredentialsFile(cfg.FirebaseCredentialsFile))
	}

	firebaseApp, err := firebase.NewApp(ctx, nil, firebaseOpts...)
	if err != nil {
		log.Fatalf("Firebase init: %v", err)
	}

	authClient, err := firebaseApp.Auth(ctx)
	if err != nil {
		log.Fatalf("Firebase Auth client: %v", err)
	}
	log.Println("Firebase Auth initialized")

	// --- Fiber ---
	app := fiber.New(fiber.Config{
		AppName: "BAP Pulse API",
	})

	app.Use(recover.New())
	app.Use(logger.New())

	// --- CORS ---
	app.Use(cors.New(cors.Config{
		AllowOrigins: cfg.CORSOrigins,
		AllowHeaders: "Origin, Content-Type, Accept, Authorization",
		AllowMethods: "GET, POST, PUT, DELETE, OPTIONS",
	}))

	// --- Public routes (no auth required) ---
	app.Get("/health", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{"status": "ok"})
	})
	app.Get("/rankings", handlers.GetRankings(pool))
	app.Get("/rankings/elo", handlers.GetEloRanking(pool))
	app.Get("/rankings/performance", handlers.GetPerformanceRanking(pool))
	app.Get("/rankings/league", handlers.GetLeagueRanking(pool))
	app.Get("/rankings/matches-played", handlers.GetMatchesPlayedRanking(pool))
	app.Get("/rankings/giant-killer", handlers.GetGiantKillerRanking(pool))

	// --- Swagger UI (dev only) ---
	swaggerHandler := func(c *fiber.Ctx) error {
		return c.Type("html").SendString(swaggerUI)
	}
	app.Get("/swagger", swaggerHandler)
	app.Get("/swagger/", swaggerHandler)
	app.Get("/swagger/index.html", swaggerHandler)
	app.Get("/swagger/doc.json", func(c *fiber.Ctx) error {
		c.Set("Content-Type", "application/json")
		return c.Send(swaggerJSON)
	})

	// --- All routes below require a valid Firebase token ---
	app.Use(middleware.FirebaseAuth(authClient))

	// --- Auth ---
	app.Post("/auth/sync", handlers.Sync(pool))

	// --- Users ---
	users := app.Group("/users")
	users.Get("/", handlers.GetUsers(pool))
	users.Get("/:id", handlers.GetUser(pool))
	users.Put("/:id", handlers.UpdateUser(pool))
	users.Delete("/:id", handlers.DeleteUser(pool))

	// --- Matches ---
	matches := app.Group("/matches")
	matches.Get("/", handlers.GetMatches(pool))
	matches.Post("/", handlers.CreateMatch(pool))
	matches.Get("/:id", handlers.GetMatch(pool))

	// --- News (read = any auth, write = admin only) ---
	news := app.Group("/news")
	news.Get("/", handlers.ListNews(pool))
	news.Get("/:id", handlers.GetNews(pool))
	news.Post("/", middleware.RequireAdmin(pool), handlers.CreateNews(pool))
	news.Put("/:id", middleware.RequireAdmin(pool), handlers.UpdateNews(pool))
	news.Delete("/:id", middleware.RequireAdmin(pool), handlers.DeleteNews(pool))

	// --- Admin (requires role = 'admin' in DB) ---
	admin := app.Group("/admin")
	admin.Use(middleware.RequireAdmin(pool))
	admin.Post("/invite", handlers.InviteUser(pool, authClient))
	admin.Post("/users/:uid/role", handlers.SetAdminRole(pool))

	log.Printf("Server listening on port %s", cfg.Port)
	log.Fatal(app.Listen(":" + cfg.Port))
}
