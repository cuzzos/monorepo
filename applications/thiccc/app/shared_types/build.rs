use crux_core::typegen::TypeGen;
use shared::{app::*, models::*, Thiccc};
use std::path::PathBuf;

/// Creates a complete sample workout with all nested types populated.
/// This ensures TypeGen can trace all field types (Exercise, ExerciseSet, etc.).
fn sample_workout() -> Workout {
    let mut workout = Workout::new();
    workout.name = "Sample Workout".to_string();
    workout.note = Some("Sample note".to_string());
    workout.duration = Some(3600);
    workout.end_timestamp = Some(chrono::Utc::now());
    
    // Add an exercise with ALL optional fields populated
    let mut exercise = Exercise::new("Bench Press".to_string(), workout.id.clone());
    exercise.superset_id = Some(1);
    exercise.pinned_notes.push("Pinned note".to_string());
    exercise.notes.push("Regular note".to_string());
    exercise.duration = Some(300);
    exercise.exercise_type = ExerciseType::Barbell;
    exercise.weight_unit = Some(WeightUnit::Lb);
    exercise.default_warm_up_time = Some(30);
    exercise.default_rest_time = Some(60);
    exercise.body_part = Some(BodyPart::with_details(
        BodyPartMain::Chest,
        vec!["Upper Chest".to_string()],
        vec!["Pectoralis Major".to_string()],
    ));
    
    // Add a set with ALL fields populated (including all Optional fields)
    let set = exercise.add_set();
    set.weight_unit = Some(WeightUnit::Kg);
    set.suggest.weight = Some(135.0);
    set.suggest.reps = Some(10);
    set.suggest.rep_range = Some(10);
    set.suggest.rpe = Some(7.5);
    set.suggest.duration = Some(60);
    set.suggest.rest_time = Some(90);
    set.actual.weight = Some(135.0);
    set.actual.reps = Some(10);
    set.actual.rpe = Some(7.5);
    set.actual.duration = Some(60);
    set.actual.actual_rest_time = Some(90);
    
    workout.exercises.push(exercise);
    workout
}

fn main() -> anyhow::Result<()> {
    println!("cargo:rerun-if-changed=../shared");

    let mut gen = TypeGen::new();

    // Provide samples for enums containing complex types
    // DatabaseResult and StorageResult contain Vec<Workout> and Option<Workout>, so we need samples
    // CRITICAL: Must use fully populated samples so TypeGen can trace all nested types
    gen.register_type_with_samples::<Tab>(vec![Tab::default()])?;
    gen.register_type_with_samples::<DatabaseResult>(vec![
        DatabaseResult::WorkoutSaved,
        DatabaseResult::HistoryLoaded { workouts: vec![sample_workout()] },
        DatabaseResult::WorkoutLoaded { workout: Some(sample_workout()) },
        DatabaseResult::WorkoutLoaded { workout: None },
    ])?;
    gen.register_type_with_samples::<StorageResult>(vec![
        StorageResult::CurrentWorkoutSaved,
        StorageResult::CurrentWorkoutLoaded { workout: Some(sample_workout()) },
        StorageResult::CurrentWorkoutLoaded { workout: None },
        StorageResult::CurrentWorkoutDeleted,
    ])?;

    // Register the app (auto-discovers Event and ViewModel types)
    gen.register_app::<Thiccc>()?;

    // Generate Swift bindings
    let output_root = PathBuf::from("./generated");
    gen.swift("SharedTypes", output_root.join("swift"))?;

    println!("cargo:warning=Successfully generated Swift type bindings!");

    Ok(())
}

