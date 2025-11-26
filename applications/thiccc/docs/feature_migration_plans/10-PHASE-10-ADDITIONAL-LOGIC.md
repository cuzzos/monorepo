# Phase 10: Additional Business Logic

## Overview

**Goal**: Implement remaining business logic (stats calculation, plate calculator, exercise library).

**Phase Duration**: Estimated 2-3 hours  
**Complexity**: Medium  
**Dependencies**: Phase 4 (Core Business Logic)  
**Blocks**: None

## Why This Phase Matters

These components enhance functionality:
- Stats provide workout insights
- Plate calculator helps with barbell loading
- Exercise library enables exercise selection

## Task Breakdown

### Task 10.1: Implement Plate Calculator Logic

**Estimated Time**: 1 hour  
**Complexity**: Medium  
**Priority**: Medium

#### Objective
Pure Rust implementation of plate calculation algorithm.

#### Reference Files
- `legacy/Goonlytics/Goonlytics/Sources/Workout/Models/PlateCalculator.swift`

#### Implementation

**File**: `/applications/thiccc/app/shared/src/plate_calculator.rs` (new file)

```rust
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
pub enum BarType {
    Olympic, // 45 lbs
    Standard, // 15 lbs
    Womens, // 35 lbs
    Training, // 10 lbs
}

impl BarType {
    pub fn weight(&self) -> f64 {
        match self {
            BarType::Olympic => 45.0,
            BarType::Standard => 15.0,
            BarType::Womens => 35.0,
            BarType::Training => 10.0,
        }
    }
    
    pub fn name(&self) -> &str {
        match self {
            BarType::Olympic => "Olympic",
            BarType::Standard => "Standard",
            BarType::Womens => "Women's",
            BarType::Training => "Training",
        }
    }
    
    pub fn all_cases() -> Vec<BarType> {
        vec![
            BarType::Olympic,
            BarType::Standard,
            BarType::Womens,
            BarType::Training,
        ]
    }
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
pub struct Plate {
    pub weight: f64,
}

impl Plate {
    /// Standard available plates (in lbs)
    pub fn standard_plates() -> Vec<Plate> {
        vec![
            Plate { weight: 45.0 },
            Plate { weight: 35.0 },
            Plate { weight: 25.0 },
            Plate { weight: 10.0 },
            Plate { weight: 5.0 },
            Plate { weight: 2.5 },
        ]
    }
    
    pub fn color(&self) -> &str {
        match self.weight as i32 {
            45 => "red",
            35 => "blue",
            25 => "green",
            10 => "black",
            5 => "gray",
            2 | 3 => "purple", // 2.5 rounds to 2 or 3
            _ => "orange",
        }
    }
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
pub struct PlateCalculation {
    pub target_weight: f64,
    pub bar_type: BarType,
    pub total_weight: f64,
    pub plates_per_side: Vec<Plate>,
}

impl PlateCalculation {
    pub fn formatted_description(&self) -> String {
        let mut counts: std::collections::HashMap<String, i32> = std::collections::HashMap::new();
        
        for plate in &self.plates_per_side {
            let key = if plate.weight == 2.5 {
                "2.5".to_string()
            } else {
                format!("{}", plate.weight as i32)
            };
            *counts.entry(key).or_insert(0) += 1;
        }
        
        let mut parts: Vec<String> = counts
            .iter()
            .map(|(weight, count)| format!("{}×{}", count, weight))
            .collect();
        
        parts.sort();
        parts.join(", ")
    }
}

/// Calculate plates needed for target weight
pub fn calculate_plates(
    target_weight: f64,
    bar_type: BarType,
    use_percentage: Option<f64>,
) -> PlateCalculation {
    let actual_target = if let Some(pct) = use_percentage {
        target_weight * (pct / 100.0)
    } else {
        target_weight
    };
    
    let bar_weight = bar_type.weight();
    
    // Weight remaining for plates (divide by 2 for each side)
    let weight_for_plates = (actual_target - bar_weight).max(0.0) / 2.0;
    
    let mut remaining = weight_for_plates;
    let mut plates = Vec::new();
    let available_plates = Plate::standard_plates();
    
    // Greedy algorithm - use largest plates first
    for plate in available_plates {
        while remaining >= plate.weight - 0.01 { // Small epsilon for float comparison
            plates.push(Plate {
                weight: plate.weight,
            });
            remaining -= plate.weight;
        }
    }
    
    // Calculate actual total weight
    let actual_total = bar_weight + (plates.iter().map(|p| p.weight).sum::<f64>() * 2.0);
    
    PlateCalculation {
        target_weight: actual_target,
        bar_type,
        total_weight: actual_total,
        plates_per_side: plates,
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_olympic_bar_weight() {
        assert_eq!(BarType::Olympic.weight(), 45.0);
    }
    
    #[test]
    fn test_calculate_225_lbs() {
        let calc = calculate_plates(225.0, BarType::Olympic, None);
        
        assert_eq!(calc.total_weight, 225.0);
        assert_eq!(calc.plates_per_side.len(), 2); // Should be 2×45
        assert_eq!(calc.plates_per_side[0].weight, 45.0);
        assert_eq!(calc.plates_per_side[1].weight, 45.0);
    }
    
    #[test]
    fn test_calculate_with_percentage() {
        let calc = calculate_plates(100.0, BarType::Olympic, Some(90.0));
        
        assert_eq!(calc.target_weight, 90.0);
        // 90 - 45 (bar) = 45 / 2 = 22.5 per side
        // Should be 1×10, 1×10, 1×2.5 per side
    }
    
    #[test]
    fn test_formatted_description() {
        let calc = PlateCalculation {
            target_weight: 225.0,
            bar_type: BarType::Olympic,
            total_weight: 225.0,
            plates_per_side: vec![
                Plate { weight: 45.0 },
                Plate { weight: 45.0 },
            ],
        };
        
        let desc = calc.formatted_description();
        assert_eq!(desc, "2×45");
    }
}
```

**Success Criteria**:
- [ ] Algorithm computes correct plates
- [ ] Handles all bar types
- [ ] Handles percentage calculations
- [ ] Returns formatted description
- [ ] Tests pass

---

### Task 10.2: Implement Stats Calculation

**Estimated Time**: 30 minutes  
**Complexity**: Low  
**Priority**: High

#### Objective
Calculate workout statistics (volume, sets, PRs).

#### Implementation

**File**: `/applications/thiccc/app/shared/src/stats.rs` (new file)

```rust
use crate::models::*;

/// Calculate total volume for a workout (weight × reps summed)
pub fn calculate_volume(workout: &Workout) -> i32 {
    workout
        .exercises
        .iter()
        .flat_map(|e| &e.sets)
        .filter_map(|s| {
            match (s.actual.weight, s.actual.reps) {
                (Some(w), Some(r)) => Some((w * r as f64) as i32),
                _ => None,
            }
        })
        .sum()
}

/// Calculate total number of completed sets
pub fn count_completed_sets(workout: &Workout) -> usize {
    workout
        .exercises
        .iter()
        .flat_map(|e| &e.sets)
        .filter(|s| s.is_completed)
        .count()
}

/// Calculate total number of sets (completed or not)
pub fn count_total_sets(workout: &Workout) -> usize {
    workout
        .exercises
        .iter()
        .map(|e| e.sets.len())
        .sum()
}

/// Format duration as "MM:SS" or "HH:MM:SS"
pub fn format_duration(seconds: i32) -> String {
    if seconds < 0 {
        return "00:00".to_string();
    }
    
    let hours = seconds / 3600;
    let minutes = (seconds % 3600) / 60;
    let secs = seconds % 60;
    
    if hours > 0 {
        format!("{:02}:{:02}:{:02}", hours, minutes, secs)
    } else {
        format!("{:02}:{:02}", minutes, secs)
    }
}

/// Get max weight for an exercise across all sets
pub fn max_weight_for_exercise(exercise: &Exercise) -> Option<f64> {
    exercise
        .sets
        .iter()
        .filter_map(|s| s.actual.weight)
        .max_by(|a, b| a.partial_cmp(b).unwrap())
}

/// Get max reps for an exercise across all sets
pub fn max_reps_for_exercise(exercise: &Exercise) -> Option<i32> {
    exercise
        .sets
        .iter()
        .filter_map(|s| s.actual.reps)
        .max()
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_calculate_volume() {
        let mut workout = Workout::new();
        let mut exercise = Exercise {
            id: uuid::Uuid::new_v4(),
            workout_id: workout.id,
            name: "Bench Press".to_string(),
            sets: vec![],
            // ... other fields
        };
        
        exercise.sets.push(ExerciseSet {
            actual: SetActual {
                weight: Some(225.0),
                reps: Some(10),
                ..Default::default()
            },
            // ... other fields
        });
        
        exercise.sets.push(ExerciseSet {
            actual: SetActual {
                weight: Some(225.0),
                reps: Some(8),
                ..Default::default()
            },
            // ... other fields
        });
        
        workout.exercises.push(exercise);
        
        // 225*10 + 225*8 = 2250 + 1800 = 4050
        assert_eq!(calculate_volume(&workout), 4050);
    }
    
    #[test]
    fn test_format_duration() {
        assert_eq!(format_duration(0), "00:00");
        assert_eq!(format_duration(65), "01:05");
        assert_eq!(format_duration(3661), "01:01:01");
    }
}
```

**Success Criteria**:
- [ ] Volume calculation correct
- [ ] Set counting correct
- [ ] Duration formatting correct
- [ ] Tests pass

---

### Task 10.3: Implement Exercise Library

**Estimated Time**: 45 minutes  
**Complexity**: Low  
**Priority**: High

#### Objective
Static exercise library with search/filter capability.

#### Implementation

**File**: `/applications/thiccc/app/shared/src/exercise_library.rs` (new file)

```rust
use crate::models::GlobalExercise;
use uuid::Uuid;

/// Get all exercises in the library
pub fn get_all_exercises() -> Vec<GlobalExercise> {
    vec![
        GlobalExercise {
            id: Uuid::parse_str("00000000-0000-0000-0000-000000000001").unwrap(),
            name: "Squat (Barbell)".to_string(),
            exercise_type: "barbell".to_string(),
            additional_fk: None,
            muscle_group: "Quadriceps".to_string(),
            image_name: "squat_barbell".to_string(),
        },
        GlobalExercise {
            id: Uuid::parse_str("00000000-0000-0000-0000-000000000002").unwrap(),
            name: "Bench Press (Barbell)".to_string(),
            exercise_type: "barbell".to_string(),
            additional_fk: None,
            muscle_group: "Chest".to_string(),
            image_name: "benchpress_barbell".to_string(),
        },
        GlobalExercise {
            id: Uuid::parse_str("00000000-0000-0000-0000-000000000003").unwrap(),
            name: "Deadlift (Barbell)".to_string(),
            exercise_type: "barbell".to_string(),
            additional_fk: None,
            muscle_group: "Back".to_string(),
            image_name: "deadlift_barbell".to_string(),
        },
        GlobalExercise {
            id: Uuid::parse_str("00000000-0000-0000-0000-000000000004").unwrap(),
            name: "Pull Up".to_string(),
            exercise_type: "bodyweight".to_string(),
            additional_fk: None,
            muscle_group: "Back".to_string(),
            image_name: "pullup".to_string(),
        },
        GlobalExercise {
            id: Uuid::parse_str("00000000-0000-0000-0000-000000000005").unwrap(),
            name: "Push Up".to_string(),
            exercise_type: "bodyweight".to_string(),
            additional_fk: None,
            muscle_group: "Chest".to_string(),
            image_name: "pushup".to_string(),
        },
        GlobalExercise {
            id: Uuid::parse_str("00000000-0000-0000-0000-000000000006").unwrap(),
            name: "Overhead Press (Barbell)".to_string(),
            exercise_type: "barbell".to_string(),
            additional_fk: None,
            muscle_group: "Shoulders".to_string(),
            image_name: "overhead_press_barbell".to_string(),
        },
        GlobalExercise {
            id: Uuid::parse_str("00000000-0000-0000-0000-000000000007").unwrap(),
            name: "Romanian Deadlift (Barbell)".to_string(),
            exercise_type: "barbell".to_string(),
            additional_fk: None,
            muscle_group: "Hamstrings".to_string(),
            image_name: "romanian_deadlift".to_string(),
        },
        // Add more exercises...
    ]
}

/// Search exercises by name (case-insensitive)
pub fn search_exercises(query: &str) -> Vec<GlobalExercise> {
    if query.is_empty() {
        return get_all_exercises();
    }
    
    let query_lower = query.to_lowercase();
    get_all_exercises()
        .into_iter()
        .filter(|ex| ex.name.to_lowercase().contains(&query_lower))
        .collect()
}

/// Filter exercises by equipment type
pub fn filter_by_type(exercise_type: &str) -> Vec<GlobalExercise> {
    get_all_exercises()
        .into_iter()
        .filter(|ex| ex.exercise_type == exercise_type)
        .collect()
}

/// Filter exercises by muscle group
pub fn filter_by_muscle(muscle_group: &str) -> Vec<GlobalExercise> {
    get_all_exercises()
        .into_iter()
        .filter(|ex| ex.muscle_group == muscle_group)
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_get_all_exercises() {
        let exercises = get_all_exercises();
        assert!(!exercises.is_empty());
    }
    
    #[test]
    fn test_search_exercises() {
        let results = search_exercises("squat");
        assert!(results.iter().any(|e| e.name.to_lowercase().contains("squat")));
    }
    
    #[test]
    fn test_filter_by_type() {
        let barbell_exercises = filter_by_type("barbell");
        assert!(barbell_exercises.iter().all(|e| e.exercise_type == "barbell"));
    }
}
```

**Success Criteria**:
- [ ] Exercise library returns exercises
- [ ] Search works
- [ ] Filtering works
- [ ] Tests pass

---

### Task 10.4: Integrate Logic into Update/View Functions

**Estimated Time**: 30 minutes  
**Complexity**: Low  
**Priority**: High

#### Objective
Use new modules in core business logic.

#### Implementation

**File**: Update `/applications/thiccc/app/shared/src/lib.rs`

```rust
pub mod app;
pub mod models;
pub mod plate_calculator;
pub mod stats;
pub mod exercise_library;

pub use plate_calculator::*;
pub use stats::*;
pub use exercise_library::*;
```

**File**: Update `/applications/thiccc/app/shared/src/app.rs`

```rust
use crate::plate_calculator;
use crate::stats;
use crate::exercise_library;

// In update function:
Event::CalculatePlates { target_weight, bar_type, use_percentage } => {
    let calculation = plate_calculator::calculate_plates(
        target_weight,
        bar_type,
        use_percentage
    );
    model.plate_calculation = Some(calculation);
    render()
}

// In view function helper methods:
fn build_workout_view(&self, model: &Model) -> WorkoutViewModel {
    if let Some(ref workout) = model.current_workout {
        WorkoutViewModel {
            has_active_workout: true,
            workout_name: workout.name.clone(),
            formatted_duration: stats::format_duration(model.workout_timer_seconds),
            total_volume: stats::calculate_volume(workout),
            total_sets: stats::count_total_sets(workout),
            // ... other fields
        }
    } else {
        WorkoutViewModel::default()
    }
}
```

**Success Criteria**:
- [ ] Modules integrated
- [ ] Stats used in view function
- [ ] Plate calculator used in update
- [ ] Exercise library available
- [ ] Code compiles

---

## Phase 10 Completion Checklist

Before moving to next phase, verify:

- [ ] Plate calculator implemented
- [ ] Stats calculation implemented
- [ ] Exercise library implemented
- [ ] All modules integrated into core
- [ ] Tests written and passing
- [ ] Code compiles without errors
- [ ] Functions work in simulator

## Testing Phase 10

### Unit Tests
Run all tests:
```bash
cd applications/thiccc/app/shared
cargo test
```

### Integration Tests
- [ ] Use plate calculator in app
- [ ] Verify stats display correctly
- [ ] Search exercises in library

## Next Steps

After completing Phase 10:
- **[Phase 11: Polish & Testing](./11-PHASE-11-POLISH.md)** - Final polish
- **[Phase 12: Optional Enhancements](./12-PHASE-12-OPTIONAL.md)** - Nice-to-haves

---

**Phase Status**: 📋 Ready for Implementation  
**Last Updated**: November 26, 2025

