# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Music Portfolio AI is a three-tier platform connecting musicians and clients. Musicians upload audio tracks that are automatically analyzed (BPM, key, genre) by a Python service and described by an LLM. Clients post jobs or request direct productions; an AI matching service maps natural-language queries to tracks.

**Stack**: Rails 7 API (Ruby 3.1.3) · Next.js 15 / React 19 (TypeScript strict) · Python audio analyzer · PostgreSQL 14 · Docker Compose

---

## Development Commands

### Docker (recommended for full-stack)

```bash
docker compose up                        # Start all services (DB, backend :3000, frontend :3001)
docker compose down
docker compose -f docker-compose.production.yml build --no-cache  # Production build
```

### Backend (Rails)

```bash
cd backend
bundle install
bin/rails db:setup                       # Create + migrate + seed
bin/rails db:migrate
bin/rails server                         # localhost:3000

# Tests
bundle exec rspec                        # All specs
bundle exec rspec spec/models/           # Model specs only
bundle exec rspec spec/path/to/file_spec.rb  # Single file
bundle exec rspec spec/path/to/file_spec.rb:42  # Single example by line
```

### Frontend (Next.js)

```bash
cd frontend
npm install
npm run dev                              # localhost:3001

# CI checks (both must pass)
npm run lint                             # ESLint 9
npx tsc --noEmit                         # TypeScript strict check
```

### Python Analyzer

```bash
cd analyzer
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
python music_analyzer.py --file <audio_file>
python test_music_analyzer.py            # Unit tests
```

---

## Architecture

### Data Flow for Track Upload

1. **Frontend** `POST /api/v1/tracks` with audio file
2. **TracksController#create** saves the record, then calls `AnalyzerRunner`
3. **AnalyzerRunner** (`backend/app/services/analyzer_runner.rb`) spawns the Python process via `Open3.popen3` with a 60-second timeout → returns `{bpm, key, genre}`
4. **AiTextGenerator** (`backend/app/services/ai_text_generator.rb`) calls OpenAI GPT-4o-mini with the analysis data → stores a 3-4 sentence JP description on the track
5. Track record is saved with all metadata; frontend polling or response returns the result

### AI Matching Flow

1. Client sends natural-language query to `POST /api/v1/matching`
2. **AiMatchingService** (`backend/app/services/ai_matching_service.rb`) fetches the 50 most recent tracks and sends them + query to GPT-4o-mini
3. LLM returns `[{track_uuid, score (0–100), reason}]`; service filters `score >= 30`, returns top 5
4. Frontend `/matching` page renders results

### Authentication

Devise + devise-jwt with a JwtDenylist table. The JWT is stored in `localStorage` on the frontend. `useUser()` hook (`frontend/src/hooks/`) reads it. The API client (`frontend/src/lib/api/client.ts`) attaches `Authorization: Bearer <token>` to every request and redirects to `/login` on 401.

### SSR / API URL Duality

The frontend API client distinguishes two base URLs:
- **Browser**: `NEXT_PUBLIC_API_URL` (e.g., `http://localhost:3000`)
- **Server-side (SSR)**: `API_INTERNAL_URL` (Docker internal network address)

This is handled in `frontend/src/lib/api/client.ts` — always respect this pattern when adding new API calls.

### Conversation XOR Constraint

A `Conversation` belongs to either a `Job` OR a `Contract`, never both. This is enforced at the model level. When creating conversations, pass exactly one of `job_id` or `contract_id`.

### Job Status Lifecycle

`Job` uses a Rails enum: `draft → published → contracted → completed`. State transitions are enforced by the model; controllers should not manually set arbitrary statuses.

---

## Key Conventions

### Backend

- All API routes are namespaced under `/api/v1/`
- Controllers inherit from `ApplicationController` which handles JWT authentication; use `before_action :authenticate_user!` for protected routes
- UUID primary keys are used throughout — use `SecureRandom.uuid` pattern in migrations
- RSpec tests use FactoryBot; factories live in `spec/factories/`
- Service objects in `app/services/` follow the pattern of a single public `call` method
- `AnalyzerRunner` and `AiTextGenerator` both have graceful degradation: analyzer falls back to BPM=120/Key=C/Genre=Pop; text generator returns `nil` if `OPENAI_API_KEY` is absent

### Frontend

- TypeScript strict mode is enforced — no `any`, no implicit nulls
- Zod is used for runtime validation of API responses; add schemas in `src/types/` or alongside the relevant API client file
- `useAsyncData()` is the standard hook for data fetching with loading/error states — use it instead of raw `useEffect` + `useState` pairs
- Tailwind CSS 4 (no config file needed for basic usage)
- Toast notifications use `sonner`

### Environment Variables

Backend (set in `.env` or Docker Compose):
- `JWT_SECRET_KEY` — required for auth
- `OPENAI_API_KEY` — optional; AI features degrade gracefully without it
- `FRONTEND_URL` — used for CORS allowlist

Frontend:
- `NEXT_PUBLIC_API_URL` — browser-side API base URL
- `API_INTERNAL_URL` — server-side (SSR) API base URL

---

## CI/CD

GitHub Actions (`.github/workflows/test.yml`) runs on every PR and push to `main`:
- **Backend job**: Ruby 3.1.3 + PostgreSQL 15 service → `bundle exec rspec`
- **Frontend job**: Node 20 → `npm ci && npm run lint && npx tsc --noEmit`

Both jobs run in parallel. Deployment to EC2 triggers automatically after tests pass on `main` (`.github/workflows/deploy.yml`): SSH → git pull → Docker rebuild → `db:migrate` → health check at `/api/v1/health`.

Pre-commit and pre-push hooks live in `.githooks/`.
