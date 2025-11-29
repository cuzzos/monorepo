//! Import/Export event handlers.
//!
//! Handles workout import from JSON and template loading.

use crux_core::{render::render, Command};

use crate::models::Workout;

use super::super::{Effect, Event, Model};

/// Handle import/export events.
pub fn handle_event(event: Event, model: &mut Model) -> Command<Effect, Event> {
    match event {
        Event::ImportWorkout { json_data } => {
            match serde_json::from_str::<Workout>(&json_data) {
                Ok(workout) => {
                    // Validate all IDs in the imported workout to prevent data corruption
                    // The Id type uses #[serde(transparent)] which bypasses validation
                    // during deserialization, so we must validate manually.
                    if let Err(e) = super::super::Thiccc::validate_workout_ids(&workout) {
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
            render()
        }

        Event::ShowImportView => {
            model.showing_import = true;
            render()
        }

        Event::DismissImportView => {
            model.showing_import = false;
            render()
        }

        Event::LoadWorkoutTemplate => {
            // TODO: In Phase 3, implement template loading via capability
            model.error_message = Some("Template loading not yet implemented".to_string());
            render()
        }

        _ => unreachable!("import_export module received wrong event type"),
    }
}

