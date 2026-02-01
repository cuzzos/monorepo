use crux_core::typegen::TypeGen;
use shared::{app::*, models::*, operations::*, Thiccc};
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

    // IMPORTANT: Registration order matters for TypeGen tracing
    // Register simple types first, then types that contain them
    
    // 1. Register simple enum types first
    gen.register_type_with_samples::<Tab>(vec![Tab::Workout, Tab::History, Tab::Debug])?;
    gen.register_type_with_samples::<TimerOutput>(vec![
        TimerOutput::Tick,
        TimerOutput::Started,
        TimerOutput::Stopped,
    ])?;
    gen.register_type_with_samples::<TimerOperation>(vec![
        TimerOperation::Start,
        TimerOperation::Stop,
    ])?;

    // 2. Register database and storage result types (they use JSON strings)
    gen.register_type_with_samples::<DatabaseResult>(vec![
        DatabaseResult::WorkoutSaved,
        DatabaseResult::WorkoutDeleted,
        DatabaseResult::HistoryLoaded { workouts_json: vec!["{}".to_string()] },
        DatabaseResult::WorkoutLoaded { workout_json: Some("{}".to_string()) },
        DatabaseResult::WorkoutLoaded { workout_json: None },
        DatabaseResult::Error { message: "Sample error".to_string() },
    ])?;
    gen.register_type_with_samples::<StorageResult>(vec![
        StorageResult::CurrentWorkoutSaved,
        StorageResult::CurrentWorkoutLoaded { workout_json: Some("{}".to_string()) },
        StorageResult::CurrentWorkoutLoaded { workout_json: None },
        StorageResult::CurrentWorkoutDeleted,
    ])?;

    // 3. Register operation types
    // Note: DatabaseOperation and StorageOperation now use JSON strings for workout data
    // to avoid TypeGen issues with complex nested types in Request<T>
    gen.register_type_with_samples::<DatabaseOperation>(vec![
        DatabaseOperation::SaveWorkout("{}".to_string()),  // JSON placeholder
        DatabaseOperation::LoadAllWorkouts,
        DatabaseOperation::LoadWorkoutById("00000000-0000-0000-0000-000000000000".to_string()),
        DatabaseOperation::DeleteWorkout("00000000-0000-0000-0000-000000000000".to_string()),
    ])?;
    gen.register_type_with_samples::<StorageOperation>(vec![
        StorageOperation::SaveCurrentWorkout("{}".to_string()),  // JSON placeholder
        StorageOperation::LoadCurrentWorkout,
        StorageOperation::DeleteCurrentWorkout,
    ])?;

    // 4. Register the app (auto-discovers Event, ViewModel, Effect and their nested types)
    gen.register_app::<Thiccc>()?;

    // 5. Explicitly register History ViewModels (since they're in Option<T>)
    gen.register_type::<HistoryViewModel>()?;
    gen.register_type::<HistoryItemViewModel>()?;
    gen.register_type::<HistoryDetailViewModel>()?;
    gen.register_type::<ExerciseDetailViewModel>()?;
    gen.register_type::<SetDetailViewModel>()?;

    // Generate Swift bindings
    let output_root = PathBuf::from("./generated");
    gen.swift("SharedTypes", output_root.join("swift"))?;

    println!("cargo:warning=Successfully generated Swift type bindings!");

    Ok(())
}

