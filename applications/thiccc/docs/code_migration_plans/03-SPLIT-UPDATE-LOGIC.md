# Phase 3: Split Update Logic (Optional)

**Goal:** Break the 400-line `update()` method into feature-based modules for easier maintenance.

**Time:** ~1-2 hours | **Risk:** Medium

**Note:** Only do this if `app.rs` still feels unwieldy after Phase 2. The Crux weather example keeps update logic unified.

---

## Steps

### 1. Create update module directory

```bash
cd app/shared/src/app
mkdir update
touch update/mod.rs
```

### 2. Create feature modules

```bash
cd update
touch workout.rs exercise.rs sets.rs timer.rs history.rs plate_calculator.rs import_export.rs capabilities.rs
```

### 3. Extract update handlers by feature

Each module gets a `handle_event()` function. Example for `update/workout.rs`:

```rust
use crux_core::{render::render, Command};
use crate::app::{Event, Model, Effect};

pub fn handle_event(event: Event, model: &mut Model) -> Command<Effect, Event> {
    match event {
        Event::StartWorkout => {
            if model.current_workout.is_some() {
                model.error_message = Some("Workout already in progress".to_string());
            } else {
                model.current_workout = Some(Workout::new());
                model.workout_timer_seconds = 0;
                model.timer_running = true;
                model.error_message = None;
            }
        }
        Event::FinishWorkout => {
            // ... logic
        }
        // ... other workout events
        _ => unreachable!("workout module received invalid event"),
    }
    render()
}
```

### 4. Map events to modules

**`update/mod.rs`:**
```rust
mod workout;
mod exercise;
mod sets;
mod timer;
mod history;
mod plate_calculator;
mod import_export;
mod capabilities;

use crux_core::Command;
use crate::app::{Event, Model, Effect};

/// Delegate events to feature modules
pub fn handle_event(event: Event, model: &mut Model) -> Command<Effect, Event> {
    match event {
        // Workout events
        Event::StartWorkout | Event::FinishWorkout | Event::DiscardWorkout 
        | Event::UpdateWorkoutName { .. } | Event::UpdateWorkoutNotes { .. } 
            => workout::handle_event(event, model),
        
        // Exercise events
        Event::AddExercise { .. } | Event::DeleteExercise { .. } 
        | Event::MoveExercise { .. } | Event::ShowAddExerciseView 
        | Event::DismissAddExerciseView 
            => exercise::handle_event(event, model),
        
        // Set events
        Event::AddSet { .. } | Event::DeleteSet { .. } 
        | Event::UpdateSetActual { .. } | Event::ToggleSetCompleted { .. }
            => sets::handle_event(event, model),
        
        // Timer events
        Event::TimerTick | Event::StartTimer | Event::StopTimer 
        | Event::ToggleTimer | Event::ShowStopwatch | Event::DismissStopwatch
        | Event::ShowRestTimer { .. } | Event::DismissRestTimer
            => timer::handle_event(event, model),
        
        // History events
        Event::LoadHistory | Event::ViewHistoryItem { .. } 
        | Event::NavigateBack | Event::ChangeTab { .. }
            => history::handle_event(event, model),
        
        // Plate calculator events
        Event::CalculatePlates { .. } | Event::ClearPlateCalculation
        | Event::ShowPlateCalculator | Event::DismissPlateCalculator
            => plate_calculator::handle_event(event, model),
        
        // Import/Export events
        Event::ImportWorkout { .. } | Event::ShowImportView
        | Event::DismissImportView | Event::LoadWorkoutTemplate
            => import_export::handle_event(event, model),
        
        // Capability responses
        Event::DatabaseResponse { .. } | Event::StorageResponse { .. }
        | Event::Error { .. }
            => capabilities::handle_event(event, model),
    }
}
```

### 5. Update app.rs

Replace the large `update()` method body with delegation:

```rust
impl App for Thiccc {
    // ... trait types ...
    
    fn update(&self, event: Event, model: &mut Model, _caps: &()) -> Command<Effect, Event> {
        app::update::handle_event(event, model)
    }
    
    // view() stays the same
}
```

---

## Verify

```bash
cd app/shared

# Check compilation
cargo check

# Run all tests
cargo test --lib

# Verify each feature still works
cargo test workout
cargo test exercise
cargo test timer
# etc.
```

---

## Rollback

```bash
git checkout app/shared/src/app.rs
rm -rf app/shared/src/app/update/
```

---

## Success Criteria

✅ All tests pass  
✅ `app.rs` now ~200-300 lines (orchestration only)  
✅ Update logic organized by feature  
✅ Easy to find and modify specific functionality  
✅ No behavior changes  

---

## Done!

Your codebase now has maximum modularity while maintaining the Crux architecture pattern. Each feature is self-contained and easy to work on independently.

