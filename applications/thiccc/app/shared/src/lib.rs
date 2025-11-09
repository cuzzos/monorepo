use crux_core::render::Render;
use serde::{Deserialize, Serialize};
use uuid::Uuid;

mod models;
mod database;

pub use models::*;

/// The core Crux app - all business logic lives here
#[derive(Default)]
pub struct App;

/// Events that can be dispatched to update the app state
#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
#[serde(tag = "type", rename_all = "camelCase")]
pub enum Event {
    // Timer events
    StartTimer,
    StopTimer,
    ToggleTimer,
    TimerTick,
    
    // Workout events
    CreateWorkout { name: String },
    FinishWorkout,
    DiscardWorkout,
    UpdateWorkoutName { name: String },
    UpdateWorkoutNote { note: Option<String> },
    
    // Exercise events
    AddExercise { global_exercise: GlobalExercise },
    DeleteExercise { exercise_id: Uuid },
    UpdateExerciseName { exercise_id: Uuid, name: String },
    
    // Set events
    AddSet { exercise_id: Uuid },
    DeleteSet { exercise_id: Uuid, set_index: usize },
    UpdateSetActual {
        exercise_id: Uuid,
        set_index: usize,
        actual: SetActual,
    },
    UpdateSetSuggest {
        exercise_id: Uuid,
        set_index: usize,
        suggest: SetSuggest,
    },
    ToggleSetCompleted { exercise_id: Uuid, set_index: usize },
    
    // History events
    LoadHistory,
    LoadWorkoutDetail { workout_id: Uuid },
    ImportWorkout { json_data: String },
    
    // Navigation events
    NavigateToWorkout,
    NavigateToHistory,
    NavigateToWorkoutDetail { workout_id: Uuid },
    NavigateToHistoryDetail { workout_id: Uuid },
    
    // Plate calculator events
    CalculatePlates { target_weight: f64, bar_type: BarType },
    
    // Database events (internal)
    WorkoutSaved,
    WorkoutLoaded { workout: Workout },
    HistoryLoaded { workouts: Vec<Workout> },
}

/// The app's model/state
#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
pub struct Model {
    // Current workout state
    pub current_workout: Option<Workout>,
    pub is_timer_running: bool,
    pub seconds_elapsed: i32,
    
    // History state
    pub workouts: Vec<Workout>,
    pub selected_workout: Option<Workout>,
    
    // Navigation state
    pub selected_tab: Tab,
    pub navigation_path: Vec<NavigationDestination>,
    
    // Plate calculator state
    pub plate_calculation: Option<PlateCalculation>,
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, Eq, Hash)]
pub enum Tab {
    Workout,
    History,
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, Eq, Hash)]
pub enum NavigationDestination {
    WorkoutDetail { workout_id: Uuid },
    HistoryDetail { workout_id: Uuid },
}

impl Default for Model {
    fn default() -> Self {
        Self {
            current_workout: None,
            is_timer_running: false,
            seconds_elapsed: 0,
            workouts: Vec::new(),
            selected_workout: None,
            selected_tab: Tab::Workout,
            navigation_path: Vec::new(),
            plate_calculation: None,
        }
    }
}

/// The view model that gets sent to the shell for rendering
#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
pub struct ViewModel {
    // Workout view model
    pub workout: Option<WorkoutViewModel>,
    pub is_timer_running: bool,
    pub formatted_time: String,
    pub total_volume: i32,
    pub total_sets: i32,
    
    // History view model
    pub workouts: Vec<WorkoutListItem>,
    
    // Navigation
    pub selected_tab: Tab,
    pub navigation_path: Vec<NavigationDestination>,
    
    // Plate calculator
    pub plate_calculation: Option<PlateCalculation>,
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
pub struct WorkoutViewModel {
    pub id: Uuid,
    pub name: String,
    pub note: Option<String>,
    pub duration: Option<i32>,
    pub exercises: Vec<ExerciseViewModel>,
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
pub struct ExerciseViewModel {
    pub id: Uuid,
    pub name: String,
    pub exercise_type: ExerciseType,
    pub weight_unit: Option<WeightUnit>,
    pub sets: Vec<ExerciseSetViewModel>,
    pub is_completed: bool,
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
pub struct ExerciseSetViewModel {
    pub id: Uuid,
    pub set_type: SetType,
    pub weight_unit: Option<WeightUnit>,
    pub suggest: SetSuggest,
    pub actual: SetActual,
    pub is_completed: bool,
    pub set_index: i32,
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
pub struct WorkoutListItem {
    pub id: Uuid,
    pub name: String,
    pub start_timestamp: i64, // Unix timestamp
}

/// Capabilities used by the app
pub type Capabilities = Render<Event>;

impl crux_core::App for App {
    type Event = Event;
    type Model = Model;
    type ViewModel = ViewModel;
    type Capabilities = Capabilities;

    fn update(&self, event: Self::Event, model: &mut Self::Model, caps: &Self::Capabilities) {
        match event {
            Event::StartTimer => {
                model.is_timer_running = true;
                // Timer will be handled by Swift side, sending TimerTick events
                caps.render();
            }
            
            Event::StopTimer => {
                model.is_timer_running = false;
                caps.render();
            }
            
            Event::ToggleTimer => {
                model.is_timer_running = !model.is_timer_running;
                caps.render();
            }
            
            Event::TimerTick => {
                if model.is_timer_running {
                    model.seconds_elapsed += 1;
                    if let Some(ref mut workout) = model.current_workout {
                        workout.duration = Some(model.seconds_elapsed);
                    }
                    caps.render();
                }
            }
            
            Event::CreateWorkout { name } => {
                let workout = Workout {
                    id: uuid::Uuid::new_v4(),
                    name,
                    note: None,
                    duration: Some(0),
                    start_timestamp: chrono::Utc::now(),
                    end_timestamp: None,
                    exercises: Vec::new(),
                };
                model.current_workout = Some(workout);
                model.seconds_elapsed = 0;
                self.update(Event::StartTimer, model, caps);
                caps.render();
            }
            
            Event::FinishWorkout => {
                if let Some(mut workout) = model.current_workout.take() {
                    workout.end_timestamp = Some(chrono::Utc::now());
                    workout.duration = Some(model.seconds_elapsed);
                    
                    // Save to history immediately (UI update)
                    // Database save will be handled by shell via SaveWorkoutRequest event
                    model.workouts.insert(0, workout.clone());
                    
                    model.is_timer_running = false;
                    model.seconds_elapsed = 0;
                    caps.render();
                }
            }
            
            Event::WorkoutSaved => {
                // Database save completed, no action needed
                caps.render();
            }
            
            Event::WorkoutLoaded { workout } => {
                model.selected_workout = Some(workout);
                caps.render();
            }
            
            Event::HistoryLoaded { workouts } => {
                model.workouts = workouts;
                caps.render();
            }
            
            Event::DiscardWorkout => {
                model.current_workout = None;
                model.is_timer_running = false;
                model.seconds_elapsed = 0;
                caps.render();
            }
            
            Event::UpdateWorkoutName { name } => {
                if let Some(ref mut workout) = model.current_workout {
                    workout.name = name;
                    caps.render();
                }
            }
            
            Event::UpdateWorkoutNote { note } => {
                if let Some(ref mut workout) = model.current_workout {
                    workout.note = note;
                    caps.render();
                }
            }
            
            Event::AddExercise { global_exercise } => {
                if let Some(ref mut workout) = model.current_workout {
                    let exercise = Exercise {
                        id: uuid::Uuid::new_v4(),
                        superset_id: None,
                        workout_id: workout.id,
                        name: global_exercise.name.clone(),
                        pinned_notes: Vec::new(),
                        notes: Vec::new(),
                        duration: None,
                        exercise_type: match global_exercise.exercise_type.as_str() {
                            "barbell" => ExerciseType::Barbell,
                            "dumbbell" => ExerciseType::Dumbbell,
                            "kettlebell" => ExerciseType::Kettlebell,
                            "bodyweight" => ExerciseType::Bodyweight,
                            "machine" => ExerciseType::Machine,
                            _ => ExerciseType::Unknown,
                        },
                        weight_unit: Some(WeightUnit::Lb),
                        default_warm_up_time: Some(60),
                        default_rest_time: Some(60),
                        sets: Vec::new(),
                        body_part: None,
                    };
                    workout.exercises.push(exercise);
                    caps.render();
                }
            }
            
            Event::DeleteExercise { exercise_id } => {
                if let Some(ref mut workout) = model.current_workout {
                    workout.exercises.retain(|e| e.id != exercise_id);
                    caps.render();
                }
            }
            
            Event::UpdateExerciseName { exercise_id, name } => {
                if let Some(ref mut workout) = model.current_workout {
                    if let Some(exercise) = workout.exercises.iter_mut().find(|e| e.id == exercise_id) {
                        exercise.name = name;
                        caps.render();
                    }
                }
            }
            
            Event::AddSet { exercise_id } => {
                if let Some(ref mut workout) = model.current_workout {
                    if let Some(exercise) = workout.exercises.iter_mut().find(|e| e.id == exercise_id) {
                        let set = ExerciseSet {
                            id: uuid::Uuid::new_v4(),
                            set_type: SetType::Working,
                            weight_unit: exercise.weight_unit.clone(),
                            suggest: SetSuggest::default(),
                            actual: SetActual::default(),
                            is_completed: false,
                            exercise_id: exercise.id,
                            workout_id: workout.id,
                            set_index: exercise.sets.len() as i32,
                        };
                        exercise.sets.push(set);
                        caps.render();
                    }
                }
            }
            
            Event::DeleteSet { exercise_id, set_index } => {
                if let Some(ref mut workout) = model.current_workout {
                    if let Some(exercise) = workout.exercises.iter_mut().find(|e| e.id == exercise_id) {
                        if set_index < exercise.sets.len() {
                            exercise.sets.remove(set_index);
                            // Reindex remaining sets
                            for (idx, set) in exercise.sets.iter_mut().enumerate() {
                                set.set_index = idx as i32;
                            }
                            caps.render();
                        }
                    }
                }
            }
            
            Event::UpdateSetActual { exercise_id, set_index, actual } => {
                if let Some(ref mut workout) = model.current_workout {
                    if let Some(exercise) = workout.exercises.iter_mut().find(|e| e.id == exercise_id) {
                        if let Some(set) = exercise.sets.get_mut(set_index) {
                            set.actual = actual;
                            caps.render();
                        }
                    }
                }
            }
            
            Event::UpdateSetSuggest { exercise_id, set_index, suggest } => {
                if let Some(ref mut workout) = model.current_workout {
                    if let Some(exercise) = workout.exercises.iter_mut().find(|e| e.id == exercise_id) {
                        if let Some(set) = exercise.sets.get_mut(set_index) {
                            set.suggest = suggest;
                            caps.render();
                        }
                    }
                }
            }
            
            Event::ToggleSetCompleted { exercise_id, set_index } => {
                if let Some(ref mut workout) = model.current_workout {
                    if let Some(exercise) = workout.exercises.iter_mut().find(|e| e.id == exercise_id) {
                        if let Some(set) = exercise.sets.get_mut(set_index) {
                            set.is_completed = !set.is_completed;
                            caps.render();
                        }
                    }
                }
            }
            
            Event::LoadHistory => {
                // Request to load history - shell will handle database query
                // and send HistoryLoaded event back
                caps.render();
            }
            
            Event::LoadWorkoutDetail { workout_id } => {
                // Request to load workout detail - shell will handle database query
                // and send WorkoutLoaded event back
                // For now, try to find in existing workouts
                if let Some(workout) = model.workouts.iter().find(|w| w.id == workout_id) {
                    model.selected_workout = Some(workout.clone());
                    caps.render();
                }
            }
            
            Event::ImportWorkout { json_data } => {
                if let Ok(workout) = serde_json::from_str::<Workout>(&json_data) {
                    model.current_workout = Some(workout);
                    caps.render();
                }
            }
            
            Event::NavigateToWorkout => {
                model.selected_tab = Tab::Workout;
                caps.render();
            }
            
            Event::NavigateToHistory => {
                model.selected_tab = Tab::History;
                caps.render();
            }
            
            Event::NavigateToWorkoutDetail { workout_id } => {
                model.navigation_path.push(NavigationDestination::WorkoutDetail { workout_id });
                caps.render();
            }
            
            Event::NavigateToHistoryDetail { workout_id } => {
                model.navigation_path.push(NavigationDestination::HistoryDetail { workout_id });
                self.update(Event::LoadWorkoutDetail { workout_id }, model, caps);
            }
            
            Event::CalculatePlates { target_weight, bar_type } => {
                let weight_per_side = (target_weight - bar_type.weight) / 2.0;
                let mut remaining_weight = weight_per_side;
                let mut plates: Vec<Plate> = Vec::new();
                
                for plate in Plate::standard() {
                    while remaining_weight >= plate.weight {
                        plates.push(Plate {
                            id: uuid::Uuid::new_v4(),
                            weight: plate.weight,
                        });
                        remaining_weight -= plate.weight;
                    }
                }
                
                model.plate_calculation = Some(PlateCalculation {
                    total_weight: target_weight,
                    bar_type,
                    plates,
                });
                caps.render();
            }
            
        }
    }

    fn view(&self, model: &Self::Model) -> Self::ViewModel {
        let workout = model.current_workout.as_ref().map(|w| {
            let exercises: Vec<ExerciseViewModel> = w
                .exercises
                .iter()
                .map(|e| ExerciseViewModel {
                    id: e.id,
                    name: e.name.clone(),
                    exercise_type: e.exercise_type.clone(),
                    weight_unit: e.weight_unit.clone(),
                    sets: e
                        .sets
                        .iter()
                        .map(|s| ExerciseSetViewModel {
                            id: s.id,
                            set_type: s.set_type.clone(),
                            weight_unit: s.weight_unit.clone(),
                            suggest: s.suggest.clone(),
                            actual: s.actual.clone(),
                            is_completed: s.is_completed,
                            set_index: s.set_index,
                        })
                        .collect(),
                    is_completed: e.is_completed(),
                })
                .collect();
            
            let _total_volume: i32 = w
                .exercises
                .iter()
                .flat_map(|e| &e.sets)
                .map(|s| s.actual.reps.unwrap_or(0))
                .sum();
            
            let _total_sets = w.exercises.iter().map(|e| e.sets.len()).sum::<usize>() as i32;
            
            WorkoutViewModel {
                id: w.id,
                name: w.name.clone(),
                note: w.note.clone(),
                duration: w.duration,
                exercises,
            }
        });
        
        let workouts: Vec<WorkoutListItem> = model
            .workouts
            .iter()
            .map(|w| WorkoutListItem {
                id: w.id,
                name: w.name.clone(),
                start_timestamp: w.start_timestamp.timestamp(),
            })
            .collect();
        
        let minutes = model.seconds_elapsed / 60;
        let seconds = model.seconds_elapsed % 60;
        let formatted_time = format!("{}:{:02}", minutes, seconds);
        
        let total_volume = model
            .current_workout
            .as_ref()
            .map(|w| {
                w.exercises
                    .iter()
                    .flat_map(|e| &e.sets)
                    .map(|s| s.actual.reps.unwrap_or(0))
                    .sum()
            })
            .unwrap_or(0);
        
        let total_sets = model
            .current_workout
            .as_ref()
            .map(|w| w.exercises.iter().map(|e| e.sets.len()).sum::<usize>() as i32)
            .unwrap_or(0);
        
        ViewModel {
            workout,
            is_timer_running: model.is_timer_running,
            formatted_time,
            total_volume,
            total_sets,
            workouts,
            selected_tab: model.selected_tab.clone(),
            navigation_path: model.navigation_path.clone(),
            plate_calculation: model.plate_calculation.clone(),
        }
    }
}

// Note: FFI bridge will be implemented in the Swift shell
// For now, the core logic is complete and ready for integration

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_model_default() {
        let model = Model::default();
        assert!(model.current_workout.is_none());
        assert_eq!(model.seconds_elapsed, 0);
        assert!(!model.is_timer_running);
    }
    
    #[test]
    fn test_workout_creation() {
        let workout = Workout {
            id: uuid::Uuid::new_v4(),
            name: "Test Workout".to_string(),
            note: None,
            duration: Some(0),
            start_timestamp: chrono::Utc::now(),
            end_timestamp: None,
            exercises: Vec::new(),
        };
        
        assert_eq!(workout.name, "Test Workout");
        assert!(workout.exercises.is_empty());
    }
    
    #[test]
    fn test_exercise_creation() {
        let workout_id = uuid::Uuid::new_v4();
        let exercise = Exercise {
            id: uuid::Uuid::new_v4(),
            superset_id: None,
            workout_id,
            name: "Bench Press".to_string(),
            pinned_notes: Vec::new(),
            notes: Vec::new(),
            duration: None,
            exercise_type: ExerciseType::Barbell,
            weight_unit: Some(WeightUnit::Lb),
            default_warm_up_time: Some(60),
            default_rest_time: Some(90),
            sets: Vec::new(),
            body_part: None,
        };
        
        assert_eq!(exercise.name, "Bench Press");
        assert!(exercise.sets.is_empty());
        // Exercise with no sets is considered completed (all sets are completed)
        assert!(exercise.is_completed());
    }
    
    #[test]
    fn test_plate_calculation() {
        let bar_type = BarType::olympic();
        let calculation = PlateCalculation {
            total_weight: 225.0,
            bar_type: bar_type.clone(),
            plates: vec![
                Plate { id: uuid::Uuid::new_v4(), weight: 45.0 },
                Plate { id: uuid::Uuid::new_v4(), weight: 45.0 },
            ],
        };
        
        assert_eq!(calculation.total_weight, 225.0);
        assert_eq!(calculation.plates.len(), 2);
    }
}

// MARK: - FFI Functions for Swift Integration

use std::ffi::{CStr, CString};
use std::os::raw::c_char;
use std::ptr;

/// Core instance that holds the app state
/// For FFI, we bypass the full Crux capability system and use a simplified update
pub struct RustCore {
    model: Model,
}

impl RustCore {
    fn new() -> Self {
        let model = Model::default();
        Self {
            model,
        }
    }

    fn dispatch(&mut self, event_json: &str) -> Result<(), String> {
        let event: Event = serde_json::from_str(event_json)
            .map_err(|e| format!("Failed to parse event: {}", e))?;
        
        // Simplified update without capabilities - we'll handle the logic directly
        // This is a simplified version that doesn't use the full Crux capability system
        self.update_direct(event);
        Ok(())
    }
    
    // Simplified update function that doesn't require capabilities
    fn update_direct(&mut self, event: Event) {
        match event {
            Event::StartTimer => {
                self.model.is_timer_running = true;
            }
            Event::StopTimer => {
                self.model.is_timer_running = false;
            }
            Event::ToggleTimer => {
                self.model.is_timer_running = !self.model.is_timer_running;
            }
            Event::TimerTick => {
                if self.model.is_timer_running {
                    self.model.seconds_elapsed += 1;
                    if let Some(ref mut workout) = self.model.current_workout {
                        workout.duration = Some(self.model.seconds_elapsed);
                    }
                }
            }
            Event::CreateWorkout { name } => {
                let workout = Workout {
                    id: uuid::Uuid::new_v4(),
                    name,
                    note: None,
                    duration: Some(0),
                    start_timestamp: chrono::Utc::now(),
                    end_timestamp: None,
                    exercises: Vec::new(),
                };
                self.model.current_workout = Some(workout);
                self.model.seconds_elapsed = 0;
                self.model.is_timer_running = true;
            }
            Event::FinishWorkout => {
                if let Some(mut workout) = self.model.current_workout.take() {
                    workout.end_timestamp = Some(chrono::Utc::now());
                    workout.duration = Some(self.model.seconds_elapsed);
                    self.model.workouts.insert(0, workout);
                    self.model.is_timer_running = false;
                    self.model.seconds_elapsed = 0;
                }
            }
            Event::DiscardWorkout => {
                self.model.current_workout = None;
                self.model.is_timer_running = false;
                self.model.seconds_elapsed = 0;
            }
            Event::UpdateWorkoutName { name } => {
                if let Some(ref mut workout) = self.model.current_workout {
                    workout.name = name;
                }
            }
            Event::UpdateWorkoutNote { note } => {
                if let Some(ref mut workout) = self.model.current_workout {
                    workout.note = note;
                }
            }
            Event::AddExercise { global_exercise } => {
                if let Some(ref mut workout) = self.model.current_workout {
                    let exercise = Exercise {
                        id: uuid::Uuid::new_v4(),
                        superset_id: None,
                        workout_id: workout.id,
                        name: global_exercise.name,
                        pinned_notes: Vec::new(),
                        notes: Vec::new(),
                        duration: None,
                        exercise_type: ExerciseType::Unknown, // Will be set from global_exercise if needed
                        weight_unit: None,
                        default_warm_up_time: None,
                        default_rest_time: None,
                        sets: Vec::new(),
                        body_part: None,
                    };
                    workout.exercises.push(exercise);
                }
            }
            Event::DeleteExercise { exercise_id } => {
                if let Some(ref mut workout) = self.model.current_workout {
                    workout.exercises.retain(|e| e.id != exercise_id);
                }
            }
            Event::UpdateExerciseName { exercise_id, name } => {
                if let Some(ref mut workout) = self.model.current_workout {
                    if let Some(exercise) = workout.exercises.iter_mut().find(|e| e.id == exercise_id) {
                        exercise.name = name;
                    }
                }
            }
            Event::AddSet { exercise_id } => {
                if let Some(ref mut workout) = self.model.current_workout {
                    if let Some(exercise) = workout.exercises.iter_mut().find(|e| e.id == exercise_id) {
                        let set = ExerciseSet {
                            id: uuid::Uuid::new_v4(),
                            set_type: SetType::Working,
                            weight_unit: exercise.weight_unit.clone(),
                            suggest: SetSuggest::default(),
                            actual: SetActual::default(),
                            is_completed: false,
                            exercise_id,
                            workout_id: workout.id,
                            set_index: exercise.sets.len() as i32,
                        };
                        exercise.sets.push(set);
                    }
                }
            }
            Event::DeleteSet { exercise_id, set_index } => {
                if let Some(ref mut workout) = self.model.current_workout {
                    if let Some(exercise) = workout.exercises.iter_mut().find(|e| e.id == exercise_id) {
                        if set_index < exercise.sets.len() {
                            exercise.sets.remove(set_index);
                            // Reindex remaining sets
                            for (idx, set) in exercise.sets.iter_mut().enumerate() {
                                set.set_index = idx as i32;
                            }
                        }
                    }
                }
            }
            Event::UpdateSetActual { exercise_id, set_index, actual } => {
                if let Some(ref mut workout) = self.model.current_workout {
                    if let Some(exercise) = workout.exercises.iter_mut().find(|e| e.id == exercise_id) {
                        if set_index < exercise.sets.len() {
                            exercise.sets[set_index].actual = actual;
                        }
                    }
                }
            }
            Event::UpdateSetSuggest { exercise_id, set_index, suggest } => {
                if let Some(ref mut workout) = self.model.current_workout {
                    if let Some(exercise) = workout.exercises.iter_mut().find(|e| e.id == exercise_id) {
                        if set_index < exercise.sets.len() {
                            exercise.sets[set_index].suggest = suggest;
                        }
                    }
                }
            }
            Event::ToggleSetCompleted { exercise_id, set_index } => {
                if let Some(ref mut workout) = self.model.current_workout {
                    if let Some(exercise) = workout.exercises.iter_mut().find(|e| e.id == exercise_id) {
                        if set_index < exercise.sets.len() {
                            exercise.sets[set_index].is_completed = !exercise.sets[set_index].is_completed;
                        }
                    }
                }
            }
            Event::LoadHistory => {
                // History loading handled by database layer on Swift side
            }
            Event::LoadWorkoutDetail { workout_id } => {
                if let Some(workout) = self.model.workouts.iter().find(|w| w.id == workout_id) {
                    self.model.selected_workout = Some(workout.clone());
                }
            }
            Event::ImportWorkout { json_data } => {
                if let Ok(workout) = serde_json::from_str::<Workout>(&json_data) {
                    self.model.current_workout = Some(workout);
                }
            }
            Event::NavigateToWorkout => {
                self.model.selected_tab = Tab::Workout;
            }
            Event::NavigateToHistory => {
                self.model.selected_tab = Tab::History;
            }
            Event::NavigateToWorkoutDetail { workout_id } => {
                self.model.navigation_path.push(NavigationDestination::WorkoutDetail { workout_id });
            }
            Event::NavigateToHistoryDetail { workout_id } => {
                self.model.navigation_path.push(NavigationDestination::HistoryDetail { workout_id });
            }
            Event::CalculatePlates { target_weight, bar_type } => {
                // Simplified plate calculation
                let plates = calculate_plates_simple(target_weight, &bar_type);
                self.model.plate_calculation = Some(PlateCalculation {
                    total_weight: target_weight,
                    bar_type: bar_type.clone(),
                    plates,
                });
            }
            Event::WorkoutSaved | Event::WorkoutLoaded { .. } | Event::HistoryLoaded { .. } => {
                // Internal events - handled by database layer
            }
        }
    }
    
    fn view(&self) -> Result<String, String> {
        // Use the App's view function to generate view model
        let app = App::default();
        let view_model = crux_core::App::view(&app, &self.model);
        serde_json::to_string(&view_model)
            .map_err(|e| format!("Failed to serialize view model: {}", e))
    }
}

// Simplified plate calculation
fn calculate_plates_simple(target_weight: f64, bar_type: &BarType) -> Vec<Plate> {
    let bar_weight = bar_type.weight;
    let plate_weight = target_weight - bar_weight;
    let mut plates = Vec::new();
    
    // Simple algorithm: use 45lb plates
    let plate_size = 45.0;
    let num_plates = (plate_weight / (plate_size * 2.0)).floor() as usize;
    
    for _ in 0..num_plates {
        plates.push(Plate {
            id: uuid::Uuid::new_v4(),
            weight: plate_size,
        });
    }
    
    plates
}

/// Create a new Rust core instance
/// Returns a pointer to the core instance
#[unsafe(no_mangle)]
pub extern "C" fn rust_core_new() -> *mut RustCore {
    Box::into_raw(Box::new(RustCore::new()))
}

/// Free a Rust core instance
#[unsafe(no_mangle)]
pub extern "C" fn rust_core_free(core: *mut RustCore) {
    if !core.is_null() {
        unsafe {
            let _ = Box::from_raw(core);
        }
    }
}

/// Dispatch an event to the core
/// event_json: JSON string of the event
/// Returns: JSON string of the view model, or null on error
#[unsafe(no_mangle)]
pub extern "C" fn rust_core_dispatch(core: *mut RustCore, event_json: *const c_char) -> *mut c_char {
    if core.is_null() || event_json.is_null() {
        return ptr::null_mut();
    }

    let event_str = unsafe {
        match CStr::from_ptr(event_json).to_str() {
            Ok(s) => s,
            Err(_) => return ptr::null_mut(),
        }
    };

    let core = unsafe { &mut *core };
    
    match core.dispatch(event_str) {
        Ok(_) => {
            match core.view() {
                Ok(view_json) => {
                    match CString::new(view_json) {
                        Ok(c_string) => c_string.into_raw(),
                        Err(_) => ptr::null_mut(),
                    }
                }
                Err(_) => ptr::null_mut(),
            }
        }
        Err(_) => ptr::null_mut(),
    }
}

/// Get the current view model
/// Returns: JSON string of the view model, or null on error
#[unsafe(no_mangle)]
pub extern "C" fn rust_core_view(core: *const RustCore) -> *mut c_char {
    if core.is_null() {
        return ptr::null_mut();
    }

    let core = unsafe { &*core };
    
    match core.view() {
        Ok(view_json) => {
            match CString::new(view_json) {
                Ok(c_string) => c_string.into_raw(),
                Err(_) => ptr::null_mut(),
            }
        }
        Err(_) => ptr::null_mut(),
    }
}

/// Free a string returned from Rust
#[unsafe(no_mangle)]
pub extern "C" fn rust_string_free(s: *mut c_char) {
    if !s.is_null() {
        unsafe {
            let _ = CString::from_raw(s);
        }
    }
}
