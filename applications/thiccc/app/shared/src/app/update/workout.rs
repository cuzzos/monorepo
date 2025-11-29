//! Workout management event handlers.
//!
//! Handles starting, finishing, discarding, and updating workouts.

use crux_core::{render::render, Command};

use crate::models::Workout;
use crate::operations::{DatabaseOperation, StorageOperation, TimerOperation};

use super::super::{Effect, Event, Model};

/// Handle workout management events.
pub fn handle_event(event: Event, model: &mut Model) -> Command<Effect, Event> {
    match event {
        Event::StartWorkout => {
            if model.current_workout.is_some() {
                const WIP_MSG: &str =
                    "A workout is already in progress. Please finish or discard it first.";
                model.error_message = Some(WIP_MSG.to_string());
                render()
            } else {
                model.current_workout = Some(Workout::new());
                model.workout_timer_seconds = 0;
                model.timer_running = true;
                model.error_message = None; // Clear any stale errors on successful start

                // Start timer and save current workout to storage
                // Serialize workout to JSON for storage operation
                let workout_json = model
                    .current_workout
                    .as_ref()
                    .and_then(|w| serde_json::to_string(w).ok())
                    .unwrap_or_else(|| {
                        eprintln!("ERROR: Failed to serialize workout for storage");
                        "{}".to_string() // Return valid empty JSON as fallback
                    });
                Command::all([
                    Command::request_from_shell(TimerOperation::Start)
                        .then_send(|output| Event::TimerResponse { output }),
                    Command::request_from_shell(StorageOperation::SaveCurrentWorkout(
                        workout_json,
                    ))
                    .then_send(|result| Event::StorageResponse { result }),
                    render(),
                ])
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
                Command::all([
                    Command::request_from_shell(DatabaseOperation::SaveWorkout(workout_json))
                        .then_send(|result| Event::DatabaseResponse { result }),
                    Command::request_from_shell(StorageOperation::DeleteCurrentWorkout)
                        .then_send(|result| Event::StorageResponse { result }),
                    Command::request_from_shell(TimerOperation::Stop)
                        .then_send(|output| Event::TimerResponse { output }),
                    render(),
                ])
            } else {
                model.current_workout = None;
                model.workout_timer_seconds = 0;
                model.timer_running = false;
                model.error_message = None; // Clear any previous error
                render()
            }
        }

        Event::DiscardWorkout => {
            model.current_workout = None;
            model.workout_timer_seconds = 0;
            model.timer_running = false;
            model.error_message = None; // Clear any stale errors on discard

            // Delete from storage and stop timer
            Command::all([
                Command::request_from_shell(StorageOperation::DeleteCurrentWorkout)
                    .then_send(|result| Event::StorageResponse { result }),
                Command::request_from_shell(TimerOperation::Stop)
                    .then_send(|output| Event::TimerResponse { output }),
                render(),
            ])
        }

        Event::UpdateWorkoutName { name } => {
            if let Some(workout) = &mut model.current_workout {
                workout.name = name;
            }
            render()
        }

        Event::UpdateWorkoutNotes { notes } => {
            if let Some(workout) = &mut model.current_workout {
                workout.note = if notes.is_empty() { None } else { Some(notes) };
            }
            render()
        }

        _ => unreachable!("workout module received wrong event type"),
    }
}

