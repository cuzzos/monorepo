import Foundation

// MARK: - Event Enum
// Matches Rust Event enum in app/shared/src/lib.rs
// Serialized with camelCase naming

enum Event: Codable {
    // Timer events
    case startTimer
    case stopTimer
    case toggleTimer
    case timerTick
    
    // Workout events
    case createWorkout(name: String)
    case finishWorkout
    case discardWorkout
    case updateWorkoutName(name: String)
    case updateWorkoutNote(note: String?)
    
    // Exercise events
    case addExercise(globalExercise: GlobalExercise)
    case deleteExercise(exerciseId: UUID)
    case updateExerciseName(exerciseId: UUID, name: String)
    
    // Set events
    case addSet(exerciseId: UUID)
    case deleteSet(exerciseId: UUID, setIndex: Int)
    case updateSetActual(exerciseId: UUID, setIndex: Int, actual: SetActual)
    case updateSetSuggest(exerciseId: UUID, setIndex: Int, suggest: SetSuggest)
    case toggleSetCompleted(exerciseId: UUID, setIndex: Int)
    
    // History events
    case loadHistory
    case loadWorkoutDetail(workoutId: UUID)
    case importWorkout(jsonData: String)
    
    // Navigation events
    case navigateToWorkout
    case navigateToHistory
    case navigateToWorkoutDetail(workoutId: UUID)
    case navigateToHistoryDetail(workoutId: UUID)
    
    // Plate calculator events
    case calculatePlates(targetWeight: Double, barType: BarType)
    
    // Database events (internal)
    case workoutSaved
    case workoutLoaded(workout: Workout)
    case historyLoaded(workouts: [Workout])
}

// MARK: - Tab Enum
enum Tab: String, Codable {
    case workout
    case history
}

// MARK: - NavigationDestination Enum
enum NavigationDestination: Codable, Hashable {
    case workoutDetail(workoutId: UUID)
    case historyDetail(workoutId: UUID)
}

// MARK: - ViewModel
struct ViewModel: Codable {
    // Workout view model
    let workout: WorkoutViewModel?
    let isTimerRunning: Bool
    let formattedTime: String
    let totalVolume: Int
    let totalSets: Int
    
    // History view model
    let workouts: [WorkoutListItem]
    
    // Navigation
    let selectedTab: Tab
    let navigationPath: [NavigationDestination]
    
    // Plate calculator
    let plateCalculation: PlateCalculation?
}

// MARK: - ViewModel Subtypes
struct WorkoutViewModel: Codable {
    let id: UUID
    let name: String
    let note: String?
    let duration: Int?
    let exercises: [ExerciseViewModel]
}

struct ExerciseViewModel: Codable {
    let id: UUID
    let name: String
    let exerciseType: ExerciseType
    let weightUnit: WeightUnit?
    let sets: [ExerciseSetViewModel]
    let isCompleted: Bool
}

struct ExerciseSetViewModel: Codable {
    let id: UUID
    let setType: SetType
    let weightUnit: WeightUnit?
    let suggest: SetSuggest
    let actual: SetActual
    let isCompleted: Bool
    let setIndex: Int
}

struct WorkoutListItem: Codable {
    let id: UUID
    let name: String
    let startTimestamp: Int64 // Unix timestamp
}

// Note: SetActual, SetSuggest, GlobalExercise, and PlateCalculation are defined in Workout.swift and PlateCalculation.swift

