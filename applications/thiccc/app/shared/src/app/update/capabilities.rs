//! Capability response handlers.
//!
//! Handles responses from platform capabilities (database, storage, timer).

use chrono::Utc;
use crux_core::{render::render, Command};

use crate::models::Workout;
use crate::operations::{TimerOperation, TimerOutput};

use super::super::{DatabaseResult, Effect, Event, Model, StorageResult};

/// Handle capability response events.
pub fn handle_event(event: Event, model: &mut Model) -> Command<Effect, Event> {
    match event {
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
            render()
        }

        Event::StorageResponse { result } => {
            model.is_loading = false;
            match result {
                StorageResult::CurrentWorkoutSaved => {
                    // Success - no action needed
                    render()
                }
                StorageResult::CurrentWorkoutLoaded { workout_json } => {
                    // Deserialize workout from JSON if present
                    if let Some(json) = workout_json {
                        match serde_json::from_str::<Workout>(&json) {
                            Ok(workout) => {
                                // Calculate elapsed time since workout started
                                let elapsed =
                                    Utc::now().signed_duration_since(workout.start_timestamp);
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
                    render()
                }
                StorageResult::CurrentWorkoutDeleted => {
                    // Success - no action needed
                    render()
                }
                StorageResult::Error { message } => {
                    model.error_message = Some(format!("Storage error: {}", message));
                    render()
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
            render()
        }

        Event::Error { message } => {
            model.error_message = Some(message);
            model.is_loading = false;
            render()
        }

        _ => unreachable!("capabilities module received wrong event type"),
    }
}

