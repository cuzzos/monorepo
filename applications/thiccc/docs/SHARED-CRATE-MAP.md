# Thiccc Shared Crate - Codebase/Method Map

> **Last Updated:** January 2026
>
> This document provides a comprehensive map of all structures, methods, and logic in the `shared/` Rust crate. **Consult this first** before making any modifications to the shared crate.

## Overview

The `shared` crate is the **Rust core** of the Thiccc workout tracking application, built using the **Crux framework**. It contains all business logic, data models, and state management, following a strict architecture where the Rust core handles all logic while the iOS shell (SwiftUI) and web frontend are thin UI layers.

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
│                        app.rs (Crux App)                        │
│  ┌─────────────┐  ┌──────────────┐  ┌────────────────────────┐  │
│  │   Events    │──│    update()  │──│      Model             │  │
│  │  (40+ types)│  │ (state logic)│  │ (app state)            │  │
│  └─────────────┘  └──────────────┘  └────────────────────────┘  │
│                           │                                      │
│                   ┌───────▼──────┐                               │
│                   │    view()    │                               │
│                   │ Model→ViewModel                              │
│                   └──────────────┘                               │
└─────────────────────────────────────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────────┐
│                      models.rs (Domain)                         │
│  Workout │ Exercise │ ExerciseSet │ SetActual │ PlateCalculator │
└─────────────────────────────────────────────────────────────────┘
```

---

## File Structure Summary

| File | Lines | Logic Type | Responsibility |
|------|-------|------------|----------------|
| `shared/src/lib.rs` | ~66 | **Infrastructure** | FFI bridge, serialization, singleton core |
| `shared/src/app/mod.rs` | ~1700 | **Application** | State machine, event handling, view transformation |
| `shared/src/models.rs` | ~1000 | **Domain** | Business entities, data structures, business rules |
| `shared/src/shared.udl` | 6 | **Interface** | FFI contract definition for UniFFI |
| `shared/src/bin/uniffi-bindgen.rs` | 4 | **Build** | Code generation tool for Swift bindings |

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

### 2. `src/app.rs` - Crux Application Logic

**Purpose:** Core application implementation with events, model, view models, and update logic.

#### 2.1 Events (User Interactions & System Events)

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

All tests are located in `shared/src/app/tests/`:

- **Event tests:** Event serialization, event handling
- **Model tests:** Model methods, state transitions
- **ViewModel tests:** ViewModel defaults, view transformation
- **Integration tests:** Full update + view cycle

Run tests with:
```bash
just thiccc ios test
# Or directly:
cd shared && cargo test
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

