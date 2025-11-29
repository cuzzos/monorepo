# Thiccc Application Architecture

**Last Updated:** November 2025

This document provides a high-level architectural overview of the Thiccc workout tracking application.

---

## Table of Contents

- [Technology Stack](#technology-stack)
- [Architectural Pattern](#architectural-pattern)
- [Project Structure](#project-structure)
- [Data Flow](#data-flow)
- [Key Design Decisions](#key-design-decisions)
- [Development Workflow](#development-workflow)

---

## Technology Stack

### Core (Business Logic)
- **Rust (2024 Edition)** - All business logic, state management, and data models
- **Crux Framework** - Cross-platform application framework
- **Serde** - Serialization for data transfer across FFI boundary
- **UniFFI** - Automatic Rust ↔ Swift bindings generation
- **Chrono** - Date and time handling

### Shell (iOS UI)
- **Swift 6.0+** - iOS shell implementation
- **SwiftUI** - Declarative UI framework
- **iOS 18.0+** - Minimum deployment target (latest only)

### Testing
- **Rust built-in test framework** - Unit and integration tests
- **XCTest** - iOS UI tests (planned)

---

## Architectural Pattern

Thiccc follows the **Crux architecture pattern**, which separates business logic from platform-specific code:

```
┌──────────────────────────────────────────────────────┐
│                   iOS Shell (Swift)                  │
│              Thin UI layer - SwiftUI Views           │
│                                                      │
│  - Renders ViewModels                                │
│  - Captures user interactions                        │
│  - Implements platform capabilities                  │
└──────────────┬───────────────────────┬───────────────┘
               │                       │
          Events (↓)            ViewModels (↑)
        (serialized bytes)      (serialized bytes)
               │                       │
┌──────────────▼───────────────────────▼───────────────┐
│              Rust Core (Business Logic)              │
│                                                      │
│  ┌────────────────────────────────────────────────┐  │
│  │  Event → Update → Model → View → ViewModel    │  │
│  └────────────────────────────────────────────────┘  │
│                                                      │
│  - All state management                              │
│  - All business rules                                │
│  - All data validation                               │
│  - Platform-agnostic                                 │
└──────────────────────────────────────────────────────┘
```

### Why This Architecture?

1. **Shared Logic**: Write business logic once, use across platforms (iOS, Android, Web)
2. **Testability**: Pure Rust logic is easy to test without UI
3. **Type Safety**: Rust's type system prevents entire classes of bugs
4. **Clear Boundaries**: Strict separation between UI and logic
5. **Platform Independence**: Core logic never depends on platform APIs

---

## Project Structure

```
applications/thiccc/
├── app/
│   ├── iOS/                          # iOS Shell (Swift/SwiftUI)
│   │   ├── Thiccc/
│   │   │   ├── Views/                # SwiftUI Views
│   │   │   ├── Capabilities/         # Platform implementations
│   │   │   └── Core.swift            # Crux bridge
│   │   └── Thiccc.xcodeproj/
│   │
│   ├── shared/                       # Rust Core (Business Logic)
│   │   ├── src/
│   │   │   ├── lib.rs                # FFI bridge & exports
│   │   │   ├── models.rs             # Domain models (Workout, Exercise, etc.)
│   │   │   ├── id.rs                 # Type-safe UUID wrapper
│   │   │   ├── operations.rs        # Capability operation types
│   │   │   └── app/                  # Crux App implementation
│   │   │       ├── mod.rs            # App trait impl, orchestration
│   │   │       ├── events.rs         # Event definitions (40+ variants)
│   │   │       ├── model.rs          # App state
│   │   │       ├── view_models.rs    # ViewModels for UI
│   │   │       ├── effects.rs        # Capability effects
│   │   │       ├── update/           # Business logic by feature
│   │   │       │   ├── mod.rs        # Event routing
│   │   │       │   ├── workout.rs
│   │   │       │   ├── exercise.rs
│   │   │       │   ├── sets.rs
│   │   │       │   ├── timer.rs
│   │   │       │   ├── history.rs
│   │   │       │   ├── import_export.rs
│   │   │       │   ├── plate_calculator.rs
│   │   │       │   ├── capabilities.rs
│   │   │       │   └── app_lifecycle.rs
│   │   │       └── tests/            # Comprehensive test suite
│   │   │           ├── mod.rs
│   │   │           ├── event_tests.rs
│   │   │           ├── model_tests.rs
│   │   │           ├── view_model_tests.rs
│   │   │           └── integration_tests.rs
│   │   └── Cargo.toml
│   │
│   └── shared_types/                 # Generated Swift types
│       └── generated/swift/
│
├── docs/                             # Documentation
│   ├── ARCHITECTURE.md               # This file
│   ├── ADDING-FEATURES-GUIDE.md      # Developer guide
│   ├── SHARED-CRATE-MAP.md           # Detailed code map
│   └── code_migration_plans/         # Refactoring plans
│
└── Makefile                          # Build commands
```

---

## Data Flow

### Event Flow (User Action → State Update)

```
1. User taps "Add Exercise" button in SwiftUI
   ↓
2. Swift calls: core.process_event(Event.addExercise(...))
   ↓
3. Event serialized to bytes, crosses FFI boundary
   ↓
4. Rust deserializes Event
   ↓
5. update::handle_event() routes to exercise.rs module
   ↓
6. exercise::handle_event() mutates Model, returns Command
   ↓
7. Command executed (may trigger capabilities)
   ↓
8. Rust serializes ViewModel, returns bytes
   ↓
9. Swift deserializes ViewModel, updates UI
```

### Capability Flow (Async Operations)

```
1. Core needs data from database
   ↓
2. Returns Command::request_from_shell(DatabaseOperation::LoadWorkouts)
   ↓
3. iOS capability receives request
   ↓
4. iOS performs database query
   ↓
5. iOS calls: core.handle_response(id, result)
   ↓
6. Core receives DatabaseResult, updates Model
   ↓
7. Returns updated ViewModel to iOS
```

---

## Key Design Decisions

### 1. String IDs at FFI Boundary

**Decision:** Use `String` for IDs in Events/ViewModels, convert to type-safe `Id` in Rust.

**Rationale:**
- UniFFI doesn't support custom wrappers well
- Validation happens at the boundary
- Type safety maintained within Rust core

```rust
// In Event
Event::DeleteExercise { exercise_id: String }

// In Rust handler
match Id::from_string(exercise_id) {
    Ok(id) => { /* use validated ID */ }
    Err(e) => { /* handle error */ }
}
```

### 2. Feature-Based Update Modules

**Decision:** Split update logic into feature modules (workout.rs, exercise.rs, etc.).

**Rationale:**
- Each module averages ~70 lines (highly maintainable)
- Clear separation of concerns
- Easy to locate feature logic
- Scales well as app grows

### 3. Immutable Model + Command Pattern

**Decision:** Update functions mutate Model and return Commands for side effects.

**Rationale:**
- Clear distinction between state changes and side effects
- Testable: Can verify state without executing capabilities
- Crux framework requirement

### 4. Comprehensive Test Coverage

**Decision:** Tests organized by concern (events, model, viewmodels, integration).

**Rationale:**
- Fast feedback during development
- Prevents regressions
- Documents expected behavior
- Enables confident refactoring

### 5. iOS 18.0+ Only

**Decision:** No backward compatibility, latest iOS SDK only.

**Rationale:**
- Always use latest Swift/SwiftUI features
- Simpler codebase (no version checks)
- Better performance and security
- Follows 2025 best practices

---

## Development Workflow

### Adding a New Feature

1. **Define Event** (events.rs)
2. **Update Model** (model.rs)
3. **Create/Update Module** (update/feature.rs)
4. **Route Event** (update/mod.rs)
5. **Add ViewModel** (view_models.rs)
6. **Update View Builder** (mod.rs)
7. **Write Tests** (tests/)
8. **Build** (`make build-shared` generates Swift types)
9. **Implement Swift UI** (iOS/)

See [ADDING-FEATURES-GUIDE.md](./ADDING-FEATURES-GUIDE.md) for detailed instructions.

### Testing Strategy

```bash
# Rust tests (fast, run frequently)
cd app/shared
cargo test --lib

# Type generation
cargo build

# Full iOS build
cd app/iOS
xcodebuild ...
```

### Build Commands

```bash
# Development
make dev              # Start full dev environment

# Rust core
make build-shared     # Build Rust, generate types
make test-shared      # Run Rust tests
make check-shared     # Check compilation

# iOS
make build-ios        # Build iOS app
make run-ios          # Run in simulator
```

---

## Capability System

Capabilities are platform-specific operations that the core can request:

| Capability | Purpose | Operations |
|------------|---------|------------|
| **Database** | Persistent workout storage | Save, Load, Delete workouts |
| **Storage** | Temporary workout storage | Save/Load in-progress workout |
| **Timer** | Workout timer | Start, Stop, Tick |
| **Render** | UI update trigger | Force re-render |

**Pattern:**
```rust
// Core requests operation
Command::request_from_shell(DatabaseOperation::LoadWorkouts)
    .then_send(|result| Event::DatabaseResponse { result })

// Platform executes, returns result
// Core handles response in capabilities.rs
```

---

## State Management

All application state lives in the `Model` struct:

```rust
pub struct Model {
    // Active workout state
    current_workout: Option<Workout>,
    workout_timer_seconds: i32,
    timer_running: bool,
    
    // History
    workout_history: Vec<Workout>,
    
    // Navigation
    selected_tab: Tab,
    navigation_stack: Vec<NavigationDestination>,
    
    // UI state (modals, loading, errors)
    showing_add_exercise: bool,
    is_loading: bool,
    error_message: Option<String>,
    // ... etc
}
```

**Rules:**
- Model is the **single source of truth**
- Only update() functions mutate Model
- Swift UI is **derived from ViewModels** (never holds state)

---

## Error Handling

### Rust Core
- Use `Result<T, E>` for recoverable errors
- Set `model.error_message` for user-facing errors
- Log errors for debugging

### Swift Shell
- Display `error_message` from ViewModel
- Present user-friendly alerts
- Log errors for diagnostics

---

## Performance Considerations

### Serialization Overhead
- Events/ViewModels cross FFI boundary as bytes
- Serde serialization is fast but not free
- Keep ViewModels lean (only UI-necessary data)

### Memory Management
- Rust core owns all data
- Swift only holds ViewModels (lightweight)
- No shared memory across FFI

### Rendering
- Only trigger renders when state changes
- Batch updates when possible
- SwiftUI efficiently diffs ViewModels

---

## Security

### Data Validation
- **Always validate at boundaries** (FFI, JSON import)
- IDs validated when converting from String
- User input sanitized before database operations

### Storage
- Sensitive data encrypted (planned)
- Database access restricted to app sandbox
- No hardcoded secrets

---

## Future Considerations

### Potential Features
- [ ] Android support (reuse Rust core)
- [ ] Web version (WASM + Rust core)
- [ ] Apple Watch companion app
- [ ] Workout templates
- [ ] Social features (share workouts)
- [ ] Analytics/insights
- [ ] Cloud sync

### Technical Debt
- [ ] Add workout template system
- [ ] Implement comprehensive iOS UI tests
- [ ] Add performance benchmarks
- [ ] Consider pagination for large history

---

## References

- **Crux Framework**: https://github.com/redbadger/crux
- **UniFFI**: https://mozilla.github.io/uniffi-rs/
- **Rust Book**: https://doc.rust-lang.org/book/
- **SwiftUI**: https://developer.apple.com/documentation/swiftui/

---

## Questions?

1. **Adding Features?** → [ADDING-FEATURES-GUIDE.md](./ADDING-FEATURES-GUIDE.md)
2. **Code Details?** → [SHARED-CRATE-MAP.md](./SHARED-CRATE-MAP.md)
3. **Refactoring History?** → [code_migration_plans/README.md](./code_migration_plans/README.md)

**For architecture questions or suggestions, open an issue or PR!**
