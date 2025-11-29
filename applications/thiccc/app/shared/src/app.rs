//! Core application logic for the Thiccc workout tracking application.
//!
//! This module implements the Crux App trait, defining the application's:
//! - Events: All user interactions and system events
//! - Model: Complete application state
//! - ViewModels: UI-friendly data structures
//! - Business logic: Event handling (update) and state transformation (view)

use crux_core::{
    macros::effect,
    render::{render, RenderOperation},
    App, Command,
};
use serde::{Deserialize, Serialize};
use chrono::Utc;

use crate::id::Id;
use crate::models::*;
use crate::operations::{DatabaseOperation, StorageOperation, TimerOperation, TimerOutput};

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

// =============================================================================
// MARK: - Core Application State (Model)
// =============================================================================

/// Core application state for the Thiccc workout tracking app.
///
/// **Default Trait: IMPLEMENTED**
///
/// Reasoning: The Model struct represents complex application state with many
/// fields. Implementing Default provides a clear, well-documented initial state
/// for the application. This makes it easy to initialize the app and write tests.
/// The Default implementation explicitly defines what "empty/fresh app state"
/// means, serving as living documentation of the app's initial conditions.
///
/// The Model contains all application state managed by the Rust core, including:
/// - Active workout session data
/// - Workout history
/// - Navigation and modal state
/// - Timer state
/// - Loading and error state
#[derive(Debug)]
pub struct Model {
    // ===== Active Workout =====
    /// The currently active workout (None if no workout in progress)
    pub current_workout: Option<Workout>,

    /// Elapsed seconds for current workout
    pub workout_timer_seconds: i32,

    /// Whether the workout timer is running
    pub timer_running: bool,

    // ===== History =====
    /// List of completed workouts loaded from the database
    pub workout_history: Vec<Workout>,

    // ===== Navigation State =====
    /// Currently selected tab
    pub selected_tab: Tab,

    /// Navigation stack for drill-down navigation
    pub navigation_stack: Vec<NavigationDestination>,

    // ===== Modal State =====
    /// Whether add exercise view is shown
    pub showing_add_exercise: bool,

    /// Whether import view is shown
    pub showing_import: bool,

    /// Whether stopwatch modal is shown
    pub showing_stopwatch: bool,

    /// Rest timer duration (None if not shown, Some(duration) if shown)
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

impl Default for Model {
    /// Creates the initial application state.
    ///
    /// This represents a fresh app start with:
    /// - No active workout
    /// - Empty workout history
    /// - Workout tab selected
    /// - All modals closed
    /// - No loading or error state
    fn default() -> Self {
        Self {
            // Active workout state
            current_workout: None,
            workout_timer_seconds: 0,
            timer_running: false,

            // History
            workout_history: Vec::new(),

            // Navigation - explicitly start on Workout tab
            selected_tab: Tab::Workout,
            navigation_stack: Vec::new(),

            // Modals - all closed initially
            showing_add_exercise: false,
            showing_import: false,
            showing_stopwatch: false,
            showing_rest_timer: None,
            showing_plate_calculator: false,

            // Plate calculator
            plate_calculation: None,

            // Loading/Error state
            is_loading: false,
            error_message: None,
        }
    }
}

impl Model {
    /// Get the current workout or create a new one if none exists.
    ///
    /// This is a convenience method for operations that need to work with
    /// a workout, creating one automatically if needed.
    pub fn get_or_create_workout(&mut self) -> &mut Workout {
        if self.current_workout.is_none() {
            self.current_workout = Some(Workout::new());
        }
        self.current_workout.as_mut().expect("Just created workout")
    }

    /// Find an exercise by ID in the current workout.
    ///
    /// Returns None if no workout is active or if the exercise is not found.
    pub fn find_exercise_mut(&mut self, exercise_id: &Id) -> Option<&mut Exercise> {
        self.current_workout
            .as_mut()?
            .exercises
            .iter_mut()
            .find(|e| e.id == *exercise_id)
    }

    /// Find a set by ID across all exercises in the current workout.
    ///
    /// Returns None if no workout is active or if the set is not found.
    pub fn find_set_mut(&mut self, set_id: &Id) -> Option<&mut ExerciseSet> {
        self.current_workout
            .as_mut()?
            .exercises
            .iter_mut()
            .flat_map(|e| e.sets.iter_mut())
            .find(|s| s.id == *set_id)
    }

    /// Calculate total volume for the current workout.
    ///
    /// Volume is calculated as the sum of (weight × reps) for all completed sets.
    /// Returns 0 if no workout is active.
    pub fn calculate_total_volume(&self) -> i32 {
        self.current_workout
            .as_ref()
            .map(|w| w.total_volume() as i32)
            .unwrap_or(0)
    }

    /// Calculate total number of sets in the current workout.
    ///
    /// Returns 0 if no workout is active.
    pub fn calculate_total_sets(&self) -> usize {
        self.current_workout
            .as_ref()
            .map(|w| w.total_sets())
            .unwrap_or(0)
    }

    /// Format the workout timer duration as "MM:SS".
    ///
    /// Example: 323 seconds -> "05:23"
    pub fn format_duration(&self) -> String {
        let minutes = self.workout_timer_seconds / 60;
        let seconds = self.workout_timer_seconds % 60;
        format!("{:02}:{:02}", minutes, seconds)
    }
}

// =============================================================================
// MARK: - Effects
// =============================================================================

/// Effects the Core will request from the Shell.
///
/// Each variant represents a different capability that the platform shell
/// must implement. The shell receives these effects, performs the platform
/// operation, and sends the result back via `handle_response`.
///
/// The `#[effect(typegen)]` macro generates:
/// - `From<Request<Op>>` implementations for each operation type
/// - TypeGen registration for Swift/Kotlin code generation
#[effect(typegen)]
pub enum Effect {
    /// Request a UI re-render
    Render(RenderOperation),
    /// Database operations (save/load workouts to GRDB)
    Database(DatabaseOperation),
    /// File storage operations (current workout persistence)
    Storage(StorageOperation),
    /// Timer operations (workout duration tracking)
    Timer(TimerOperation),
}

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
    /// Current error message to display (if any)
    pub error_message: Option<String>,
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

// =============================================================================
// MARK: - Crux App Implementation
// =============================================================================

#[derive(Default)]
pub struct Thiccc;

// =============================================================================
// MARK: - View Helper Methods
// =============================================================================

impl Thiccc {
    /// Builds the WorkoutViewModel from the current Model state.
    fn build_workout_view(&self, model: &Model) -> WorkoutViewModel {
        let has_active_workout = model.current_workout.is_some();

        let (workout_name, exercises) = if let Some(workout) = &model.current_workout {
            let exercise_vms = workout
                .exercises
                .iter()
                .map(|exercise| self.build_exercise_view(exercise))
                .collect();

            (workout.name.clone(), exercise_vms)
        } else {
            (String::new(), Vec::new())
        };

        WorkoutViewModel {
            has_active_workout,
            workout_name,
            formatted_duration: model.format_duration(),
            total_volume: model.calculate_total_volume(),
            total_sets: model.calculate_total_sets(),
            exercises,
            timer_running: model.timer_running,
            showing_add_exercise: model.showing_add_exercise,
            showing_import: model.showing_import,
            showing_stopwatch: model.showing_stopwatch,
            showing_rest_timer: model.showing_rest_timer,
        }
    }

    /// Builds an ExerciseViewModel from an Exercise.
    fn build_exercise_view(&self, exercise: &Exercise) -> ExerciseViewModel {
        let sets = exercise
            .sets
            .iter()
            .enumerate()
            .map(|(idx, set)| self.build_set_view(set, idx as i32 + 1))
            .collect();

        ExerciseViewModel {
            id: exercise.id.as_str().to_string(), // Convert Id to String for ViewModel
            name: exercise.name.clone(),
            sets,
        }
    }

    /// Builds a SetViewModel from an ExerciseSet.
    fn build_set_view(&self, set: &ExerciseSet, set_number: i32) -> SetViewModel {
        // Build previous display string
        let previous_display =
            if let (Some(weight), Some(reps)) = (set.suggest.weight, set.suggest.reps) {
                format!("{} × {}", weight, reps)
            } else {
                String::new()
            };

        // Convert actual values to strings for text field binding
        let weight = set.actual.weight.map(|w| w.to_string()).unwrap_or_default();
        let reps = set.actual.reps.map(|r| r.to_string()).unwrap_or_default();
        let rpe = set.actual.rpe.map(|r| r.to_string()).unwrap_or_default();

        SetViewModel {
            id: set.id.as_str().to_string(), // Convert Id to String for ViewModel
            set_number,
            previous_display,
            weight,
            reps,
            rpe,
            is_completed: set.is_completed,
        }
    }

    /// Builds the HistoryViewModel from the current Model state.
    fn build_history_view(&self, model: &Model) -> HistoryViewModel {
        let workouts = model
            .workout_history
            .iter()
            .map(|workout| self.build_history_item(workout))
            .collect();

        HistoryViewModel {
            workouts,
            is_loading: model.is_loading,
        }
    }

    /// Builds a HistoryItemViewModel from a Workout.
    fn build_history_item(&self, workout: &Workout) -> HistoryItemViewModel {
        let date = workout.start_timestamp.format("%b %d, %Y").to_string();

        HistoryItemViewModel {
            id: workout.id.as_str().to_string(), // Convert Id to String for ViewModel
            name: workout.name.clone(),
            date,
            exercise_count: workout.exercises.len(),
            set_count: workout.total_sets(),
            total_volume: workout.total_volume() as i32,
        }
    }

    /// Performs the plate calculation after all validations have passed.
    ///
    /// # Arguments
    /// * `model` - The model to update with the calculation result
    /// * `target_weight` - The target weight to load (pre-validated as > 0)
    /// * `bar_weight` - The weight of the bar (pre-validated as > 0)
    /// * `percentage` - Optional percentage to apply (pre-validated as 0-100)
    fn perform_plate_calculation(
        model: &mut Model,
        target_weight: f64,
        bar_weight: f64,
        percentage: Option<f64>,
    ) {
        let actual_weight = if let Some(pct) = percentage {
            target_weight * (pct / 100.0)
        } else {
            target_weight
        };

        // Calculate weight remaining after bar
        let weight_per_side = (actual_weight - bar_weight) / 2.0;

        if weight_per_side < 0.0 {
            model.error_message = Some("Target weight is less than bar weight".to_string());
            model.plate_calculation = None;
        } else {
            // Get standard plates (use pounds for now)
            let available_plates = Plate::standard();
            let mut remaining = weight_per_side;
            let mut plates = Vec::new();

            // Greedy algorithm: use largest plates first
            for plate in &available_plates {
                while remaining >= plate.weight - 0.01 {
                    // Small epsilon for floating point
                    plates.push(plate.clone());
                    remaining -= plate.weight;
                }
            }

            // Create a BarType based on the weight for the calculation result
            let bar_type = BarType::new("Bar", bar_weight);

            model.plate_calculation = Some(PlateCalculation {
                total_weight: actual_weight,
                bar_type,
                plates,
                weight_unit: WeightUnit::Lb, // TODO: Use user preference
            });
        }
    }

    /// Validates all IDs in a workout to ensure they are valid UUIDs.
    ///
    /// The Id type uses #[serde(transparent)] which allows invalid strings
    /// to bypass validation during deserialization. This function manually
    /// validates all IDs to prevent data corruption from malformed imports.
    ///
    /// # Returns
    /// - `Ok(())` if all IDs are valid UUIDs
    /// - `Err(String)` with a descriptive error message if any ID is invalid
    fn validate_workout_ids(workout: &Workout) -> Result<(), String> {
        // Validate workout ID
        Id::from_string(workout.id.as_str().to_string())
            .map_err(|e| format!("Invalid workout ID: {}", e))?;

        // Validate all exercise IDs and their nested set IDs
        for (exercise_idx, exercise) in workout.exercises.iter().enumerate() {
            // Validate exercise ID
            Id::from_string(exercise.id.as_str().to_string())
                .map_err(|e| format!("Invalid exercise ID at index {}: {}", exercise_idx, e))?;

            // Validate exercise's workout_id reference
            Id::from_string(exercise.workout_id.as_str().to_string()).map_err(|e| {
                format!(
                    "Invalid workout_id in exercise at index {}: {}",
                    exercise_idx, e
                )
            })?;

            // Validate all set IDs
            for (set_idx, set) in exercise.sets.iter().enumerate() {
                // Validate set ID
                Id::from_string(set.id.as_str().to_string()).map_err(|e| {
                    format!(
                        "Invalid set ID at exercise {} set {}: {}",
                        exercise_idx, set_idx, e
                    )
                })?;

                // Validate set's exercise_id reference
                Id::from_string(set.exercise_id.as_str().to_string()).map_err(|e| {
                    format!(
                        "Invalid exercise_id in set at exercise {} set {}: {}",
                        exercise_idx, set_idx, e
                    )
                })?;

                // Validate set's workout_id reference
                Id::from_string(set.workout_id.as_str().to_string()).map_err(|e| {
                    format!(
                        "Invalid workout_id in set at exercise {} set {}: {}",
                        exercise_idx, set_idx, e
                    )
                })?;
            }
        }

        Ok(())
    }
}

// =============================================================================
// MARK: - Crux App Implementation
// =============================================================================

impl App for Thiccc {
    type Event = Event;
    type Model = Model;
    type ViewModel = ViewModel;
    type Capabilities = (); // will be deprecated, so use unit type for now
    type Effect = Effect;

    fn update(
        &self,
        event: Self::Event,
        model: &mut Self::Model,
        _caps: &(), // will be deprecated, so prefix with underscore for now
    ) -> Command<Effect, Event> {
        match event {
            // =================================================================
            // App Lifecycle
            // =================================================================
            Event::Initialize => {
                // Load any saved in-progress workout from storage
                return Command::request_from_shell(StorageOperation::LoadCurrentWorkout)
                    .then_send(|result| Event::StorageResponse { result });
            }

            // =================================================================
            // Workout Management
            // =================================================================
            Event::StartWorkout => {
                if model.current_workout.is_some() {
                    const WIP_MSG: &str = "A workout is already in progress. Please finish or discard it first.";
                    model.error_message = Some(WIP_MSG.to_string());
                } else {
                    model.current_workout = Some(Workout::new());
                    model.workout_timer_seconds = 0;
                    model.timer_running = true;
                    model.error_message = None; // Clear any stale errors on successful start

                    // Start timer and save current workout to storage
                    // Serialize workout to JSON for storage operation
                    let workout_json = model.current_workout.as_ref()
                        .and_then(|w| serde_json::to_string(w).ok())
                        .unwrap_or_else(|| {
                            eprintln!("ERROR: Failed to serialize workout for storage");
                            "{}".to_string() // Return valid empty JSON as fallback
                        });
                    return Command::all([
                        Command::request_from_shell(TimerOperation::Start)
                            .then_send(|output| Event::TimerResponse { output }),
                        Command::request_from_shell(StorageOperation::SaveCurrentWorkout(workout_json))
                            .then_send(|result| Event::StorageResponse { result }),
                        render(),
                    ]);
                }
            }

            Event::FinishWorkout => {
                if let Some(mut workout) = model.current_workout.take() {
                    workout.finish(model.workout_timer_seconds);
                    model.workout_history.insert(0, workout.clone());
                    model.workout_timer_seconds = 0;
                    model.timer_running = false;
                    model.error_message = None; // Clear any stale errors on successful finish

                    // Save to database, delete from storage, stop timer
                    // Serialize workout to JSON for database operation
                    let workout_json = serde_json::to_string(&workout).unwrap_or_else(|e| {
                        eprintln!("ERROR: Failed to serialize workout for database: {}", e);
                        "{}".to_string() // Return valid empty JSON as fallback
                    });
                    return Command::all([
                        Command::request_from_shell(DatabaseOperation::SaveWorkout(workout_json))
                            .then_send(|result| Event::DatabaseResponse { result }),
                        Command::request_from_shell(StorageOperation::DeleteCurrentWorkout)
                            .then_send(|result| Event::StorageResponse { result }),
                        Command::request_from_shell(TimerOperation::Stop)
                            .then_send(|output| Event::TimerResponse { output }),
                        render(),
                    ]);
                }
                model.current_workout = None;
                model.workout_timer_seconds = 0;
                model.timer_running = false;
                model.error_message = None; // Clear any previous error
            }

            Event::DiscardWorkout => {
                model.current_workout = None;
                model.workout_timer_seconds = 0;
                model.timer_running = false;
                model.error_message = None; // Clear any stale errors on discard

                // Delete from storage and stop timer
                return Command::all([
                    Command::request_from_shell(StorageOperation::DeleteCurrentWorkout)
                        .then_send(|result| Event::StorageResponse { result }),
                    Command::request_from_shell(TimerOperation::Stop)
                        .then_send(|output| Event::TimerResponse { output }),
                    render(),
                ]);                
            }

            Event::UpdateWorkoutName { name } => {
                if let Some(workout) = &mut model.current_workout {
                    workout.name = name;
                }
            }

            Event::UpdateWorkoutNotes { notes } => {
                if let Some(workout) = &mut model.current_workout {
                    workout.note = if notes.is_empty() { None } else { Some(notes) };
                }
            }

            // =================================================================
            // Exercise Management
            // =================================================================
            Event::AddExercise {
                name,
                exercise_type,
                muscle_group,
            } => {
                let workout = model.get_or_create_workout();
                // Create GlobalExercise from the provided fields
                let global_exercise = GlobalExercise::new(name, exercise_type, muscle_group);
                let new_exercise = Exercise::from_global(&global_exercise, workout.id.clone());
                workout.exercises.push(new_exercise);
                model.showing_add_exercise = false;
                model.error_message = None; // Clear any stale errors on successful add
            }

            Event::DeleteExercise { exercise_id } => {
                // Validate and convert String to Id type
                match Id::from_string(exercise_id) {
                    Ok(id) => {
                        if let Some(workout) = &mut model.current_workout {
                            workout.exercises.retain(|e| e.id != id);
                        }
                    }
                    Err(e) => {
                        model.error_message = Some(format!("Invalid exercise ID: {}", e));
                    }
                }
            }

            Event::MoveExercise {
                from_index,
                to_index,
            } => {
                if let Some(workout) = &mut model.current_workout {
                    if from_index < workout.exercises.len() && to_index < workout.exercises.len() {
                        let exercise = workout.exercises.remove(from_index);
                        workout.exercises.insert(to_index, exercise);
                    } else {
                        model.error_message = Some(format!(
                            "Cannot move exercise: invalid position (from: {}, to: {}, total: {})",
                            from_index,
                            to_index,
                            workout.exercises.len()
                        ));
                    }
                }
            }

            Event::ShowAddExerciseView => {
                model.showing_add_exercise = true;
            }

            Event::DismissAddExerciseView => {
                model.showing_add_exercise = false;
            }

            // =================================================================
            // Set Management
            // =================================================================
            Event::AddSet { exercise_id } => {
                // Validate and convert String to Id type at the boundary
                match Id::from_string(exercise_id) {
                    Ok(id) => {
                        if let Some(exercise) = model.find_exercise_mut(&id) {
                            exercise.add_set();
                            model.error_message = None; // Clear any stale errors on successful add
                        }
                    }
                    Err(e) => {
                        model.error_message = Some(format!("Invalid exercise ID: {}", e));
                    }
                }
            }

            Event::DeleteSet {
                exercise_id,
                set_index,
            } => {
                // Validate and convert String to Id type at the boundary
                match Id::from_string(exercise_id) {
                    Ok(id) => {
                        if let Some(exercise) = model.find_exercise_mut(&id) {
                            if set_index < exercise.sets.len() {
                                exercise.sets.remove(set_index);
                                // Re-index remaining sets
                                for (idx, set) in exercise.sets.iter_mut().enumerate() {
                                    set.set_index = idx as i32;
                                }
                            } else {
                                model.error_message = Some(format!(
                                    "Cannot delete set: index {} is out of bounds (total sets: {})",
                                    set_index,
                                    exercise.sets.len()
                                ));
                            }
                        }
                    }
                    Err(e) => {
                        model.error_message = Some(format!("Invalid exercise ID: {}", e));
                    }
                }
            }

            Event::UpdateSetActual { set_id, actual } => {
                // Validate and convert String to Id type at the boundary
                match Id::from_string(set_id) {
                    Ok(id) => {
                        if let Some(set) = model.find_set_mut(&id) {
                            set.actual = actual;
                        }
                    }
                    Err(e) => {
                        model.error_message = Some(format!("Invalid set ID: {}", e));
                    }
                }
            }

            Event::ToggleSetCompleted { set_id } => {
                // Validate and convert String to Id type at the boundary
                match Id::from_string(set_id) {
                    Ok(id) => {
                        if let Some(set) = model.find_set_mut(&id) {
                            set.is_completed = !set.is_completed;
                        }
                    }
                    Err(e) => {
                        model.error_message = Some(format!("Invalid set ID: {}", e));
                    }
                }
            }

            // =================================================================
            // Timer Events
            // =================================================================
            Event::TimerTick => {
                if model.timer_running {
                    model.workout_timer_seconds += 1;
                }
            }

            Event::StartTimer => {
                model.timer_running = true;
                return Command::request_from_shell(TimerOperation::Start)
                    .then_send(|output| Event::TimerResponse { output });
            }

            Event::StopTimer => {
                model.timer_running = false;
                return Command::request_from_shell(TimerOperation::Stop)
                    .then_send(|output| Event::TimerResponse { output });
            }

            Event::ToggleTimer => {
                model.timer_running = !model.timer_running;
                let operation = if model.timer_running {TimerOperation::Start} else {TimerOperation::Stop};
                return Command::request_from_shell(operation)
                    .then_send(|output| Event::TimerResponse { output });
            }

            Event::ShowStopwatch => {
                model.showing_stopwatch = true;
            }

            Event::DismissStopwatch => {
                model.showing_stopwatch = false;
            }

            Event::ShowRestTimer { duration_seconds } => {
                model.showing_rest_timer = Some(duration_seconds);
            }

            Event::DismissRestTimer => {
                model.showing_rest_timer = None;
            }

            // =================================================================
            // History & Navigation
            // =================================================================
            Event::LoadHistory => {
                model.is_loading = true;
                return Command::request_from_shell(DatabaseOperation::LoadAllWorkouts)
                    .then_send(|result| Event::DatabaseResponse { result });
            }

            Event::ViewHistoryItem { workout_id } => {
                // String IDs are used directly in navigation - no parsing needed
                // They'll be parsed when actually loading the workout from database
                model
                    .navigation_stack
                    .push(NavigationDestination::HistoryDetail { workout_id });
            }

            Event::NavigateBack => {
                model.navigation_stack.pop();
            }

            Event::ChangeTab { tab } => {
                model.selected_tab = tab;
                // Clear navigation stack when changing tabs
                model.navigation_stack.clear();
                model.error_message = None; // Clear stale errors when navigating
            }

            // =================================================================
            // Import/Export
            // =================================================================
            Event::ImportWorkout { json_data } => {
                match serde_json::from_str::<Workout>(&json_data) {
                    Ok(workout) => {
                        // Validate all IDs in the imported workout to prevent data corruption
                        // The Id type uses #[serde(transparent)] which bypasses validation
                        // during deserialization, so we must validate manually.
                        if let Err(e) = Self::validate_workout_ids(&workout) {
                            model.error_message = Some(format!("Invalid workout data: {}", e));
                        } else {
                            model.current_workout = Some(workout);
                            model.showing_import = false;
                            model.error_message = None;
                        }
                    }
                    Err(e) => {
                        model.error_message = Some(format!("Failed to import workout: {}", e));
                    }
                }
            }

            Event::ShowImportView => {
                model.showing_import = true;
            }

            Event::DismissImportView => {
                model.showing_import = false;
            }

            Event::LoadWorkoutTemplate => {
                // TODO: In Phase 3, implement template loading via capability
                model.error_message = Some("Template loading not yet implemented".to_string());
            }

            // =================================================================
            // Plate Calculator
            // =================================================================
            Event::CalculatePlates {
                target_weight,
                bar_weight,
                use_percentage,
            } => {
                // Validate inputs before calculation
                if target_weight <= 0.0 {
                    model.error_message = Some("Target weight must be greater than 0".to_string());
                    model.plate_calculation = None;
                } else if bar_weight <= 0.0 {
                    model.error_message = Some("Bar weight must be greater than 0".to_string());
                    model.plate_calculation = None;
                } else if let Some(percentage) = use_percentage {
                    if percentage < 0.0 || percentage > 100.0 {
                        model.error_message = Some(format!(
                            "Percentage must be between 0 and 100 (got {})",
                            percentage
                        ));
                        model.plate_calculation = None;
                    } else {
                        // All validations passed, perform calculation
                        Self::perform_plate_calculation(
                            model,
                            target_weight,
                            bar_weight,
                            Some(percentage),
                        );
                    }
                } else {
                    // No percentage, perform calculation directly
                    Self::perform_plate_calculation(model, target_weight, bar_weight, None);
                }
            }

            Event::ClearPlateCalculation => {
                model.plate_calculation = None;
            }

            Event::ShowPlateCalculator => {
                model.showing_plate_calculator = true;
            }

            Event::DismissPlateCalculator => {
                model.showing_plate_calculator = false;
                model.plate_calculation = None;
            }

            // =================================================================
            // Capability Responses
            // =================================================================
            Event::DatabaseResponse { result } => {
                model.is_loading = false;
                match result {
                    DatabaseResult::WorkoutSaved => {
                        // Success - no action needed
                    }
                    DatabaseResult::WorkoutDeleted => {
                        // Success - workout removed from database
                    }
                    DatabaseResult::HistoryLoaded { workouts } => {
                        model.workout_history = workouts;
                    }
                    DatabaseResult::WorkoutLoaded { workout } => {
                        model.current_workout = workout;
                    }
                }
            }

            Event::StorageResponse { result } => {
                model.is_loading = false;
                match result {
                    StorageResult::CurrentWorkoutSaved => {
                        // Success - no action needed
                    }
                    StorageResult::CurrentWorkoutLoaded { workout_json } => {
                        // Deserialize workout from JSON if present
                        if let Some(json) = workout_json {
                            match serde_json::from_str::<Workout>(&json) {
                                Ok(workout) => {
                                    // Calculate elapsed time since workout started
                                    let elapsed = Utc::now().signed_duration_since(workout.start_timestamp);
                                    model.workout_timer_seconds = elapsed.num_seconds().max(0) as i32;
                                    
                                    model.current_workout = Some(workout);
                                    // If a workout was loaded, also start the timer
                                    model.timer_running = true;
                                    return Command::request_from_shell(TimerOperation::Start)
                                        .then_send(|output| Event::TimerResponse { output });
                                }
                                Err(e) => {
                                    model.error_message =
                                        Some(format!("Failed to load workout: {}", e));
                                }
                            }
                        }
                    }
                    StorageResult::CurrentWorkoutDeleted => {
                        // Success - no action needed
                    }
                    StorageResult::Error { message } => {
                        model.error_message = Some(format!("Storage error: {}", message));
                    }
                }
            }

            Event::TimerResponse { output } => {
                match output {
                    TimerOutput::Tick => {
                        // Timer tick - increment workout duration
                        if model.timer_running {
                            model.workout_timer_seconds += 1;
                        }
                    }
                    TimerOutput::Started => {
                        // Timer started - no action needed, state already set
                    }
                    TimerOutput::Stopped => {
                        // Timer stopped - no action needed, state already set
                    }
                }
            }

            Event::Error { message } => {
                model.error_message = Some(message);
                model.is_loading = false;
            }
        }

        render()
    }

    fn view(&self, model: &Self::Model) -> Self::ViewModel {
        ViewModel {
            selected_tab: model.selected_tab.clone(),
            workout_view: self.build_workout_view(model),
            history_view: self.build_history_view(model),
            error_message: model.error_message.clone(),
            is_loading: model.is_loading,
        }
    }
}

// =============================================================================
// MARK: - Tests
// =============================================================================

#[cfg(test)]
#[path = "app/tests/mod.rs"]
mod tests;
