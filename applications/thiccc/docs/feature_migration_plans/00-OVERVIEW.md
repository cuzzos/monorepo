# Goonlytics → Thiccc Migration Overview

> **🚨 CURRENT STATUS (December 2025):**  
> **MVP Progress:** 70% complete (6/9 MVP phases done)  
> **Next Phase:** Phase 9 - Database & Persistence (CRITICAL - blocks MVP completion)  
> **Why:** App currently works but doesn't save data. Phase 9 enables real usage.

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
| 1 | Core Data Models | Medium | 2 | None | ✅ Complete | Foundation - data structures | All domain models implemented |
| 2 | Events & State | Medium | 3 | Phase 1 | ✅ Complete | Foundation - event handling | All events + state management done |
| 3 | Capabilities | High | 3 | Phase 2 | ✅ Complete | Foundation - platform integration | Database/Storage/Timer capabilities ready |
| 4 | Core Business Logic | High | 4 | Phases 1-3 | ✅ Complete | Foundation - business rules | All update/view logic implemented |
| 5 | Main Navigation UI | Medium | 3 | Phase 4 | ✅ Complete | MVP - basic navigation | Tab navigation + routing working |
| 6 | Workout View UI | High | 3 | Phase 5 | ✅ Complete | MVP CRITICAL - workout tracking | Full workout tracking UI complete |
| 7 | History Views UI | Medium | 2 | Phase 9 | ⏳ Blocked | MVP - requires saved workouts | Views exist but need database |
| 8 | Additional Features UI | Medium | 4 | Phase 5 | 🟡 Partial | MVP - exercise library (hardcoded) | Add/Import done; Timer/Calculator missing |
| 9 | Database Implementation | High | 3 | Phase 3 | 🚨 **NEXT** | **MVP BLOCKER - persistence required** | Capability shell exists; GRDB schema needed |
| 10 | Additional Business Logic | Medium | 3 | Phase 4 | 📋 Ready | Post-MVP - stats/calculator | Core logic ready; needs DB for history stats |
| 11 | Polish & Testing | Medium | 4 | All previous | ⏳ Blocked | Post-MVP - quality assurance | Continuous; formal polish after MVP |
| 12 | Optional Enhancements | Low | 3+ | Phase 11 | ⏳ Blocked | Future - nice-to-haves | Custom exercises, social features, etc. |

## Recommended Execution Order

### Critical Path (MVP - Minimum Viable Product)
**These phases make the app functional for real users:**

1. ✅ **Foundation** (Phases 1-4) - Data models, events, capabilities, business logic
2. ✅ **Navigation** (Phase 5) - Basic app structure and tab navigation  
3. ✅ **Workout Tracking** (Phase 6) - Create workouts, add exercises, log sets
4. ✅ **Exercise Library** (Phase 8 - partial) - Hardcoded exercise list for MVP
5. 🚨 **Persistence** (Phase 9) - **CRITICAL: Save workouts to database**
   - **Why MVP?** Without this, users cannot save their workouts. App is unusable.
   - **Blocks:** Phase 7 (History) - needs saved workouts to display
6. **History** (Phase 7) - View past workouts and track progress

**MVP Complete After:** Phase 9 + Phase 7 = Users can track, save, and review workouts

### Post-MVP Enhancements
- **Phase 10** - Advanced features (detailed stats, plate calculator)
- **Phase 11** - Polish, testing, performance optimization
- **Phase 12** - Optional nice-to-haves

### Parallel Opportunities
- Phase 10 can be developed alongside Phase 7/9
- Phase 11 should be continuous (test as you build)

---

## 🚨 Why Phase 9 (Database) is Next

### Current State Assessment
**What Works:**
- ✅ Users can start a workout session
- ✅ Users can add exercises from library (60+ exercises available)
- ✅ Users can log sets with weight, reps, RPE
- ✅ Timer tracks workout duration
- ✅ Stats display in real-time (volume, sets, duration)

**What Doesn't Work:**
- ❌ Workouts disappear when app closes
- ❌ No workout history
- ❌ No progress tracking
- ❌ No "previous" data shown for sets
- ❌ Cannot view or edit past workouts

### MVP Definition: "Can a user actually use this for their workout routine?"

**Without Phase 9:** NO
- User logs a workout Monday → closes app → **data is lost**
- User opens app Tuesday → **no record of Monday's workout**
- User cannot track progress week-to-week
- App is a **demo, not a product**

**With Phase 9:** YES
- User logs workout → **saves to database**
- User can view workout history
- User sees "previous" data for each exercise
- User can track progress over time
- App is **functional for real workouts**

### Phase 9 vs Other Phases for MVP

| Phase | Contributes to MVP? | Justification |
|-------|---------------------|---------------|
| Phase 7 (History) | **Critical, but blocked** | Needs Phase 9 data to display |
| Phase 10 (Stats/Calculator) | Post-MVP | Nice-to-have, not essential for tracking |
| Phase 11 (Polish) | Post-MVP | Quality, not functionality |
| Phase 12 (Optional) | Post-MVP | Explicitly optional features |

**Phase 9 is the ONLY unblocked phase that moves us toward MVP.**

### Business Value
- **User Retention:** Users won't return if data isn't saved
- **Real Usage:** Database enables actual workout tracking (not just demo)
- **Progress Tracking:** Foundation for showing improvement over time
- **History Feature:** Unblocks Phase 7, completing the core user flow

### Technical Dependencies
- ✅ Phase 3 (Capabilities) - Database capability interface exists
- ✅ Phase 4 (Business Logic) - Workout save/load logic ready
- ❌ No blockers - all dependencies satisfied

**Conclusion:** Phase 9 transforms the app from "interesting demo" to "useful tool."

---

## 📚 Exercise Library Strategy (Addressing Phase 8 Status)

### Current Implementation (Phase 8 - Partial)
**What's Done:**
- ✅ `AddExerciseView.swift` - Searchable exercise picker with muscle group filtering
- ✅ `ImportWorkoutView.swift` - JSON import for workout templates
- ✅ Hardcoded library: 60+ exercises in Swift (temporary for MVP)

**What's Missing from Phase 8:**
- ❌ Stopwatch/Timer modal views
- ❌ Plate calculator UI
- ❌ Rest timer UI

### Exercise Library Data Source Decision

**Question:** Where should exercise library data come from?

**Answer: Hardcoded in Swift (Current Approach is Correct for MVP)**

**Rationale:**
1. **No external dependency** - App works offline, always
2. **Fast startup** - No database query needed
3. **Simple deployment** - No schema changes required
4. **Sufficient for MVP** - 60+ exercises covers common use cases

**Future Enhancement (Post-MVP):**
- Phase 10 or Phase 12: Move to database for:
  - Custom exercise creation
  - User-defined exercise library
  - Cloud sync capabilities
  - Exercise usage statistics

**Why NOT database for MVP:**
- Database is for **user data** (workouts, history)
- Exercise library is **static reference data** (like enums)
- Adding to DB adds complexity without MVP value
- Users can't create custom exercises yet anyway

**Why NOT API:**
- No backend infrastructure exists
- Offline-first is core requirement
- API dependency adds failure points

### Phase 8 Status Clarification

**Correct Status:** 🟡 **Partial** (not ✅ Complete)

**For MVP:**
- Exercise library (AddExerciseView) - ✅ Complete
- Import workout - ✅ Complete  
- Timers - ❌ Not MVP critical
- Plate calculator - ❌ Not MVP critical

**Dependency on Phase 9:**
- Exercise library: ❌ No dependency (hardcoded works)
- Import: ❌ No dependency (loads into current workout)
- Timers: ❌ No dependency (UI-only feature)
- Plate calculator: ❌ No dependency (pure math)

**Bottom Line:** Phase 8 can be completed independently of Phase 9, but timers/calculator are **post-MVP nice-to-haves**.

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
- **[01-PHASE-1-DATA-MODELS.md](./01-PHASE-1-DATA-MODELS.md)** - Rust data models
- **[02-PHASE-2-EVENTS-STATE.md](./02-PHASE-2-EVENTS-STATE.md)** - Core events and state
- **[03-PHASE-3-CAPABILITIES.md](./03-PHASE-3-CAPABILITIES.md)** - Platform capabilities
- **[04-PHASE-4-BUSINESS-LOGIC.md](./04-PHASE-4-BUSINESS-LOGIC.md)** - Update and view functions
- **[05-PHASE-5-NAVIGATION.md](./05-PHASE-5-NAVIGATION.md)** - Main navigation UI
- **[06-PHASE-6-WORKOUT-VIEW.md](./06-PHASE-6-WORKOUT-VIEW.md)** - Workout tracking UI
- **[07-PHASE-7-HISTORY-VIEWS.md](./07-PHASE-7-HISTORY-VIEWS.md)** - History UI
- **[08-PHASE-8-ADDITIONAL-FEATURES.md](./08-PHASE-8-ADDITIONAL-FEATURES.md)** - Timers, calculator, etc.
- **[09-PHASE-9-DATABASE.md](./09-PHASE-9-DATABASE.md)** - Database implementation
- **[10-PHASE-10-ADDITIONAL-LOGIC.md](./10-PHASE-10-ADDITIONAL-LOGIC.md)** - Stats, calculator logic
- **[11-PHASE-11-POLISH.md](./11-PHASE-11-POLISH.md)** - Testing and polish
- **[12-PHASE-12-OPTIONAL.md](./12-PHASE-12-OPTIONAL.md)** - Optional enhancements
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

**Last Updated**: November 30, 2025  
**Status**: Phases 1-4 Complete, Phase 5+ Ready for Implementation

