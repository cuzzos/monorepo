# Goonlytics → Thiccc Migration Overview

> **🚨 CURRENT STATUS (January 16, 2026):**
> **MVP Progress:** 87.5% complete (7/8 MVP tasks done)
> **Active Phase:** Phase 7 (History Views UI) - **IN PROGRESS**
> **Next Phase:** Phase 8 (Exercise Library + Custom CRUD) - **READY**
> **Why:** History views complete the track→save→review user flow for MVP

## Executive Summary

This document provides a comprehensive plan for migrating the Goonlytics iOS workout tracking application to the new Thiccc architecture using the Crux framework (Rust core + SwiftUI shell).

**Migration Goals:**
- Port all Goonlytics features to Thiccc
- Maintain Crux architecture principles (business logic in Rust, thin UI layer)
- Ensure feature parity with Goonlytics
- Improve maintainability and testability

## Current State Analysis

### Goonlytics (Legacy)
- **Architecture**: Pure SwiftUI with GRDB database
- **State Management**: `@Observable`, `@Shared`, Swift Dependencies
- **Database**: GRDB (SQLite) with custom sharing layer
- **Features**: Full workout tracking, history, plate calculator, timers, import/export

### Thiccc (Current)
- **Architecture**: Crux framework (Rust core + SwiftUI shell)
- **Current Functionality**: Simple counter app (increment/decrement/reset)
- **Status**: Working iOS build, foundation ready for feature development

## Migration Strategy

### Architecture Principles

1. **All Business Logic in Rust Core**
   - State management
   - Data validation
   - Calculations (stats, plate calculator)
   - Exercise library

2. **Platform-Specific via Capabilities**
   - Database operations (GRDB on iOS)
   - File I/O
   - Timers
   - Network requests

3. **Thin SwiftUI Shell**
   - Declarative views
   - User input collection
   - Rendering ViewModels from core
   - Minimal local state

## Phase Organization

The migration is organized into 12 phases with approximately 40 discrete tasks:

| Phase | Focus Area | Complexity | Est. Tasks | Dependencies | Status | MVP Notes | Implementation Notes |
|-------|------------|------------|------------|--------------|--------|-----------|----------------------|
| 7 | History Views UI | Medium | 2 | Database Complete | 🚨 **ACTIVE** | MVP CRITICAL - view saved workouts | ViewModels exist, Swift UI needs implementation |
| 8 | Exercise Library + Custom CRUD | High | 6 | Phase 7 | ⏳ Ready | MVP CRITICAL - custom exercises required | Hardcoded library exists, needs database integration |
| 10 | Additional Business Logic | Medium | 3 | Phase 7 | 📋 Ready | Post-MVP - stats/calculator | Core logic ready; needs DB for history stats |
| 11 | Polish & Testing | Medium | 4 | Phase 8 | ⏳ Blocked | Post-MVP - quality assurance | Continuous; formal polish after MVP |
| 12 | Server Sync & Analytics | Very High | 10+ | Phase 11 | ⏳ Blocked | Post-MVP - cloud features | Server API, sync, analytics, images |

## Recommended Execution Order

### Critical Path (MVP - Minimum Viable Product)
**These phases make the app functional for real users:**

1. ✅ **Foundation** (Phases 1-4) - Data models, events, capabilities, business logic **[COMPLETED]**
2. ✅ **Navigation** (Phase 5) - Basic app structure and tab navigation **[COMPLETED]**
3. ✅ **Workout Tracking** (Phase 6) - Create workouts, add exercises, log sets **[COMPLETED]**
4. ✅ **Persistence** (Phase 9) - **COMPLETE: Workouts save to database** **[COMPLETED]**
   - **Result:** Users can now save their workouts. Data persists across app restarts.
   - **Unblocks:** Phase 7 (History) and Phase 8 (Custom Exercises)
5. 🚨 **History Views** (Phase 7) - **ACTIVE: View past workouts and track progress**
   - Implement Swift UI for workout history list and detail views
   - Connect existing ViewModels to database operations
   - **Why MVP-Critical:** Completes track→save→review user flow
6. ⏳ **Exercise Library + Custom CRUD** (Phase 8) - **READY: Custom exercises required**
   - Database-backed exercise library (60+ built-in exercises)
   - Custom exercise creation/deletion
   - **Why MVP-Critical:** Users need flexibility to create exercises not in built-in library

**MVP Complete After:** Phases 7 + 8 = Users can track, save, create custom exercises, and review workouts

---

## 🎉 Phase 9 Complete (December 25, 2025)

### What Was Accomplished

**Database Persistence**: Fully functional GRDB implementation with:
- ✅ 3-table schema (workouts, exercises, exerciseSets) with foreign keys
- ✅ Save/Load/Delete operations working
- ✅ 3-tier error handling (direct save → retry → backup to file)
- ✅ Database inspector debug tool
- ✅ Migrations system for schema versioning
- ✅ In-memory test database support

**Impact:**
- 🎯 **App is now persistent** - workouts survive app restarts
- 🎯 **Unblocks Phase 7** - history can now display saved workouts
- 🎯 **MVP 80% complete** - only History UI remains for core flow

### Implementation Details
- **Files Created:** 4 (Schema, Manager, Capability rewrite, Inspector)
- **Lines of Code:** ~1,560
- **Time Taken:** 1.5 hours
- **Tests:** Rust 4/4 passing

Database implementation is complete with GRDB schema, 3-tier error handling, and comprehensive testing.

---

## 🚨 Why Phase 7 (History) is Next

### Current State Assessment
**What Works:**
- ✅ Users can start a workout session
- ✅ Users can add exercises from library (60+ exercises available)
- ✅ Users can log sets with weight, reps, RPE
- ✅ Timer tracks workout duration
- ✅ Stats display in real-time (volume, sets, duration)
- ✅ **Workouts save to database and persist across restarts**

**What Doesn't Work:**
- ❌ Cannot view past workouts (History tab needs Swift UI implementation)
- ❌ Cannot see progress over time
- ❌ No "previous" data shown for exercises
- ❌ Cannot review or analyze completed workouts

### MVP Definition: "Can a user actually use this for their workout routine?"

**Current Status:** ALMOST - Phase 7 In Progress
- User logs a workout Monday → **saves to database** ✅
- User opens app Tuesday → workout is saved BUT **cannot view it** ❌
- User cannot track progress week-to-week
- App is **functional but incomplete** - missing the "review" part of track→save→review

**With Phase 7 Complete:** YES (MVP COMPLETE)
- User logs workout → saves to database ✅
- User can **view workout history** ✅
- User sees "previous" data for each exercise ✅
- User can **track progress over time** ✅
- App completes the **full user flow**

### Phase 7 vs Other Phases for MVP

| Phase | Contributes to MVP? | Justification |
|-------|---------------------|---------------|
| Phase 7 (History) | **Critical - ACTIVE** | Core user flow incomplete without it |
| Phase 8 (Exercise Library) | **Critical - NEXT** | Custom exercises needed for flexibility |
| Phase 10 (Stats/Calculator) | Post-MVP | Nice-to-have, not essential for tracking |
| Phase 11 (Polish) | Post-MVP | Quality, not functionality |
| Phase 12 (Optional) | Post-MVP | Explicitly optional features |

**Phase 7 is the CURRENT phase to complete MVP.**

### Business Value
- **Complete User Flow:** Track → Save → Review (final piece)
- **Progress Tracking:** Users can see improvement over time
- **User Retention:** Seeing history motivates continued use
- **Data Utilization:** Database is useless without a way to view it

### Technical Dependencies
- ✅ Phase 3 (Capabilities) - Database capability implemented
- ✅ Phase 4 (Business Logic) - Workout load logic ready
- ✅ Phase 9 (Database) - Persistence working
- ✅ ViewModels implemented in Rust core
- ✅ Database operations implemented
- ✅ Events and state management ready

**Conclusion:** Phase 7 is ACTIVE - implement Swift UI to complete MVP. Transforms app from "tracks and saves" to "tracks, saves, and shows progress."

---

### Post-MVP Enhancements
- **Phase 10** - Advanced features (detailed stats, plate calculator)
- **Phase 11** - Polish, testing, performance optimization
- **Phase 12** - Optional nice-to-haves (server sync, analytics)

### Parallel Opportunities
- Phase 10 can be developed alongside Phase 7
- Phase 11 should be continuous (test as you build)

---

## 📚 Exercise Library Strategy (Updated December 25, 2025)

### Decision: Single-Table Database with Custom Exercise CRUD

**What Changed:**
- ❌ **OLD:** Hardcoded Swift array (60+ exercises)
- ✅ **NEW:** Database-backed with `exercises` table
- ✅ **NEW:** Users can create/delete custom exercises
- ✅ **NEW:** Single table design (no duplication)

### Architecture

**Database Schema:**
```sql
CREATE TABLE exercises (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    muscle_group TEXT NOT NULL,
    type TEXT NOT NULL,
    source TEXT NOT NULL DEFAULT 'builtin',  -- 'builtin' | 'user' | 'community'
    is_custom BOOLEAN NOT NULL DEFAULT 0,
    usage_count INTEGER NOT NULL DEFAULT 0,  -- For future analytics
    created_at INTEGER NOT NULL
);
```

**Migration Path:**
1. **Phase 8 (Now - MVP):** Seed database with 60 built-in exercises on first launch
2. **Phase 8 (Now - MVP):** User can create custom exercises (`source = 'user'`)
3. **Phase 12 (Post-MVP):** Server provides community exercises (`source = 'community'`)

### Why This Approach?

**For MVP:**
- ✅ **Offline-first:** No server dependency
- ✅ **Flexible:** Users can create custom exercises (pen & paper equivalent)
- ✅ **Simple:** Single table, single query
- ✅ **Fast:** Local database queries are instant
- ✅ **Future-proof:** Schema ready for sync, images, analytics

**Why Custom Exercises are MVP-Critical:**
Thiccc aims to replace pen & paper workout journals. Just as users can write any exercise name in a notebook, they must be able to create custom exercises in the app. Real-world scenarios:
- User's gym has unique machines ("Hammer Strength Chest Press")
- User does exercise variations ("Close-Grip Bench Press")
- User creates compound movements ("Squat + Shoulder Press")
- User tracks unconventional exercises ("Tire Flips", "Sled Push")

**Without custom exercises:** Users are limited to 60 built-in options → frustration → churn

**With custom exercises:** Users have unlimited flexibility → adoption → retention

### Phase 8 Status: Ready (Post-Phase 7)

**What's Done (Already Implemented):**
- ✅ `AddExerciseView.swift` - Searchable exercise picker
- ✅ `ImportWorkoutView.swift` - JSON import for templates
- ✅ Hardcoded library ready for database seeding
- ✅ `GlobalExercise` model in Rust core
- ✅ `AddExercise` event handling

**What's Needed for MVP (6-8 hours):**
- 🔲 Database `exercises` table schema and operations
- 🔲 Seed database with 60+ built-in exercises on first launch
- 🔲 Custom exercise creation form
- 🔲 Custom exercise deletion (swipe-to-delete)
- 🔲 Update `AddExerciseView` to read from database
- 🔲 Database operations for exercise CRUD

**What's Post-MVP (Nice-to-Have):**
- ⏳ Stopwatch/Rest timer modals
- ⏳ Plate calculator UI

### Long-Term Vision (Phase 12)

See detailed architecture in `12-PHASE-12-OPTIONAL.md`

**Server Sync Features:**
1. **Community Exercise Library**
   - Users submit custom exercises
   - Manual moderation (Phase 1) → AI-assisted (Phase 2)
   - Conflict resolution for duplicate names
   - Exercise images/videos from CDN

2. **Workout History Backup**
   - Cloud backup of all workouts
   - Multi-device sync
   - Conflict resolution (last-write-wins or merge)

3. **Social Analytics ("Thiccc Wrapped")**
   - Spotify Wrapped-style year-end summary
   - Community rankings (top X% of users)
   - Shareable graphics for social media
   - Exercise usage statistics

4. **Advanced Features**
   - Exercise images/GIFs from open-source databases
   - Video tutorials (YouTube embeds)
   - Exercise recommendations based on history
   - Progress tracking per exercise

**Tech Stack (Planned):**
- Backend: Rust + Axum (shares types with iOS app!)
- Database: Postgres + Redis
- Storage: S3/R2 for images
- Hosting: Fly.io (~$10-20/month to start)
- Analytics: ClickHouse or TimescaleDB

**Cost Estimates:**
- MVP backend: $10-20/month
- 1K users: $50-100/month
- 10K users: $200-500/month
- 100K users: $2K-5K/month

**Feature Flags:**
Enable/disable server features without code changes:
```swift
struct FeatureFlags {
    static let serverSyncEnabled = false  // Default: offline-only
    static let communityExercisesEnabled = false
    static let analyticsEnabled = false
}
```

**Offline-First Guarantee:**
Even with server features enabled, app MUST work 100% offline. Sync happens in background when online. No user-facing failures if server is down.

---

## Key Dependencies & Risks

### Dependencies

1. **Rust Crates**
   - `crux_core` - Crux framework
   - `serde` / `serde_json` - Serialization
   - `uuid` - Unique identifiers
   - `chrono` - Date/time handling
   - `thiserror` - Error handling

2. **Swift Packages**
   - `GRDB` - SQLite database
   - Keep existing dependencies from Goonlytics where appropriate

3. **Build Tools**
   - UniFFI for Rust-Swift bindings (if needed beyond Crux)
   - Xcode project configuration

### Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Capability complexity | High | Start simple, iterate. Use Crux examples as reference |
| Database capability performance | Medium | Test with large datasets early. Consider batching operations |
| State serialization overhead | Medium | Profile and optimize. Consider selective serialization |
| Testing Rust business logic | Low | Write comprehensive unit tests in Rust from start |
| Swift-Rust type mismatches | Medium | Use shared_types code generation, validate early |

## Success Criteria

### Phase Completion Criteria
- All code compiles without errors
- All tests pass
- Feature works in iOS simulator
- Matches Goonlytics behavior
- Follows Crux architecture principles

### Migration Complete Criteria
- [ ] All Goonlytics features implemented
- [ ] App builds and runs on iOS
- [ ] All user flows tested and working
- [ ] Database persistence working
- [ ] Timer functionality working
- [ ] No regressions from Goonlytics
- [ ] Code follows principal engineer standards
- [ ] Comprehensive test coverage

## Document Index

- **[00-OVERVIEW.md](./00-OVERVIEW.md)** (this file)
- **[07-PHASE-7-HISTORY-VIEWS.md](./07-PHASE-7-HISTORY-VIEWS.md)** - History UI (ACTIVE)
- **[08-PHASE-8-ADDITIONAL-FEATURES.md](./08-PHASE-8-ADDITIONAL-FEATURES.md)** - Exercise Library + Custom CRUD (READY)
- **[10-PHASE-10-ADDITIONAL-LOGIC.md](./10-PHASE-10-ADDITIONAL-LOGIC.md)** - Stats, calculator logic
- **[11-PHASE-11-POLISH.md](./11-PHASE-11-POLISH.md)** - Testing and polish
- **[12-PHASE-12-OPTIONAL.md](./12-PHASE-12-OPTIONAL.md)** - Optional enhancements

**Completed Phases (Documents Deleted):**
- ~~Phase 1: Core Data Models~~ - ✅ Complete (Jan 2026)
- ~~Phase 2: Events & State~~ - ✅ Complete (Jan 2026)
- ~~Phase 3: Capabilities~~ - ✅ Complete (Jan 2026)
- ~~Phase 4: Core Business Logic~~ - ✅ Complete (Jan 2026)
- ~~Phase 5: Main Navigation UI~~ - ✅ Complete (Jan 2026)
- ~~Phase 6: Workout View UI~~ - ✅ Complete (Jan 2026)
- ~~Phase 9: Database Implementation~~ - ✅ Complete (Jan 2026)
- **[AGENT-PROMPT-TEMPLATES.md](./AGENT-PROMPT-TEMPLATES.md)** - Templates for prompting Cursor agents

## Notes for Future Developers

### Before Starting Any Task
1. Read the relevant phase document
2. Check dependencies are complete
3. Review the agent prompt template
4. Read the Crux documentation if needed
5. Check existing Goonlytics code for reference

### When Working on a Task
1. Follow the Crux architecture principles
2. Adhere to principal engineer standards (see `/applications/thiccc/.cursor/context`)
3. Write tests alongside implementation
4. Test in iOS simulator frequently
5. Reference Goonlytics code for UI/behavior

### When Completing a Task
1. Verify all success criteria met
2. Run tests
3. Test in iOS simulator
4. Document any deviations or issues
5. Update this plan if needed

## Contact & Questions

If you have questions about the migration plan:
- Review the detailed phase documents
- Check the agent prompt templates
- Review existing Goonlytics implementation
- Consult Crux framework documentation at github.com/redbadger/crux

---

**Last Updated**: January 16, 2026
**Status**: Phase 7 Active (History Views), Phase 8 Ready (Exercise Library)

