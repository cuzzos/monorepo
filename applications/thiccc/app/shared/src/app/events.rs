//! Event types for the Thiccc application.
//!
//! This module defines all events that can occur in the application,
//! including user interactions, system responses, and state changes.

use serde::{Deserialize, Serialize};

use crate::models::*;
use crate::operations::TimerOutput;

// =============================================================================
// MARK: - Events
// =============================================================================

/// All events that can occur in the Thiccc application.
///
/// Events represent user interactions, system responses, and state changes.
/// Each event is handled by the `update` function to modify the application state.
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

    // ===== Exercise Management =====
    /// Add an exercise from the library to the current workout
    ///
    /// Note: Takes individual fields instead of GlobalExercise to avoid
    /// UUID serialization issues with TypeGen. The core will construct
    /// the Exercise with a new UUID.
    AddExercise {
        name: String,
        exercise_type: String,
        muscle_group: String,
    },

    /// Delete an exercise from the current workout
    DeleteExercise { exercise_id: String },

    /// Reorder exercises in the workout
    MoveExercise { from_index: usize, to_index: usize },

    /// Show the add exercise view
    ShowAddExerciseView,

    /// Dismiss the add exercise view
    DismissAddExerciseView,

    // ===== Set Management =====
    /// Add a new set to an exercise
    AddSet { exercise_id: String },

    /// Delete a set from an exercise
    DeleteSet {
        exercise_id: String,
        set_index: usize,
    },

    /// Update the actual values for a set
    UpdateSetActual { set_id: String, actual: SetActual },

    /// Toggle whether a set is completed
    ToggleSetCompleted { set_id: String },

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
    ShowRestTimer { duration_seconds: i32 },

    /// Dismiss rest timer modal
    DismissRestTimer,

    // ===== History & Navigation =====
    /// Load workout history from database
    LoadHistory,

    /// View a specific workout from history
    ViewHistoryItem { workout_id: String },

    /// Navigate back
    NavigateBack,

    /// Change selected tab
    ChangeTab { tab: Tab },

    // ===== Import/Export =====
    /// Import workout from JSON string
    ImportWorkout { json_data: String },

    /// Show import view
    ShowImportView,

    /// Dismiss import view
    DismissImportView,

    /// Load workout template from file
    LoadWorkoutTemplate,

    // ===== Plate Calculator =====
    /// Calculate plates for a target weight
    ///
    /// Note: Takes bar_weight as f64 instead of BarType to avoid
    /// UUID serialization issues with TypeGen.
    CalculatePlates {
        target_weight: f64,
        bar_weight: f64,
        use_percentage: Option<f64>,
    },

    /// Clear plate calculation
    ClearPlateCalculation,

    /// Show plate calculator view
    ShowPlateCalculator,

    /// Dismiss plate calculator view
    DismissPlateCalculator,

    // ===== App Lifecycle =====
    /// Initialize the app (load current workout from storage)
    Initialize,

    // ===== Capability Responses =====
    /// Database operation completed
    DatabaseResponse { result: DatabaseResult },

    /// File storage operation completed
    StorageResponse { result: StorageResult },

    /// Timer operation response
    TimerResponse { output: TimerOutput },

    /// Error occurred
    Error { message: String },
}

// =============================================================================
// MARK: - Supporting Event Types
// =============================================================================

/// Application tabs in the main navigation.
///
/// **Default Trait: IMPLEMENTED (for ViewModel compatibility)**
///
/// Reasoning: While Tab is a simple enum where explicit construction is
/// generally preferred, we implement Default here because it's used in
/// ViewModel which needs Default for initialization. The default is
/// Tab::Workout, which is the natural starting tab for the app.
#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, Eq, Default)]
pub enum Tab {
    /// Workout tracking tab (active workout)
    #[default]
    Workout,
    /// History tab (past workouts)
    History,
}

/// Result of a database operation.
///
/// **Default Trait: IMPLEMENTED (for TypeGen compatibility)**
///
/// Reasoning: While database results should normally be constructed explicitly,
/// Default is needed for TypeGen to successfully trace this type for Swift binding
/// generation. The default (WorkoutSaved) is never actually used at runtime.
#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, Default)]
pub enum DatabaseResult {
    /// Workout was successfully saved to the database
    #[default]
    WorkoutSaved,
    /// Workout was successfully deleted from the database
    WorkoutDeleted,
    /// Workout history was loaded from the database
    HistoryLoaded { workouts: Vec<Workout> },
    /// A specific workout was loaded from the database
    WorkoutLoaded { workout: Option<Workout> },
}

/// Result of a file storage operation.
///
/// **Default Trait: IMPLEMENTED (for TypeGen compatibility)**
///
/// Reasoning: While storage results should normally be constructed explicitly,
/// Default is needed for TypeGen to successfully trace this type for Swift binding
/// generation. The default (CurrentWorkoutSaved) is never actually used at runtime.
///
/// **Note**: CurrentWorkoutLoaded uses a JSON string instead of Workout to avoid
/// TypeGen issues with complex nested types. The Rust core deserializes the JSON.
#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, Default)]
pub enum StorageResult {
    /// Current workout was saved to storage
    #[default]
    CurrentWorkoutSaved,
    /// Current workout was loaded from storage (JSON string, None if no file)
    CurrentWorkoutLoaded { workout_json: Option<String> },
    /// Current workout was deleted from storage
    CurrentWorkoutDeleted,
    /// An error occurred during storage operation
    Error { message: String },
}

/// Navigation destinations for the navigation stack.
///
/// **Default Trait: NOT implemented (Explicit Construction)**
///
/// Reasoning: Navigation destinations are specific to user actions and should
/// be explicitly constructed with the relevant IDs. No default destination makes sense.
///
/// **Note on String IDs**: Uses String instead of Uuid for cross-platform compatibility
/// and to enable TypeGen to trace these types for Swift binding generation.
#[derive(Clone, Debug, PartialEq)]
pub enum NavigationDestination {
    /// Navigate to a workout detail view (for editing active workout)
    WorkoutDetail { workout_id: String },
    /// Navigate to a history detail view (for viewing past workout)
    HistoryDetail { workout_id: String },
}

