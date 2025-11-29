//! Set management event handlers.
//!
//! Handles adding, deleting, and updating sets within exercises.

use crux_core::{render::render, Command};

use crate::id::Id;

use super::super::{Effect, Event, Model};

/// Handle set management events.
pub fn handle_event(event: Event, model: &mut Model) -> Command<Effect, Event> {
    match event {
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
            render()
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
            render()
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
            render()
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
            render()
        }

        _ => unreachable!("sets module received wrong event type"),
    }
}

