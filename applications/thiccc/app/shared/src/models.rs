use serde::{Deserialize, Serialize};
use uuid::Uuid;

// MARK: - Enums

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, Eq, Hash)]
#[serde(rename_all = "camelCase")]
pub enum ExerciseType {
    Dumbbell,
    Kettlebell,
    Barbell,
    Hexbar,
    Bodyweight,
    Machine,
    Unknown,
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, Eq, Hash)]
#[serde(rename_all = "lowercase")]
pub enum WeightUnit {
    Kg,
    Lb,
    Bodyweight,
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, Eq, Hash)]
#[serde(rename_all = "camelCase")]
pub enum SetType {
    WarmUp,
    Working,
    DropSet,
    Amrap,
    Failure,
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, Eq, Hash)]
#[serde(rename_all = "camelCase")]
pub enum BodyPartMain {
    Chest,
    Legs,
    Arms,
    Back,
    Calves,
    Shoulders,
    Core,
    Cardio,
    FullBody,
    Other,
}

// MARK: - BodyPart

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, Eq, Hash)]
pub struct BodyPart {
    pub main: BodyPartMain,
    pub detailed: Option<Vec<String>>,
    pub scientific: Option<Vec<String>>,
}

// MARK: - ExerciseSet

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
pub struct ExerciseSet {
    pub id: Uuid,
    #[serde(rename = "type")]
    pub set_type: SetType,
    pub weight_unit: Option<WeightUnit>,
    pub suggest: SetSuggest,
    pub actual: SetActual,
    #[serde(skip)]
    pub is_completed: bool,
    pub exercise_id: Uuid,
    pub workout_id: Uuid,
    pub set_index: i32,
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
pub struct SetSuggest {
    pub weight: Option<f64>,
    pub reps: Option<i32>,
    pub rep_range: Option<i32>,
    pub duration: Option<i32>,
    pub rpe: Option<f64>,
    pub rest_time: Option<i32>,
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
pub struct SetActual {
    pub weight: Option<f64>,
    pub reps: Option<i32>,
    pub duration: Option<i32>,
    pub rpe: Option<f64>,
    pub actual_rest_time: Option<i32>,
}

impl Default for SetSuggest {
    fn default() -> Self {
        Self {
            weight: None,
            reps: None,
            rep_range: None,
            duration: None,
            rpe: None,
            rest_time: None,
        }
    }
}

impl Default for SetActual {
    fn default() -> Self {
        Self {
            weight: None,
            reps: None,
            duration: None,
            rpe: None,
            actual_rest_time: None,
        }
    }
}

// MARK: - Exercise

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
pub struct Exercise {
    pub id: Uuid,
    pub superset_id: Option<i32>,
    pub workout_id: Uuid,
    pub name: String,
    pub pinned_notes: Vec<String>,
    pub notes: Vec<String>,
    pub duration: Option<i32>,
    #[serde(rename = "type")]
    pub exercise_type: ExerciseType,
    pub weight_unit: Option<WeightUnit>,
    pub default_warm_up_time: Option<i32>,
    pub default_rest_time: Option<i32>,
    #[serde(skip)]
    pub sets: Vec<ExerciseSet>,
    pub body_part: Option<BodyPart>,
}

impl Exercise {
    pub fn is_completed(&self) -> bool {
        self.sets.iter().all(|set| set.is_completed)
    }
}

// MARK: - Workout

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
pub struct Workout {
    pub id: Uuid,
    pub name: String,
    pub note: Option<String>,
    pub duration: Option<i32>,
    #[serde(with = "chrono::serde::ts_seconds")]
    pub start_timestamp: chrono::DateTime<chrono::Utc>,
    #[serde(with = "chrono::serde::ts_seconds_option")]
    pub end_timestamp: Option<chrono::DateTime<chrono::Utc>>,
    #[serde(skip)]
    pub exercises: Vec<Exercise>,
}

// MARK: - Plate Calculator Models

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
pub struct Plate {
    pub id: Uuid,
    pub weight: f64,
}

impl Plate {
    pub fn standard() -> Vec<Plate> {
        vec![
            Plate {
                id: Uuid::new_v4(),
                weight: 45.0,
            },
            Plate {
                id: Uuid::new_v4(),
                weight: 35.0,
            },
            Plate {
                id: Uuid::new_v4(),
                weight: 25.0,
            },
            Plate {
                id: Uuid::new_v4(),
                weight: 10.0,
            },
            Plate {
                id: Uuid::new_v4(),
                weight: 5.0,
            },
            Plate {
                id: Uuid::new_v4(),
                weight: 2.5,
            },
        ]
    }
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
pub struct BarType {
    pub id: Uuid,
    pub name: String,
    pub weight: f64,
}

impl BarType {
    pub fn olympic() -> Self {
        Self {
            id: Uuid::new_v4(),
            name: "Olympic".to_string(),
            weight: 45.0,
        }
    }

    pub fn standard() -> Self {
        Self {
            id: Uuid::new_v4(),
            name: "Standard".to_string(),
            weight: 20.0,
        }
    }

    pub fn ez_bar() -> Self {
        Self {
            id: Uuid::new_v4(),
            name: "EZ Bar".to_string(),
            weight: 20.0,
        }
    }

    pub fn trap_bar() -> Self {
        Self {
            id: Uuid::new_v4(),
            name: "Trap Bar".to_string(),
            weight: 45.0,
        }
    }

    pub fn all_bars() -> Vec<Self> {
        vec![
            Self::olympic(),
            Self::standard(),
            Self::ez_bar(),
            Self::trap_bar(),
        ]
    }
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
pub struct PlateCalculation {
    pub total_weight: f64,
    pub bar_type: BarType,
    pub plates: Vec<Plate>,
}

impl PlateCalculation {
    pub fn formatted_plate_description(&self) -> String {
        use std::collections::HashMap;
        // Use a workaround: convert f64 to i32 (cents) for HashMap key
        let mut plate_counts: HashMap<i32, usize> = HashMap::new();
        for plate in &self.plates {
            let weight_key = (plate.weight * 10.0) as i32; // Convert to tenths
            *plate_counts.entry(weight_key).or_insert(0) += 1;
        }

        let mut sorted_weights: Vec<i32> = plate_counts.keys().cloned().collect();
        sorted_weights.sort_by(|a, b| b.cmp(a));

        sorted_weights
            .iter()
            .map(|weight_key| {
                let count = plate_counts[weight_key];
                let weight = *weight_key as f64 / 10.0;
                let weight_str = if (weight - 2.5).abs() < 0.01 {
                    "2.5".to_string()
                } else {
                    format!("{}", weight as i32)
                };
                format!("{}x{}lb", count, weight_str)
            })
            .collect::<Vec<_>>()
            .join(", ")
    }
}

// MARK: - GlobalExercise

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, Eq, Hash)]
pub struct GlobalExercise {
    pub id: Uuid,
    pub name: String,
    #[serde(rename = "type")]
    pub exercise_type: String,
    pub additional_fk: Option<String>,
    pub muscle_group: String,
    pub image_name: String,
}

