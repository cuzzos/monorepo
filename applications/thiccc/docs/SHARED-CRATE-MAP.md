# Thiccc Shared Crate - Codebase/Method Map

> **Last Updated:** November 2025 (Updated after Phase 1-3 Refactoring)
>
> This document provides a comprehensive map of all structures, methods, and logic in the `app/shared` Rust crate. **Consult this first** before making any modifications to the shared crate.
>
> **📚 New to the codebase?** See [ADDING-FEATURES-GUIDE.md](./ADDING-FEATURES-GUIDE.md) for step-by-step instructions on adding features.

## Overview

The `shared` crate is the **Rust core** of the Thiccc workout tracking application, built using the **Crux framework**. It contains all business logic, data models, and state management, following a strict architecture where the Rust core handles all logic while the iOS shell (SwiftUI) is a thin UI layer.

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         iOS Shell (Swift)                       │
│                    (Thin UI - SwiftUI Views)                    │
└────────────────────────────┬────────────────────────────────────┘
                             │ FFI (bytes)
┌────────────────────────────▼────────────────────────────────────┐
│                        lib.rs (Bridge)                          │
│        process_event() │ handle_response() │ view()             │
└────────────────────────────┬────────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────────┐
│                     app/ (Crux App Module)                      │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ events.rs: Event enum (40+ variants)                     │   │
│  │ model.rs: Model struct (app state)                       │   │
│  │ view_models.rs: ViewModel types                          │   │
│  │ effects.rs: Effect enum (capabilities)                   │   │
│  └──────────────────────────────────────────────────────────┘   │
│                             │                                    │
│  ┌──────────────────────────▼────────────────────────────────┐  │
│  │ mod.rs: App trait impl + view builders                    │  │
│  │   • update() → delegates to update/                       │  │
│  │   • view() → builds ViewModels                            │  │
│  └──────────────────────────────────────────────────────────┘   │
│                             │                                    │
│  ┌──────────────────────────▼────────────────────────────────┐  │
│  │ update/ (Feature Modules - 10 files)                      │  │
│  │   • mod.rs (router)                                       │  │
│  │   • workout.rs, exercise.rs, sets.rs                      │  │
│  │   • timer.rs, history.rs, plate_calculator.rs             │  │
│  │   • import_export.rs, capabilities.rs, app_lifecycle.rs   │  │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────────┐
│                      models.rs (Domain)                         │
│  Workout │ Exercise │ ExerciseSet │ SetActual │ PlateCalculator │
└─────────────────────────────────────────────────────────────────┘
```

---

## File Structure Summary (After Refactoring)

| File | Lines | Logic Type | Responsibility |
|------|-------|------------|----------------|
| **Core Infrastructure** ||||
| `src/lib.rs` | 72 | **Infrastructure** | FFI bridge, serialization, singleton core |
| `src/shared.udl` | 6 | **Interface** | FFI contract definition for UniFFI |
| **Application Module** ||||
| `src/app/mod.rs` | 291 | **Application** | Crux App impl, orchestration, view builders |
| `src/app/events.rs` | 246 | **Types** | Event definitions (40+ variants) |
| `src/app/model.rs` | 186 | **State** | Core application state + helpers |
| `src/app/view_models.rs` | 265 | **Types** | UI-friendly ViewModels |
| `src/app/effects.rs` | 34 | **Types** | Capability effect definitions |
| **Update Logic (Feature Modules)** ||||
| `src/app/update/mod.rs` | 84 | **Routing** | Event routing to feature modules |
| `src/app/update/workout.rs` | 114 | **Business Logic** | Workout management (start, finish, update) |
| `src/app/update/exercise.rs` | 78 | **Business Logic** | Exercise management (add, delete, move) |
| `src/app/update/sets.rs` | 93 | **Business Logic** | Set management (add, delete, update) |
| `src/app/update/timer.rs` | 67 | **Business Logic** | Timer operations |
| `src/app/update/history.rs` | 45 | **Business Logic** | History & navigation |
| `src/app/update/plate_calculator.rs` | 66 | **Business Logic** | Plate calculation |
| `src/app/update/import_export.rs` | 54 | **Business Logic** | Workout import/export |
| `src/app/update/capabilities.rs` | 104 | **Business Logic** | Capability response handling |
| `src/app/update/app_lifecycle.rs` | 22 | **Business Logic** | App initialization |
| **Domain Models** ||||
| `src/models.rs` | 1020 | **Domain** | Business entities, data structures, business rules |
| `src/id.rs` | 254 | **Domain** | Type-safe UUID wrapper |
| `src/operations.rs` | 237 | **Domain** | Capability operation types |
| **Tests** ||||
| `src/app/tests/*.rs` | 1,172 | **Testing** | Comprehensive test suite (5 files) |

**Note:** File previously named `src/app.rs` (2,469 lines) has been refactored into a modular `src/app/` directory with 20 files totaling 2,921 lines (includes better organization and spacing).

---

## File Details

### 1. `src/lib.rs` - Entry Point & FFI Bridge

**Purpose:** Library entry point, FFI bindings, and core bridge initialization.

**Key Components:**

| Symbol | Type | Description |
|--------|------|-------------|
| `CORE` | `LazyLock<Bridge<Thiccc>>` | Singleton Crux bridge instance |
| `process_event(data: &[u8]) -> Vec<u8>` | Function | FFI entry point - sends events to the core |
| `handle_response(id: u32, data: &[u8]) -> Vec<u8>` | Function | FFI entry point - handles capability responses |
| `view() -> Vec<u8>` | Function | FFI entry point - serializes current view model |

**Re-exports:** All public types from `app` and `models` modules.

---

### 2. `src/app/` - Crux Application Module (Refactored)

**Purpose:** Modular Crux application implementation organized by concern (events, state, view, update logic).

**Structure:** After Phase 1-3 refactoring, the monolithic `app.rs` (2,469 lines) has been split into a well-organized module directory:
- **Type definitions**: `events.rs`, `model.rs`, `view_models.rs`, `effects.rs`
- **Business logic**: `update/` directory with feature-based modules
- **Tests**: `tests/` directory with organized test files
- **Orchestration**: `mod.rs` with App trait implementation

#### 2.1 Events (User Interactions & System Events)

**File:** `src/app/events.rs` (246 lines)

```rust
pub enum Event {
    // ===== Workout Management =====
    StartWorkout,                                    // Start new workout session
    FinishWorkout,                                   // Finish and save workout
    DiscardWorkout,                                  // Discard without saving
    UpdateWorkoutName { name: String },              // Update workout name
    UpdateWorkoutNotes { notes: String },            // Update workout notes

    // ===== Exercise Management =====
    AddExercise { exercise: GlobalExercise },        // Add exercise from library
    DeleteExercise { exercise_id: Uuid },            // Delete exercise
    MoveExercise { from_index, to_index },           // Reorder exercises
    ShowAddExerciseView,                             // Show exercise picker modal
    DismissAddExerciseView,                          // Dismiss modal

    // ===== Set Management =====
    AddSet { exercise_id: Uuid },                    // Add new set
    DeleteSet { exercise_id, set_index },            // Delete set
    UpdateSetActual { set_id, actual: SetActual },   // Update set values
    ToggleSetCompleted { set_id: Uuid },             // Toggle completion

    // ===== Timer Events =====
    TimerTick,                                       // Increment timer
    StartTimer, StopTimer, ToggleTimer,              // Timer controls
    ShowStopwatch, DismissStopwatch,                 // Stopwatch modal
    ShowRestTimer { duration_seconds },              // Rest timer modal
    DismissRestTimer,

    // ===== History & Navigation =====
    LoadHistory,                                     // Load from database
    ViewHistoryItem { workout_id: Uuid },            // View past workout
    NavigateBack,                                    // Pop navigation stack
    ChangeTab { tab: Tab },                          // Switch tabs

    // ===== Import/Export =====
    ImportWorkout { json_data: String },             // Import from JSON
    ShowImportView, DismissImportView,               // Import modal
    LoadWorkoutTemplate,                             // Load template file

    // ===== Plate Calculator =====
    CalculatePlates { target_weight, bar_type, use_percentage },
    ClearPlateCalculation,
    ShowPlateCalculator, DismissPlateCalculator,

    // ===== Capability Responses =====
    DatabaseResponse { result: DatabaseResult },     // DB operation completed
    StorageResponse { result: StorageResult },       // Storage operation completed
    Error { message: String },                       // Error occurred
}
```

#### 2.2 Supporting Event Types

| Type | Variants | Purpose |
|------|----------|---------|
| `Tab` | `Workout`, `History` | Main navigation tabs |
| `DatabaseResult` | `WorkoutSaved`, `HistoryLoaded { workouts }`, `WorkoutLoaded { workout }` | DB capability responses |
| `StorageResult` | `CurrentWorkoutSaved`, `CurrentWorkoutLoaded { workout }`, `CurrentWorkoutDeleted` | Storage capability responses |
| `NavigationDestination` | `WorkoutDetail { workout_id }`, `HistoryDetail { workout_id }` | Navigation stack destinations |

#### 2.3 Model (Application State)

```rust
pub struct Model {
    // ===== Active Workout =====
    pub current_workout: Option<Workout>,
    pub workout_timer_seconds: i32,
    pub timer_running: bool,

    // ===== History =====
    pub workout_history: Vec<Workout>,

    // ===== Navigation State =====
    pub selected_tab: Tab,
    pub navigation_stack: Vec<NavigationDestination>,

    // ===== Modal State =====
    pub showing_add_exercise: bool,
    pub showing_import: bool,
    pub showing_stopwatch: bool,
    pub showing_rest_timer: Option<i32>,
    pub showing_plate_calculator: bool,

    // ===== Plate Calculator =====
    pub plate_calculation: Option<PlateCalculation>,

    // ===== Loading/Error State =====
    pub is_loading: bool,
    pub error_message: Option<String>,
}
```

**Model Methods:**

| Method | Signature | Purpose |
|--------|-----------|---------|
| `default()` | `fn default() -> Self` | Initialize fresh app state |
| `get_or_create_workout()` | `fn(&mut self) -> &mut Workout` | Get current or create new workout |
| `find_exercise_mut()` | `fn(&mut self, Uuid) -> Option<&mut Exercise>` | Find exercise by ID |
| `find_set_mut()` | `fn(&mut self, Uuid) -> Option<&mut ExerciseSet>` | Find set by ID across all exercises |
| `calculate_total_volume()` | `fn(&self) -> i32` | Sum of (weight × reps) for all completed sets |
| `calculate_total_sets()` | `fn(&self) -> usize` | Count of all sets in workout |
| `format_duration()` | `fn(&self) -> String` | Format timer as "MM:SS" |

#### 2.4 ViewModels (UI State)

**File:** `src/app/view_models.rs` (265 lines)

| ViewModel | Key Fields | Purpose |
|-----------|------------|---------|
| `ViewModel` | `selected_tab`, `workout_view`, `history_view`, `error_message`, `is_loading` | Root app state |
| `WorkoutViewModel` | `has_active_workout`, `workout_name`, `formatted_duration`, `total_volume`, `exercises`, `timer_running`, modal flags | Active workout tab |
| `ExerciseViewModel` | `id`, `name`, `sets: Vec<SetViewModel>` | Single exercise display |
| `SetViewModel` | `id`, `set_number`, `previous_display`, `weight`, `reps`, `rpe`, `is_completed` | Single set display |
| `HistoryViewModel` | `workouts: Vec<HistoryItemViewModel>`, `is_loading` | History list |
| `HistoryItemViewModel` | `id`, `name`, `date`, `exercise_count`, `set_count`, `total_volume` | History list item |
| `HistoryDetailViewModel` | `workout_name`, `formatted_date`, `duration`, `exercises`, `notes`, `total_volume`, `total_sets` | Past workout detail |
| `ExerciseDetailViewModel` | `name`, `sets: Vec<SetDetailViewModel>` | Exercise in history detail |
| `SetDetailViewModel` | `set_number`, `display_text` | Set in history detail |
| `PlateCalculatorViewModel` | `target_weight`, `percentage`, `bar_type_name`, `calculation`, `is_shown` | Calculator state |
| `PlateCalculationResult` | `total_weight`, `bar_weight`, `plates_per_side`, `plates` | Calculation result |
| `PlateViewModel` | `weight`, `count`, `color` | Single plate display |

#### 2.5 Update Logic (Feature Modules)

**Directory:** `src/app/update/` (10 modules, 715 lines total)

The update logic is organized into feature-based modules for better maintainability:

| Module | Lines | Handles Events | Purpose |
|--------|-------|----------------|---------|
| `mod.rs` | 84 | - | Routes events to appropriate feature modules |
| `app_lifecycle.rs` | 22 | `Initialize` | App initialization and startup |
| `workout.rs` | 114 | `StartWorkout`, `FinishWorkout`, `DiscardWorkout`, `UpdateWorkoutName`, `UpdateWorkoutNotes` | Workout lifecycle management |
| `exercise.rs` | 78 | `AddExercise`, `DeleteExercise`, `MoveExercise`, `Show/DismissAddExerciseView` | Exercise CRUD operations |
| `sets.rs` | 93 | `AddSet`, `DeleteSet`, `UpdateSetActual`, `ToggleSetCompleted` | Set management |
| `timer.rs` | 67 | `TimerTick`, `Start/Stop/ToggleTimer`, `Show/DismissStopwatch`, `Show/DismissRestTimer` | Timer and stopwatch features |
| `history.rs` | 45 | `LoadHistory`, `ViewHistoryItem`, `NavigateBack`, `ChangeTab` | History viewing and navigation |
| `import_export.rs` | 54 | `ImportWorkout`, `Show/DismissImportView`, `LoadWorkoutTemplate` | Workout import/export |
| `plate_calculator.rs` | 66 | `CalculatePlates`, `ClearPlateCalculation`, `Show/DismissPlateCalculator` | Plate loading calculator |
| `capabilities.rs` | 104 | `DatabaseResponse`, `StorageResponse`, `TimerResponse`, `Error` | Capability response handling |

**Pattern:** Each module exports a `handle_event(Event, &mut Model) -> Command<Effect, Event>` function.

#### 2.5 Thiccc App Implementation

| Method | Purpose |
|--------|---------|
| `update(&self, Event, &mut Model, &()) -> Command<Effect, Event>` | **Main state machine** - handles all events and updates Model |
| `view(&self, &Model) -> ViewModel` | **View transformation** - converts Model to ViewModel for UI |
| `build_workout_view(&self, &Model) -> WorkoutViewModel` | Build workout tab ViewModel |
| `build_exercise_view(&self, &Exercise) -> ExerciseViewModel` | Build exercise ViewModel |
| `build_set_view(&self, &ExerciseSet, i32) -> SetViewModel` | Build set ViewModel |
| `build_history_view(&self, &Model) -> HistoryViewModel` | Build history tab ViewModel |
| `build_history_item(&self, &Workout) -> HistoryItemViewModel` | Build history item ViewModel |

#### 2.6 Effects

```rust
pub enum Effect {
    Render(RenderOperation),  // Trigger UI re-render
}
```

---

### 3. `src/models.rs` - Core Data Models

**Purpose:** Domain models representing workouts, exercises, sets, and related data structures.

#### 3.1 Enums

| Enum | Variants | Default | Purpose |
|------|----------|---------|---------|
| `ExerciseType` | `Dumbbell`, `Kettlebell`, `Barbell`, `Hexbar`, `Bodyweight`, `Machine`, `Unknown` | `Unknown` | Equipment type |
| `WeightUnit` | `Kg`, `Lb`, `Bodyweight` | `Lb` | Weight measurement unit |
| `SetType` | `WarmUp`, `Working`, `DropSet`, `Amrap`, `Failure` | `Working` | Type of set |
| `BodyPartMain` | `Chest`, `Legs`, `Arms`, `Back`, `Calves`, `Shoulders`, `Core`, `Cardio`, `FullBody`, `Other` | `Other` | Muscle group category |

#### 3.2 Data Structures

##### `BodyPart`

```rust
pub struct BodyPart {
    pub main: BodyPartMain,
    pub detailed: Option<Vec<String>>,    // e.g., "upper chest"
    pub scientific: Option<Vec<String>>,  // e.g., "pectoralis major"
}
```

| Method | Purpose |
|--------|---------|
| `new(main: BodyPartMain)` | Create with main category only |
| `with_details(main, detailed, scientific)` | Create with all fields |

##### `SetSuggest` (Planned/Target Values)

```rust
pub struct SetSuggest {
    pub weight: Option<f64>,
    pub reps: Option<i32>,
    pub rep_range: Option<i32>,
    pub duration: Option<i32>,
    pub rpe: Option<f64>,
    pub rest_time: Option<i32>,
}
```

| Method | Purpose |
|--------|---------|
| `with_rest_time(i32)` | Create with default rest time |
| `with_weight_and_reps(f64, i32)` | Create with weight and reps |

##### `SetActual` (Performed Values)

```rust
pub struct SetActual {
    pub weight: Option<f64>,
    pub reps: Option<i32>,
    pub duration: Option<i32>,
    pub rpe: Option<f64>,
    pub actual_rest_time: Option<i32>,
}
```

| Method | Purpose |
|--------|---------|
| `with_weight_and_reps(f64, i32)` | Create with weight and reps |
| `volume() -> Option<f64>` | Calculate weight × reps |

##### `ExerciseSet`

```rust
pub struct ExerciseSet {
    pub id: Uuid,
    pub set_type: SetType,
    pub weight_unit: Option<WeightUnit>,
    pub suggest: SetSuggest,
    pub actual: SetActual,
    pub is_completed: bool,
    pub exercise_id: Uuid,
    pub workout_id: Uuid,
    pub set_index: i32,
}
```

| Method | Purpose |
|--------|---------|
| `new(exercise_id, workout_id, set_index)` | Create empty set |
| `new_warmup(...)` | Create warm-up set |
| `new_working(..., suggest)` | Create working set with targets |
| `complete(actual: SetActual)` | Mark completed with values |

##### `Exercise`

```rust
pub struct Exercise {
    pub id: Uuid,
    pub superset_id: Option<i32>,
    pub workout_id: Uuid,
    pub name: String,
    pub pinned_notes: Vec<String>,
    pub notes: Vec<String>,
    pub duration: Option<i32>,
    pub exercise_type: ExerciseType,
    pub weight_unit: Option<WeightUnit>,
    pub default_warm_up_time: Option<i32>,
    pub default_rest_time: Option<i32>,
    pub sets: Vec<ExerciseSet>,
    pub body_part: Option<BodyPart>,
}
```

| Method | Purpose |
|--------|---------|
| `new(name: String, workout_id: Uuid)` | Create new exercise |
| `from_global(global: &GlobalExercise, workout_id: Uuid)` | Create from library template |
| `is_completed() -> bool` | Check if all sets completed |
| `completed_sets_count() -> usize` | Count completed sets |
| `total_volume() -> f64` | Sum of completed set volumes |
| `add_set() -> &mut ExerciseSet` | Add new empty set |

##### `Workout`

```rust
pub struct Workout {
    pub id: Uuid,
    pub name: String,
    pub note: Option<String>,
    pub duration: Option<i32>,
    pub start_timestamp: DateTime<Utc>,
    pub end_timestamp: Option<DateTime<Utc>>,
    pub exercises: Vec<Exercise>,
}
```

| Method | Purpose |
|--------|---------|
| `new()` | Create empty workout with current timestamp |
| `with_name(name: impl Into<String>)` | Create named workout |
| `is_completed() -> bool` | Check if all exercises completed |
| `total_sets() -> usize` | Count all sets across exercises |
| `completed_sets() -> usize` | Count completed sets across exercises |
| `total_volume() -> f64` | Sum of all exercise volumes |
| `finish()` | Set end timestamp and calculate duration |
| `add_exercise(name) -> &mut Exercise` | Add new exercise |

##### `GlobalExercise` (Exercise Library Template)

```rust
pub struct GlobalExercise {
    pub id: Uuid,
    pub name: String,
    pub exercise_type: String,       // Serde field: "type"
    pub additional_fk: Option<String>,
    pub muscle_group: String,
    pub image_name: String,
}
```

| Method | Purpose |
|--------|---------|
| `new(name, exercise_type, muscle_group)` | Create template exercise |

#### 3.3 Plate Calculator Models

##### `Plate`

```rust
pub struct Plate {
    pub id: Uuid,
    pub weight: f64,
}
```

| Method | Purpose |
|--------|---------|
| `new(weight: f64)` | Create single plate |
| `standard() -> Vec<Plate>` | Standard lb plates: 45, 35, 25, 10, 5, 2.5 |
| `standard_kg() -> Vec<Plate>` | Standard kg plates: 25, 20, 15, 10, 5, 2.5, 1.25 |

##### `BarType`

```rust
pub struct BarType {
    pub id: Uuid,
    pub name: String,
    pub weight: f64,
}
```

| Method | Purpose |
|--------|---------|
| `new(name, weight)` | Create custom bar type |
| `olympic()` | Olympic barbell (45 lbs) |
| `standard()` | Standard barbell (20 lbs) |
| `ez_bar()` | EZ curl bar (20 lbs) |
| `trap_bar()` | Trap/hex bar (45 lbs) |
| `all_bars() -> Vec<Self>` | All common bar types |

##### `PlateCalculation`

```rust
pub struct PlateCalculation {
    pub total_weight: f64,
    pub bar_type: BarType,
    pub plates: Vec<Plate>,
    pub weight_unit: WeightUnit,
}
```

| Method | Purpose |
|--------|---------|
| `formatted_plate_description() -> String` | Format as "2x45lb, 1x25lb" |

---

### 4. `src/shared.udl` - UniFFI Interface Definition

**Purpose:** Defines the C FFI interface for Swift interop.

```
namespace shared {
  bytes process_event([ByRef] bytes msg);
  bytes handle_response(u32 id, [ByRef] bytes res);
  bytes view();
};
```

---

### 5. `src/bin/uniffi-bindgen.rs` - Code Generator

**Purpose:** Binary to generate Swift bindings from the UDL file.

```rust
fn main() {
    uniffi::uniffi_bindgen_main()
}
```

---

## Quick Reference: Where to Make Changes

| Want to... | Modify... |
|------------|-----------|
| Add a new user action | `Event` enum in `app.rs`, then handle in `update()` |
| Add new app state | `Model` struct in `app.rs` |
| Add new UI display data | Add ViewModel in `app.rs`, update `view()` or builder method |
| Add new domain entity | `models.rs` (new struct with methods) |
| Add new domain enum | `models.rs` (new enum with serde attributes) |
| Change plate calculation | `PlateCalculation` in `models.rs`, `Event::CalculatePlates` handler in `app.rs` |
| Add modal/sheet | Add boolean flag to `Model`, add Show/Dismiss events, handle in `update()` |
| Add navigation destination | `NavigationDestination` enum, handle in `ChangeTab`/`NavigateBack` |
| Add capability response | Add variant to `DatabaseResult` or `StorageResult`, handle in `update()` |

---

## Testing

All tests are located in `#[cfg(test)]` modules at the bottom of each file:

- **`app.rs` tests:** Event serialization, Model methods, ViewModel defaults, integration tests (update + view cycle)
- **`models.rs` tests:** Serialization, constructors, business logic (volume calculation, completion checks)

Run tests with:
```bash
cd app/shared
cargo test
```

---

## Dependencies

From `Cargo.toml`:

| Crate | Version | Purpose |
|-------|---------|---------|
| `crux_core` | workspace | Crux framework core |
| `serde` | workspace | Serialization (with derive) |
| `serde_json` | 1.0 | JSON serialization |
| `uuid` | 1.0 | UUID generation (with serde, v4) |
| `chrono` | 0.4 | Date/time handling (with serde) |
| `uniffi` | 0.29.4 | Swift FFI bindings |
| `wasm-bindgen` | 0.2.100 | WASM bindings (future web support) |

