# Phase 4: Core Business Logic (Update & View Functions)

## Overview

**Goal**: Implement all business logic in the Crux core's update and view functions.

**Phase Duration**: Estimated 4-6 hours  
**Complexity**: High  
**Dependencies**: Phases 1 (Models), 2 (Events/State), 3 (Capabilities)  
**Blocks**: Phase 5 (Navigation UI), Phase 6 (Workout UI)

## ✅ PHASE COMPLETE

**Status**: All tasks in Phase 4 have been implemented!

**Implementation Date**: November 2025  
**Actual Duration**: Completed as part of earlier development  

### What Was Implemented

All business logic is now in place in the modular structure under `app/shared/src/app/`:

| File | Purpose |
|------|---------|
| `mod.rs` | Main Crux App implementation with `update()` and `view()` |
| `events.rs` | All event definitions |
| `model.rs` | Application state and helper methods |
| `view_models.rs` | All ViewModel structs |
| `effects.rs` | Effect types for capabilities |
| `tests/` | Comprehensive test suite |

---

## Completed Implementation Summary

### ✅ Task 4.1: Workout Management Logic - COMPLETE

All workout lifecycle event handlers are implemented in `app/shared/src/app/mod.rs`:

| Event | Status | Implementation Highlights |
|-------|--------|---------------------------|
| `StartWorkout` | ✅ | Creates workout, starts timer capability, saves to storage |
| `FinishWorkout` | ✅ | Sets end timestamp, saves to DB, stops timer, clears state |
| `DiscardWorkout` | ✅ | Clears state, stops timer, deletes from storage |
| `UpdateWorkoutName` | ✅ | Updates workout name |
| `UpdateWorkoutNotes` | ✅ | Updates workout notes (bonus feature) |
| `TimerTick` | ✅ | Increments timer when running |
| `StartTimer` | ✅ | Starts timer capability |
| `StopTimer` | ✅ | Stops timer capability |
| `ToggleTimer` | ✅ | Toggles timer state |

**Code Location**: Lines 270-528 in `app/shared/src/app/mod.rs`

---

### ✅ Task 4.2: Exercise Management Logic - COMPLETE

All exercise CRUD operations implemented:

| Event | Status | Implementation Highlights |
|-------|--------|---------------------------|
| `AddExercise` | ✅ | Creates exercise from name/type/muscle_group, uses `get_or_create_workout()` |
| `DeleteExercise` | ✅ | Removes by ID with proper validation |
| `MoveExercise` | ✅ | Reorders with bounds checking and error messages |
| `ShowAddExerciseView` | ✅ | Modal control |
| `DismissAddExerciseView` | ✅ | Modal control |

**Code Location**: Lines 369-425 in `app/shared/src/app/mod.rs`

---

### ✅ Task 4.3: Set Management Logic - COMPLETE

All set CRUD operations implemented:

| Event | Status | Implementation Highlights |
|-------|--------|---------------------------|
| `AddSet` | ✅ | Adds set with proper ID handling using `Id::from_string()` |
| `DeleteSet` | ✅ | Removes and re-indexes remaining sets |
| `UpdateSetActual` | ✅ | Updates weight/reps/RPE values |
| `ToggleSetCompleted` | ✅ | Toggles completion status |

**Code Location**: Lines 427-500 in `app/shared/src/app/mod.rs`

---

### ✅ Task 4.4: View Function Transformations - COMPLETE

All view transformations implemented with pure helper methods:

| Helper Method | Status | Purpose |
|---------------|--------|---------|
| `view()` | ✅ | Main Model → ViewModel transformation |
| `build_workout_view()` | ✅ | Creates WorkoutViewModel |
| `build_exercise_view()` | ✅ | Creates ExerciseViewModel |
| `build_set_view()` | ✅ | Creates SetViewModel with formatted data |
| `build_history_view()` | ✅ | Creates HistoryViewModel |
| `build_history_item()` | ✅ | Creates HistoryItemViewModel |

**Code Location**: Lines 39-139 and 744-752 in `app/shared/src/app/mod.rs`

---

### ✅ Model Helper Methods - COMPLETE

All helper methods implemented in `app/shared/src/app/model.rs`:

| Method | Status | Purpose |
|--------|--------|---------|
| `get_or_create_workout()` | ✅ | Gets or creates current workout |
| `find_exercise_mut()` | ✅ | Finds exercise by ID |
| `find_set_mut()` | ✅ | Finds set by ID |
| `calculate_total_volume()` | ✅ | Sums weight × reps for completed sets |
| `calculate_total_sets()` | ✅ | Counts total sets |
| `format_duration()` | ✅ | Formats seconds as "MM:SS" |

---

### ✅ Additional Features Implemented (Beyond Original Plan)

The implementation includes features not originally planned for Phase 4:

| Feature | Status | Description |
|---------|--------|-------------|
| Plate Calculator | ✅ | `CalculatePlates`, `ClearPlateCalculation`, `ShowPlateCalculator`, `DismissPlateCalculator` events |
| Import/Export | ✅ | `ImportWorkout` with JSON validation, `ShowImportView`, `DismissImportView` |
| Navigation | ✅ | `LoadHistory`, `ViewHistoryItem`, `NavigateBack`, `ChangeTab` events |
| Stopwatch/Rest Timer | ✅ | `ShowStopwatch`, `DismissStopwatch`, `ShowRestTimer`, `DismissRestTimer` |
| Capability Responses | ✅ | `DatabaseResponse`, `StorageResponse`, `TimerResponse`, `Error` handlers |
| ID Validation | ✅ | `validate_workout_ids()` helper for import safety |

---

### ✅ Test Coverage - COMPLETE

Comprehensive tests implemented in `app/shared/src/app/tests/`:

| Test File | Coverage |
|-----------|----------|
| `event_tests.rs` | Event serialization tests |
| `model_tests.rs` | Model helper method tests |
| `view_model_tests.rs` | ViewModel transformation tests |
| `integration_tests.rs` | Full update + view cycle tests |

**Key Tests Include**:
- `test_start_workout_flow` - Full workout start flow
- `test_add_exercise_flow` - Adding exercises
- `test_add_and_complete_set_flow` - Set lifecycle with volume calculation
- `test_finish_workout_flow` - Finishing and history
- `test_timer_tick_flow` - Timer incrementing
- `test_finish_workout_uses_timer_seconds_not_wall_clock` - Paused timer behavior
- `test_delete_set_with_invalid_index_shows_error` - Error handling
- `test_move_exercise_with_invalid_indices_shows_error` - Bounds checking
- `test_plate_calculator_*` - Multiple plate calculator tests
- `test_import_workout_*` - Import validation tests
- `test_error_message_cleared_on_*` - Error clearing behavior

Run tests:
```bash
cd app/shared
cargo test
```

---

## Phase 4 Completion Checklist

All items verified complete:

- [x] All workout management event handlers implemented
- [x] All exercise management event handlers implemented
- [x] All set management event handlers implemented
- [x] View function transforms Model → ViewModel
- [x] All helper methods implemented
- [x] Code compiles without errors
- [x] No clippy warnings
- [x] Unit tests written and passing
- [x] Business logic matches Goonlytics behavior
- [x] Proper error handling with user-friendly messages
- [x] ID validation for security
- [x] Additional features (plate calculator, import/export)

---

## Architecture Notes

The implementation follows Crux best practices:

1. **Modular Structure**: Code organized into separate files for events, model, view_models, and effects
2. **Safe ID Handling**: Uses custom `Id` type with validation at boundaries
3. **Error Messages**: User-friendly error messages for validation failures
4. **Capability Integration**: Proper use of `Command::request_from_shell()` for side effects
5. **Pure View Function**: No side effects in `view()` or helper methods
6. **Comprehensive Tests**: Full coverage of business logic

---

## Next Steps

Phase 4 is complete. Proceed to:
- **[Phase 5: Main Navigation UI](./05-PHASE-5-NAVIGATION.md)** - Build SwiftUI navigation

---

**Phase Status**: ✅ Complete  
**Last Updated**: November 30, 2025
