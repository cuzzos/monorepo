# Phase 4: Core Business Logic (Update & View Functions)

## Overview

**Goal**: Implement all business logic in the Crux core's update and view functions.

**Phase Duration**: Estimated 4-6 hours  
**Complexity**: High  
**Dependencies**: Phases 1 (Models), 2 (Events/State), 3 (Capabilities)  
**Blocks**: Phase 5 (Navigation UI), Phase 6 (Workout UI)

## Why This Phase Matters

This is where the "magic" happens - all business logic lives here. The update function:
- Handles all events
- Mutates state
- Coordinates capabilities
- Returns commands

The view function:
- Transforms Model → ViewModel
- Prepares data for UI rendering
- Keeps views pure and declarative

## Important Notes

⚠️ **Complexity Warning**: This is the most complex phase. The update function can become large. Consider:
- Organizing event handlers into helper functions
- Keeping each event handler focused
- Writing tests alongside implementation

💡 **Testing Strategy**: Write unit tests for each event handler. Test business logic thoroughly before building UI.

## Task Breakdown

### Task 4.1: Implement Workout Management Logic

**Estimated Time**: 1.5-2 hours  
**Complexity**: High  
**Priority**: Critical

#### Objective
Implement all workout lifecycle operations (start, finish, discard, update).

#### Reference Files
- `legacy/Goonlytics/Goonlytics/Sources/Workout/WorkoutModel.swift` (lines 71-124)

#### Sub-Tasks

##### Sub-Task 4.1.1: Start Workout Handler

**File**: `/applications/thiccc/app/shared/src/app.rs` (in `update` function)

**Implementation**:
```rust
Event::StartWorkout => {
    // Create new workout with current timestamp
    model.current_workout = Some(Workout::new());
    model.workout_timer_seconds = 0;
    model.timer_running = true;
    
    // Start timer capability
    caps.timer.start(Event::TimerTick);
    
    // Save to file storage for persistence
    if let Some(ref workout) = model.current_workout {
        caps.storage.save_current_workout(
            workout.clone(),
            |response| Event::StorageResponse { result: response }
        );
    }
    
    render()
}
```

**Success Criteria**:
- [ ] Creates new workout
- [ ] Initializes timer
- [ ] Starts timer capability
- [ ] Saves to file storage
- [ ] Triggers re-render

##### Sub-Task 4.1.2: Finish Workout Handler

**Implementation**:
```rust
Event::FinishWorkout => {
    if let Some(mut workout) = model.current_workout.take() {
        // Set end timestamp
        workout.end_timestamp = Some(Utc::now());
        workout.duration = Some(model.workout_timer_seconds);
        
        // Stop timer
        model.timer_running = false;
        caps.timer.stop(Event::TimerTick);
        
        // Save to database
        caps.database.save_workout(
            workout.clone(),
            |response| Event::DatabaseResponse { result: response }
        );
        
        // Delete current workout file
        caps.storage.delete_current_workout(
            |response| Event::StorageResponse { result: response }
        );
        
        // Reset timer
        model.workout_timer_seconds = 0;
    }
    
    render()
}
```

**Success Criteria**:
- [ ] Sets end timestamp
- [ ] Stops timer
- [ ] Saves to database
- [ ] Clears current workout
- [ ] Deletes file storage

##### Sub-Task 4.1.3: Discard Workout Handler

**Implementation**:
```rust
Event::DiscardWorkout => {
    if model.current_workout.is_some() {
        // Clear current workout
        model.current_workout = None;
        
        // Stop timer
        model.timer_running = false;
        caps.timer.stop(Event::TimerTick);
        model.workout_timer_seconds = 0;
        
        // Delete current workout file
        caps.storage.delete_current_workout(
            |response| Event::StorageResponse { result: response }
        );
    }
    
    render()
}
```

**Success Criteria**:
- [ ] Clears current workout without saving
- [ ] Stops timer
- [ ] Deletes file storage
- [ ] No database save

##### Sub-Task 4.1.4: Update Workout Name Handler

**Implementation**:
```rust
Event::UpdateWorkoutName { name } => {
    if let Some(ref mut workout) = model.current_workout {
        workout.name = name;
        
        // Save to file storage
        caps.storage.save_current_workout(
            workout.clone(),
            |response| Event::StorageResponse { result: response }
        );
    }
    
    render()
}
```

##### Sub-Task 4.1.5: Timer Tick Handler

**Implementation**:
```rust
Event::TimerTick => {
    if model.timer_running {
        model.workout_timer_seconds += 1;
        
        // Update duration in workout
        if let Some(ref mut workout) = model.current_workout {
            workout.duration = Some(model.workout_timer_seconds);
        }
        
        // Periodically save to file (every 10 seconds)
        if model.workout_timer_seconds % 10 == 0 {
            if let Some(ref workout) = model.current_workout {
                caps.storage.save_current_workout(
                    workout.clone(),
                    |response| Event::StorageResponse { result: response }
                );
            }
        }
    }
    
    render()
}
```

**Success Criteria**:
- [ ] Increments timer every second
- [ ] Updates workout duration
- [ ] Periodically saves to file
- [ ] Only runs when timer_running is true

#### Agent Prompt Template

```
I need you to implement workout management logic in the Crux update function for the Thiccc app.

**Reference Files:**
- @legacy/Goonlytics/Goonlytics/Sources/Workout/WorkoutModel.swift (lines 71-124)
- @shared/src/app.rs (update function)

**Task: Implement Workout Lifecycle Event Handlers**

In the `update` function of `/applications/thiccc/app/shared/src/app.rs`, implement handlers for:

1. `Event::StartWorkout` - Create new workout, start timer, save to file
2. `Event::FinishWorkout` - Set end timestamp, save to DB, clear current workout
3. `Event::DiscardWorkout` - Clear without saving, stop timer
4. `Event::UpdateWorkoutName { name }` - Update name, save to file
5. `Event::TimerTick` - Increment timer, update duration, periodic save

**Requirements:**
1. Match Goonlytics behavior exactly
2. Use capabilities for side effects (timer, database, storage)
3. Handle Option<Workout> properly (check if workout exists)
4. Return `render()` command to update UI
5. Include proper state management (timer flags, etc.)

**Success Criteria:**
- [ ] All event handlers compile and work
- [ ] Workout lifecycle works end-to-end
- [ ] Timer updates every second
- [ ] Data persists correctly
- [ ] Tests pass

Please implement following Crux patterns and principal engineer standards.
```

---

### Task 4.2: Implement Exercise Management Logic

**Estimated Time**: 1 hour  
**Complexity**: Medium  
**Priority**: Critical

#### Objective
Implement adding, deleting, and reordering exercises.

#### Reference Files
- `legacy/Goonlytics/Goonlytics/Sources/Workout/WorkoutModel.swift` (lines 162-202)

#### Implementation

**File**: `/applications/thiccc/app/shared/src/app.rs`

```rust
Event::AddExercise { exercise } => {
    let workout = model.get_or_create_workout();
    
    // Create new Exercise from GlobalExercise
    let exercise_id = Uuid::new_v4();
    let new_exercise = Exercise {
        id: exercise_id,
        superset_id: None,
        workout_id: workout.id,
        name: exercise.name.clone(),
        pinned_notes: vec![],
        notes: vec![],
        duration: None,
        exercise_type: ExerciseType::Barbell, // Default, could parse from exercise.exercise_type
        weight_unit: Some(WeightUnit::Pounds),
        default_warm_up_time: Some(60),
        default_rest_time: Some(60),
        sets: vec![],
        body_part: None,
    };
    
    workout.exercises.push(new_exercise);
    
    // Save to file storage
    caps.storage.save_current_workout(
        workout.clone(),
        |response| Event::StorageResponse { result: response }
    );
    
    render()
}

Event::DeleteExercise { exercise_id } => {
    if let Some(ref mut workout) = model.current_workout {
        workout.exercises.retain(|e| e.id != exercise_id);
        
        // Save to file storage
        caps.storage.save_current_workout(
            workout.clone(),
            |response| Event::StorageResponse { result: response }
        );
    }
    
    render()
}

Event::MoveExercise { from_index, to_index } => {
    if let Some(ref mut workout) = model.current_workout {
        if from_index < workout.exercises.len() && to_index < workout.exercises.len() {
            let exercise = workout.exercises.remove(from_index);
            workout.exercises.insert(to_index, exercise);
            
            // Save to file storage
            caps.storage.save_current_workout(
                workout.clone(),
                |response| Event::StorageResponse { result: response }
            );
        }
    }
    
    render()
}
```

#### Success Criteria
- [ ] Can add exercises to workout
- [ ] Can delete exercises
- [ ] Can reorder exercises
- [ ] Changes persist to file
- [ ] Model helper methods work

#### Agent Prompt Template

```
I need you to implement exercise management logic in the Thiccc app's Rust core.

**Reference Files:**
- @legacy/Goonlytics/Goonlytics/Sources/Workout/WorkoutModel.swift (lines 162-202)
- @shared/src/app.rs (update function)

**Task: Implement Exercise CRUD Event Handlers**

In the `update` function, implement:
1. `Event::AddExercise { exercise }` - Add GlobalExercise to workout
2. `Event::DeleteExercise { exercise_id }` - Remove exercise by ID
3. `Event::MoveExercise { from_index, to_index }` - Reorder exercises

**Requirements:**
1. Use `model.get_or_create_workout()` helper
2. Create proper Exercise struct from GlobalExercise
3. Include initial set when adding exercise
4. Validate indices for move operation
5. Save to file storage after changes
6. Return render() command

**Success Criteria:**
- [ ] All handlers compile
- [ ] Can add/delete/move exercises
- [ ] Data persists
- [ ] Edge cases handled (empty list, invalid indices)
- [ ] Tests pass

Please implement following Crux patterns and principal engineer standards.
```

---

### Task 4.3: Implement Set Management Logic

**Estimated Time**: 1 hour  
**Complexity**: Medium  
**Priority**: Critical

#### Objective
Implement adding, deleting, and updating sets.

#### Reference Files
- `legacy/Goonlytics/Goonlytics/Sources/Workout/WorkoutModel.swift` (lines 126-149)

#### Implementation

**File**: `/applications/thiccc/app/shared/src/app.rs`

```rust
Event::AddSet { exercise_id } => {
    if let Some(exercise) = model.find_exercise_mut(exercise_id) {
        let set_index = exercise.sets.len();
        // Get workout_id safely from the exercise (it already has the workout_id)
        let workout_id = exercise.workout_id;
        
        let new_set = ExerciseSet {
            id: Uuid::new_v4(),
            set_type: SetType::Working,
            weight_unit: exercise.weight_unit,
            suggest: SetSuggest::default(),
            actual: SetActual::default(),
            is_completed: false,
            exercise_id,
            workout_id, // Use the safe workout_id from exercise
            set_index: set_index as i32,
        };
        
        exercise.sets.push(new_set);
        
        // Save to file storage
        if let Some(ref workout) = model.current_workout {
            caps.storage.save_current_workout(
                workout.clone(),
                |response| Event::StorageResponse { result: response }
            );
        }
    }
    
    render()
}

Event::DeleteSet { exercise_id, set_index } => {
    if let Some(exercise) = model.find_exercise_mut(exercise_id) {
        if set_index < exercise.sets.len() {
            exercise.sets.remove(set_index);
            
            // Re-index remaining sets
            for (i, set) in exercise.sets.iter_mut().enumerate() {
                set.set_index = i as i32;
            }
            
            // Save to file storage
            if let Some(ref workout) = model.current_workout {
                caps.storage.save_current_workout(
                    workout.clone(),
                    |response| Event::StorageResponse { result: response }
                );
            }
        }
    }
    
    render()
}

Event::UpdateSetActual { set_id, actual } => {
    if let Some(set) = model.find_set_mut(set_id) {
        set.actual = actual;
        
        // Save to file storage (but not on every keystroke - maybe debounce this)
        if let Some(ref workout) = model.current_workout {
            caps.storage.save_current_workout(
                workout.clone(),
                |response| Event::StorageResponse { result: response }
            );
        }
    }
    
    render()
}

Event::ToggleSetCompleted { set_id } => {
    if let Some(set) = model.find_set_mut(set_id) {
        set.is_completed = !set.is_completed;
        
        // Save to file storage
        if let Some(ref workout) = model.current_workout {
            caps.storage.save_current_workout(
                workout.clone(),
                |response| Event::StorageResponse { result: response }
            );
        }
    }
    
    render()
}
```

#### Success Criteria
- [ ] Can add sets to exercises
- [ ] Can delete sets
- [ ] Can update set actual values
- [ ] Can toggle completion status
- [ ] Set indices stay correct
- [ ] Changes persist

---

### Task 4.4: Implement View Function Transformations

**Estimated Time**: 1.5-2 hours  
**Complexity**: Medium  
**Priority**: Critical

#### Objective
Transform Model → ViewModels for all views.

#### Implementation

**File**: `/applications/thiccc/app/shared/src/app.rs` (in `view` function)

```rust
fn view(&self, model: &Self::Model) -> Self::ViewModel {
    AppViewModel {
        selected_tab: model.selected_tab.clone(),
        workout_view: self.build_workout_view(model),
        history_view: self.build_history_view(model),
    }
}
```

**Helper methods** (add impl block for Thiccc):

```rust
impl Thiccc {
    fn build_workout_view(&self, model: &Model) -> WorkoutViewModel {
        if let Some(ref workout) = model.current_workout {
            WorkoutViewModel {
                has_active_workout: true,
                workout_name: workout.name.clone(),
                formatted_duration: model.format_duration(),
                total_volume: model.calculate_total_volume(),
                total_sets: model.calculate_total_sets(),
                exercises: workout.exercises.iter().map(|e| self.build_exercise_view(e)).collect(),
                timer_running: model.timer_running,
                showing_add_exercise: model.showing_add_exercise,
            }
        } else {
            WorkoutViewModel::default()
        }
    }
    
    fn build_exercise_view(&self, exercise: &Exercise) -> ExerciseViewModel {
        ExerciseViewModel {
            id: exercise.id,
            name: exercise.name.clone(),
            sets: exercise.sets.iter().enumerate().map(|(i, s)| self.build_set_view(s, i)).collect(),
        }
    }
    
    fn build_set_view(&self, set: &ExerciseSet, index: usize) -> SetViewModel {
        SetViewModel {
            id: set.id,
            set_number: (index + 1) as i32,
            previous_display: self.format_previous_set(set),
            weight: set.actual.weight.map(|w| w.to_string()).unwrap_or_default(),
            reps: set.actual.reps.map(|r| r.to_string()).unwrap_or_default(),
            rpe: set.actual.rpe.map(|r| r.to_string()).unwrap_or_default(),
            is_completed: set.is_completed,
        }
    }
    
    fn format_previous_set(&self, set: &ExerciseSet) -> String {
        // TODO: Look up previous workout data
        // For now, show suggested values
        match (set.suggest.weight, set.suggest.reps) {
            (Some(w), Some(r)) => format!("{} × {}", w, r),
            _ => String::new(),
        }
    }
    
    fn build_history_view(&self, model: &Model) -> HistoryViewModel {
        HistoryViewModel {
            workouts: model.workout_history.iter().map(|w| self.build_history_item(w)).collect(),
            is_loading: model.is_loading,
        }
    }
    
    fn build_history_item(&self, workout: &Workout) -> HistoryItemViewModel {
        HistoryItemViewModel {
            id: workout.id,
            name: workout.name.clone(),
            date: self.format_date(workout.start_timestamp),
            exercise_count: workout.exercises.len(),
            set_count: workout.exercises.iter().map(|e| e.sets.len()).sum(),
        }
    }
    
    fn format_date(&self, date: DateTime<Utc>) -> String {
        // Format as "Nov 26, 2025"
        date.format("%b %d, %Y").to_string()
    }
}
```

#### Success Criteria
- [ ] View function compiles
- [ ] All ViewModels properly populated
- [ ] Data is pre-formatted for UI
- [ ] Handles None/empty cases gracefully
- [ ] Helper methods are pure functions

#### Agent Prompt Template

```
I need you to implement the view function that transforms Model → ViewModel in the Thiccc app's Rust core.

**Reference Files:**
- @shared/src/app.rs (current view function, Model, ViewModels)
- @legacy/Goonlytics/Goonlytics/Sources/Workout/WorkoutView.swift (what UI displays)

**Task: Implement View Function Transformations**

In `/applications/thiccc/app/shared/src/app.rs`, implement the `view` function and helper methods to transform Model into ViewModels.

**ViewModels to build:**
1. AppViewModel - main container
2. WorkoutViewModel - active workout view
3. ExerciseViewModel - exercise display
4. SetViewModel - set row display
5. HistoryViewModel - history list
6. HistoryItemViewModel - history item

**Requirements:**
1. Keep view function pure (no side effects)
2. Pre-format all data for display (e.g., "5:23" for duration)
3. Pre-calculate computed values (volume, set counts)
4. Handle Option/None cases gracefully
5. Use helper methods to keep code organized
6. All strings should be ready to display (no formatting in UI)

**Success Criteria:**
- [ ] View function compiles
- [ ] All ViewModels populated correctly
- [ ] Handles empty/None cases
- [ ] Data is pre-formatted
- [ ] Pure functions (no side effects)

Please implement following Crux patterns and principal engineer standards.
```

---

## Phase 4 Completion Checklist

Before moving to Phase 5, verify:

- [ ] All workout management event handlers implemented
- [ ] All exercise management event handlers implemented
- [ ] All set management event handlers implemented
- [ ] View function transforms Model → ViewModel
- [ ] All helper methods implemented
- [ ] Code compiles without errors
- [ ] No clippy warnings
- [ ] Unit tests written and passing
- [ ] Business logic matches Goonlytics behavior

## Testing Phase 4

### Unit Tests

Create comprehensive test suite:

```rust
#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_start_workout_creates_new_workout() {
        let mut model = Model::default();
        let app = Thiccc::default();
        let caps = MockCapabilities::default();
        
        let cmd = app.update(Event::StartWorkout, &mut model, &caps);
        
        assert!(model.current_workout.is_some());
        assert_eq!(model.workout_timer_seconds, 0);
        assert!(model.timer_running);
    }
    
    #[test]
    fn test_finish_workout_saves_and_clears() {
        let mut model = Model::default();
        model.current_workout = Some(Workout::new());
        model.workout_timer_seconds = 300;
        
        let app = Thiccc::default();
        let caps = MockCapabilities::default();
        
        let cmd = app.update(Event::FinishWorkout, &mut model, &caps);
        
        assert!(model.current_workout.is_none());
        assert_eq!(model.workout_timer_seconds, 0);
        assert!(!model.timer_running);
        // Verify database save was called
    }
    
    #[test]
    fn test_add_exercise_to_workout() {
        let mut model = Model::default();
        model.current_workout = Some(Workout::new());
        
        let exercise = GlobalExercise {
            id: Uuid::new_v4(),
            name: "Squat".to_string(),
            exercise_type: "barbell".to_string(),
            additional_fk: None,
            muscle_group: "Quadriceps".to_string(),
            image_name: "squat".to_string(),
        };
        
        let app = Thiccc::default();
        let caps = MockCapabilities::default();
        
        let cmd = app.update(Event::AddExercise { exercise }, &mut model, &caps);
        
        assert_eq!(model.current_workout.as_ref().unwrap().exercises.len(), 1);
        assert_eq!(model.current_workout.as_ref().unwrap().exercises[0].name, "Squat");
    }
    
    #[test]
    fn test_add_set_to_exercise() {
        let mut model = Model::default();
        let mut workout = Workout::new();
        let exercise_id = Uuid::new_v4();
        
        workout.exercises.push(Exercise {
            id: exercise_id,
            workout_id: workout.id,
            name: "Squat".to_string(),
            sets: vec![],
            // ... other fields
        });
        
        model.current_workout = Some(workout);
        
        let app = Thiccc::default();
        let caps = MockCapabilities::default();
        
        let cmd = app.update(Event::AddSet { exercise_id }, &mut model, &caps);
        
        let exercise = model.find_exercise_mut(exercise_id).unwrap();
        assert_eq!(exercise.sets.len(), 1);
        assert_eq!(exercise.sets[0].set_index, 0);
    }
    
    #[test]
    fn test_view_function_formats_duration() {
        let mut model = Model::default();
        model.current_workout = Some(Workout::new());
        model.workout_timer_seconds = 323; // 5:23
        
        let app = Thiccc::default();
        let view = app.view(&model);
        
        assert_eq!(view.workout_view.formatted_duration, "05:23");
    }
    
    #[test]
    fn test_calculate_total_volume() {
        let mut model = Model::default();
        let mut workout = Workout::new();
        let exercise_id = Uuid::new_v4();
        
        let mut exercise = Exercise {
            id: exercise_id,
            workout_id: workout.id,
            name: "Bench Press".to_string(),
            sets: vec![],
            // ... other fields
        };
        
        // Add sets with weight × reps
        exercise.sets.push(ExerciseSet {
            actual: SetActual {
                weight: Some(225.0),
                reps: Some(10),
                ..Default::default()
            },
            // ... other fields
        });
        
        exercise.sets.push(ExerciseSet {
            actual: SetActual {
                weight: Some(225.0),
                reps: Some(8),
                ..Default::default()
            },
            // ... other fields
        });
        
        workout.exercises.push(exercise);
        model.current_workout = Some(workout);
        
        // Total: 225*10 + 225*8 = 2250 + 1800 = 4050
        assert_eq!(model.calculate_total_volume(), 4050);
    }
}
```

Run tests:
```bash
cd applications/thiccc/app/shared
cargo test
```

## Common Issues & Solutions

### Issue: Unsafe unwrap() causing runtime panics
**Solution**: Avoid `unwrap()` on `Option` types. Use safe patterns:
```rust
// ❌ Wrong - Will panic if None
workout_id: model.current_workout.as_ref().unwrap().id,

// ✅ Correct - Use data already available
workout_id: exercise.workout_id, // Exercise already has workout_id

// ✅ Also correct - Use if let or match
if let Some(workout) = &model.current_workout {
    workout_id: workout.id,
} else {
    return render(); // Handle None case
}
```

### Issue: Capability responses not updating model
**Solution**: Ensure capability response events are handled in update function

### Issue: File saves causing performance issues
**Solution**: Debounce saves, don't save on every keystroke

### Issue: Set indices getting out of sync
**Solution**: Re-index after deletions, validate indices

### Issue: View function too complex
**Solution**: Break into helper methods, keep each focused

## Next Steps

After completing Phase 4, proceed to:
- **[Phase 5: Main Navigation UI](./05-PHASE-5-NAVIGATION.md)** - Build SwiftUI navigation

---

**Phase Status**: 📋 Ready for Implementation  
**Last Updated**: November 26, 2025
