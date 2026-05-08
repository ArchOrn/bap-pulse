# Load .env if it exists
-include .env
export

.PHONY: run build migrate-up migrate-down sqlc swagger tidy seed-news

# Start the server in development mode
run:
	go run ./main.go

# Compile the binary
build:
	go build -o bin/api ./main.go

# Apply all pending migrations
migrate-up:
	goose -dir db/migrations postgres "$(DATABASE_URL)" up

# Revert the last migration
migrate-down:
	goose -dir db/migrations postgres "$(DATABASE_URL)" down

# Generate Go code from SQL queries
sqlc:
	sqlc generate

# Generate Swagger docs from annotations
swagger:
	swag init -g main.go --output docs --parseDependency --parseInternal

# Install dependencies
tidy:
	go mod tidy

# Insert demo news rows into the local DB (idempotent).
seed-news:
	psql "$(DATABASE_URL)" -f db/seeds/demo_news.sql
