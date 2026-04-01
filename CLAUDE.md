# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

BAP Pulse is a badminton club management system (Bad A Paname) with real-time match scoring and ELO-based player rankings. It's a monorepo with three components:

- **`/api`** — Go REST API (Fiber v2, PostgreSQL 17, Firebase Auth, sqlc)
- **`/bo`** — Nuxt 4 back-office frontend (Vue 3, TypeScript, Nuxt UI, Firebase client auth)
- **`/app`** — Flutter mobile app (early stage, Firebase Auth)

## Development Commands

### API (`/api`)

```bash
docker compose up -d          # Start PostgreSQL + RustFS (S3-compatible storage)
make run                      # Start dev server (port 8080)
make build                    # Compile binary
make migrate-up               # Run goose migrations
make migrate-down             # Rollback migrations
make sqlc                     # Regenerate Go code from SQL queries
make swagger                  # Regenerate Swagger docs
make tidy                     # go mod tidy
```

### Frontend (`/bo`)

```bash
pnpm install                  # Install dependencies
pnpm dev                      # Dev server (port 3000)
pnpm build                    # Production build
pnpm lint                     # ESLint
pnpm typecheck                # TypeScript validation
```

### Mobile (`/app`)

```bash
flutter pub get               # Install dependencies
flutter run                   # Run on emulator/device
```

## Architecture

### API

- **Entry point:** `main.go` — server setup, route definitions, middleware wiring
- **Database layer:** sqlc-generated code in `db/` from SQL in `db/queries/`. Models and query functions are generated — edit `.sql` files, then run `make sqlc`
- **Migrations:** goose migrations in `db/migrations/`
- **Auth:** Firebase Admin SDK verifies ID tokens in `middleware/auth.go`. Two levels: `FirebaseAuth` (any authenticated user) and admin role check
- **Handlers:** in `handlers/` — return Fiber handler closures for dependency injection
- **Services:** business logic in `services/` (ELO calculations)
- **Swagger:** annotations on handler functions, generated docs in `docs/`

**Route structure:**
- Public: `/health`, `/rankings`, `/swagger/*` (dev only)
- Protected (Firebase token): `/auth/sync`, `/users/*`, `/matches/*`
- Admin only: `/admin/invite`, `/admin/users/:uid/role`

### Database Schema

- **users** — keyed by Firebase UID (VARCHAR 128), stores ELO rating and role
- **matches** — UUID PK, supports SINGLES/DOUBLES/MIXED with up to 4 player slots and 3 sets
- **elo_history** — tracks per-match ELO deltas per user

### Frontend (BO)

- **Auth flow:** `plugins/firebase.client.ts` initializes Firebase; `middleware/auth.global.ts` protects routes; `composables/useAuth.ts` manages state
- **API calls:** `composables/useApi.ts` provides base URL and auth headers for `$fetch`
- **Shared types:** `shared/types/api.ts` — TypeScript interfaces matching API responses
- **Pages:** file-based routing under `app/pages/` (login, players, users, matches, rankings)
- **SSR disabled** — runs as SPA
- **CI:** GitHub Actions runs lint + typecheck on push (Node 22)

### Cross-cutting

- Firebase is the auth backbone across all three components
- API env: `DATABASE_URL`, `PORT`, `FIREBASE_CREDENTIALS_FILE`, `CORS_ORIGINS`
- Frontend env: `NUXT_PUBLIC_API_BASE_URL`, `NUXT_PUBLIC_FIREBASE_*` variables
- Both have `.env.example` files to copy from

## Key Conventions

- Database queries are written in SQL (`api/db/queries/`) and code-generated via sqlc — never edit `api/db/*.go` directly
- API error responses follow `{"error": "message"}` format, in English
- ELO calculation: individual delta for singles, team-average delta for doubles/mixed
- Firebase UIDs as user primary keys; UUIDs for matches and ELO history
- Frontend uses composables pattern for shared logic
- Commit messages are descriptive, no conventional commit prefix enforced
