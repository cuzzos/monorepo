//! App lifecycle event handlers.
//!
//! Handles initialization and app startup events.

use crux_core::Command;

use crate::operations::StorageOperation;

use super::super::{Effect, Event, Model};

/// Handle app lifecycle events.
pub fn handle_event(event: Event, _model: &mut Model) -> Command<Effect, Event> {
    match event {
        Event::Initialize => {
            // Load any saved in-progress workout from storage
            Command::request_from_shell(StorageOperation::LoadCurrentWorkout)
                .then_send(|result| Event::StorageResponse { result })
        }
        _ => unreachable!("app_lifecycle module received wrong event type"),
    }
}

