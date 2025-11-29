//! Core data models for the Thiccc workout tracking application.
//!
//! This module contains all domain models that represent workouts, exercises,
//! sets, and related data structures. These models are serializable for
//! cross-platform communication between the Rust core and Swift shell.

use crate::id::Id;
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};

// =============================================================================
// MARK: - Enums
// =============================================================================

/// Type of exercise equipment used.
///
/// Determines the type of equipment for an exercise, which affects
/// how weight and reps are tracked and displayed.
#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, Eq, Hash, Default)]
#[serde(rename_all = "camelCase")]
pub enum ExerciseType {
    /// Dumbbell exercises (e.g., dumbbell curls, dumbbell press)
    Dumbbell,
    /// Kettlebell exercises (e.g., kettlebell swings)
    Kettlebell,
    /// Barbell exercises (e.g., bench press, squats, deadlifts)
    Barbell,
    /// Hex bar / trap bar exercises (e.g., hex bar deadlifts)
    Hexbar,
    /// Bodyweight exercises (e.g., push-ups, pull-ups)
    Bodyweight,
    /// Machine exercises (e.g., leg press, cable machines)
    Machine,
    /// Unknown or unspecified exercise type
    #[default]
    Unknown,
}

/// Unit of weight measurement.
///
/// Used to specify whether weights are in kilograms, pounds, or bodyweight.
#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, Eq, Hash, Default)]
#[serde(rename_all = "lowercase")]
pub enum WeightUnit {
    /// Kilograms
    Kg,
    /// Pounds
    #[default]
    Lb,
    /// Bodyweight (for bodyweight exercises)
    Bodyweight,
}

/// Type of set within an exercise.
///
/// Different set types affect how the set is tracked and displayed,
/// and may have different completion criteria.
#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, Eq, Hash, Default)]
#[serde(rename_all = "camelCase")]
pub enum SetType {
    /// Warm-up set with lighter weight
    WarmUp,
    /// Standard working set
    #[default]
    Working,
    /// Drop set (reduced weight without rest)
    DropSet,
    /// As Many Reps As Possible
    Amrap,
    /// Set to failure
    Failure,
}

/// Main body part categories for exercise classification.
///
/// Used to categorize exercises by the primary muscle group targeted.
#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, Eq, Hash, Default)]
#[serde(rename_all = "camelCase")]
pub enum BodyPartMain {
    /// Chest muscles (pectorals)
    Chest,
    /// Leg muscles (quadriceps, hamstrings, glutes)
    Legs,
    /// Arm muscles (biceps, triceps, forearms)
    Arms,
    /// Back muscles (lats, traps, rhomboids)
    Back,
    /// Calf muscles
    Calves,
    /// Shoulder muscles (deltoids)
    Shoulders,
    /// Core muscles (abs, obliques)
    Core,
    /// Cardiovascular exercises
    Cardio,
    /// Full body compound exercises
    FullBody,
    /// Other/miscellaneous
    #[default]
    Other,
}

// =============================================================================
// MARK: - BodyPart
// =============================================================================

/// Detailed body part information for an exercise.
///
/// Contains the main body part category along with optional detailed
/// and scientific muscle names.
#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, Eq, Hash)]
pub struct BodyPart {
    /// Main body part category
    pub main: BodyPartMain,
    /// Detailed muscle names (e.g., "upper chest", "rear delts")
    pub detailed: Option<Vec<String>>,
    /// Scientific muscle names (e.g., "pectoralis major")
    pub scientific: Option<Vec<String>>,
}

impl BodyPart {
    /// Creates a new BodyPart with only the main category.
    pub fn new(main: BodyPartMain) -> Self {
        Self {
            main,
            detailed: None,
            scientific: None,
        }
    }

    /// Creates a new BodyPart with all fields specified.
    pub fn with_details(
        main: BodyPartMain,
        detailed: Vec<String>,
        scientific: Vec<String>,
    ) -> Self {
        Self {
            main,
            detailed: Some(detailed),
            scientific: Some(scientific),
        }
    }
}

// =============================================================================
// MARK: - Set Data Structures
// =============================================================================

/// Suggested/planned values for a set.
///
/// These are the target values the user plans to hit for the set,
/// which can be compared against actual values after completion.
#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, Default)]
pub struct SetSuggest {
    /// Suggested weight to use
    pub weight: Option<f64>,
    /// Suggested number of reps
    pub reps: Option<i32>,
    /// Suggested rep range (for AMRAP or variable sets)
    pub rep_range: Option<i32>,
    /// Suggested duration in seconds (for timed exercises)
    pub duration: Option<i32>,
    /// Suggested RPE (Rate of Perceived Exertion, 1-10)
    pub rpe: Option<f64>,
    /// Suggested rest time after this set in seconds
    pub rest_time: Option<i32>,
}

impl SetSuggest {
    /// Creates a new SetSuggest with default rest time.
    pub fn with_rest_time(rest_time: i32) -> Self {
        Self {
            rest_time: Some(rest_time),
            ..Default::default()
        }
    }

    /// Creates a new SetSuggest with weight and reps.
    pub fn with_weight_and_reps(weight: f64, reps: i32) -> Self {
        Self {
            weight: Some(weight),
            reps: Some(reps),
            ..Default::default()
        }
    }
}

/// Actual performed values for a set.
///
/// These are the values the user actually achieved when performing the set,
/// tracked for progress monitoring and history.
#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, Default)]
pub struct SetActual {
    /// Actual weight used
    pub weight: Option<f64>,
    /// Actual reps performed
    pub reps: Option<i32>,
    /// Actual duration in seconds
    pub duration: Option<i32>,
    /// Actual RPE (Rate of Perceived Exertion, 1-10)
    pub rpe: Option<f64>,
    /// Actual rest time taken after this set in seconds
    pub actual_rest_time: Option<i32>,
}

impl SetActual {
    /// Creates a new SetActual with weight and reps.
    pub fn with_weight_and_reps(weight: f64, reps: i32) -> Self {
        Self {
            weight: Some(weight),
            reps: Some(reps),
            ..Default::default()
        }
    }

    /// Calculates the volume (weight × reps) for this set.
    ///
    /// Returns `None` if either weight or reps is not set.
    pub fn volume(&self) -> Option<f64> {
        match (self.weight, self.reps) {
            (Some(w), Some(r)) => Some(w * f64::from(r)),
            _ => None,
        }
    }
}

/// A single set within an exercise.
///
/// Represents one set of an exercise, tracking both planned (suggest)
/// and actual values, along with completion status.
#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
pub struct ExerciseSet {
    /// Unique identifier for this set
    pub id: Id,
    /// Type of set (warm-up, working, drop set, etc.)
    #[serde(rename = "type")]
    pub set_type: SetType,
    /// Weight unit override for this specific set
    pub weight_unit: Option<WeightUnit>,
    /// Suggested/planned values for this set
    pub suggest: SetSuggest,
    /// Actual performed values for this set
    pub actual: SetActual,
    /// Whether this set has been completed
    pub is_completed: bool,
    /// ID of the exercise this set belongs to
    pub exercise_id: Id,
    /// ID of the workout this set belongs to
    pub workout_id: Id,
    /// Index of this set within the exercise (0-based)
    pub set_index: i32,
}

impl ExerciseSet {
    /// Creates a new empty set with the given IDs.
    pub fn new(exercise_id: Id, workout_id: Id, set_index: i32) -> Self {
        Self {
            id: Id::new(),
            set_type: SetType::default(),
            weight_unit: None,
            suggest: SetSuggest::default(),
            actual: SetActual::default(),
            is_completed: false,
            exercise_id,
            workout_id,
            set_index,
        }
    }

    /// Creates a new warm-up set.
    pub fn new_warmup(exercise_id: Id, workout_id: Id, set_index: i32) -> Self {
        Self {
            set_type: SetType::WarmUp,
            ..Self::new(exercise_id, workout_id, set_index)
        }
    }

    /// Creates a new working set with suggested values.
    pub fn new_working(
        exercise_id: Id,
        workout_id: Id,
        set_index: i32,
        suggest: SetSuggest,
    ) -> Self {
        Self {
            suggest,
            ..Self::new(exercise_id, workout_id, set_index)
        }
    }

    /// Marks this set as completed with the given actual values.
    pub fn complete(&mut self, actual: SetActual) {
        self.actual = actual;
        self.is_completed = true;
    }
}

// =============================================================================
// MARK: - Exercise
// =============================================================================

/// An exercise within a workout.
///
/// Represents a single exercise (e.g., "Bench Press") with all its sets,
/// notes, and configuration. Exercises belong to a workout and contain
/// multiple sets.
#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
pub struct Exercise {
    /// Unique identifier for this exercise
    pub id: Id,
    /// Superset grouping ID (exercises with same ID are supersetted)
    pub superset_id: Option<i32>,
    /// ID of the workout this exercise belongs to
    pub workout_id: Id,
    /// Name of the exercise (e.g., "Bench Press", "Squat")
    pub name: String,
    /// Pinned notes that persist across workouts
    pub pinned_notes: Vec<String>,
    /// Session-specific notes for this workout only
    pub notes: Vec<String>,
    /// Total duration of this exercise in seconds
    pub duration: Option<i32>,
    /// Type of exercise equipment
    #[serde(rename = "type")]
    pub exercise_type: ExerciseType,
    /// Default weight unit for sets in this exercise
    pub weight_unit: Option<WeightUnit>,
    /// Default warm-up time in seconds
    pub default_warm_up_time: Option<i32>,
    /// Default rest time between sets in seconds
    pub default_rest_time: Option<i32>,
    /// Sets performed for this exercise
    pub sets: Vec<ExerciseSet>,
    /// Body part information for this exercise
    pub body_part: Option<BodyPart>,
}

impl Exercise {
    /// Creates a new exercise with the given name and workout ID.
    pub fn new(name: String, workout_id: Id) -> Self {
        Self {
            id: Id::new(),
            superset_id: None,
            workout_id,
            name,
            pinned_notes: Vec::new(),
            notes: Vec::new(),
            duration: None,
            exercise_type: ExerciseType::default(),
            weight_unit: None,
            default_warm_up_time: None,
            default_rest_time: Some(60), // Default 60 second rest
            sets: Vec::new(),
            body_part: None,
        }
    }

    /// Creates an exercise from a GlobalExercise template.
    pub fn from_global(global: &GlobalExercise, workout_id: Id) -> Self {
        Self {
            id: Id::new(),
            superset_id: None,
            workout_id,
            name: global.name.clone(),
            pinned_notes: Vec::new(),
            notes: Vec::new(),
            duration: None,
            exercise_type: ExerciseType::default(), // Will be parsed from global.exercise_type
            weight_unit: None,
            default_warm_up_time: None,
            default_rest_time: Some(60),
            sets: Vec::new(),
            body_part: None,
        }
    }

    /// Returns whether all sets in this exercise are completed.
    pub fn is_completed(&self) -> bool {
        !self.sets.is_empty() && self.sets.iter().all(|set| set.is_completed)
    }

    /// Returns the number of completed sets.
    pub fn completed_sets_count(&self) -> usize {
        self.sets.iter().filter(|set| set.is_completed).count()
    }

    /// Calculates total volume for all completed sets.
    ///
    /// Volume is calculated as weight × reps for each completed set.
    pub fn total_volume(&self) -> f64 {
        self.sets
            .iter()
            .filter(|set| set.is_completed)
            .filter_map(|set| set.actual.volume())
            .sum()
    }

    /// Adds a new empty set to this exercise.
    pub fn add_set(&mut self) -> &mut ExerciseSet {
        let set_index = self.sets.len() as i32;
        let set = ExerciseSet::new(self.id.clone(), self.workout_id.clone(), set_index);
        self.sets.push(set);
        self.sets.last_mut().expect("Just pushed a set")
    }
}

// =============================================================================
// MARK: - Workout
// =============================================================================

/// A complete workout session.
///
/// Represents a single workout session containing multiple exercises.
/// Tracks the workout name, notes, duration, and all exercises performed.
#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
pub struct Workout {
    /// Unique identifier for this workout
    pub id: Id,
    /// User-provided name for the workout (e.g., "Push Day", "Leg Day")
    pub name: String,
    /// Optional notes about the workout
    pub note: Option<String>,
    /// Total duration of the workout in seconds
    pub duration: Option<i32>,
    /// When the workout started (UTC, ISO8601 format)
    pub start_timestamp: DateTime<Utc>,
    /// When the workout ended (UTC, ISO8601 format)
    pub end_timestamp: Option<DateTime<Utc>>,
    /// Exercises performed in this workout
    pub exercises: Vec<Exercise>,
}

impl Workout {
    /// Creates a new empty workout with the current timestamp.
    pub fn new() -> Self {
        Self {
            id: Id::new(),
            name: String::new(),
            note: None,
            duration: None,
            start_timestamp: Utc::now(),
            end_timestamp: None,
            exercises: Vec::new(),
        }
    }

    /// Creates a new workout with the given name.
    pub fn with_name(name: impl Into<String>) -> Self {
        Self {
            name: name.into(),
            ..Self::new()
        }
    }

    /// Returns whether all exercises in this workout are completed.
    pub fn is_completed(&self) -> bool {
        !self.exercises.is_empty() && self.exercises.iter().all(|ex| ex.is_completed())
    }

    /// Returns the total number of sets across all exercises.
    pub fn total_sets(&self) -> usize {
        self.exercises.iter().map(|ex| ex.sets.len()).sum()
    }

    /// Returns the number of completed sets across all exercises.
    pub fn completed_sets(&self) -> usize {
        self.exercises
            .iter()
            .map(|ex| ex.completed_sets_count())
            .sum()
    }

    /// Calculates total volume for the entire workout.
    ///
    /// Volume is calculated as weight × reps for each completed set.
    pub fn total_volume(&self) -> f64 {
        self.exercises.iter().map(|ex| ex.total_volume()).sum()
    }

    /// Finishes the workout by setting the end timestamp and duration.
    ///
    /// # Arguments
    /// * `elapsed_seconds` - The actual elapsed time in seconds (excluding paused time)
    pub fn finish(&mut self, elapsed_seconds: i32) {
        self.end_timestamp = Some(Utc::now());
        self.duration = Some(elapsed_seconds);
    }

    /// Adds an exercise to this workout.
    pub fn add_exercise(&mut self, name: impl Into<String>) -> &mut Exercise {
        let exercise = Exercise::new(name.into(), self.id.clone());
        self.exercises.push(exercise);
        self.exercises.last_mut().expect("Just pushed an exercise")
    }
}

impl Default for Workout {
    fn default() -> Self {
        Self::new()
    }
}

// =============================================================================
// MARK: - Plate Calculator Models
// =============================================================================

/// A weight plate for the plate calculator.
///
/// Represents a single weight plate with its weight value.
#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
pub struct Plate {
    /// Unique identifier for this plate
    pub id: Id,
    /// Weight of the plate in the user's preferred unit
    pub weight: f64,
}

impl Plate {
    /// Creates a new plate with the given weight.
    pub fn new(weight: f64) -> Self {
        Self {
            id: Id::new(),
            weight,
        }
    }

    /// Returns the standard set of weight plates (in pounds).
    ///
    /// Includes: 45, 35, 25, 10, 5, and 2.5 lb plates.
    pub fn standard() -> Vec<Plate> {
        vec![
            Plate::new(45.0),
            Plate::new(35.0),
            Plate::new(25.0),
            Plate::new(10.0),
            Plate::new(5.0),
            Plate::new(2.5),
        ]
    }

    /// Returns the standard set of weight plates (in kilograms).
    ///
    /// Includes: 25, 20, 15, 10, 5, 2.5, and 1.25 kg plates.
    pub fn standard_kg() -> Vec<Plate> {
        vec![
            Plate::new(25.0),
            Plate::new(20.0),
            Plate::new(15.0),
            Plate::new(10.0),
            Plate::new(5.0),
            Plate::new(2.5),
            Plate::new(1.25),
        ]
    }
}

/// Type of barbell for the plate calculator.
///
/// Different bars have different weights, affecting the plate calculation.
#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
pub struct BarType {
    /// Unique identifier for this bar type
    pub id: Id,
    /// Display name for the bar type
    pub name: String,
    /// Weight of the bar in the user's preferred unit
    pub weight: f64,
}

impl BarType {
    /// Creates a new bar type with the given name and weight.
    pub fn new(name: impl Into<String>, weight: f64) -> Self {
        Self {
            id: Id::new(),
            name: name.into(),
            weight,
        }
    }

    /// Standard Olympic barbell (45 lbs / 20 kg).
    pub fn olympic() -> Self {
        Self::new("Olympic", 45.0)
    }

    /// Standard barbell (20 lbs).
    pub fn standard() -> Self {
        Self::new("Standard", 20.0)
    }

    /// EZ curl bar (20 lbs).
    pub fn ez_bar() -> Self {
        Self::new("EZ Bar", 20.0)
    }

    /// Trap/hex bar (45 lbs).
    pub fn trap_bar() -> Self {
        Self::new("Trap Bar", 45.0)
    }

    /// Returns all common bar types.
    pub fn all_bars() -> Vec<Self> {
        vec![
            Self::olympic(),
            Self::standard(),
            Self::ez_bar(),
            Self::trap_bar(),
        ]
    }
}

impl Default for BarType {
    fn default() -> Self {
        Self::olympic()
    }
}

/// Result of a plate calculation.
///
/// Contains the target weight, bar type used, and the plates needed
/// on each side of the bar.
#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
pub struct PlateCalculation {
    /// Target total weight
    pub total_weight: f64,
    /// Bar type used for calculation
    pub bar_type: BarType,
    /// Plates needed on each side of the bar (sorted by weight, largest first)
    pub plates: Vec<Plate>,
    /// Weight unit for display (lb or kg)
    pub weight_unit: WeightUnit,
}

impl PlateCalculation {
    /// Creates a formatted description of the plates needed.
    ///
    /// Example output: "2x45lb, 1x25lb, 1x10lb" or "2x20kg, 1x1.25kg"
    pub fn formatted_plate_description(&self) -> String {
        use std::collections::HashMap;

        // Determine the unit suffix based on weight_unit
        let unit_suffix = match self.weight_unit {
            WeightUnit::Kg => "kg",
            WeightUnit::Lb | WeightUnit::Bodyweight => "lb",
        };

        // Group plates by weight (using fixed-point representation for HashMap key)
        // Multiply by 100 and round to handle weights with up to 2 decimal places (e.g., 1.25 kg)
        let mut plate_counts: HashMap<i32, usize> = HashMap::new();
        for plate in &self.plates {
            let weight_key = (plate.weight * 100.0).round() as i32; // Convert to hundredths
            *plate_counts.entry(weight_key).or_insert(0) += 1;
        }

        // Sort weights in descending order
        let mut sorted_weights: Vec<i32> = plate_counts.keys().copied().collect();
        sorted_weights.sort_by(|a, b| b.cmp(a));

        // Format each plate count
        sorted_weights
            .iter()
            .map(|weight_key| {
                let count = plate_counts[weight_key];
                let weight = *weight_key as f64 / 100.0;
                // Format as integer if whole number, otherwise show decimal
                let weight_str = if weight.fract().abs() < 0.001 {
                    format!("{}", weight as i32)
                } else {
                    format!("{weight}")
                };
                format!("{}x{}{}", count, weight_str, unit_suffix)
            })
            .collect::<Vec<_>>()
            .join(", ")
    }
}

// =============================================================================
// MARK: - GlobalExercise
// =============================================================================

/// An exercise from the global exercise library.
///
/// Represents a template exercise from the exercise database that users
/// can add to their workouts. Contains metadata about the exercise
/// such as muscle group and equipment type.
#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, Eq, Hash)]
pub struct GlobalExercise {
    /// Unique identifier for this exercise template
    pub id: Id,
    /// Display name of the exercise
    pub name: String,
    /// Type of equipment used (as a string for flexibility)
    #[serde(rename = "type")]
    pub exercise_type: String,
    /// Additional foreign key for external references
    pub additional_fk: Option<String>,
    /// Primary muscle group targeted by this exercise
    pub muscle_group: String,
    /// Asset name for the exercise image
    pub image_name: String,
}

impl GlobalExercise {
    /// Creates a new GlobalExercise with the given details.
    pub fn new(
        name: impl Into<String>,
        exercise_type: impl Into<String>,
        muscle_group: impl Into<String>,
    ) -> Self {
        Self {
            id: Id::new(),
            name: name.into(),
            exercise_type: exercise_type.into(),
            additional_fk: None,
            muscle_group: muscle_group.into(),
            image_name: String::new(),
        }
    }
}

// =============================================================================
// MARK: - Tests
// =============================================================================

#[cfg(test)]
mod tests {
    use super::*;

    // -------------------------------------------------------------------------
    // Workout Tests
    // -------------------------------------------------------------------------

    #[test]
    fn test_workout_serialization() {
        let workout = Workout::new();
        let json = serde_json::to_string(&workout).expect("Failed to serialize workout");
        let deserialized: Workout =
            serde_json::from_str(&json).expect("Failed to deserialize workout");

        assert_eq!(workout.id, deserialized.id);
        assert_eq!(workout.name, deserialized.name);
        assert_eq!(workout.exercises.len(), deserialized.exercises.len());
    }

    #[test]
    fn test_workout_with_name() {
        let workout = Workout::with_name("Push Day");
        assert_eq!(workout.name, "Push Day");
        assert!(workout.exercises.is_empty());
    }

    #[test]
    fn test_workout_add_exercise() {
        let mut workout = Workout::new();
        workout.add_exercise("Bench Press");

        assert_eq!(workout.exercises.len(), 1);
        assert_eq!(workout.exercises[0].name, "Bench Press");
        assert_eq!(workout.exercises[0].workout_id, workout.id);
    }

    #[test]
    fn test_workout_not_completed_when_empty() {
        let workout = Workout::new();
        assert!(!workout.is_completed());
    }

    #[test]
    fn test_workout_completed_when_all_sets_done() {
        let mut workout = Workout::new();
        let exercise = workout.add_exercise("Squat");
        let set = exercise.add_set();
        set.complete(SetActual::with_weight_and_reps(225.0, 5));

        assert!(workout.is_completed());
    }

    #[test]
    fn test_workout_total_volume() {
        let mut workout = Workout::new();
        let exercise = workout.add_exercise("Bench Press");

        // Add two completed sets
        let set1 = exercise.add_set();
        set1.complete(SetActual::with_weight_and_reps(135.0, 10));

        let set2 = exercise.add_set();
        set2.complete(SetActual::with_weight_and_reps(185.0, 5));

        // Volume = (135 * 10) + (185 * 5) = 1350 + 925 = 2275
        assert!((workout.total_volume() - 2275.0).abs() < 0.01);
    }

    // -------------------------------------------------------------------------
    // Exercise Tests
    // -------------------------------------------------------------------------

    #[test]
    fn test_exercise_serialization() {
        let workout_id = Id::new();
        let exercise = Exercise::new("Deadlift".to_string(), workout_id);

        let json = serde_json::to_string(&exercise).expect("Failed to serialize exercise");
        let deserialized: Exercise =
            serde_json::from_str(&json).expect("Failed to deserialize exercise");

        assert_eq!(exercise.id, deserialized.id);
        assert_eq!(exercise.name, deserialized.name);
        assert_eq!(exercise.workout_id, deserialized.workout_id);
    }

    #[test]
    fn test_exercise_from_global() {
        let global = GlobalExercise::new("Squat", "barbell", "legs");
        let workout_id = Id::new();
        let exercise = Exercise::from_global(&global, workout_id.clone());

        assert_eq!(exercise.name, "Squat");
        assert_eq!(exercise.workout_id, workout_id);
        assert!(exercise.sets.is_empty());
    }

    #[test]
    fn test_exercise_is_completed() {
        let workout_id = Id::new();
        let mut exercise = Exercise::new("Curl".to_string(), workout_id);

        // Empty exercise is not completed
        assert!(!exercise.is_completed());

        // Add incomplete set
        exercise.add_set();
        assert!(!exercise.is_completed());

        // Complete the set
        exercise.sets[0].complete(SetActual::with_weight_and_reps(25.0, 12));
        assert!(exercise.is_completed());
    }

    // -------------------------------------------------------------------------
    // ExerciseSet Tests
    // -------------------------------------------------------------------------

    #[test]
    fn test_exercise_set_with_actual_values() {
        let exercise_id = Id::new();
        let workout_id = Id::new();

        let mut set = ExerciseSet::new(exercise_id, workout_id, 0);
        set.complete(SetActual {
            weight: Some(225.0),
            reps: Some(10),
            rpe: Some(8.0),
            ..Default::default()
        });

        let json = serde_json::to_string(&set).expect("Failed to serialize set");
        assert!(json.contains("225"));
        assert!(json.contains("10"));
        assert!(set.is_completed);
    }

    #[test]
    fn test_set_actual_volume() {
        let actual = SetActual::with_weight_and_reps(135.0, 8);
        assert_eq!(actual.volume(), Some(1080.0));

        let empty = SetActual::default();
        assert_eq!(empty.volume(), None);
    }

    #[test]
    fn test_exercise_set_new_warmup() {
        let exercise_id = Id::new();
        let workout_id = Id::new();

        let set = ExerciseSet::new_warmup(exercise_id, workout_id, 0);
        assert_eq!(set.set_type, SetType::WarmUp);
        assert!(!set.is_completed);
    }

    // -------------------------------------------------------------------------
    // Enum Tests
    // -------------------------------------------------------------------------

    #[test]
    fn test_exercise_type_serialization() {
        let exercise_type = ExerciseType::Barbell;
        let json = serde_json::to_string(&exercise_type).expect("Failed to serialize");
        assert_eq!(json, "\"barbell\"");

        let deserialized: ExerciseType =
            serde_json::from_str(&json).expect("Failed to deserialize");
        assert_eq!(deserialized, ExerciseType::Barbell);
    }

    #[test]
    fn test_weight_unit_serialization() {
        let kg = WeightUnit::Kg;
        let lb = WeightUnit::Lb;

        assert_eq!(serde_json::to_string(&kg).unwrap(), "\"kg\"");
        assert_eq!(serde_json::to_string(&lb).unwrap(), "\"lb\"");
    }

    #[test]
    fn test_set_type_serialization() {
        let warm_up = SetType::WarmUp;
        let drop_set = SetType::DropSet;

        assert_eq!(serde_json::to_string(&warm_up).unwrap(), "\"warmUp\"");
        assert_eq!(serde_json::to_string(&drop_set).unwrap(), "\"dropSet\"");
    }

    #[test]
    fn test_body_part_main_serialization() {
        let full_body = BodyPartMain::FullBody;
        assert_eq!(serde_json::to_string(&full_body).unwrap(), "\"fullBody\"");
    }

    // -------------------------------------------------------------------------
    // BodyPart Tests
    // -------------------------------------------------------------------------

    #[test]
    fn test_body_part_serialization() {
        let body_part = BodyPart::with_details(
            BodyPartMain::Chest,
            vec!["upper chest".to_string()],
            vec!["pectoralis major".to_string()],
        );

        let json = serde_json::to_string(&body_part).expect("Failed to serialize");
        let deserialized: BodyPart = serde_json::from_str(&json).expect("Failed to deserialize");

        assert_eq!(deserialized.main, BodyPartMain::Chest);
        assert_eq!(deserialized.detailed, Some(vec!["upper chest".to_string()]));
    }

    // -------------------------------------------------------------------------
    // GlobalExercise Tests
    // -------------------------------------------------------------------------

    #[test]
    fn test_global_exercise_serialization() {
        let exercise = GlobalExercise::new("Bench Press", "barbell", "chest");
        let json = serde_json::to_string(&exercise).expect("Failed to serialize");

        // Verify the "type" field is renamed correctly
        assert!(json.contains("\"type\":\"barbell\""));

        let deserialized: GlobalExercise =
            serde_json::from_str(&json).expect("Failed to deserialize");
        assert_eq!(deserialized.name, "Bench Press");
        assert_eq!(deserialized.exercise_type, "barbell");
    }

    // -------------------------------------------------------------------------
    // Plate Calculator Tests
    // -------------------------------------------------------------------------

    #[test]
    fn test_plate_standard_set() {
        let plates = Plate::standard();
        assert_eq!(plates.len(), 6);
        assert!((plates[0].weight - 45.0).abs() < 0.01);
        assert!((plates[5].weight - 2.5).abs() < 0.01);
    }

    #[test]
    fn test_bar_type_all_bars() {
        let bars = BarType::all_bars();
        assert_eq!(bars.len(), 4);
        assert_eq!(bars[0].name, "Olympic");
    }

    #[test]
    fn test_plate_calculation_description() {
        let calc = PlateCalculation {
            total_weight: 225.0,
            bar_type: BarType::olympic(),
            plates: vec![Plate::new(45.0), Plate::new(45.0), Plate::new(2.5)],
            weight_unit: WeightUnit::Lb,
        };

        let description = calc.formatted_plate_description();
        assert!(description.contains("2x45lb"));
        assert!(description.contains("1x2.5lb"));
    }

    #[test]
    fn test_plate_calculation_description_with_1_25_kg() {
        // Regression test: 1.25 kg plates should display correctly with kg unit
        // Previously, truncation caused 1.25 to display as "1lb"
        let calc = PlateCalculation {
            total_weight: 62.5,
            bar_type: BarType::new("Olympic (kg)", 20.0),
            plates: vec![Plate::new(20.0), Plate::new(1.25), Plate::new(1.25)],
            weight_unit: WeightUnit::Kg,
        };

        let description = calc.formatted_plate_description();
        assert!(description.contains("1x20kg"));
        assert!(description.contains("2x1.25kg"));
    }

    // -------------------------------------------------------------------------
    // Default Trait Tests
    // -------------------------------------------------------------------------

    #[test]
    fn test_defaults() {
        assert_eq!(ExerciseType::default(), ExerciseType::Unknown);
        assert_eq!(WeightUnit::default(), WeightUnit::Lb);
        assert_eq!(SetType::default(), SetType::Working);
        assert_eq!(BodyPartMain::default(), BodyPartMain::Other);

        let bar = BarType::default();
        assert_eq!(bar.name, "Olympic");
    }
}
