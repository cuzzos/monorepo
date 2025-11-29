//! Platform operation types for the Thiccc workout tracking application.
//!
//! This module defines the operations that the Rust core can request from the
//! platform shell (iOS). Each operation type implements the `Operation` trait
//! from Crux, which defines the expected output type.
//!
//! # Architecture (Crux 0.16 Command API)
//!
//! Operations are sent to the shell as part of the Effect enum:
//! 1. Core returns `Command::request_from_shell(operation)` from `update()`
//! 2. Shell receives the effect, performs the platform operation
//! 3. Shell calls `handle_response()` with the result
//! 4. Core receives the result as an Event
//!
//! # Note on Workout Data
//!
//! Database and Storage operations use JSON strings for Workout data instead
//! of the Workout type directly. This is because TypeGen has issues tracing
//! Request<T> when T contains complex nested types like chrono::DateTime.
//! The shell deserializes the JSON to reconstruct Workout objects.

use crux_core::capability::Operation;
use serde::{Deserialize, Serialize};

use crate::app::{DatabaseResult, StorageResult};

// =============================================================================
// MARK: - Database Operations
// =============================================================================

/// Operations for persisting workout data to the database.
///
/// The database stores completed workouts with their exercises and sets.
/// On iOS, this is implemented using GRDB (SQLite).
///
/// **Note**: SaveWorkout uses JSON-encoded workout data to avoid TypeGen
/// tracing issues with complex nested types in Request<T>.
#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, Default)]
pub enum DatabaseOperation {
    /// Save a completed workout to the database.
    ///
    /// The String is a JSON-encoded Workout object.
    /// This includes all exercises and sets within the workout.
    /// Called when user finishes a workout.
    SaveWorkout(String),

    /// Load all workouts from the database for the history view.
    ///
    /// Returns workouts in reverse chronological order (newest first).
    #[default]
    LoadAllWorkouts,

    /// Load a specific workout by its ID.
    ///
    /// Used when viewing workout details from history.
    /// The String is the UUID in lowercase string format.
    LoadWorkoutById(String),

    /// Delete a workout from the database.
    ///
    /// Removes the workout and all associated exercises and sets.
    /// The String is the UUID in lowercase string format.
    DeleteWorkout(String),
}

impl Operation for DatabaseOperation {
    type Output = DatabaseResult;
}

// =============================================================================
// MARK: - Storage Operations
// =============================================================================

/// Operations for file-based storage of the current workout.
///
/// The current in-progress workout is persisted to a JSON file so it can
/// be restored if the app is terminated. This is separate from the database
/// which only stores completed workouts.
///
/// **Note**: SaveCurrentWorkout uses JSON-encoded workout data to avoid TypeGen
/// tracing issues with complex nested types in Request<T>.
#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, Default)]
pub enum StorageOperation {
    /// Save the current in-progress workout to file storage.
    ///
    /// The String is a JSON-encoded Workout object.
    /// Called periodically and when the app goes to background.
    /// Overwrites any existing saved workout.
    SaveCurrentWorkout(String),

    /// Load the current workout from file storage.
    ///
    /// Called when the app launches to restore an in-progress workout.
    /// Returns None if no workout was saved.
    #[default]
    LoadCurrentWorkout,

    /// Delete the current workout file from storage.
    ///
    /// Called when a workout is finished or discarded.
    DeleteCurrentWorkout,
}

impl Operation for StorageOperation {
    type Output = StorageResult;
}

// =============================================================================
// MARK: - Timer Operations
// =============================================================================

/// Result of a timer operation.
///
/// Timer operations produce a stream of ticks or control responses.
#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, Default)]
pub enum TimerOutput {
    /// Timer tick - sent every second while timer is running.
    #[default]
    Tick,

    /// Timer was successfully started.
    Started,

    /// Timer was successfully stopped.
    Stopped,
}

/// Operations for the workout timer.
///
/// The timer sends tick events every second while a workout is in progress.
/// This is used to track workout duration.
#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
pub enum TimerOperation {
    /// Start the timer.
    ///
    /// Begins sending Tick events every second.
    /// If timer is already running, this has no effect.
    Start,

    /// Stop the timer.
    ///
    /// Stops sending Tick events.
    /// If timer is not running, this has no effect.
    Stop,
}

impl Operation for TimerOperation {
    type Output = TimerOutput;
}

// =============================================================================
// MARK: - Tests
// =============================================================================

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_database_operation_serialization() {
        // SaveWorkout now takes a JSON string (not a Workout directly)
        let workout_json = r#"{"id":"123","name":"Test"}"#.to_string();
        let op = DatabaseOperation::SaveWorkout(workout_json);

        let json = serde_json::to_string(&op).expect("Failed to serialize");
        let deserialized: DatabaseOperation =
            serde_json::from_str(&json).expect("Failed to deserialize");

        assert_eq!(op, deserialized);
    }

    #[test]
    fn test_database_operation_load_all() {
        let op = DatabaseOperation::LoadAllWorkouts;

        let json = serde_json::to_string(&op).expect("Failed to serialize");
        let deserialized: DatabaseOperation =
            serde_json::from_str(&json).expect("Failed to deserialize");

        assert_eq!(op, deserialized);
    }

    #[test]
    fn test_storage_operation_serialization() {
        // SaveCurrentWorkout now takes a JSON string (not a Workout directly)
        let workout_json = r#"{"id":"123","name":"Test"}"#.to_string();
        let op = StorageOperation::SaveCurrentWorkout(workout_json);

        let json = serde_json::to_string(&op).expect("Failed to serialize");
        let deserialized: StorageOperation =
            serde_json::from_str(&json).expect("Failed to deserialize");

        assert_eq!(op, deserialized);
    }

    #[test]
    fn test_storage_operation_load() {
        let op = StorageOperation::LoadCurrentWorkout;

        let json = serde_json::to_string(&op).expect("Failed to serialize");
        let deserialized: StorageOperation =
            serde_json::from_str(&json).expect("Failed to deserialize");

        assert_eq!(op, deserialized);
    }

    #[test]
    fn test_timer_operation_serialization() {
        let op = TimerOperation::Start;

        let json = serde_json::to_string(&op).expect("Failed to serialize");
        let deserialized: TimerOperation =
            serde_json::from_str(&json).expect("Failed to deserialize");

        assert_eq!(op, deserialized);
    }

    #[test]
    fn test_timer_output_default() {
        let output = TimerOutput::default();
        assert_eq!(output, TimerOutput::Tick);
    }

    #[test]
    fn test_database_operation_default() {
        let op = DatabaseOperation::default();
        assert_eq!(op, DatabaseOperation::LoadAllWorkouts);
    }

    #[test]
    fn test_storage_operation_default() {
        let op = StorageOperation::default();
        assert_eq!(op, StorageOperation::LoadCurrentWorkout);
    }
}

