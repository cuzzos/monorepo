//! ViewModel types for the Thiccc application.
//!
//! This module defines all ViewModels that are sent to the UI layer.
//! ViewModels are UI-friendly representations of the application state.

use serde::{Deserialize, Serialize};

use super::events::Tab;

// =============================================================================
// MARK: - ViewModels
// =============================================================================

/// Root ViewModel for the entire application.
///
/// **Default Trait: IMPLEMENTED**
///
/// Reasoning: AppViewModel is the top-level view state structure. Having a
/// Default implementation makes it easy to create initial/empty states for
/// testing and ensures all child ViewModels also have sensible defaults.
#[derive(Serialize, Deserialize, Clone, Debug, Default)]
pub struct ViewModel {
    /// Currently selected tab
    pub selected_tab: Tab,
    /// ViewModel for the workout tab
    pub workout_view: WorkoutViewModel,
    /// ViewModel for the history tab
    pub history_view: HistoryViewModel,
    /// ViewModel for the history detail view (when viewing a specific workout)
    pub history_detail_view: Option<HistoryDetailViewModel>,
    /// Current error message to display (if any)
    pub error_message: Option<String>,
    /// Whether error alert is shown
    pub showing_error: bool,
    /// Whether a loading operation is in progress
    pub is_loading: bool,
}

/// ViewModel for the active workout view.
///
/// **Default Trait: IMPLEMENTED**
///
/// Reasoning: WorkoutViewModel represents the workout tab's state. A Default
/// implementation provides a clear "no active workout" state, which is useful
/// for testing and initialization. The default represents an empty workout screen.
#[derive(Serialize, Deserialize, Clone, Debug, Default)]
pub struct WorkoutViewModel {
    /// Whether a workout is currently active
    pub has_active_workout: bool,

    /// Workout name
    pub workout_name: String,

    /// Formatted duration (e.g., "05:23")
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

    /// Whether import view is shown
    pub showing_import: bool,

    /// Whether stopwatch modal is shown
    pub showing_stopwatch: bool,

    /// Rest timer duration in seconds (None if not shown)
    pub showing_rest_timer: Option<i32>,
}

/// ViewModel for an individual exercise in the workout.
///
/// **Default Trait: NOT implemented (Explicit Construction)**
///
/// Reasoning: ExerciseViewModel is always constructed from a specific Exercise
/// model entity with a real ID and name. There's no meaningful "default exercise"
/// - each instance should be intentionally created from domain data.
#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct ExerciseViewModel {
    /// Unique identifier for this exercise
    pub id: String, // UUID as string for easier Swift interop
    /// Exercise name
    pub name: String,
    /// Sets for this exercise
    pub sets: Vec<SetViewModel>,
}

/// ViewModel for an individual set within an exercise.
///
/// **Default Trait: NOT implemented (Explicit Construction)**
///
/// Reasoning: SetViewModel represents a specific set with actual data. Each
/// instance should be constructed from a real ExerciseSet with contextual
/// information (set number, previous values). No meaningful default exists.
#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct SetViewModel {
    /// Unique identifier for this set
    pub id: String, // UUID as string for easier Swift interop
    /// Set number (1-indexed for display)
    pub set_number: i32,
    /// Previous performance display (e.g., "225 × 10")
    pub previous_display: String,
    /// Current weight as string (for text field binding)
    pub weight: String,
    /// Current reps as string (for text field binding)
    pub reps: String,
    /// Current RPE as string (for text field binding)
    pub rpe: String,
    /// Whether this set is completed
    pub is_completed: bool,
}

/// ViewModel for the history list view.
///
/// **Default Trait: IMPLEMENTED**
///
/// Reasoning: HistoryViewModel represents the history tab's state. A Default
/// implementation provides a clear "empty history" state, useful for initial
/// load and testing scenarios. An empty workout list is a valid state.
#[derive(Serialize, Deserialize, Clone, Debug, Default)]
pub struct HistoryViewModel {
    /// List of workout history items
    pub workouts: Vec<HistoryItemViewModel>,
    /// Whether history is currently loading from database
    pub is_loading: bool,
}

/// ViewModel for a single item in the history list.
///
/// **Default Trait: NOT implemented (Explicit Construction)**
///
/// Reasoning: HistoryItemViewModel represents a specific past workout with
/// actual data. Each instance should be constructed from a real Workout entity.
/// No meaningful default exists.
#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct HistoryItemViewModel {
    /// Unique identifier for this workout
    pub id: String, // UUID as string for easier Swift interop
    /// Workout name
    pub name: String,
    /// Formatted date (e.g., "Nov 26, 2025")
    pub date: String,
    /// Number of exercises in the workout
    pub exercise_count: usize,
    /// Total number of sets in the workout
    pub set_count: usize,
    /// Total volume
    pub total_volume: i32,
}

/// ViewModel for the workout detail view (viewing a past workout).
///
/// **Default Trait: NOT implemented (Explicit Construction)**
///
/// Reasoning: HistoryDetailViewModel shows a specific past workout's complete
/// details. It should always be constructed from an actual Workout entity.
/// No meaningful default exists.
#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct HistoryDetailViewModel {
    /// Unique identifier for this workout
    pub id: String, // UUID as string for easier Swift interop
    /// Workout name
    pub workout_name: String,
    /// Formatted date (e.g., "Nov 26, 2025 at 3:45 PM")
    pub formatted_date: String,
    /// Duration (e.g., "45:23")
    pub duration: Option<String>,
    /// Exercises in this workout
    pub exercises: Vec<ExerciseDetailViewModel>,
    /// Workout notes
    pub notes: Option<String>,
    /// Total volume
    pub total_volume: i32,
    /// Total sets completed
    pub total_sets: usize,
}

/// ViewModel for an exercise in the history detail view.
///
/// **Default Trait: NOT implemented (Explicit Construction)**
///
/// Reasoning: ExerciseDetailViewModel represents a specific exercise from a
/// past workout. Should be constructed from actual Exercise data.
#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct ExerciseDetailViewModel {
    /// Exercise name
    pub name: String,
    /// Sets for this exercise
    pub sets: Vec<SetDetailViewModel>,
}

/// ViewModel for a set in the history detail view.
///
/// **Default Trait: NOT implemented (Explicit Construction)**
///
/// Reasoning: SetDetailViewModel shows a specific completed set's data.
/// Should be constructed from actual ExerciseSet data.
#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct SetDetailViewModel {
    /// Set number (1-indexed for display)
    pub set_number: i32,
    /// Complete display text (e.g., "225 lb × 10 reps @ 8.0 RPE")
    pub display_text: String,
}

/// ViewModel for the plate calculator.
///
/// **Default Trait: IMPLEMENTED**
///
/// Reasoning: PlateCalculatorViewModel represents calculator state. A Default
/// implementation provides a clear "empty calculator" state with no inputs or
/// results, which is useful for initialization and testing.
#[derive(Serialize, Deserialize, Clone, Debug, Default)]
pub struct PlateCalculatorViewModel {
    /// Target weight input as string
    pub target_weight: String,
    /// Percentage input as string (optional)
    pub percentage: String,
    /// Selected bar type (if any)
    pub bar_type_name: Option<String>,
    /// Calculation result (if calculated)
    pub calculation: Option<PlateCalculationResult>,
    /// Whether the calculator is shown
    pub is_shown: bool,
}

/// Result of a plate calculation for the UI.
///
/// **Default Trait: NOT implemented (Explicit Construction)**
///
/// Reasoning: PlateCalculationResult is always the output of an actual
/// calculation with specific plate data. No meaningful default exists.
#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct PlateCalculationResult {
    /// Total weight calculated
    pub total_weight: f64,
    /// Bar weight used
    pub bar_weight: f64,
    /// Formatted plates description (e.g., "2×45lb, 1×25lb")
    pub plates_per_side: String,
    /// Individual plates with count
    pub plates: Vec<PlateViewModel>,
}

/// ViewModel for a single plate in the calculator.
///
/// **Default Trait: NOT implemented (Explicit Construction)**
///
/// Reasoning: PlateViewModel represents a specific plate with actual weight
/// and count data. Should be constructed from calculation results.
#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct PlateViewModel {
    /// Plate weight
    pub weight: f64,
    /// Number of this plate needed per side
    pub count: i32,
    /// Color name for UI display
    pub color: String,
}

