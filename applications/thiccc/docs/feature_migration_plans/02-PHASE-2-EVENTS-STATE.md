# Phase 2: Core Events & State

## Overview

**Goal**: Define all application events and the core Model state structure for the Crux app.

**Phase Duration**: Estimated 2-3 hours  
**Complexity**: Medium  
**Dependencies**: Phase 1 (Data Models)  
**Blocks**: Phase 3 (Capabilities), Phase 4 (Business Logic)

## Why This Phase Matters

Events are the primary mechanism for communication between the UI and core. The Model represents the entire application state. Getting these right ensures:
- Clear separation between UI and business logic
- Type-safe event handling
- Predictable state transitions
- Easy testing of business logic

## Task Breakdown

### Task 2.1: Define Application Events

**Estimated Time**: 1-1.5 hours  
**Complexity**: Medium  
**Priority**: Critical

#### Objective
Define all events that users can trigger in the app, organized by feature area.

#### Reference Files
- `legacy/Goonlytics/Goonlytics/Sources/Workout/WorkoutView.swift` (user interactions)
- `legacy/Goonlytics/Goonlytics/Sources/Workout/WorkoutModel.swift` (model methods)
- `legacy/Goonlytics/Goonlytics/Sources/History/HistoryView.swift`

#### Sub-Tasks

##### Sub-Task 2.1.1: Workout Management Events

**File**: `/applications/thiccc/app/shared/src/app.rs`

**Implementation Details**:
```rust
use serde::{Deserialize, Serialize};
use uuid::Uuid;
use crate::models::*;

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
pub enum Event {
    // ===== Workout Management =====
    
    /// Start a new workout session
    StartWorkout,
    
    /// Finish and save the current workout
    FinishWorkout,
    
    /// Discard the current workout without saving
    DiscardWorkout,
    
    /// Update the workout name
    UpdateWorkoutName { name: String },
    
    /// Update workout notes
    UpdateWorkoutNotes { notes: String },
    
    // More events will be added in subsequent sub-tasks...
}
```

**Success Criteria**:
- [ ] Events compile without errors
- [ ] Event names use imperative mood
- [ ] Events are serializable
- [ ] Doc comments explain purpose

##### Sub-Task 2.1.2: Exercise Management Events

**File**: `/applications/thiccc/app/shared/src/app.rs`

**Add to Event enum**:
```rust
    // ===== Exercise Management =====
    
    /// Add an exercise from the library to the current workout
    AddExercise { 
        exercise: GlobalExercise 
    },
    
    /// Delete an exercise from the current workout
    DeleteExercise { 
        exercise_id: Uuid 
    },
    
    /// Reorder exercises in the workout
    MoveExercise { 
        from_index: usize, 
        to_index: usize 
    },
    
    /// Show the add exercise view
    ShowAddExerciseView,
    
    /// Dismiss the add exercise view
    DismissAddExerciseView,
```

##### Sub-Task 2.1.3: Set Management Events

**Add to Event enum**:
```rust
    // ===== Set Management =====
    
    /// Add a new set to an exercise
    AddSet { 
        exercise_id: Uuid 
    },
    
    /// Delete a set from an exercise
    DeleteSet { 
        exercise_id: Uuid, 
        set_index: usize 
    },
    
    /// Update the actual values for a set
    UpdateSetActual {
        set_id: Uuid,
        actual: SetActual,
    },
    
    /// Toggle whether a set is completed
    ToggleSetCompleted { 
        set_id: Uuid 
    },
```

##### Sub-Task 2.1.4: Timer Events

**Add to Event enum**:
```rust
    // ===== Timer Events =====
    
    /// Timer tick (increments workout duration)
    TimerTick,
    
    /// Start the workout timer
    StartTimer,
    
    /// Stop the workout timer
    StopTimer,
    
    /// Toggle timer pause state
    ToggleTimer,
    
    /// Show stopwatch modal
    ShowStopwatch,
    
    /// Dismiss stopwatch modal
    DismissStopwatch,
    
    /// Show rest timer modal
    ShowRestTimer { 
        duration_seconds: i32 
    },
    
    /// Dismiss rest timer modal
    DismissRestTimer,
```

##### Sub-Task 2.1.5: History & Navigation Events

**Add to Event enum**:
```rust
    // ===== History & Navigation =====
    
    /// Load workout history from database
    LoadHistory,
    
    /// View a specific workout from history
    ViewHistoryItem { 
        workout_id: Uuid 
    },
    
    /// Navigate back
    NavigateBack,
    
    /// Change selected tab
    ChangeTab { 
        tab: Tab 
    },
```

##### Sub-Task 2.1.6: Import/Export Events

**Add to Event enum**:
```rust
    // ===== Import/Export =====
    
    /// Import workout from JSON string
    ImportWorkout { 
        json_data: String 
    },
    
    /// Show import view
    ShowImportView,
    
    /// Dismiss import view
    DismissImportView,
    
    /// Load workout template from file
    LoadWorkoutTemplate,
```

##### Sub-Task 2.1.7: Plate Calculator Events

**Add to Event enum**:
```rust
    // ===== Plate Calculator =====
    
    /// Calculate plates for a target weight
    CalculatePlates {
        target_weight: f64,
        bar_type: BarType,
        use_percentage: Option<f64>,
    },
    
    /// Clear plate calculation
    ClearPlateCalculation,
    
    /// Show plate calculator view
    ShowPlateCalculator,
    
    /// Dismiss plate calculator view
    DismissPlateCalculator,
```

##### Sub-Task 2.1.8: Capability Response Events

**Add to Event enum**:
```rust
    // ===== Capability Responses =====
    
    /// Database operation completed
    DatabaseResponse { 
        result: DatabaseResult 
    },
    
    /// File storage operation completed
    StorageResponse { 
        result: StorageResult 
    },
    
    /// Error occurred
    Error { 
        message: String 
    },
}
```

#### Supporting Types

**Add after Event enum**:
```rust
#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, Eq)]
pub enum Tab {
    Workout,
    History,
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
pub enum DatabaseResult {
    WorkoutSaved,
    HistoryLoaded { workouts: Vec<Workout> },
    WorkoutLoaded { workout: Option<Workout> },
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
pub enum StorageResult {
    CurrentWorkoutSaved,
    CurrentWorkoutLoaded { workout: Option<Workout> },
    CurrentWorkoutDeleted,
}
```

#### Agent Prompt Template

```
I need you to define all application events for the Thiccc workout tracking app using the Crux framework.

**Reference Files:**
- @legacy/Goonlytics/Goonlytics/Sources/Workout/WorkoutView.swift (UI interactions)
- @legacy/Goonlytics/Goonlytics/Sources/Workout/WorkoutModel.swift (business logic)
- @shared/src/app.rs (current Event enum)

**Task: Define Complete Event Enum**

In `/applications/thiccc/app/shared/src/app.rs`, expand the `Event` enum to include all user interactions and system events.

**Event Categories:**
1. Workout Management: StartWorkout, FinishWorkout, DiscardWorkout, UpdateWorkoutName, UpdateWorkoutNotes
2. Exercise Management: AddExercise, DeleteExercise, MoveExercise, ShowAddExerciseView, DismissAddExerciseView
3. Set Management: AddSet, DeleteSet, UpdateSetActual, ToggleSetCompleted
4. Timer: TimerTick, StartTimer, StopTimer, ToggleTimer, ShowStopwatch, DismissStopwatch, ShowRestTimer, DismissRestTimer
5. History & Navigation: LoadHistory, ViewHistoryItem, NavigateBack, ChangeTab
6. Import/Export: ImportWorkout, ShowImportView, DismissImportView, LoadWorkoutTemplate
7. Plate Calculator: CalculatePlates, ClearPlateCalculation, ShowPlateCalculator, DismissPlateCalculator
8. Capability Responses: DatabaseResponse, StorageResponse, Error

**Also define:**
- `Tab` enum (Workout, History)
- `DatabaseResult` enum
- `StorageResult` enum

**Requirements:**
1. All enums derive: `Serialize`, `Deserialize`, `Clone`, `Debug`, `PartialEq`
2. Use imperative mood for event names
3. Include payload data in variants as needed
4. Add doc comments for each event
5. Group events with comments

**Success Criteria:**
- [ ] All events compile
- [ ] Events are serializable
- [ ] Clear, descriptive names
- [ ] Proper doc comments
- [ ] No clippy warnings
```

---

### Task 2.2: Define Core Model State

**Estimated Time**: 1 hour  
**Complexity**: Medium  
**Priority**: Critical

#### Objective
Define the Model struct that represents the entire application state.

#### Reference Files
- `legacy/Goonlytics/Goonlytics/Sources/GoonlyticsApp.swift` (AppModel)
- `legacy/Goonlytics/Goonlytics/Sources/Workout/WorkoutModel.swift`
- `legacy/Goonlytics/Goonlytics/Sources/History/HistoryView.swift` (HistoryModel)

#### Implementation Details

**File**: `/applications/thiccc/app/shared/src/app.rs`

```rust
/// Core application state
#[derive(Default, Debug)]
pub struct Model {
    // ===== Active Workout =====
    /// The currently active workout (None if no workout in progress)
    pub current_workout: Option<Workout>,
    
    /// Elapsed seconds for current workout
    pub workout_timer_seconds: i32,
    
    /// Whether the workout timer is running
    pub timer_running: bool,
    
    // ===== History =====
    /// List of completed workouts
    pub workout_history: Vec<Workout>,
    
    // ===== Navigation State =====
    /// Currently selected tab
    pub selected_tab: Tab,
    
    /// Navigation stack
    pub navigation_stack: Vec<NavigationDestination>,
    
    // ===== Modal State =====
    /// Whether add exercise view is shown
    pub showing_add_exercise: bool,
    
    /// Whether import view is shown
    pub showing_import: bool,
    
    /// Whether stopwatch modal is shown
    pub showing_stopwatch: bool,
    
    /// Rest timer duration (None if not shown)
    pub showing_rest_timer: Option<i32>,
    
    /// Whether plate calculator is shown
    pub showing_plate_calculator: bool,
    
    // ===== Plate Calculator State =====
    /// Current plate calculation result
    pub plate_calculation: Option<PlateCalculation>,
    
    // ===== Loading & Error State =====
    /// Whether a database operation is in progress
    pub is_loading: bool,
    
    /// Current error message (if any)
    pub error_message: Option<String>,
}

#[derive(Clone, Debug, PartialEq)]
pub enum NavigationDestination {
    WorkoutDetail { workout_id: Uuid },
    HistoryDetail { workout_id: Uuid },
}
```

#### Supporting Model Methods

Add implementation block:
```rust
impl Model {
    /// Get the current workout or create a new one
    pub fn get_or_create_workout(&mut self) -> &mut Workout {
        if self.current_workout.is_none() {
            self.current_workout = Some(Workout::new());
        }
        self.current_workout.as_mut().unwrap()
    }
    
    /// Find an exercise by ID in the current workout
    pub fn find_exercise_mut(&mut self, exercise_id: Uuid) -> Option<&mut Exercise> {
        self.current_workout
            .as_mut()?
            .exercises
            .iter_mut()
            .find(|e| e.id == exercise_id)
    }
    
    /// Find a set by ID in the current workout
    pub fn find_set_mut(&mut self, set_id: Uuid) -> Option<&mut ExerciseSet> {
        self.current_workout.as_mut()?
            .exercises
            .iter_mut()
            .flat_map(|e| e.sets.iter_mut())
            .find(|s| s.id == set_id)
    }
    
    /// Calculate total volume for current workout
    pub fn calculate_total_volume(&self) -> i32 {
        self.current_workout
            .as_ref()
            .map(|w| {
                w.exercises
                    .iter()
                    .flat_map(|e| &e.sets)
                    .filter_map(|s| {
                        match (s.actual.weight, s.actual.reps) {
                            (Some(w), Some(r)) => Some((w * r as f64) as i32),
                            _ => None,
                        }
                    })
                    .sum()
            })
            .unwrap_or(0)
    }
    
    /// Calculate total sets for current workout
    pub fn calculate_total_sets(&self) -> usize {
        self.current_workout
            .as_ref()
            .map(|w| w.exercises.iter().map(|e| e.sets.len()).sum())
            .unwrap_or(0)
    }
    
    /// Format timer duration as "MM:SS"
    pub fn format_duration(&self) -> String {
        let minutes = self.workout_timer_seconds / 60;
        let seconds = self.workout_timer_seconds % 60;
        format!("{:02}:{:02}", minutes, seconds)
    }
}
```

#### Success Criteria
- [ ] Model struct compiles without errors
- [ ] Includes all necessary state fields
- [ ] Helper methods compile and work correctly
- [ ] Default implementation provided
- [ ] Doc comments for all public items

#### Agent Prompt Template

```
I need you to define the core Model state structure for the Thiccc app using the Crux framework.

**Reference Files:**
- @legacy/Goonlytics/Goonlytics/Sources/GoonlyticsApp.swift (AppModel structure)
- @legacy/Goonlytics/Goonlytics/Sources/Workout/WorkoutModel.swift (WorkoutModel fields)

**Task: Define Model Struct**

In `/applications/thiccc/app/shared/src/app.rs`, define the `Model` struct that represents entire app state.

**State Categories:**
1. Active Workout: current_workout (Option<Workout>), workout_timer_seconds, timer_running
2. History: workout_history (Vec<Workout>)
3. Navigation: selected_tab, navigation_stack
4. Modals: showing_add_exercise, showing_import, showing_stopwatch, showing_rest_timer, showing_plate_calculator
5. Plate Calculator: plate_calculation (Option<PlateCalculation>)
6. Loading/Error: is_loading, error_message

**Also implement:**
- `Default` trait for Model
- Helper methods:
  - `get_or_create_workout(&mut self) -> &mut Workout`
  - `find_exercise_mut(&mut self, id: Uuid) -> Option<&mut Exercise>`
  - `find_set_mut(&mut self, id: Uuid) -> Option<&mut ExerciseSet>`
  - `calculate_total_volume(&self) -> i32`
  - `calculate_total_sets(&self) -> usize`
  - `format_duration(&self) -> String`

**Requirements:**
1. Use appropriate types (Option for nullable, Vec for lists)
2. Add comprehensive doc comments
3. Implement Default trait
4. Helper methods should be ergonomic and efficient

**Success Criteria:**
- [ ] Model compiles without errors
- [ ] Default implementation provided
- [ ] Helper methods work correctly
- [ ] Doc comments present
```

---

### Task 2.3: Define ViewModel Structures

**Estimated Time**: 1 hour  
**Complexity**: Medium  
**Priority**: Critical

#### Objective
Define ViewModel structures that the UI will render.

#### Reference Files
- Current ViewModel in `app.rs` (simple counter example)
- SwiftUI views from Goonlytics (to understand what data they need)

#### Sub-Tasks

##### Sub-Task 2.3.1: Workout View Models

**File**: `/applications/thiccc/app/shared/src/app.rs`

```rust
/// ViewModel for the main app view
#[derive(Serialize, Deserialize, Clone, Debug, Default)]
pub struct AppViewModel {
    pub selected_tab: Tab,
    pub workout_view: WorkoutViewModel,
    pub history_view: HistoryViewModel,
}

/// ViewModel for active workout view
#[derive(Serialize, Deserialize, Clone, Debug, Default)]
pub struct WorkoutViewModel {
    /// Whether a workout is currently active
    pub has_active_workout: bool,
    
    /// Workout name
    pub workout_name: String,
    
    /// Formatted duration (e.g., "5:23")
    pub formatted_duration: String,
    
    /// Total volume in pounds
    pub total_volume: i32,
    
    /// Total number of sets
    pub total_sets: usize,
    
    /// List of exercises with their sets
    pub exercises: Vec<ExerciseViewModel>,
    
    /// Whether timer is running
    pub timer_running: bool,
    
    /// Whether add exercise view is shown
    pub showing_add_exercise: bool,
}

/// ViewModel for an individual exercise
#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct ExerciseViewModel {
    pub id: Uuid,
    pub name: String,
    pub sets: Vec<SetViewModel>,
}

/// ViewModel for an individual set
#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct SetViewModel {
    pub id: Uuid,
    pub set_number: i32,
    pub previous_display: String,  // e.g., "225 × 10"
    pub weight: String,            // Current weight as string
    pub reps: String,              // Current reps as string
    pub rpe: String,               // Current RPE as string
    pub is_completed: bool,
}
```

##### Sub-Task 2.3.2: History View Models

```rust
/// ViewModel for history list
#[derive(Serialize, Deserialize, Clone, Debug, Default)]
pub struct HistoryViewModel {
    pub workouts: Vec<HistoryItemViewModel>,
    pub is_loading: bool,
}

/// ViewModel for a history list item
#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct HistoryItemViewModel {
    pub id: Uuid,
    pub name: String,
    pub date: String,              // Pre-formatted date
    pub exercise_count: usize,
    pub set_count: usize,
}

/// ViewModel for history detail view
#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct HistoryDetailViewModel {
    pub workout_name: String,
    pub formatted_date: String,
    pub duration: Option<String>,
    pub exercises: Vec<ExerciseDetailViewModel>,
    pub notes: Option<String>,
}

/// ViewModel for exercise in history detail
#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct ExerciseDetailViewModel {
    pub name: String,
    pub sets: Vec<SetDetailViewModel>,
}

/// ViewModel for set in history detail
#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct SetDetailViewModel {
    pub set_number: i32,
    pub display_text: String,      // e.g., "225 lb × 10 reps @ 8.0"
}
```

##### Sub-Task 2.3.3: Plate Calculator View Model

```rust
/// ViewModel for plate calculator
#[derive(Serialize, Deserialize, Clone, Debug, Default)]
pub struct PlateCalculatorViewModel {
    pub target_weight: String,
    pub percentage: String,
    pub bar_type: Option<BarType>,
    pub calculation: Option<PlateCalculationResult>,
}

#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct PlateCalculationResult {
    pub total_weight: f64,
    pub bar_weight: f64,
    pub plates_per_side: String,   // e.g., "2×45, 1×25, 1×10"
    pub plates: Vec<PlateViewModel>,
}

#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct PlateViewModel {
    pub weight: f64,
    pub count: i32,
    pub color: String,             // Color name for UI
}
```

#### Success Criteria
- [ ] All ViewModels compile without errors
- [ ] All ViewModels derive `Serialize`, `Deserialize`, `Clone`, `Debug`
- [ ] Fields use simple, UI-friendly types (String instead of complex types)
- [ ] Data is pre-formatted (e.g., "5:23" instead of 323 seconds)
- [ ] Doc comments added

#### Agent Prompt Template

```
I need you to define ViewModel structures for the Thiccc app's UI using the Crux framework.

**Context:**
ViewModels transform the core Model into UI-friendly data structures. They should contain pre-formatted data ready for display.

**Reference:**
- @shared/src/app.rs (current simple ViewModel)
- @legacy/Goonlytics/Goonlytics/Sources/Workout/WorkoutView.swift (what UI needs)

**Task: Define ViewModels**

In `/applications/thiccc/app/shared/src/app.rs`, create these ViewModels:

1. `AppViewModel`: selected_tab, workout_view, history_view
2. `WorkoutViewModel`: has_active_workout, workout_name, formatted_duration, total_volume, total_sets, exercises, timer_running, showing_add_exercise
3. `ExerciseViewModel`: id, name, sets
4. `SetViewModel`: id, set_number, previous_display, weight, reps, rpe, is_completed
5. `HistoryViewModel`: workouts, is_loading
6. `HistoryItemViewModel`: id, name, date, exercise_count, set_count
7. `HistoryDetailViewModel`: workout_name, formatted_date, duration, exercises, notes
8. `ExerciseDetailViewModel`: name, sets
9. `SetDetailViewModel`: set_number, display_text
10. `PlateCalculatorViewModel`: target_weight, percentage, bar_type, calculation
11. `PlateCalculationResult`: total_weight, bar_weight, plates_per_side, plates
12. `PlateViewModel`: weight, count, color

**Requirements:**
1. All ViewModels derive: `Serialize`, `Deserialize`, `Clone`, `Debug`
2. Use simple types (String, i32, bool, Vec)
3. Pre-format data for display (e.g., "5:23" for duration)
4. Use String for numeric inputs (easier for text fields)
5. Add doc comments
6. Implement `Default` where appropriate

**Success Criteria:**
- [ ] All ViewModels compile
- [ ] Proper derives
- [ ] Simple, UI-friendly types
- [ ] Doc comments present
```

---

## Phase 2 Completion Checklist

Before moving to Phase 3, verify:

- [ ] All events are defined and compile without errors
- [ ] Model struct is complete with all state fields
- [ ] All ViewModels are defined
- [ ] Supporting types (Tab, DatabaseResult, etc.) are defined
- [ ] No clippy warnings: `cargo clippy --all-targets`
- [ ] Code is formatted: `cargo fmt`
- [ ] Doc comments are comprehensive

## Testing Phase 2

Add tests to verify event serialization:

```rust
#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_event_serialization() {
        let event = Event::AddExercise {
            exercise: GlobalExercise {
                id: Uuid::new_v4(),
                name: "Squat".to_string(),
                exercise_type: "barbell".to_string(),
                additional_fk: None,
                muscle_group: "Quadriceps".to_string(),
                image_name: "squat".to_string(),
            }
        };
        
        let json = serde_json::to_string(&event).expect("Failed to serialize");
        let deserialized: Event = serde_json::from_str(&json).expect("Failed to deserialize");
        assert_eq!(event, deserialized);
    }
    
    #[test]
    fn test_model_helper_methods() {
        let mut model = Model::default();
        
        // Test get_or_create_workout
        let workout = model.get_or_create_workout();
        assert_eq!(workout.exercises.len(), 0);
        
        // Test calculate_total_volume (empty workout)
        assert_eq!(model.calculate_total_volume(), 0);
        
        // Test format_duration
        model.workout_timer_seconds = 323;
        assert_eq!(model.format_duration(), "05:23");
    }
}
```

## Next Steps

After completing Phase 2, proceed to:
- **[Phase 3: Capabilities](./03-PHASE-3-CAPABILITIES.md)** - Define platform integration capabilities

---

**Phase Status**: 📋 Ready for Implementation  
**Last Updated**: November 26, 2025

