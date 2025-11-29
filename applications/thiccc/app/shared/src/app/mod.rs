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
mod update;

// Re-export all public types for convenience
pub use events::*;
pub use model::*;
pub use view_models::*;
pub use effects::*;

use crux_core::{App, Command};

use crate::id::Id;
use crate::models::*;

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
    pub(crate) fn perform_plate_calculation(
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
    pub(crate) fn validate_workout_ids(workout: &Workout) -> Result<(), String> {
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
        // Delegate to feature-specific update modules
        update::handle_event(event, model)
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
