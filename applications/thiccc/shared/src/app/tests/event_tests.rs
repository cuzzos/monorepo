use super::super::*;

// -------------------------------------------------------------------------
// Event Serialization Tests
// -------------------------------------------------------------------------

#[test]
fn test_event_serialization_add_exercise() {
    let event = Event::AddExercise {
        name: "Squat".to_string(),
        exercise_type: "barbell".to_string(),
        muscle_group: "Quadriceps".to_string(),
    };

    let json = serde_json::to_string(&event).expect("Failed to serialize event");
    let deserialized: Event = serde_json::from_str(&json).expect("Failed to deserialize event");

    assert_eq!(event, deserialized);
}

#[test]
fn test_event_serialization_update_set_actual() {
    let set_id = Id::new().as_str().to_string(); // Create Id, convert to String for Event
    let actual = SetActual::with_weight_and_reps(225.0, 5);
    let event = Event::UpdateSetActual {
        set_id,
        actual: actual.clone(),
    };

    let json = serde_json::to_string(&event).expect("Failed to serialize event");
    let deserialized: Event = serde_json::from_str(&json).expect("Failed to deserialize event");

    assert_eq!(event, deserialized);
}

#[test]
fn test_event_serialization_change_tab() {
    let event = Event::ChangeTab { tab: Tab::History };

    let json = serde_json::to_string(&event).expect("Failed to serialize event");
    let deserialized: Event = serde_json::from_str(&json).expect("Failed to deserialize event");

    assert_eq!(event, deserialized);
}

#[test]
fn test_event_serialization_calculate_plates() {
    let event = Event::CalculatePlates {
        target_weight: 225.0,
        bar_weight: 45.0, // Olympic bar weight
        use_percentage: Some(90.0),
    };

    let json = serde_json::to_string(&event).expect("Failed to serialize event");
    let deserialized: Event = serde_json::from_str(&json).expect("Failed to deserialize event");

    assert_eq!(event, deserialized);
}

#[test]
fn test_tab_serialization() {
    let workout_tab = Tab::Workout;
    let history_tab = Tab::History;

    let workout_json = serde_json::to_string(&workout_tab).unwrap();
    let history_json = serde_json::to_string(&history_tab).unwrap();

    assert_eq!(workout_json, r#""Workout""#);
    assert_eq!(history_json, r#""History""#);

    let deserialized_workout: Tab = serde_json::from_str(&workout_json).unwrap();
    let deserialized_history: Tab = serde_json::from_str(&history_json).unwrap();

    assert_eq!(deserialized_workout, Tab::Workout);
    assert_eq!(deserialized_history, Tab::History);
}

#[test]
fn test_tab_default() {
    let tab = Tab::default();
    assert_eq!(tab, Tab::Workout);
}

