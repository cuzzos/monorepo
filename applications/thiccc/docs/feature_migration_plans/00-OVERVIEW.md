# Goonlytics → Thiccc Migration Overview

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

| Phase | Focus Area | Complexity | Est. Tasks | Dependencies | Status |
|-------|------------|------------|------------|--------------|--------|
| 1 | Core Data Models | Medium | 2 | None | ✅ Complete |
| 2 | Events & State | Medium | 3 | Phase 1 | ✅ Complete |
| 3 | Capabilities | High | 3 | Phase 2 | ✅ Complete |
| 4 | Core Business Logic | High | 4 | Phases 1-3 | ✅ Complete |
| 5 | Main Navigation UI | Medium | 3 | Phase 4 | 🟡 ~30% Done |
| 6 | Workout View UI | High | 3 | Phase 5 | ⏳ Blocked |
| 7 | History Views UI | Medium | 2 | Phase 5 | ⏳ Blocked |
| 8 | Additional Features UI | Medium | 4 | Phase 5 | ⏳ Blocked |
| 9 | Database Implementation | High | 3 | Phase 3 | 📋 Ready |
| 10 | Additional Business Logic | Medium | 3 | Phase 4 | 📋 Ready |
| 11 | Polish & Testing | Medium | 4 | All previous | ⏳ Blocked |
| 12 | Optional Enhancements | Low | 3+ | Phase 11 | ⏳ Blocked |

## Recommended Execution Order

### Critical Path (Must be done in order)
1. Phase 1 → Phase 2 → Phase 3 → Phase 4 (Foundation)
2. Phase 5 (Navigation)
3. Phase 6 (Workout View - core feature)
4. Phase 9 (Database persistence)

### Parallel Opportunities
- Phases 7 & 8 can be done in parallel after Phase 5
- Phase 10 can be done alongside Phase 8
- Phase 11 should be continuous throughout

### Optional
- Phase 12 can be done after everything else

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

