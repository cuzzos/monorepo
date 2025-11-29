//! Exercise management event handlers.
//!
//! Handles adding, deleting, and reordering exercises in workouts.

use crux_core::{render::render, Command};

use crate::id::Id;
use crate::models::{Exercise, GlobalExercise};

use super::super::{Effect, Event, Model};

/// Handle exercise management events.
pub fn handle_event(event: Event, model: &mut Model) -> Command<Effect, Event> {
    match event {
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
            render()
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
            render()
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
            render()
        }

        Event::ShowAddExerciseView => {
            model.showing_add_exercise = true;
            render()
        }

        Event::DismissAddExerciseView => {
            model.showing_add_exercise = false;
            render()
        }

        _ => unreachable!("exercise module received wrong event type"),
    }
}

