//! History and navigation event handlers.
//!
//! Handles loading workout history, viewing history items, and navigation.

use crux_core::{render::render, Command};

use crate::operations::DatabaseOperation;

use super::super::{Effect, Event, Model, NavigationDestination};

/// Handle history and navigation events.
pub fn handle_event(event: Event, model: &mut Model) -> Command<Effect, Event> {
    match event {
        Event::LoadHistory => {
            model.is_loading = true;
            Command::request_from_shell(DatabaseOperation::LoadAllWorkouts)
                .then_send(|result| Event::DatabaseResponse { result })
        }

        Event::ViewHistoryItem { workout_id } => {
            // String IDs are used directly in navigation - no parsing needed
            // They'll be parsed when actually loading the workout from database
            model
                .navigation_stack
                .push(NavigationDestination::HistoryDetail { workout_id });
            render()
        }

        Event::NavigateBack => {
            model.navigation_stack.pop();
            render()
        }

        Event::ChangeTab { tab } => {
            model.selected_tab = tab;
            // Clear navigation stack when changing tabs
            model.navigation_stack.clear();
            model.error_message = None; // Clear stale errors when navigating
            render()
        }

        _ => unreachable!("history module received wrong event type"),
    }
}

