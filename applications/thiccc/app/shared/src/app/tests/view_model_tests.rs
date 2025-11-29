use super::super::*;

// -------------------------------------------------------------------------
// Database and Storage Result Tests
// -------------------------------------------------------------------------

#[test]
fn test_database_result_serialization() {
    let result = DatabaseResult::WorkoutSaved;
    let json = serde_json::to_string(&result).expect("Failed to serialize");
    let deserialized: DatabaseResult =
        serde_json::from_str(&json).expect("Failed to deserialize");
    assert_eq!(result, deserialized);

    let result2 = DatabaseResult::HistoryLoaded {
        workouts: vec![Workout::new()],
    };
    let json2 = serde_json::to_string(&result2).expect("Failed to serialize");
    let deserialized2: DatabaseResult =
        serde_json::from_str(&json2).expect("Failed to deserialize");
    assert_eq!(result2, deserialized2);
}

#[test]
fn test_storage_result_serialization() {
    let result = StorageResult::CurrentWorkoutSaved;
    let json = serde_json::to_string(&result).expect("Failed to serialize");
    let deserialized: StorageResult =
        serde_json::from_str(&json).expect("Failed to deserialize");
    assert_eq!(result, deserialized);
}

// -------------------------------------------------------------------------
// ViewModel Tests
// -------------------------------------------------------------------------

#[test]
fn test_view_model_default() {
    let vm = ViewModel::default();

    // Should have default tab
    assert_eq!(vm.selected_tab, Tab::Workout);

    // Should have default child ViewModels
    assert!(!vm.workout_view.has_active_workout);
    assert!(vm.history_view.workouts.is_empty());

    // Should have no error or loading state
    assert!(vm.error_message.is_none());
    assert!(!vm.is_loading);
}

#[test]
fn test_workout_view_model_default() {
    let vm = WorkoutViewModel::default();

    assert!(!vm.has_active_workout);
    assert_eq!(vm.workout_name, "");
    assert_eq!(vm.formatted_duration, "");
    assert_eq!(vm.total_volume, 0);
    assert_eq!(vm.total_sets, 0);
    assert!(vm.exercises.is_empty());
    assert!(!vm.timer_running);
}

#[test]
fn test_history_view_model_default() {
    let vm = HistoryViewModel::default();

    assert!(vm.workouts.is_empty());
    assert!(!vm.is_loading);
}

#[test]
fn test_plate_calculator_view_model_default() {
    let vm = PlateCalculatorViewModel::default();

    assert_eq!(vm.target_weight, "");
    assert_eq!(vm.percentage, "");
    assert!(vm.bar_type_name.is_none());
    assert!(vm.calculation.is_none());
    assert!(!vm.is_shown);
}

#[test]
fn test_exercise_view_model_serialization() {
    let vm = ExerciseViewModel {
        id: Id::new().as_str().to_string(),
        name: "Bench Press".to_string(),
        sets: vec![],
    };

    let json = serde_json::to_string(&vm).expect("Failed to serialize");
    let deserialized: ExerciseViewModel =
        serde_json::from_str(&json).expect("Failed to deserialize");

    assert_eq!(vm.id, deserialized.id);
    assert_eq!(vm.name, deserialized.name);
}

#[test]
fn test_set_view_model_serialization() {
    let vm = SetViewModel {
        id: Id::new().as_str().to_string(),
        set_number: 1,
        previous_display: "225 × 10".to_string(),
        weight: "225".to_string(),
        reps: "10".to_string(),
        rpe: "8".to_string(),
        is_completed: false,
    };

    let json = serde_json::to_string(&vm).expect("Failed to serialize");
    let deserialized: SetViewModel =
        serde_json::from_str(&json).expect("Failed to deserialize");

    assert_eq!(vm.id, deserialized.id);
    assert_eq!(vm.set_number, deserialized.set_number);
    assert_eq!(vm.weight, deserialized.weight);
}

#[test]
fn test_history_item_view_model_serialization() {
    let vm = HistoryItemViewModel {
        id: Id::new().as_str().to_string(),
        name: "Push Day".to_string(),
        date: "Nov 26, 2025".to_string(),
        exercise_count: 5,
        set_count: 20,
        total_volume: 10000,
    };

    let json = serde_json::to_string(&vm).expect("Failed to serialize");
    let deserialized: HistoryItemViewModel =
        serde_json::from_str(&json).expect("Failed to deserialize");

    assert_eq!(vm.name, deserialized.name);
    assert_eq!(vm.exercise_count, deserialized.exercise_count);
}

