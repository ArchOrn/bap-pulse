# BAP Pulse API

REST API in Go (Fiber) for the BAP Pulse app — Bad A Paname badminton club.

## Stack

| Tool | Role |
|---|---|
| [Fiber v2](https://gofiber.io) | HTTP framework |
| [pgx v5](https://github.com/jackc/pgx) | PostgreSQL driver |
| [sqlc](https://sqlc.dev) | SQL → Go code generation |
| [goose](https://github.com/pressly/goose) | Database migrations |
| [Firebase Admin SDK](https://firebase.google.com/docs/admin/setup) | Token verification (auth) |
| [godotenv](https://github.com/joho/godotenv) | Environment variables |

## Local services (Docker)

```bash
docker compose up -d
```

| Service | Port | Description |
|---|---|---|
| PostgreSQL 17 | `5432` | Main database |
| RustFS | `9000` | S3-compatible object storage |
| RustFS console | `9001` | Web UI for storage |

> **Note:** RustFS runs as UID 10001. If you get permission errors on the storage volume, run:
> ```bash
> sudo chown -R 10001:10001 .docker/storage/data
> ```

## Quick start

```bash
# 1. Copy and fill in environment variables
cp .env.example .env

# 2. Start local services
docker compose up -d

# 3. Install Go dependencies
go mod tidy

# 4. Install tools (if not already installed)
go install github.com/sqlc-dev/sqlc/cmd/sqlc@latest
go install github.com/pressly/goose/v3/cmd/goose@latest

# 5. Apply migrations
make migrate-up

# 6. Generate typed SQL code
make sqlc

# 7. Start the API
make run
```

## Environment variables

| Variable | Description |
|---|---|
| `DATABASE_URL` | PostgreSQL connection string |
| `PORT` | Port the API listens on (default: `3000`) |
| `FIREBASE_CREDENTIALS_FILE` | Path to Firebase service account JSON (local dev only — omit in prod) |

In production on Cloud Run, Firebase uses ADC (Application Default Credentials) automatically.

## Authentication

Authentication is handled entirely by Firebase on the client side. The API only verifies Firebase ID Tokens via the `FirebaseAuth` middleware.

On first login, the client calls `POST /auth/sync` with the user's display name to create their player profile. Subsequent calls to the same endpoint return the existing profile.

## Routes

### Auth
| Method | Route | Auth | Description |
|---|---|---|---|
| POST | `/auth/sync` | Firebase token | Create or retrieve player profile |

### Rankings (public)
| Method | Route | Auth | Description |
|---|---|---|---|
| GET | `/rankings` | — | ELO leaderboard |

### Players (Firebase token required)
| Method | Route | Auth | Description |
|---|---|---|---|
| GET | `/players` | Firebase token | List all players |
| GET | `/players/:id` | Firebase token | Get a player |
| PUT | `/players/:id` | Firebase token (owner only) | Update profile |
| DELETE | `/players/:id` | Firebase token (owner only) | Delete account |

### Matches (Firebase token required)
| Method | Route | Auth | Description |
|---|---|---|---|
| GET | `/matches` | Firebase token | List matches |
| POST | `/matches` | Firebase token | Create a match + update ELO |
| GET | `/matches/:id` | Firebase token | Get a match |

## Match types

Matches support three formats via the `match_type` field:

| Value | Format | Players |
|---|---|---|
| `SINGLES` | 1v1 | `team1_player1_id`, `team2_player1_id` |
| `DOUBLES` | 2v2 (same gender) | All 4 player fields |
| `MIXED` | 2v2 (mixed gender) | All 4 player fields |

ELO is calculated per player: individual ratings for singles, team-average delta applied individually for doubles/mixed.
