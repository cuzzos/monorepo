# Phase 3: Core API & Database

## 🤖 AI Agent Instructions

**When starting this phase:**
1. Read all files in "Required Context" section below
2. Understand we're setting up database schema and first API endpoints
3. Follow tasks sequentially
4. Validate each step before proceeding
5. Stop at human checkpoints (marked with 🚨)

---

## 📚 Required Context

Auto-read these files before starting:

### Previous phases
- `@applications/thiccc/docs/web/02-PHASE-2-AUTH.md` - Auth setup

### Data models
- `@applications/thiccc/shared/src/models.rs` - Existing Rust data models
- `@applications/thiccc/ios/Thiccc/Tests/DatabaseCapabilityTests.swift` - iOS schema reference

### Backend patterns
- `@applications/thiccc/api_server/src/main.rs` - Current backend

---

## 🎯 Feature Overview

**What we're building:** Database schema and foundational API endpoints

**Why:** Need persistent storage for workouts and a REST API for frontend to consume.

**Success criteria:**
- ✅ PostgreSQL schema matches iOS app (workouts, exercises, sets)
- ✅ Database migrations work
- ✅ Health check endpoint works
- ✅ `/api/me` endpoint returns current user
- ✅ Error handling middleware in place
- ✅ CORS configured correctly
- ✅ All tests passing (100% coverage)

---

## 🔨 Tasks

### Task 1: Design Database Schema (Estimated: 30 mins)

**Goal:** Create SQL schema matching iOS app structure

Create first migration: `api_server/migrations/001_initial_schema.sql`

Tables:
- `workouts` (id, user_id, name, started_at, completed_at, notes)
- `exercises` (id, workout_id, name, order_index)
- `sets` (id, exercise_id, weight, reps, completed_at, rpe)

---

### Task 2: Setup SQLx (Estimated: 20 mins)

**Goal:** Configure database connection and migrations

Update `main.rs` to connect to PostgreSQL.

Use `sqlx::migrate!()` to apply migrations.

---

### Task 3: Run First Migration (Estimated: 10 mins)

**Goal:** Apply schema to Railway database

**Validation:**
```bash
dagger call db-migrate --source=applications/thiccc/api_server
dagger call db-query --sql="\\dt"
```

---

### Task 4: Create Error Handling Middleware (Estimated: 25 mins)

**Goal:** Standardized error responses

Create `api_server/src/middleware/error.rs`.

Define `ApiError` type with proper HTTP status codes.

---

### Task 5: Create `/api/me` Endpoint (Estimated: 30 mins)

**Goal:** Return current user from JWT

Create `api_server/src/routes/users.rs`.

Extract user ID from JWT, query database (or return from token).

---

### Task 6: Setup CORS (Estimated: 10 mins)

**Goal:** Allow frontend (localhost:3000) to call API

Add `tower-http` CORS layer.

---

### Task 7: Add API Client to Frontend (Estimated: 20 mins)

**Goal:** Centralized API calling with React Query

Create `web_frontend/lib/api.ts`.

Setup React Query provider.

---

## ✅ Phase Completion Checklist

- [ ] Database schema created
- [ ] Migrations applied to Railway
- [ ] Health check endpoint works
- [ ] `/api/me` endpoint works
- [ ] Error handling works
- [ ] CORS configured
- [ ] Frontend can call API
- [ ] All backend tests passing (100%)
- [ ] Frontend type checks pass

---

## 🚨 Common Issues

### Issue: Migration fails

**Symptom:** `sqlx error: relation already exists`

**Solution:** Reset database and reapply:
```bash
dagger call db-reset --source=applications/thiccc/api_server
dagger call db-migrate --source=applications/thiccc/api_server
```

### Issue: CORS error in browser

**Symptom:** `Access to fetch blocked by CORS policy`

**Solution:** Check `tower-http` CORS configuration allows `http://localhost:3000`.

---

## 🔗 Dependencies

**Requires:**
- Phase 2: Auth (needs JWT validation)

**Blocks:**
- Phase 4: Admin Dashboard (needs `/api/me` endpoint)

---

## Next Phase

Once complete, proceed to:
**Phase 4: Admin Dashboard & Debug Panel** (`04-PHASE-4-ADMIN-DEBUG.md`)

