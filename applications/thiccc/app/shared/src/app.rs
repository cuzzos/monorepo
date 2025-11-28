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

use crate::id::Id;
use crate::models::*;

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

    // ===== Capability Responses =====
    /// Database operation completed
    DatabaseResponse { result: DatabaseResult },

    /// File storage operation completed
    StorageResponse { result: StorageResult },

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
#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, Default)]
pub enum StorageResult {
    /// Current workout was saved to storage
    #[default]
    CurrentWorkoutSaved,
    /// Current workout was loaded from storage
    CurrentWorkoutLoaded { workout: Option<Workout> },
    /// Current workout was deleted from storage
    CurrentWorkoutDeleted,
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

#[effect(typegen)]
pub enum Effect {
    Render(RenderOperation),
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
                }
            }

            Event::FinishWorkout => {
                if let Some(workout) = &mut model.current_workout {
                    workout.finish();
                    model.workout_history.insert(0, workout.clone());
                    // TODO: In Phase 3, trigger database save capability
                }
                model.current_workout = None;
                model.workout_timer_seconds = 0;
                model.timer_running = false;
            }

            Event::DiscardWorkout => {
                model.current_workout = None;
                model.workout_timer_seconds = 0;
                model.timer_running = false;
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
            }

            Event::StopTimer => {
                model.timer_running = false;
            }

            Event::ToggleTimer => {
                model.timer_running = !model.timer_running;
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
                // TODO: In Phase 3, trigger database load capability
                // For now, just use what's in memory
                model.is_loading = false;
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
                let actual_weight = if let Some(percentage) = use_percentage {
                    target_weight * (percentage / 100.0)
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
                    StorageResult::CurrentWorkoutLoaded { workout } => {
                        model.current_workout = workout;
                    }
                    StorageResult::CurrentWorkoutDeleted => {
                        // Success - no action needed
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
#[allow(unused_must_use)] // Commands in tests are intentionally not used
mod tests {
    use super::*;

    // -------------------------------------------------------------------------
    // Event Serialization Tests
    // -------------------------------------------------------------------------

    #[test]
    fn test_event_serialization_add_exercise() {
        let event = Event::AddExercise {
            name: "Squat".to_string(),
            exercise_type: "barbell".to_string(),
            muscle_group: "Quadriceps".to_string(),
        };

        let json = serde_json::to_string(&event).expect("Failed to serialize event");
        let deserialized: Event = serde_json::from_str(&json).expect("Failed to deserialize event");

        assert_eq!(event, deserialized);
    }

    #[test]
    fn test_event_serialization_update_set_actual() {
        let set_id = Id::new().as_str().to_string(); // Create Id, convert to String for Event
        let actual = SetActual::with_weight_and_reps(225.0, 5);
        let event = Event::UpdateSetActual {
            set_id,
            actual: actual.clone(),
        };

        let json = serde_json::to_string(&event).expect("Failed to serialize event");
        let deserialized: Event = serde_json::from_str(&json).expect("Failed to deserialize event");

        assert_eq!(event, deserialized);
    }

    #[test]
    fn test_event_serialization_change_tab() {
        let event = Event::ChangeTab { tab: Tab::History };

        let json = serde_json::to_string(&event).expect("Failed to serialize event");
        let deserialized: Event = serde_json::from_str(&json).expect("Failed to deserialize event");

        assert_eq!(event, deserialized);
    }

    #[test]
    fn test_event_serialization_calculate_plates() {
        let event = Event::CalculatePlates {
            target_weight: 225.0,
            bar_weight: 45.0, // Olympic bar weight
            use_percentage: Some(90.0),
        };

        let json = serde_json::to_string(&event).expect("Failed to serialize event");
        let deserialized: Event = serde_json::from_str(&json).expect("Failed to deserialize event");

        assert_eq!(event, deserialized);
    }

    #[test]
    fn test_tab_serialization() {
        let workout_tab = Tab::Workout;
        let history_tab = Tab::History;

        let workout_json = serde_json::to_string(&workout_tab).unwrap();
        let history_json = serde_json::to_string(&history_tab).unwrap();

        assert_eq!(workout_json, r#""Workout""#);
        assert_eq!(history_json, r#""History""#);

        let deserialized_workout: Tab = serde_json::from_str(&workout_json).unwrap();
        let deserialized_history: Tab = serde_json::from_str(&history_json).unwrap();

        assert_eq!(deserialized_workout, Tab::Workout);
        assert_eq!(deserialized_history, Tab::History);
    }

    // -------------------------------------------------------------------------
    // Model Tests
    // -------------------------------------------------------------------------

    #[test]
    fn test_model_default() {
        let model = Model::default();

        // Active workout should be None
        assert!(model.current_workout.is_none());
        assert_eq!(model.workout_timer_seconds, 0);
        assert!(!model.timer_running);

        // History should be empty
        assert!(model.workout_history.is_empty());

        // Should start on Workout tab
        assert_eq!(model.selected_tab, Tab::Workout);
        assert!(model.navigation_stack.is_empty());

        // All modals should be closed
        assert!(!model.showing_add_exercise);
        assert!(!model.showing_import);
        assert!(!model.showing_stopwatch);
        assert!(model.showing_rest_timer.is_none());
        assert!(!model.showing_plate_calculator);

        // No plate calculation
        assert!(model.plate_calculation.is_none());

        // No loading or error state
        assert!(!model.is_loading);
        assert!(model.error_message.is_none());
    }

    #[test]
    fn test_model_get_or_create_workout() {
        let mut model = Model::default();

        // Should be None initially
        assert!(model.current_workout.is_none());

        // Get or create should create a new workout
        let workout = model.get_or_create_workout();
        assert!(workout.exercises.is_empty());
        let first_id = workout.id.clone();

        // Should not create a second workout (same ID)
        let workout2 = model.get_or_create_workout();
        assert_eq!(first_id, workout2.id);
    }

    #[test]
    fn test_model_find_exercise_mut() {
        let mut model = Model::default();

        // Should return None when no workout exists
        let non_existent_id = Id::new();
        assert!(model.find_exercise_mut(&non_existent_id).is_none());

        // Add a workout with an exercise
        let workout = model.get_or_create_workout();
        let exercise = workout.add_exercise("Bench Press");
        let exercise_id = exercise.id.clone();

        // Should find the exercise
        let found = model.find_exercise_mut(&exercise_id);
        assert!(found.is_some());
        assert_eq!(found.unwrap().name, "Bench Press");

        // Should not find non-existent exercise
        let another_id = Id::new();
        assert!(model.find_exercise_mut(&another_id).is_none());
    }

    #[test]
    fn test_model_find_set_mut() {
        let mut model = Model::default();

        // Add a workout with an exercise and a set
        let workout = model.get_or_create_workout();
        let exercise = workout.add_exercise("Squat");
        let set = exercise.add_set();
        let set_id = set.id.clone();

        // Should find the set
        let found = model.find_set_mut(&set_id);
        assert!(found.is_some());
        assert_eq!(found.unwrap().id, set_id);

        // Should not find non-existent set
        let another_id = Id::new();
        assert!(model.find_set_mut(&another_id).is_none());
    }

    #[test]
    fn test_model_calculate_total_volume() {
        let mut model = Model::default();

        // Should return 0 when no workout exists
        assert_eq!(model.calculate_total_volume(), 0);

        // Add a workout with exercises and completed sets
        let workout = model.get_or_create_workout();
        let exercise = workout.add_exercise("Bench Press");

        // Add two completed sets
        let set1 = exercise.add_set();
        set1.complete(SetActual::with_weight_and_reps(135.0, 10));

        let set2 = exercise.add_set();
        set2.complete(SetActual::with_weight_and_reps(185.0, 5));

        // Volume = (135 * 10) + (185 * 5) = 1350 + 925 = 2275
        assert_eq!(model.calculate_total_volume(), 2275);
    }

    #[test]
    fn test_model_calculate_total_sets() {
        let mut model = Model::default();

        // Should return 0 when no workout exists
        assert_eq!(model.calculate_total_sets(), 0);

        // Add a workout with exercises and sets
        let workout = model.get_or_create_workout();
        let exercise1 = workout.add_exercise("Squat");
        exercise1.add_set();
        exercise1.add_set();

        let exercise2 = workout.add_exercise("Deadlift");
        exercise2.add_set();

        // Total should be 3 sets
        assert_eq!(model.calculate_total_sets(), 3);
    }

    #[test]
    fn test_model_format_duration() {
        // Test various durations
        let model = Model {
            workout_timer_seconds: 0,
            ..Default::default()
        };
        assert_eq!(model.format_duration(), "00:00");

        let model = Model {
            workout_timer_seconds: 59,
            ..Default::default()
        };
        assert_eq!(model.format_duration(), "00:59");

        let model = Model {
            workout_timer_seconds: 60,
            ..Default::default()
        };
        assert_eq!(model.format_duration(), "01:00");

        let model = Model {
            workout_timer_seconds: 323,
            ..Default::default()
        };
        assert_eq!(model.format_duration(), "05:23");

        let model = Model {
            workout_timer_seconds: 3661,
            ..Default::default()
        };
        assert_eq!(model.format_duration(), "61:01");
    }

    // -------------------------------------------------------------------------
    // Database and Storage Result Tests
    // -------------------------------------------------------------------------

    #[test]
    fn test_database_result_serialization() {
        let result = DatabaseResult::WorkoutSaved;
        let json = serde_json::to_string(&result).expect("Failed to serialize");
        let deserialized: DatabaseResult =
            serde_json::from_str(&json).expect("Failed to deserialize");
        assert_eq!(result, deserialized);

        let result2 = DatabaseResult::HistoryLoaded {
            workouts: vec![Workout::new()],
        };
        let json2 = serde_json::to_string(&result2).expect("Failed to serialize");
        let deserialized2: DatabaseResult =
            serde_json::from_str(&json2).expect("Failed to deserialize");
        assert_eq!(result2, deserialized2);
    }

    #[test]
    fn test_storage_result_serialization() {
        let result = StorageResult::CurrentWorkoutSaved;
        let json = serde_json::to_string(&result).expect("Failed to serialize");
        let deserialized: StorageResult =
            serde_json::from_str(&json).expect("Failed to deserialize");
        assert_eq!(result, deserialized);
    }

    // -------------------------------------------------------------------------
    // ViewModel Tests
    // -------------------------------------------------------------------------

    #[test]
    fn test_view_model_default() {
        let vm = ViewModel::default();

        // Should have default tab
        assert_eq!(vm.selected_tab, Tab::Workout);

        // Should have default child ViewModels
        assert!(!vm.workout_view.has_active_workout);
        assert!(vm.history_view.workouts.is_empty());

        // Should have no error or loading state
        assert!(vm.error_message.is_none());
        assert!(!vm.is_loading);
    }

    #[test]
    fn test_workout_view_model_default() {
        let vm = WorkoutViewModel::default();

        assert!(!vm.has_active_workout);
        assert_eq!(vm.workout_name, "");
        assert_eq!(vm.formatted_duration, "");
        assert_eq!(vm.total_volume, 0);
        assert_eq!(vm.total_sets, 0);
        assert!(vm.exercises.is_empty());
        assert!(!vm.timer_running);
    }

    #[test]
    fn test_history_view_model_default() {
        let vm = HistoryViewModel::default();

        assert!(vm.workouts.is_empty());
        assert!(!vm.is_loading);
    }

    #[test]
    fn test_plate_calculator_view_model_default() {
        let vm = PlateCalculatorViewModel::default();

        assert_eq!(vm.target_weight, "");
        assert_eq!(vm.percentage, "");
        assert!(vm.bar_type_name.is_none());
        assert!(vm.calculation.is_none());
        assert!(!vm.is_shown);
    }

    #[test]
    fn test_exercise_view_model_serialization() {
        let vm = ExerciseViewModel {
            id: Id::new().as_str().to_string(),
            name: "Bench Press".to_string(),
            sets: vec![],
        };

        let json = serde_json::to_string(&vm).expect("Failed to serialize");
        let deserialized: ExerciseViewModel =
            serde_json::from_str(&json).expect("Failed to deserialize");

        assert_eq!(vm.id, deserialized.id);
        assert_eq!(vm.name, deserialized.name);
    }

    #[test]
    fn test_set_view_model_serialization() {
        let vm = SetViewModel {
            id: Id::new().as_str().to_string(),
            set_number: 1,
            previous_display: "225 × 10".to_string(),
            weight: "225".to_string(),
            reps: "10".to_string(),
            rpe: "8".to_string(),
            is_completed: false,
        };

        let json = serde_json::to_string(&vm).expect("Failed to serialize");
        let deserialized: SetViewModel =
            serde_json::from_str(&json).expect("Failed to deserialize");

        assert_eq!(vm.id, deserialized.id);
        assert_eq!(vm.set_number, deserialized.set_number);
        assert_eq!(vm.weight, deserialized.weight);
    }

    #[test]
    fn test_history_item_view_model_serialization() {
        let vm = HistoryItemViewModel {
            id: Id::new().as_str().to_string(),
            name: "Push Day".to_string(),
            date: "Nov 26, 2025".to_string(),
            exercise_count: 5,
            set_count: 20,
            total_volume: 10000,
        };

        let json = serde_json::to_string(&vm).expect("Failed to serialize");
        let deserialized: HistoryItemViewModel =
            serde_json::from_str(&json).expect("Failed to deserialize");

        assert_eq!(vm.name, deserialized.name);
        assert_eq!(vm.exercise_count, deserialized.exercise_count);
    }

    #[test]
    fn test_tab_default() {
        let tab = Tab::default();
        assert_eq!(tab, Tab::Workout);
    }

    // -------------------------------------------------------------------------
    // Integration Tests (Update + View Cycle)
    // -------------------------------------------------------------------------

    #[test]
    fn test_start_workout_flow() {
        let app = Thiccc;
        let mut model = Model::default();

        // Start workout
        app.update(Event::StartWorkout, &mut model, &());

        // Verify model state
        assert!(model.current_workout.is_some());
        assert_eq!(model.workout_timer_seconds, 0);
        assert!(model.timer_running);

        // Verify view state
        let view = app.view(&model);
        assert!(view.workout_view.has_active_workout);
        assert_eq!(view.workout_view.formatted_duration, "00:00");
    }

    #[test]
    fn test_add_exercise_flow() {
        let app = Thiccc;
        let mut model = Model::default();

        // Start workout
        app.update(Event::StartWorkout, &mut model, &());

        // Add exercise
        app.update(
            Event::AddExercise {
                name: "Bench Press".to_string(),
                exercise_type: "barbell".to_string(),
                muscle_group: "chest".to_string(),
            },
            &mut model,
            &(),
        );

        // Verify model state
        assert_eq!(model.current_workout.as_ref().unwrap().exercises.len(), 1);
        assert_eq!(
            model.current_workout.as_ref().unwrap().exercises[0].name,
            "Bench Press"
        );

        // Verify view state
        let view = app.view(&model);
        assert_eq!(view.workout_view.exercises.len(), 1);
        assert_eq!(view.workout_view.exercises[0].name, "Bench Press");
    }

    #[test]
    fn test_add_and_complete_set_flow() {
        let app = Thiccc;
        let mut model = Model::default();

        // Start workout and add exercise
        app.update(Event::StartWorkout, &mut model, &());
        app.update(
            Event::AddExercise {
                name: "Squat".to_string(),
                exercise_type: "barbell".to_string(),
                muscle_group: "legs".to_string(),
            },
            &mut model,
            &(),
        );

        let exercise_id = model.current_workout.as_ref().unwrap().exercises[0]
            .id
            .to_string();

        // Add a set
        app.update(
            Event::AddSet {
                exercise_id: exercise_id.clone(),
            },
            &mut model,
            &(),
        );

        // Verify set was added
        let view = app.view(&model);
        assert_eq!(view.workout_view.exercises[0].sets.len(), 1);
        assert!(!view.workout_view.exercises[0].sets[0].is_completed);

        // Complete the set
        let set_id = model.current_workout.as_ref().unwrap().exercises[0].sets[0]
            .id
            .to_string();
        app.update(
            Event::UpdateSetActual {
                set_id: set_id.clone(),
                actual: SetActual::with_weight_and_reps(225.0, 5),
            },
            &mut model,
            &(),
        );
        app.update(Event::ToggleSetCompleted { set_id }, &mut model, &());

        // Verify set is completed and has values
        let view = app.view(&model);
        assert!(view.workout_view.exercises[0].sets[0].is_completed);
        assert_eq!(view.workout_view.exercises[0].sets[0].weight, "225");
        assert_eq!(view.workout_view.exercises[0].sets[0].reps, "5");

        // Verify volume calculation
        assert_eq!(view.workout_view.total_volume, 1125); // 225 * 5
    }

    #[test]
    fn test_finish_workout_flow() {
        let app = Thiccc;
        let mut model = Model::default();

        // Start workout
        app.update(Event::StartWorkout, &mut model, &());

        // Add exercise and set
        app.update(
            Event::AddExercise {
                name: "Deadlift".to_string(),
                exercise_type: "barbell".to_string(),
                muscle_group: "back".to_string(),
            },
            &mut model,
            &(),
        );

        let exercise_id = model.current_workout.as_ref().unwrap().exercises[0]
            .id
            .to_string();
        app.update(Event::AddSet { exercise_id }, &mut model, &());

        // Finish workout
        app.update(Event::FinishWorkout, &mut model, &());

        // Verify workout was moved to history
        assert!(model.current_workout.is_none());
        assert_eq!(model.workout_history.len(), 1);
        assert!(!model.timer_running);

        // Verify view state
        let view = app.view(&model);
        assert!(!view.workout_view.has_active_workout);
        assert_eq!(view.history_view.workouts.len(), 1);
    }

    #[test]
    fn test_timer_tick_flow() {
        let app = Thiccc;
        let mut model = Model::default();

        // Start workout
        app.update(Event::StartWorkout, &mut model, &());

        // Simulate timer ticks
        for _ in 0..65 {
            app.update(Event::TimerTick, &mut model, &());
        }

        // Verify timer state
        assert_eq!(model.workout_timer_seconds, 65);

        // Verify view formatting
        let view = app.view(&model);
        assert_eq!(view.workout_view.formatted_duration, "01:05");
    }

    #[test]
    fn test_change_tab_flow() {
        let app = Thiccc;
        let mut model = Model::default();

        // Default tab should be Workout
        assert_eq!(model.selected_tab, Tab::Workout);

        // Change to History
        app.update(Event::ChangeTab { tab: Tab::History }, &mut model, &());

        // Verify model and view
        assert_eq!(model.selected_tab, Tab::History);
        let view = app.view(&model);
        assert_eq!(view.selected_tab, Tab::History);
    }

    #[test]
    fn test_plate_calculator_flow() {
        let app = Thiccc;
        let mut model = Model::default();

        // Calculate plates for 225 lbs
        app.update(
            Event::CalculatePlates {
                target_weight: 225.0,
                bar_weight: 45.0, // Olympic bar weight
                use_percentage: None,
            },
            &mut model,
            &(),
        );

        // Verify calculation
        assert!(model.plate_calculation.is_some());
        let calc = model.plate_calculation.as_ref().unwrap();
        assert_eq!(calc.total_weight, 225.0);

        // (225 - 45) / 2 = 90 lbs per side
        // Should use: 2x45 (90 lbs total)
        let description = calc.formatted_plate_description();
        assert!(description.contains("45lb"));
    }

    #[test]
    fn test_import_workout_flow() {
        let app = Thiccc;
        let mut model = Model::default();

        // Create a workout and serialize it
        let workout = Workout::with_name("Test Workout");
        let json = serde_json::to_string(&workout).unwrap();

        // Import it
        app.update(Event::ImportWorkout { json_data: json }, &mut model, &());

        // Verify it was imported
        assert!(model.current_workout.is_some());
        assert_eq!(model.current_workout.as_ref().unwrap().name, "Test Workout");
        assert!(model.error_message.is_none());
    }

    #[test]
    fn test_import_invalid_workout_shows_error() {
        let app = Thiccc;
        let mut model = Model::default();

        // Try to import invalid JSON
        app.update(
            Event::ImportWorkout {
                json_data: "{ invalid json }".to_string(),
            },
            &mut model,
            &(),
        );

        // Verify error was set
        assert!(model.error_message.is_some());
        assert!(model
            .error_message
            .as_ref()
            .unwrap()
            .contains("Failed to import"));
    }

    #[test]
    fn test_import_workout_with_invalid_uuid_is_rejected() {
        let app = Thiccc;
        let mut model = Model::default();

        // Create JSON with an invalid UUID (bypasses serde validation due to transparent)
        let malformed_json = r#"{
            "id": "not-a-valid-uuid",
            "name": "Malicious Workout",
            "note": null,
            "duration": null,
            "start_timestamp": "2025-01-01T12:00:00Z",
            "end_timestamp": null,
            "exercises": []
        }"#;

        // Try to import it
        app.update(
            Event::ImportWorkout {
                json_data: malformed_json.to_string(),
            },
            &mut model,
            &(),
        );

        // Verify the malformed UUID was caught and rejected
        assert!(model.current_workout.is_none(), "Workout with invalid UUID should not be imported");
        assert!(model.error_message.is_some(), "Error message should be set");
        assert!(
            model
                .error_message
                .as_ref()
                .unwrap()
                .contains("Invalid workout data"),
            "Error should mention invalid workout data"
        );
        assert!(
            model
                .error_message
                .as_ref()
                .unwrap()
                .contains("Invalid workout ID"),
            "Error should specifically mention the workout ID"
        );
    }
}
