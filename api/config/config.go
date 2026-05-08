package config

import (
	"fmt"
	"os"

	"github.com/joho/godotenv"
)

type Config struct {
	DatabaseURL string
	Port        string
	// Local dev: path to the Firebase service account JSON file.
	// Production (Cloud Run): leave empty, ADC handles authentication automatically.
	FirebaseCredentialsFile string
	// Comma-separated list of allowed CORS origins (e.g. "http://localhost:3000,https://bo.example.com")
	CORSOrigins string
}

func Load() (*Config, error) {
	// In production (Cloud Run), variables are injected directly.
	// Locally, load from .env if it exists.
	_ = godotenv.Load()

	cfg := &Config{
		DatabaseURL:             os.Getenv("DATABASE_URL"),
		Port:                    getEnvOrDefault("PORT", "8080"),
		FirebaseCredentialsFile: os.Getenv("FIREBASE_CREDENTIALS_FILE"),
		// Permissive default for dev (Flutter web's port is non-deterministic).
		// Always lock down via CORS_ORIGINS in prod.
		CORSOrigins: getEnvOrDefault("CORS_ORIGINS", "*"),
	}

	if cfg.DatabaseURL == "" {
		return nil, fmt.Errorf("DATABASE_URL est requis")
	}

	return cfg, nil
}

func getEnvOrDefault(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
