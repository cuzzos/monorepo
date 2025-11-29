//! Update logic modules for the Thiccc application.
//!
//! This module organizes event handlers by feature domain. Each sub-module
//! handles events for a specific feature area (workouts, exercises, sets, etc.).

mod app_lifecycle;
mod capabilities;
mod exercise;
mod history;
mod import_export;
mod plate_calculator;
mod sets;
mod timer;
mod workout;

use crux_core::Command;

use super::{Effect, Event, Model};

/// Route events to the appropriate handler module.
///
/// This function acts as a dispatcher, sending each event to the module
/// responsible for handling that type of event.
pub fn handle_event(event: Event, model: &mut Model) -> Command<Effect, Event> {
    match event {
        // App Lifecycle
        Event::Initialize => app_lifecycle::handle_event(event, model),

        // Workout Management
        Event::StartWorkout
        | Event::FinishWorkout
        | Event::DiscardWorkout
        | Event::UpdateWorkoutName { .. }
        | Event::UpdateWorkoutNotes { .. } => workout::handle_event(event, model),

        // Exercise Management
        Event::AddExercise { .. }
        | Event::DeleteExercise { .. }
        | Event::MoveExercise { .. }
        | Event::ShowAddExerciseView
        | Event::DismissAddExerciseView => exercise::handle_event(event, model),

        // Set Management
        Event::AddSet { .. }
        | Event::DeleteSet { .. }
        | Event::UpdateSetActual { .. }
        | Event::ToggleSetCompleted { .. } => sets::handle_event(event, model),

        // Timer Events
        Event::TimerTick
        | Event::StartTimer
        | Event::StopTimer
        | Event::ToggleTimer
        | Event::ShowStopwatch
        | Event::DismissStopwatch
        | Event::ShowRestTimer { .. }
        | Event::DismissRestTimer => timer::handle_event(event, model),

        // History & Navigation
        Event::LoadHistory
        | Event::ViewHistoryItem { .. }
        | Event::NavigateBack
        | Event::ChangeTab { .. } => history::handle_event(event, model),

        // Import/Export
        Event::ImportWorkout { .. }
        | Event::ShowImportView
        | Event::DismissImportView
        | Event::LoadWorkoutTemplate => import_export::handle_event(event, model),

        // Plate Calculator
        Event::CalculatePlates { .. }
        | Event::ClearPlateCalculation
        | Event::ShowPlateCalculator
        | Event::DismissPlateCalculator => plate_calculator::handle_event(event, model),

        // Capability Responses
        Event::DatabaseResponse { .. }
        | Event::StorageResponse { .. }
        | Event::TimerResponse { .. }
        | Event::Error { .. } => capabilities::handle_event(event, model),
    }
}

