# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

BAP Pulse is a badminton club management system (Bad A Paname) with real-time match scoring and ELO-based player rankings. It's a monorepo with three components:

- **`/api`** — Go REST API (Fiber v2, PostgreSQL 17, Firebase Auth, sqlc)
- **`/bo`** — Nuxt 4 back-office frontend (Vue 3, TypeScript, Nuxt UI, Firebase client auth)
- **`/app`** — Flutter mobile + web app (Material 3 dark theme, flutter_bloc, go_router, Firebase Auth). Targets iOS, Android, and web (mobile-framed on desktop)

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

### Mobile / Web (`/app`)

```bash
flutter pub get               # Install dependencies
flutter analyze               # Static analysis (zero issues expected)
flutter run                   # Run on connected device / picks default
flutter run -d chrome         # Run web build (mobile-framed on desktop)
flutter run -d <iPhone-UDID>  # Run on a specific iOS simulator
```

iOS deployment target is **15.0** (required by current Firebase iOS pods). Bumping it lower will break `pod install`.

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

### Mobile / Web App

- **Entry:** `lib/main.dart` initializes Firebase, then `lib/app.dart` provides `AuthBloc` + `MaterialApp.router`. The router is wrapped in `MobileFrame` so desktop-web viewports render in a centered phone-width column (`>600px` viewport ⇒ frame, otherwise full-bleed)
- **Routing:** `lib/core/router/app_router.dart` — go_router with a top-level `redirect` driven by `AuthBloc` state, plus a `ShellRoute` for the 5 bottom-nav tabs
- **State:** flutter_bloc + Equatable. One BLoC per feature. Currently only `AuthBloc` is wired to Firebase; the rest read from `MockRepository` (no API integration yet)
- **Mock data:** `lib/shared/data/mock_repository.dart` — port of `data.jsx` from the Claude Design kit. Will be swapped for an `ApiRepository` without changing the BLoCs
- **Theme:** Material 3 dark only. Design tokens in `lib/core/theme/colors.dart`, typography (Space Grotesk + Inter via `google_fonts`) in `text_styles.dart`. Brand accent is one swappable line (`AccentSage`/`AccentPulse`/`AccentBlue`/etc. — see `lib/core/theme/accent.dart`)
- **Layout under `lib/`:** flat — each feature has its own folder (`auth/`, `home/`, `score/`, `leaderboard/`, `club/`, `jerseys/`, `profile/`, `shell/`) with `bloc/` + `presentation/` subfolders. Shared building blocks live in `core/widgets/` (`PlayerAvatar`, `JerseyBadge`, `TrendChip`, `PrimaryButton`, `BapLogo`, `PulseLogo`, `MobileFrame`, etc.)
- **Auth flow:** Splash → Login / Register / Forgot password (email + password only). Firebase Auth wrapper is `lib/auth/data/auth_service.dart`. `redirect` in the router bounces unauthenticated users back to `/`
- **Assets:** `assets/images/bap_pulse_logo.svg` (app brand) and `assets/images/logo_bap.svg` (club brand). Both rendered via `flutter_svg` and tintable

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
- Frontend (BO) uses composables pattern for shared logic
- Mobile/web app uses flutter_bloc; UI strings are in French; semantic colors (win/defeat/streak/leader) are independent from the brand accent and stay constant when the accent palette is swapped
- Commit messages are descriptive, no conventional commit prefix enforced
