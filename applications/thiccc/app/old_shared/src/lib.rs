use crux_core::render::{render, RenderOperation};
use crux_core::Command;
use serde::{Deserialize, Serialize};
use uuid::Uuid;

mod models;
mod database;

/// Effect enum for the app
#[crux_core::macros::effect]
pub enum Effect {
    Render(RenderOperation),
}

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

/// Capabilities used by the app (deprecated, will be removed in future versions)
#[derive(Default)]
pub struct Capabilities;

impl crux_core::App for App {
    type Event = Event;
    type Model = Model;
    type ViewModel = ViewModel;
    type Capabilities = Capabilities;
    type Effect = Effect;

    fn update(&self, event: Self::Event, model: &mut Self::Model, _caps: &Self::Capabilities) -> Command<Self::Effect, Self::Event> {
        match event {
            Event::StartTimer => {
                model.is_timer_running = true;
                // Timer will be handled by Swift side, sending TimerTick events
                return render();
            }
            
            Event::StopTimer => {
                model.is_timer_running = false;
                return render();
            }
            
            Event::ToggleTimer => {
                model.is_timer_running = !model.is_timer_running;
                return render();
            }
            
            Event::TimerTick => {
                if model.is_timer_running {
                    model.seconds_elapsed += 1;
                    if let Some(ref mut workout) = model.current_workout {
                        workout.duration = Some(model.seconds_elapsed);
                    }
                    return render();
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
                // Call StartTimer which will also render
                return self.update(Event::StartTimer, model, _caps);
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
                    return render();
                }
            }
            
            Event::WorkoutSaved => {
                // Database save completed, no action needed
                return render();
            }
            
            Event::WorkoutLoaded { workout } => {
                model.selected_workout = Some(workout);
                return render();
            }
            
            Event::HistoryLoaded { workouts } => {
                model.workouts = workouts;
                return render();
            }

            Event::DiscardWorkout => {
                model.current_workout = None;
                model.is_timer_running = false;
                model.seconds_elapsed = 0;
                return render();
            }
            
            Event::UpdateWorkoutName { name } => {
                if let Some(ref mut workout) = model.current_workout {
                    workout.name = name;
                    return render();
                }
            }
            
            Event::UpdateWorkoutNote { note } => {
                if let Some(ref mut workout) = model.current_workout {
                    workout.note = note;
                    return render();
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
                    return render();
                }
            }
            
            Event::DeleteExercise { exercise_id } => {
                if let Some(ref mut workout) = model.current_workout {
                    workout.exercises.retain(|e| e.id != exercise_id);
                    return render();
                }
            }
            
            Event::UpdateExerciseName { exercise_id, name } => {
                if let Some(ref mut workout) = model.current_workout {
                    if let Some(exercise) = workout.exercises.iter_mut().find(|e| e.id == exercise_id) {
                        exercise.name = name;
                        return render();
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
                        return render();
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
                            return render();
                        }
                    }
                }
            }
            
            Event::UpdateSetActual { exercise_id, set_index, actual } => {
                if let Some(ref mut workout) = model.current_workout {
                    if let Some(exercise) = workout.exercises.iter_mut().find(|e| e.id == exercise_id) {
                        if let Some(set) = exercise.sets.get_mut(set_index) {
                            set.actual = actual;
                            return render();
                        }
                    }
                }
            }
            
            Event::UpdateSetSuggest { exercise_id, set_index, suggest } => {
                if let Some(ref mut workout) = model.current_workout {
                    if let Some(exercise) = workout.exercises.iter_mut().find(|e| e.id == exercise_id) {
                        if let Some(set) = exercise.sets.get_mut(set_index) {
                            set.suggest = suggest;
                            return render();
                        }
                    }
                }
            }
            
            Event::ToggleSetCompleted { exercise_id, set_index } => {
                if let Some(ref mut workout) = model.current_workout {
                    if let Some(exercise) = workout.exercises.iter_mut().find(|e| e.id == exercise_id) {
                        if let Some(set) = exercise.sets.get_mut(set_index) {
                            set.is_completed = !set.is_completed;
                            return render();
                        }
                    }
                }
            }
            
            Event::LoadHistory => {
                // Request to load history - shell will handle database query
                // and send HistoryLoaded event back
                return render();
            }
            
            Event::LoadWorkoutDetail { workout_id } => {
                // Request to load workout detail - shell will handle database query
                // and send WorkoutLoaded event back
                // For now, try to find in existing workouts
                if let Some(workout) = model.workouts.iter().find(|w| w.id == workout_id) {
                    model.selected_workout = Some(workout.clone());
                    return render();
                }
            }
            
            Event::ImportWorkout { json_data } => {
                if let Ok(workout) = serde_json::from_str::<Workout>(&json_data) {
                    model.current_workout = Some(workout);
                    return render();
                }
            }
            
            Event::NavigateToWorkout => {
                model.selected_tab = Tab::Workout;
                return render();
            }
            
            Event::NavigateToHistory => {
                model.selected_tab = Tab::History;
                return render();
            }
            
            Event::NavigateToWorkoutDetail { workout_id } => {
                model.navigation_path.push(NavigationDestination::WorkoutDetail { workout_id });
                return render();
            }
            
            Event::NavigateToHistoryDetail { workout_id } => {
                model.navigation_path.push(NavigationDestination::HistoryDetail { workout_id });
                return self.update(Event::LoadWorkoutDetail { workout_id }, model, _caps);
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
                return render();
            }
            
        }
        
        Command::done()
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

// MARK: - UniFFI Integration

use std::sync::Mutex;

/// Error type for UniFFI FFI operations
#[derive(Debug, thiserror::Error)]
pub enum CoreError {
    #[error("Serialization error: {0}")]
    SerializationError(String),
    #[error("Deserialization error: {0}")]
    DeserializationError(String),
    #[error("Event processing error: {0}")]
    EventProcessingError(String),
}

/// Global core state (thread-safe)
static CORE_STATE: Mutex<Option<CoreState>> = Mutex::new(None);

struct CoreState {
    model: Model,
}

/// Process an event and return the updated view model
pub fn process_event(msg: &[u8]) -> Result<Vec<u8>, CoreError> {
    let event: Event = serde_json::from_slice(msg)
        .map_err(|e| CoreError::DeserializationError(e.to_string()))?;

    let mut state = CORE_STATE.lock().unwrap();
    if state.is_none() {
        *state = Some(CoreState {
            model: Model::default(),
        });
    }

    let core_state = state.as_mut().unwrap();
    let app = App::default();

    // Update the model with the event
    let caps = Capabilities::default();
    let _command = crux_core::App::update(&app, event, &mut core_state.model, &caps);

    // Generate and serialize the view model
    let view_model = crux_core::App::view(&app, &core_state.model);
    serde_json::to_vec(&view_model)
        .map_err(|e| CoreError::SerializationError(e.to_string()))
}

/// Get the current view model without processing an event
pub fn view() -> Result<Vec<u8>, CoreError> {
    let state = CORE_STATE.lock().unwrap();

    let app = App::default();
    let view_model = if let Some(core_state) = state.as_ref() {
        crux_core::App::view(&app, &core_state.model)
    } else {
        let default_model = Model::default();
        crux_core::App::view(&app, &default_model)
    };

    serde_json::to_vec(&view_model)
        .map_err(|e| CoreError::SerializationError(e.to_string()))
}

/// Handle a capability response (for future use with full Crux capabilities)
pub fn handle_response(_id: u32, _res: &[u8]) -> Result<Vec<u8>, CoreError> {
    // For now, just return the current view
    // In the future, this would process capability responses
    view()
}

// Include UniFFI scaffolding
uniffi::include_scaffolding!("shared");

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
