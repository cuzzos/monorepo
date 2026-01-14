# Phase 5: Workouts CRUD

> **TLDR:** Core workout management feature. Complete CRUD operations for workouts, exercises, and sets. Backend imports business logic from `shared/` crate. Frontend uses TypeScript types from `shared_types`. Includes workout list page, detail page, creation flow, and React Query mutations with optimistic updates. Estimated time: 2 weeks.

## Table of Contents
- [AI Agent Instructions](#-ai-agent-instructions)
- [Required Context](#-required-context)
- [Feature Overview](#-feature-overview)
- [Tasks](#-tasks)
  - [Backend Tasks](#backend-tasks)
  - [Frontend Tasks](#frontend-tasks)
- [Phase Completion Checklist](#-phase-completion-checklist)
- [Dependencies](#-dependencies)
- [Next Phase](#next-phase)

---

## 🤖 AI Agent Instructions

**When starting this phase:**
1. Read all files in "Required Context" section below
2. Understand we're implementing core workout management features
3. Follow tasks sequentially - this is the biggest phase
4. Validate each step before proceeding
5. Stop at human checkpoints (marked with 🚨)

---

## 📚 Required Context

Auto-read these files before starting:

### Previous phases
- `@applications/thiccc/docs/web/04-PHASE-4-ADMIN-DEBUG.md` - Admin features

### Business logic
- `@applications/thiccc/shared/src/models.rs` - Workout, Exercise, ExerciseSet models
- `@applications/thiccc/shared/src/operations.rs` - Business operations

### Database schema
- `@applications/thiccc/api_server/migrations/001_initial_schema.sql` - Schema

---

## 🎯 Feature Overview

**What we're building:** Complete workout management (create, view, edit, delete workouts/exercises/sets)

**Why:** This is the core feature - users track their workouts

**Success criteria:**
- ✅ Users can create workouts
- ✅ Users can add exercises to workouts
- ✅ Users can add sets to exercises
- ✅ Users can view workout history
- ✅ Users can edit past workouts
- ✅ Users can delete workouts
- ✅ All CRUD operations work
- ✅ Backend uses `shared` crate logic
- ✅ Frontend uses TypeScript types from `shared_types`
- ✅ All tests passing (100% backend, >80% frontend)

---

## 🔨 Tasks

### Backend Tasks

1. **Create `/api/workouts` endpoints** (40 mins)
   - POST /api/workouts - Create complete workout with exercises and sets (atomic)
   - GET /api/workouts - List user's workouts
   - GET /api/workouts/:id - Get single workout
   - PATCH /api/workouts/:id - Update workout metadata
   - DELETE /api/workouts/:id - Delete workout

2. **Create `/api/workouts/:id/exercises` endpoints** (30 mins)
   - POST - Add exercise to existing workout
   - PATCH /api/exercises/:id - Update exercise
   - DELETE /api/exercises/:id - Remove exercise and sets

3. **Create `/api/exercises/:id/sets` endpoints** (30 mins)
   - POST - Add set to existing exercise
   - PATCH /api/sets/:id - Update individual set
   - DELETE /api/sets/:id - Remove set

4. **Import business logic from `shared` crate** (20 mins)
   - Use existing models
   - Use existing validation logic
   - Map to/from database types

**Notes:**
- Primary creation flow: POST /api/workouts with complete nested data
- Edit flow: Use granular PATCH endpoints for individual changes
- See `@applications/thiccc/docs/web/reference/API-SPEC.md` for full API details

#### Quick Reference: Request/Response Examples

> 📖 **Full API documentation:** [reference/API-SPEC.md](./reference/API-SPEC.md)

**POST /api/workouts** - Create workout (atomic with exercises and sets):

```json
// Request
{
  "name": "Push Day",
  "notes": "Feeling strong",
  "startedAt": "2025-01-15T10:00:00Z",
  "completedAt": "2025-01-15T11:00:00Z",
  "exercises": [
    {
      "name": "Bench Press",
      "orderIndex": 0,
      "notes": "Pause at bottom",
      "sets": [
        { "weight": 225, "reps": 5, "rpe": 8 },
        { "weight": 225, "reps": 5, "rpe": 9 },
        { "weight": 235, "reps": 3, "rpe": 9 }
      ]
    }
  ]
}

// Response: 201 Created
{
  "data": {
    "id": "workout_123",
    "userId": "user_abc",
    "name": "Push Day",
    "exercises": [
      {
        "id": "exercise_456",
        "name": "Bench Press",
        "orderIndex": 0,
        "sets": [
          { "id": "set_789", "weight": 225, "reps": 5, "rpe": 8 }
          // ... remaining sets with assigned IDs
        ]
      }
    ]
  }
}
```

**GET /api/workouts** - List workouts (paginated):

```json
// Response: 200 OK
{
  "data": {
    "currentItemCount": 10,
    "itemsPerPage": 50,
    "totalItems": 42,
    "items": [
      { "id": "workout_123", "name": "Push Day", "startedAt": "2025-01-15T10:00:00Z" }
    ]
  }
}
```

**PATCH /api/sets/:id** - Update individual set:

```json
// Request
{ "weight": 230, "reps": 6, "rpe": 8 }

// Response: 200 OK
{
  "data": {
    "id": "set_789",
    "exerciseId": "exercise_456",
    "weight": 230,
    "reps": 6,
    "rpe": 8
  }
}
```

### Frontend Tasks

5. **Create workout list page** (30 mins)
   - `app/(dashboard)/workouts/page.tsx`
   - Table/grid of workouts
   - Sort by date

6. **Create workout detail page** (40 mins)
   - `app/(dashboard)/workouts/[id]/page.tsx`
   - Show all exercises and sets
   - Edit button

7. **Create "new workout" flow** (45 mins)
   - Modal or page to create workout
   - Add exercises dynamically
   - Add sets to each exercise
   - Submit entire workout as one POST request
   - See API-SPEC.md for nested payload structure

8. **Add React Query mutations** (25 mins)
   - Optimistic updates
   - Error handling
   - Cache invalidation

9. **Create workout components** (60 mins)
   - WorkoutCard component
   - ExerciseList component
   - SetRow component
   - Shadcn/ui components

---

## ✅ Phase Completion Checklist

- [ ] All backend endpoints implemented
- [ ] Backend tests passing (100%)
- [ ] Frontend pages created
- [ ] Frontend components created
- [ ] React Query setup complete
- [ ] Can create workout end-to-end
- [ ] Can view workout history
- [ ] Can edit workout
- [ ] Can delete workout
- [ ] All frontend tests passing (>80%)
- [ ] E2E test for full workout flow

---

## 🔗 Dependencies

**Requires:**
- Phase 4: Admin Dashboard (users and auth working)

**Blocks:**
- Phase 6: Live Tracking (needs workout CRUD)

---

## Next Phase

Once complete, proceed to:
**Phase 6: Live Workout Tracking** (`06-PHASE-6-TRACKING.md`)

