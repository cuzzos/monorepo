use super::super::*;

// -------------------------------------------------------------------------
// Integration Tests (Update + View Cycle)
// -------------------------------------------------------------------------

#[test]
fn test_start_workout_flow() {
    let app = Thiccc;
    let mut model = Model::default();

    // Start workout
    app.update(Event::StartWorkout, &mut model, &());

    // Verify model state
    assert!(model.current_workout.is_some());
    assert_eq!(model.workout_timer_seconds, 0);
    assert!(model.timer_running);

    // Verify view state
    let view = app.view(&model);
    assert!(view.workout_view.has_active_workout);
    assert_eq!(view.workout_view.formatted_duration, "00:00");
}

#[test]
fn test_workout_deserialization_with_notes_and_body_parts() {
    let app = Thiccc;
    let mut model = Model::default();

    // Switch to History tab so database responses populate history_detail_view
    app.update(Event::ChangeTab { tab: Tab::History }, &mut model, &());

    // Create a workout with the features we fixed (notes and body parts)
    let mut workout = Workout::new();
    workout.name = "Test Workout Deserialization".to_string();
    workout.note = Some("Testing deserialization fixes".to_string());

    // Create an exercise with notes and body parts
    let mut exercise = Exercise::new("Bench Press".to_string(), workout.id.clone());
    exercise.pinned_notes = vec!["Keep elbows tucked".to_string(), "Breathe out on press".to_string()];
    exercise.notes = vec!["Felt strong today".to_string(), "Good form".to_string()];
    exercise.body_part = Some(BodyPart::with_details(
        BodyPartMain::Chest,
        vec!["upper chest".to_string(), "inner chest".to_string()],
        vec!["pectoralis major".to_string()],
    ));

    // Add a set
    let set = ExerciseSet::new_working(
        exercise.id.clone(),
        workout.id.clone(),
        0,
        SetSuggest::with_weight_and_reps(185.0, 8),
    );
    exercise.sets.push(set);
    workout.exercises.push(exercise);

    // Serialize to JSON (this is what the database would return)
    let workout_json = serde_json::to_string(&workout).expect("Failed to serialize workout");

    // Simulate database response with workout loaded
    app.update(
        Event::DatabaseResponse {
            result: DatabaseResult::WorkoutLoaded {
                workout_json: Some(workout_json),
            },
        },
        &mut model,
        &(),
    );

    // Verify the workout was loaded into history_detail_view
    assert!(model.history_detail_view.is_some(), "Workout should be loaded into history_detail_view");
    let loaded_workout = model.history_detail_view.as_ref().unwrap();

    // Verify basic workout properties
    assert_eq!(loaded_workout.name, "Test Workout Deserialization");
    assert_eq!(loaded_workout.exercises.len(), 1);

    // Verify exercise with notes
    let loaded_exercise = &loaded_workout.exercises[0];
    assert_eq!(loaded_exercise.name, "Bench Press");
    assert_eq!(loaded_exercise.pinned_notes, vec!["Keep elbows tucked", "Breathe out on press"]);
    assert_eq!(loaded_exercise.notes, vec!["Felt strong today", "Good form"]);
    assert_eq!(loaded_exercise.sets.len(), 1);

    // Verify body part
    assert!(loaded_exercise.body_part.is_some());
    let body_part = loaded_exercise.body_part.as_ref().unwrap();
    assert_eq!(body_part.main, BodyPartMain::Chest);
    assert_eq!(body_part.detailed.as_ref().unwrap(), &vec!["upper chest", "inner chest"]);

    // This test verifies that the deserialization fixes work:
    // - pinned_notes and notes arrays are properly parsed
    // - body_part objects are properly parsed
    // - The workout loads without "missing field" errors
}

#[test]
fn test_history_detail_view_model_includes_workout_id() {
    let app = Thiccc;
    let mut model = Model::default();

    // Switch to History tab so database responses populate history_detail_view
    app.update(Event::ChangeTab { tab: Tab::History }, &mut model, &());

    // Create a workout to test with
    let mut workout = Workout::new();
    let workout_id = workout.id.clone();
    workout.name = "ID Test Workout".to_string();

    // Add an exercise
    let exercise = workout.add_exercise("Test Exercise");
    let set = exercise.add_set();
    set.suggest.weight = Some(100.0);
    set.suggest.reps = Some(10);
    set.actual.weight = Some(100.0);
    set.actual.reps = Some(10);

    // Serialize to JSON (this is what the database would return)
    let workout_json = serde_json::to_string(&workout).expect("Failed to serialize workout");

    // Simulate database response with workout loaded
    app.update(
        Event::DatabaseResponse {
            result: DatabaseResult::WorkoutLoaded {
                workout_json: Some(workout_json),
            },
        },
        &mut model,
        &(),
    );

    // Build the view model
    let view = app.view(&model);

    // Verify the HistoryDetailViewModel has the correct workout ID
    assert!(view.history_detail_view.is_some(), "HistoryDetailViewModel should be populated");
    let detail_view = view.history_detail_view.as_ref().unwrap();

    // This is the key test: verify the workout ID is included and matches
    assert_eq!(detail_view.id, workout_id.as_str(), "HistoryDetailViewModel should include the workout ID");
    assert_eq!(detail_view.workout_name, "ID Test Workout", "Workout name should match");
    assert_eq!(detail_view.exercises.len(), 1, "Should have one exercise");

    // This test verifies that HistoryDetailViewModel now includes the workout ID field,
    // which allows Swift UI to validate data freshness and prevent stale data display
}

#[test]
fn test_add_exercise_flow() {
    let app = Thiccc;
    let mut model = Model::default();

    // Start workout
    app.update(Event::StartWorkout, &mut model, &());

    // Add exercise
    app.update(
        Event::AddExercise {
            name: "Bench Press".to_string(),
            exercise_type: "barbell".to_string(),
            muscle_group: "chest".to_string(),
        },
        &mut model,
        &(),
    );

    // Verify model state
    assert_eq!(model.current_workout.as_ref().unwrap().exercises.len(), 1);
    assert_eq!(
        model.current_workout.as_ref().unwrap().exercises[0].name,
        "Bench Press"
    );

    // Verify view state
    let view = app.view(&model);
    assert_eq!(view.workout_view.exercises.len(), 1);
    assert_eq!(view.workout_view.exercises[0].name, "Bench Press");
}

#[test]
fn test_add_and_complete_set_flow() {
    let app = Thiccc;
    let mut model = Model::default();

    // Start workout and add exercise
    app.update(Event::StartWorkout, &mut model, &());
    app.update(
        Event::AddExercise {
            name: "Squat".to_string(),
            exercise_type: "barbell".to_string(),
            muscle_group: "legs".to_string(),
        },
        &mut model,
        &(),
    );

    let exercise_id = model.current_workout.as_ref().unwrap().exercises[0]
        .id
        .to_string();

    // Add a set
    app.update(
        Event::AddSet {
            exercise_id: exercise_id.clone(),
        },
        &mut model,
        &(),
    );

    // Verify set was added
    let view = app.view(&model);
    assert_eq!(view.workout_view.exercises[0].sets.len(), 1);
    assert!(!view.workout_view.exercises[0].sets[0].is_completed);

    // Complete the set
    let set_id = model.current_workout.as_ref().unwrap().exercises[0].sets[0]
        .id
        .to_string();
    app.update(
        Event::UpdateSetActual {
            set_id: set_id.clone(),
            actual: SetActual::with_weight_and_reps(225.0, 5),
        },
        &mut model,
        &(),
    );
    app.update(Event::ToggleSetCompleted { set_id }, &mut model, &());

    // Verify set is completed and has values
    let view = app.view(&model);
    assert!(view.workout_view.exercises[0].sets[0].is_completed);
    assert_eq!(view.workout_view.exercises[0].sets[0].weight, "225");
    assert_eq!(view.workout_view.exercises[0].sets[0].reps, "5");

    // Verify volume calculation
    assert_eq!(view.workout_view.total_volume, 1125); // 225 * 5
}

#[test]
fn test_finish_workout_flow() {
    let app = Thiccc;
    let mut model = Model::default();

    // Start workout
    app.update(Event::StartWorkout, &mut model, &());

    // Add exercise and set
    app.update(
        Event::AddExercise {
            name: "Deadlift".to_string(),
            exercise_type: "barbell".to_string(),
            muscle_group: "back".to_string(),
        },
        &mut model,
        &(),
    );

    let exercise_id = model.current_workout.as_ref().unwrap().exercises[0]
        .id
        .to_string();
    app.update(Event::AddSet { exercise_id }, &mut model, &());

    // Finish workout
    app.update(Event::FinishWorkout, &mut model, &());

    // Verify workout was moved to history
    assert!(model.current_workout.is_none());
    assert_eq!(model.workout_history.len(), 1);
    assert!(!model.timer_running);

    // Verify view state
    let view = app.view(&model);
    assert!(!view.workout_view.has_active_workout);
    assert_eq!(view.history_view.workouts.len(), 1);
}

#[test]
fn test_timer_tick_flow() {
    let app = Thiccc;
    let mut model = Model::default();

    // Start workout
    app.update(Event::StartWorkout, &mut model, &());

    // Simulate timer ticks
    for _ in 0..65 {
        app.update(Event::TimerTick, &mut model, &());
    }

    // Verify timer state
    assert_eq!(model.workout_timer_seconds, 65);

    // Verify view formatting
    let view = app.view(&model);
    assert_eq!(view.workout_view.formatted_duration, "01:05");
}

#[test]
fn test_finish_workout_uses_timer_seconds_not_wall_clock() {
    let app = Thiccc;
    let mut model = Model::default();

    // Start workout
    app.update(Event::StartWorkout, &mut model, &());

    // Simulate 60 seconds of active workout time
    for _ in 0..60 {
        app.update(Event::TimerTick, &mut model, &());
    }
    assert_eq!(model.workout_timer_seconds, 60);

    // Pause the timer
    app.update(Event::StopTimer, &mut model, &());

    // Simulate wall-clock time passing (e.g., 120 seconds)
    // but timer doesn't increment because it's paused
    for _ in 0..120 {
        app.update(Event::TimerTick, &mut model, &());
    }
    assert_eq!(model.workout_timer_seconds, 60, "Timer should not increment while paused");

    // Resume and add 30 more seconds
    app.update(Event::StartTimer, &mut model, &());
    for _ in 0..30 {
        app.update(Event::TimerTick, &mut model, &());
    }
    assert_eq!(model.workout_timer_seconds, 90);

    // Finish workout
    app.update(Event::FinishWorkout, &mut model, &());

    // Verify the saved duration is 90 seconds (actual active time),
    // not 210 seconds (wall-clock time: 60 + 120 + 30)
    assert_eq!(model.workout_history.len(), 1);
    let finished_workout = &model.workout_history[0];
    assert_eq!(
        finished_workout.duration,
        Some(90),
        "Workout duration should be 90s (active time), not wall-clock time"
    );
}

#[test]
fn test_delete_set_with_invalid_index_shows_error() {
    let app = Thiccc;
    let mut model = Model::default();

    // Start workout and add exercise with one set
    app.update(Event::StartWorkout, &mut model, &());
    app.update(
        Event::AddExercise {
            name: "Bench Press".to_string(),
            exercise_type: "barbell".to_string(),
            muscle_group: "chest".to_string(),
        },
        &mut model,
        &(),
    );

    let exercise_id = model.current_workout.as_ref().unwrap().exercises[0]
        .id
        .to_string();

    app.update(
        Event::AddSet {
            exercise_id: exercise_id.clone(),
        },
        &mut model,
        &(),
    );

    // Verify we have 1 set
    assert_eq!(model.current_workout.as_ref().unwrap().exercises[0].sets.len(), 1);

    // Try to delete set at index 5 (out of bounds)
    app.update(
        Event::DeleteSet {
            exercise_id: exercise_id.clone(),
            set_index: 5,
        },
        &mut model,
        &(),
    );

    // Verify error message was set
    assert!(model.error_message.is_some(), "Error message should be set");
    assert!(
        model
            .error_message
            .as_ref()
            .unwrap()
            .contains("Cannot delete set"),
        "Error should mention deletion failure"
    );
    assert!(
        model
            .error_message
            .as_ref()
            .unwrap()
            .contains("out of bounds"),
        "Error should mention out of bounds"
    );

    // Verify the set was NOT deleted
    assert_eq!(
        model.current_workout.as_ref().unwrap().exercises[0].sets.len(),
        1,
        "Set should not have been deleted"
    );
}

#[test]
fn test_move_exercise_with_invalid_indices_shows_error() {
    let app = Thiccc;
    let mut model = Model::default();

    // Start workout and add two exercises
    app.update(Event::StartWorkout, &mut model, &());
    app.update(
        Event::AddExercise {
            name: "Squat".to_string(),
            exercise_type: "barbell".to_string(),
            muscle_group: "legs".to_string(),
        },
        &mut model,
        &(),
    );
    app.update(
        Event::AddExercise {
            name: "Deadlift".to_string(),
            exercise_type: "barbell".to_string(),
            muscle_group: "back".to_string(),
        },
        &mut model,
        &(),
    );

    // Verify we have 2 exercises
    assert_eq!(model.current_workout.as_ref().unwrap().exercises.len(), 2);
    let first_exercise_name = model.current_workout.as_ref().unwrap().exercises[0].name.clone();

    // Try to move exercise from index 0 to index 10 (out of bounds)
    app.update(
        Event::MoveExercise {
            from_index: 0,
            to_index: 10,
        },
        &mut model,
        &(),
    );

    // Verify error message was set
    assert!(model.error_message.is_some(), "Error message should be set");
    assert!(
        model
            .error_message
            .as_ref()
            .unwrap()
            .contains("Cannot move exercise"),
        "Error should mention move failure"
    );
    assert!(
        model
            .error_message
            .as_ref()
            .unwrap()
            .contains("invalid position"),
        "Error should mention invalid position"
    );

    // Verify exercise order was NOT changed
    assert_eq!(
        model.current_workout.as_ref().unwrap().exercises[0].name,
        first_exercise_name,
        "Exercise order should not have changed"
    );
}

#[test]
fn test_change_tab_flow() {
    let app = Thiccc;
    let mut model = Model::default();

    // Default tab should be Workout
    assert_eq!(model.selected_tab, Tab::Workout);

    // Change to History
    app.update(Event::ChangeTab { tab: Tab::History }, &mut model, &());

    // Verify model and view
    assert_eq!(model.selected_tab, Tab::History);
    let view = app.view(&model);
    assert_eq!(view.selected_tab, Tab::History);
}

#[test]
fn test_error_message_cleared_on_start_workout() {
    let app = Thiccc;
    let mut model = Model {
        error_message: Some("Previous error".to_string()),
        ..Default::default()
    };

    // Start workout (should clear error on success)
    app.update(Event::StartWorkout, &mut model, &());

    // Verify error was cleared
    assert!(model.error_message.is_none(), "Error should be cleared on successful StartWorkout");
}

#[test]
fn test_error_message_cleared_on_add_exercise() {
    let app = Thiccc;
    let mut model = Model::default();

    // Start workout
    app.update(Event::StartWorkout, &mut model, &());

    // Set an error message
    model.error_message = Some("Previous error".to_string());

    // Add exercise (should clear error)
    app.update(
        Event::AddExercise {
            name: "Squat".to_string(),
            exercise_type: "barbell".to_string(),
            muscle_group: "legs".to_string(),
        },
        &mut model,
        &(),
    );

    // Verify error was cleared
    assert!(model.error_message.is_none(), "Error should be cleared on successful AddExercise");
}

#[test]
fn test_error_message_cleared_on_add_set() {
    let app = Thiccc;
    let mut model = Model::default();

    // Start workout and add exercise
    app.update(Event::StartWorkout, &mut model, &());
    app.update(
        Event::AddExercise {
            name: "Squat".to_string(),
            exercise_type: "barbell".to_string(),
            muscle_group: "legs".to_string(),
        },
        &mut model,
        &(),
    );

    let exercise_id = model.current_workout.as_ref().unwrap().exercises[0]
        .id
        .to_string();

    // Set an error message
    model.error_message = Some("Previous error".to_string());

    // Add set (should clear error)
    app.update(Event::AddSet { exercise_id }, &mut model, &());

    // Verify error was cleared
    assert!(model.error_message.is_none(), "Error should be cleared on successful AddSet");
}

#[test]
fn test_error_message_cleared_on_change_tab() {
    let app = Thiccc;
    let mut model = Model {
        error_message: Some("Previous error".to_string()),
        ..Default::default()
    };

    // Change tab (should clear error)
    app.update(Event::ChangeTab { tab: Tab::History }, &mut model, &());

    // Verify error was cleared
    assert!(model.error_message.is_none(), "Error should be cleared when changing tabs");
}

#[test]
fn test_error_message_cleared_on_finish_workout() {
    let app = Thiccc;
    let mut model = Model::default();

    // Start workout
    app.update(Event::StartWorkout, &mut model, &());

    // Set an error message
    model.error_message = Some("Previous error".to_string());

    // Finish workout (should clear error)
    app.update(Event::FinishWorkout, &mut model, &());

    // Verify error was cleared
    assert!(model.error_message.is_none(), "Error should be cleared on FinishWorkout");
}

#[test]
fn test_error_message_cleared_on_discard_workout() {
    let app = Thiccc;
    let mut model = Model::default();

    // Start workout
    app.update(Event::StartWorkout, &mut model, &());

    // Set an error message
    model.error_message = Some("Previous error".to_string());

    // Discard workout (should clear error)
    app.update(Event::DiscardWorkout, &mut model, &());

    // Verify error was cleared
    assert!(model.error_message.is_none(), "Error should be cleared on DiscardWorkout");
}

#[test]
fn test_plate_calculator_flow() {
    let app = Thiccc;
    let mut model = Model::default();

    // Calculate plates for 225 lbs
    app.update(
        Event::CalculatePlates {
            target_weight: 225.0,
            bar_weight: 45.0, // Olympic bar weight
            use_percentage: None,
        },
        &mut model,
        &(),
    );

    // Verify calculation
    assert!(model.plate_calculation.is_some());
    let calc = model.plate_calculation.as_ref().unwrap();
    assert_eq!(calc.total_weight, 225.0);

    // (225 - 45) / 2 = 90 lbs per side
    // Should use: 2x45 (90 lbs total)
    let description = calc.formatted_plate_description();
    assert!(description.contains("45lb"));
}

#[test]
fn test_plate_calculator_rejects_negative_target_weight() {
    let app = Thiccc;
    let mut model = Model::default();

    app.update(
        Event::CalculatePlates {
            target_weight: -100.0,
            bar_weight: 45.0,
            use_percentage: None,
        },
        &mut model,
        &(),
    );

    // Verify error message was set
    assert!(model.error_message.is_some());
    assert!(model
        .error_message
        .as_ref()
        .unwrap()
        .contains("Target weight must be greater than 0"));
    assert!(model.plate_calculation.is_none());
}

#[test]
fn test_plate_calculator_rejects_zero_target_weight() {
    let app = Thiccc;
    let mut model = Model::default();

    app.update(
        Event::CalculatePlates {
            target_weight: 0.0,
            bar_weight: 45.0,
            use_percentage: None,
        },
        &mut model,
        &(),
    );

    // Verify error message was set
    assert!(model.error_message.is_some());
    assert!(model
        .error_message
        .as_ref()
        .unwrap()
        .contains("Target weight must be greater than 0"));
    assert!(model.plate_calculation.is_none());
}

#[test]
fn test_plate_calculator_rejects_negative_bar_weight() {
    let app = Thiccc;
    let mut model = Model::default();

    app.update(
        Event::CalculatePlates {
            target_weight: 225.0,
            bar_weight: -45.0,
            use_percentage: None,
        },
        &mut model,
        &(),
    );

    // Verify error message was set
    assert!(model.error_message.is_some());
    assert!(model
        .error_message
        .as_ref()
        .unwrap()
        .contains("Bar weight must be greater than 0"));
    assert!(model.plate_calculation.is_none());
}

#[test]
fn test_plate_calculator_rejects_negative_percentage() {
    let app = Thiccc;
    let mut model = Model::default();

    app.update(
        Event::CalculatePlates {
            target_weight: 225.0,
            bar_weight: 45.0,
            use_percentage: Some(-50.0),
        },
        &mut model,
        &(),
    );

    // Verify error message was set
    assert!(model.error_message.is_some());
    assert!(model
        .error_message
        .as_ref()
        .unwrap()
        .contains("Percentage must be between 0 and 100"));
    assert!(model.plate_calculation.is_none());
}

#[test]
fn test_plate_calculator_rejects_percentage_over_100() {
    let app = Thiccc;
    let mut model = Model::default();

    app.update(
        Event::CalculatePlates {
            target_weight: 225.0,
            bar_weight: 45.0,
            use_percentage: Some(150.0),
        },
        &mut model,
        &(),
    );

    // Verify error message was set
    assert!(model.error_message.is_some());
    assert!(model
        .error_message
        .as_ref()
        .unwrap()
        .contains("Percentage must be between 0 and 100"));
    assert!(model
        .error_message
        .as_ref()
        .unwrap()
        .contains("150"));
    assert!(model.plate_calculation.is_none());
}

#[test]
fn test_plate_calculator_accepts_percentage_100() {
    let app = Thiccc;
    let mut model = Model::default();

    app.update(
        Event::CalculatePlates {
            target_weight: 225.0,
            bar_weight: 45.0,
            use_percentage: Some(100.0),
        },
        &mut model,
        &(),
    );

    // Verify calculation succeeded (100% of 225 = 225)
    assert!(model.error_message.is_none());
    assert!(model.plate_calculation.is_some());
    assert_eq!(model.plate_calculation.as_ref().unwrap().total_weight, 225.0);
}

#[test]
fn test_import_workout_flow() {
    let app = Thiccc;
    let mut model = Model::default();

    // Create a workout and serialize it
    let workout = Workout::with_name("Test Workout");
    let json = serde_json::to_string(&workout).unwrap();

    // Import it
    app.update(Event::ImportWorkout { json_data: json }, &mut model, &());

    // Verify it was imported
    assert!(model.current_workout.is_some());
    assert_eq!(model.current_workout.as_ref().unwrap().name, "Test Workout");
    assert!(model.error_message.is_none());
}

#[test]
fn test_import_invalid_workout_shows_error() {
    let app = Thiccc;
    let mut model = Model::default();

    // Try to import invalid JSON
    app.update(
        Event::ImportWorkout {
            json_data: "{ invalid json }".to_string(),
        },
        &mut model,
        &(),
    );

    // Verify error was set
    assert!(model.error_message.is_some());
    assert!(model
        .error_message
        .as_ref()
        .unwrap()
        .contains("Failed to import"));
}

#[test]
fn test_import_workout_with_invalid_uuid_is_rejected() {
    let app = Thiccc;
    let mut model = Model::default();

    // Create JSON with an invalid UUID (bypasses serde validation due to transparent)
    let malformed_json = r#"{
        "id": "not-a-valid-uuid",
        "name": "Malicious Workout",
        "note": null,
        "duration": null,
        "start_timestamp": "2025-01-01T12:00:00Z",
        "end_timestamp": null,
        "exercises": []
    }"#;

    // Try to import it
    app.update(
        Event::ImportWorkout {
            json_data: malformed_json.to_string(),
        },
        &mut model,
        &(),
    );

    // Verify the malformed UUID was caught and rejected
    assert!(model.current_workout.is_none(), "Workout with invalid UUID should not be imported");
    assert!(model.error_message.is_some(), "Error message should be set");
    assert!(
        model
            .error_message
            .as_ref()
            .unwrap()
            .contains("Invalid workout data"),
        "Error should mention invalid workout data"
    );
    assert!(
        model
            .error_message
            .as_ref()
            .unwrap()
            .contains("Invalid workout ID"),
        "Error should specifically mention the workout ID"
    );
}

