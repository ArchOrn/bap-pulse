package main

import (
	"context"
	"log"

	firebase "firebase.google.com/go/v4"
	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/logger"
	"github.com/gofiber/fiber/v2/middleware/recover"
	"github.com/jackc/pgx/v5/pgxpool"
	"google.golang.org/api/option"

	"bap-pulse/config"
	"bap-pulse/handlers"
	"bap-pulse/middleware"
)

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

	app.Get("/health", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{"status": "ok"})
	})

	// --- Auth: profile sync after client-side Firebase login ---
	// The client authenticates via the Firebase SDK, obtains an ID Token,
	// then calls POST /auth/sync to create or retrieve their profile.
	app.Post("/auth/sync", middleware.FirebaseAuth(authClient), handlers.Sync(pool))

	// --- Public routes ---
	app.Get("/rankings", handlers.GetRankings(pool))

	// --- Routes protected by Firebase Auth ---
	protected := app.Group("", middleware.FirebaseAuth(authClient))

	players := protected.Group("/players")
	players.Get("/", handlers.GetPlayers(pool))
	players.Get("/:id", handlers.GetPlayer(pool))
	players.Put("/:id", handlers.UpdatePlayer(pool))
	players.Delete("/:id", handlers.DeletePlayer(pool))

	matches := protected.Group("/matches")
	matches.Get("/", handlers.GetMatches(pool))
	matches.Post("/", handlers.CreateMatch(pool))
	matches.Get("/:id", handlers.GetMatch(pool))

	log.Printf("Server listening on port %s", cfg.Port)
	log.Fatal(app.Listen(":" + cfg.Port))
}
