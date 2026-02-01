//! Application state (Model) for the Thiccc application.
//!
//! This module defines the core application state and helper methods
//! for working with that state.

use super::events::{NavigationDestination, Tab};
use crate::id::Id;
use crate::models::*;

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

    /// Detail view data for currently viewed historical workout
    pub history_detail_view: Option<Workout>,

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
            history_detail_view: None,

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

