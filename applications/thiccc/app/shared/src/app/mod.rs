//! Core application logic for the Thiccc workout tracking application.
//!
//! This module implements the Crux App trait, defining the application's:
//! - Events: All user interactions and system events
//! - Model: Complete application state
//! - ViewModels: UI-friendly data structures
//! - Business logic: Event handling (update) and state transformation (view)

// Module declarations
pub mod events;
pub mod model;
pub mod view_models;
pub mod effects;

// Re-export all public types for convenience
pub use events::*;
pub use model::*;
pub use view_models::*;
pub use effects::*;

use crux_core::{render::render, App, Command};
use chrono::Utc;

use crate::id::Id;
use crate::models::*;
use crate::operations::{DatabaseOperation, StorageOperation, TimerOperation, TimerOutput};

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
                // Load any saved in-progress workout from storage AND load workout history from database
                return Command::all([
                    Command::request_from_shell(StorageOperation::LoadCurrentWorkout)
                        .then_send(|result| Event::StorageResponse { result }),
                    Command::request_from_shell(DatabaseOperation::LoadAllWorkouts)
                        .then_send(|result| Event::DatabaseResponse { result }),
                ]);
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
                    DatabaseResult::HistoryLoaded { workouts_json } => {
                        // Deserialize JSON strings to Workout objects
                        let workouts: Vec<Workout> = workouts_json
                            .iter()
                            .filter_map(|json| serde_json::from_str(json).ok())
                            .collect();
                        model.workout_history = workouts;
                    }
                    DatabaseResult::WorkoutLoaded { workout_json } => {
                        // Deserialize JSON string to Workout object
                        model.current_workout = workout_json
                            .and_then(|json| serde_json::from_str(&json).ok());
                    }
                    DatabaseResult::Error { message } => {
                        // Database error occurred
                        model.error_message = Some(message);
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
mod tests;
