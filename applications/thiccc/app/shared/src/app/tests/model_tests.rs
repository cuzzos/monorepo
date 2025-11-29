use super::super::*;

// -------------------------------------------------------------------------
// Model Tests
// -------------------------------------------------------------------------

#[test]
fn test_model_default() {
    let model = Model::default();

    // Active workout should be None
    assert!(model.current_workout.is_none());
    assert_eq!(model.workout_timer_seconds, 0);
    assert!(!model.timer_running);

    // History should be empty
    assert!(model.workout_history.is_empty());

    // Should start on Workout tab
    assert_eq!(model.selected_tab, Tab::Workout);
    assert!(model.navigation_stack.is_empty());

    // All modals should be closed
    assert!(!model.showing_add_exercise);
    assert!(!model.showing_import);
    assert!(!model.showing_stopwatch);
    assert!(model.showing_rest_timer.is_none());
    assert!(!model.showing_plate_calculator);

    // No plate calculation
    assert!(model.plate_calculation.is_none());

    // No loading or error state
    assert!(!model.is_loading);
    assert!(model.error_message.is_none());
}

#[test]
fn test_model_get_or_create_workout() {
    let mut model = Model::default();

    // Should be None initially
    assert!(model.current_workout.is_none());

    // Get or create should create a new workout
    let workout = model.get_or_create_workout();
    assert!(workout.exercises.is_empty());
    let first_id = workout.id.clone();

    // Should not create a second workout (same ID)
    let workout2 = model.get_or_create_workout();
    assert_eq!(first_id, workout2.id);
}

#[test]
fn test_model_find_exercise_mut() {
    let mut model = Model::default();

    // Should return None when no workout exists
    let non_existent_id = Id::new();
    assert!(model.find_exercise_mut(&non_existent_id).is_none());

    // Add a workout with an exercise
    let workout = model.get_or_create_workout();
    let exercise = workout.add_exercise("Bench Press");
    let exercise_id = exercise.id.clone();

    // Should find the exercise
    let found = model.find_exercise_mut(&exercise_id);
    assert!(found.is_some());
    assert_eq!(found.unwrap().name, "Bench Press");

    // Should not find non-existent exercise
    let another_id = Id::new();
    assert!(model.find_exercise_mut(&another_id).is_none());
}

#[test]
fn test_model_find_set_mut() {
    let mut model = Model::default();

    // Add a workout with an exercise and a set
    let workout = model.get_or_create_workout();
    let exercise = workout.add_exercise("Squat");
    let set = exercise.add_set();
    let set_id = set.id.clone();

    // Should find the set
    let found = model.find_set_mut(&set_id);
    assert!(found.is_some());
    assert_eq!(found.unwrap().id, set_id);

    // Should not find non-existent set
    let another_id = Id::new();
    assert!(model.find_set_mut(&another_id).is_none());
}

#[test]
fn test_model_calculate_total_volume() {
    let mut model = Model::default();

    // Should return 0 when no workout exists
    assert_eq!(model.calculate_total_volume(), 0);

    // Add a workout with exercises and completed sets
    let workout = model.get_or_create_workout();
    let exercise = workout.add_exercise("Bench Press");

    // Add two completed sets
    let set1 = exercise.add_set();
    set1.complete(SetActual::with_weight_and_reps(135.0, 10));

    let set2 = exercise.add_set();
    set2.complete(SetActual::with_weight_and_reps(185.0, 5));

    // Volume = (135 * 10) + (185 * 5) = 1350 + 925 = 2275
    assert_eq!(model.calculate_total_volume(), 2275);
}

#[test]
fn test_model_calculate_total_sets() {
    let mut model = Model::default();

    // Should return 0 when no workout exists
    assert_eq!(model.calculate_total_sets(), 0);

    // Add a workout with exercises and sets
    let workout = model.get_or_create_workout();
    let exercise1 = workout.add_exercise("Squat");
    exercise1.add_set();
    exercise1.add_set();

    let exercise2 = workout.add_exercise("Deadlift");
    exercise2.add_set();

    // Total should be 3 sets
    assert_eq!(model.calculate_total_sets(), 3);
}

#[test]
fn test_model_format_duration() {
    // Test various durations
    let model = Model {
        workout_timer_seconds: 0,
        ..Default::default()
    };
    assert_eq!(model.format_duration(), "00:00");

    let model = Model {
        workout_timer_seconds: 59,
        ..Default::default()
    };
    assert_eq!(model.format_duration(), "00:59");

    let model = Model {
        workout_timer_seconds: 60,
        ..Default::default()
    };
    assert_eq!(model.format_duration(), "01:00");

    let model = Model {
        workout_timer_seconds: 323,
        ..Default::default()
    };
    assert_eq!(model.format_duration(), "05:23");

    let model = Model {
        workout_timer_seconds: 3661,
        ..Default::default()
    };
    assert_eq!(model.format_duration(), "61:01");
}

