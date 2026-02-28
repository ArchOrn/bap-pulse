# Load .env if it exists
-include .env
export

.PHONY: run build migrate-up migrate-down sqlc tidy

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

# Install dependencies
tidy:
	go mod tidy
