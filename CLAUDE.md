# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

BAP Pulse is a badminton club management system (Bad A Paname) with real-time match scoring. The primary public number is a **performance score** (monotonically increasing, monthly reset); the underlying **ELO** stays in the data model and is shown discreetly in the UI so players can spot who's stronger than them (the upsets jersey rewards beating higher-ELO opponents). It's a monorepo with three components:

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
- **Mock data:** `lib/shared/data/mock_repository.dart` — every screen reads from this (BLoCs included). Each `Player` exposes both `performance` (public score, ≥ 0, only goes up within the month, resets monthly) + `perfGain` (last-7-days delta) AND `elo` + `trend` (hidden, drive the algo). Swap this repo for an `ApiRepository` without touching the BLoCs
- **Public ranking model:** four classements, one per jersey, surfaced through a single criterion selector on the leaderboard screen (`lib/leaderboard/presentation/leaderboard_screen.dart`):
  - **Performance** (Maillot Jaune) → sorted by `performance`, default
  - **Ligue** (Maillot Vert) → sorted by `winsMonth`
  - **Combatif** (Maillot du Combatif) → sorted by `matchesMonth`
  - **Upsets** (Maillot à Pois) → sorted by `winsVsBetter` (a win against a player with higher hidden ELO)
- **ELO visibility rule:** never the primary number. Surface it as small `textFaint` (30% white) text next to the perf score on player cards, leaderboard rows, score-flow player sides, and the profile/score screen — readable, never central. It's never shown on the home (rank header, podium, feed)
- **Theme:** Material 3 dark only. Design tokens in `lib/core/theme/colors.dart`, typography (Space Grotesk + Inter via `google_fonts`) in `text_styles.dart`. Brand accent is one swappable line (`AccentSage`/`AccentPulse`/`AccentBlue`/etc. — see `lib/core/theme/accent.dart`). Semantic colors (red/green/yellow/orange) live in `AppColors` and are independent from the accent
- **Layout under `lib/`:** flat — each feature has its own folder (`auth/`, `home/`, `score/`, `leaderboard/`, `club/`, `jerseys/`, `profile/`, `shell/`) with `bloc/` + `presentation/` subfolders. Shared building blocks live in `core/widgets/` (`PlayerAvatar`, `JerseyBadge`, `TrendChip`, `PrimaryButton`, `BapLogo`, `PulseLogo`, `MobileFrame`, etc.)
- **Auth flow:** Splash → Login / Register / Forgot password (email + password only). Firebase Auth wrapper is `lib/auth/data/auth_service.dart`. `redirect` in the router bounces unauthenticated users back to `/`
- **Assets:** `assets/images/bap_pulse_logo.svg` (app brand, used as splash watermark and home header) and `assets/images/logo_bap.svg` (club horizontal lockup, used as the splash hero and the club watermark). Both rendered via `flutter_svg` and tintable
- **Web PWA:** `web/index.html` declares title "La Ligue du BAP", `web/favicon.svg` + `web/favicon.png` use the pulse logo on `#0B0F14`, manifest sets the same name + theme color. Generate new PNG icons via headless Chrome rendering `favicon.svg` if the accent changes

### Cross-cutting

- Firebase is the auth backbone across all three components
- API env: `DATABASE_URL`, `PORT`, `FIREBASE_CREDENTIALS_FILE`, `CORS_ORIGINS`
- Frontend env: `NUXT_PUBLIC_API_BASE_URL`, `NUXT_PUBLIC_FIREBASE_*` variables
- Both have `.env.example` files to copy from

## Key Conventions

- Database queries are written in SQL (`api/db/queries/`) and code-generated via sqlc — never edit `api/db/*.go` directly
- API error responses follow `{"error": "message"}` format, in English
- ELO calculation: individual delta for singles, team-average delta for doubles/mixed. ELO is shown in the mobile UI but as secondary info (small, `textFaint`, never the primary number) — players need it visible to identify who's stronger than them for the upsets jersey ("victories vs higher ELO"). It also drives the perf score under the hood
- Performance score is one-way: a match win adds points, a loss adds zero. Never decrement it client-side
- Firebase UIDs as user primary keys; UUIDs for matches and ELO history
- Frontend (BO) uses composables pattern for shared logic
- Mobile/web app uses flutter_bloc; UI strings are in French; semantic colors (win/defeat/streak/leader) are independent from the brand accent and stay constant when the accent palette is swapped
- Commit messages are descriptive, no conventional commit prefix enforced
