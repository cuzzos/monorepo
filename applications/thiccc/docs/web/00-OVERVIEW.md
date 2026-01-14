# Thiccc Web Application - Overview

> **TLDR:** Architecture overview for thiccc web app. Tech stack: Next.js (frontend), Rust+Axum (backend), PostgreSQL (database), Clerk (auth), hosted on Vercel+Railway. 13-week phased development plan (0-10). Reuses existing Rust business logic from iOS app's `shared/` crate. Uses Dagger for containerized dev tools.

## Table of Contents
- [What We're Building](#what-were-building)
- [Architecture](#architecture)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Development Phases](#development-phases)
- [Key Principles](#key-principles)
- [Architecture Decisions](#architecture-decisions)
- [Data Flow Example](#data-flow-example)
- [Next Steps](#next-steps)
- [Questions?](#questions)
- [Success Metrics](#success-metrics)

---

## What We're Building

A web frontend for **thiccc**, the workout tracking application. The web app will have feature parity with the iOS app, plus web-specific features like analytics dashboards, trainer client management, and workout planning.

## Architecture

```
Frontend (Next.js)     →  Backend (Rust + Axum)  →  Database (PostgreSQL)
- Hosted on Vercel        - Hosted on Railway       - Hosted on Railway
- TypeScript + React      - Imports shared crate    - Managed backups
- Shadcn/ui + Tailwind    - JWT validation          - Schema migrations
- Clerk authentication    - REST API                - User workout data
```

## Tech Stack

| Layer | Technology | Why |
|-------|-----------|-----|
| Frontend | Next.js 15 (App Router) | Modern, AI-friendly, server components |
| UI Library | Shadcn/ui + Tailwind CSS | Beautiful, accessible, customizable |
| Auth | Clerk | 5-min setup, works with iOS too |
| Backend | Rust + Axum | Reuse existing business logic from `shared/` |
| Database | PostgreSQL 16 | Relational, battle-tested |
| Hosting | Vercel + Railway | Zero-config, auto-deploy |
| Devtools | Dagger | Containerized tools, no local installs |

## Project Structure

```
applications/thiccc/
├── shared/                 # Crux core (business logic)
├── shared_types/           # Type generation (Rust → TypeScript)
├── ios/                    # iOS app (SwiftUI)
├── web_frontend/           # Web client (Next.js)
│   ├── app/                # App Router pages
│   ├── components/         # React components
│   ├── lib/                # Utilities, API client
│   └── public/             # Static assets
└── api_server/             # Shared API (serves iOS + Web)
    ├── src/
    │   ├── main.rs         # Entry point
    │   ├── routes/         # API endpoints
    │   ├── middleware/     # JWT validation, CORS
    │   └── db/             # Database queries
    ├── migrations/         # SQL migrations
    └── Cargo.toml          # Depends on ../shared
```

## Development Phases

The web application is built in phases:

| Phase | Name | Description | Est. Time |
|-------|------|-------------|-----------|
| 0 | Overview | This document | - |
| 1 | Setup | Dev environment, Dagger, accounts | 1 week |
| 2 | Auth | Clerk integration, protected routes | 1 week |
| 3 | Core API | Database, first endpoints | 1 week |
| 4 | Admin + Debug | Admin dashboard, debug panel | 1 week |
| 5 | Workouts | CRUD workouts, exercises, sets | 2 weeks |
| 6 | Tracking | Live workout tracking | 1 week |
| 7 | Analytics | Charts, data visualization | 1 week |
| 8 | Trainer | Client management, organizations | 2 weeks |
| 9 | Planning | Calendar, workout scheduling | 2 weeks |
| 10 | Polish | Performance, UX, accessibility | 1 week |

**Total estimated time:** 13 weeks for MVP

## Key Principles

### 1. Reuse Existing Business Logic

**The iOS app already has Rust business logic in `shared/`.** We import this directly:

```rust
// api_server/Cargo.toml
[dependencies]
shared = { path = "../shared" }

// api_server/src/routes/workouts.rs
use shared::models::Workout;
use shared::operations;

fn create_workout() {
    let workout = operations::create_workout(name); // Reuse!
}
```

### 2. Type Safety Across Stack

**TypeScript types are auto-generated from Rust:**

```
shared/src/models.rs  →  shared_types/  →  web_frontend/lib/types.ts
     (Rust)              (Generator)         (TypeScript)
```

Same types everywhere = fewer bugs.

### 3. Dagger for Development

**No local tool installations.** Everything runs via Dagger:

```bash
# Instead of: npm install, cargo build, etc.
dagger call node-dev --source=web_frontend
dagger call rust-serve --source=api_server
```

See: `/docs/dagger/` for details.

### 4. AI-Friendly Development

**Each phase has:**
- Clear goals and success criteria
- Detailed, sequential tasks
- Validation commands (using Dagger)
- Human checkpoints
- Common issues and solutions

**AI agents can build features with minimal human intervention.**

### 5. Feature Flags for Debug Tools

**Debug panel is always available in prod** (admin users only):

```typescript
// Admin user opens deployed site
// Presses Cmd+Shift+D
// Debug panel appears (API logs, state inspector, DB queries)
```

## Architecture Decisions

### Why Clerk for Auth?

- ✅ Works with both web and iOS (same user accounts)
- ✅ 5-minute setup vs 2-3 days for custom auth
- ✅ Handles email verification, password reset, 2FA
- ✅ Organizations feature (perfect for trainer → clients)
- ✅ Free up to 10k monthly active users

### Why Railway + Vercel?

- ✅ Zero-config deployment (git push = deployed)
- ✅ Railway: managed PostgreSQL + Rust hosting
- ✅ Vercel: perfect for Next.js, free tier
- ✅ No Kubernetes/Terraform needed (save weeks of work)
- ✅ Can migrate to GCP/AWS later if needed

### Why Dagger?

- ✅ AI agents don't need local tool installs
- ✅ Same environment locally and in CI
- ✅ Faster onboarding (5 mins vs 1-2 hours)
- ✅ Shared across all monorepo apps (not just thiccc)
- ✅ Zero filesystem bloat (no node_modules, cargo cache)

### Why Rust Backend (not Python/Node)?

- ✅ Directly import `shared/` crate (business logic)
- ✅ Type safety (no runtime errors)
- ✅ Performance (handles thousands of requests/sec)
- ✅ Single language for core + API (Rust everywhere)

## Data Flow Example

**User creates a workout:**

1. User clicks "Create Workout" in Next.js UI
2. React Query sends POST to `/api/workouts`
3. Request includes Clerk JWT in Authorization header
4. Rust API validates JWT (checks if real user)
5. API calls `shared::operations::create_workout()` (existing logic!)
6. API saves workout to PostgreSQL
7. Returns JSON response
8. React Query updates cache
9. UI updates automatically

**No business logic in frontend or API - it's all in `shared/`!**

## Next Steps

1. **Read Phase 1:** `01-PHASE-1-SETUP.md` - Setup dev environment
2. **Install Dagger:** See `/docs/dagger/QUICKSTART.md`
3. **Start building:** Follow phases sequentially

## Questions?

- **Architecture:** See `reference/` folder
- **Dagger:** See `/docs/dagger/`
- **iOS app:** See `../ARCHITECTURE.md`
- **Rust core:** See `../SHARED-CRATE-MAP.md`

## Success Metrics

**MVP is complete when:**
- ✅ Users can sign up and log in
- ✅ Users can create and track workouts
- ✅ Users can view workout history
- ✅ Users can see analytics (charts, PRs)
- ✅ Trainers can manage clients
- ✅ Admins can view system health
- ✅ All tests passing (Rust: 100%, Frontend: >80%)
- ✅ Deployed to production (Vercel + Railway)

**Target: 13 weeks from Phase 1 to production-ready MVP.**

