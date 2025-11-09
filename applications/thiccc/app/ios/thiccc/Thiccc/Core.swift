//
//  Core.swift
//  Thiccc
//
//  Swift bridge to Rust/Crux core
//

import Foundation
import Combine

// MARK: - Event Types (matching Rust Event enum)
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

// MARK: - ViewModel (matching Rust ViewModel struct)
struct ViewModel: Codable, Equatable {
    var workout: WorkoutViewModel?
    var isTimerRunning: Bool
    var formattedTime: String
    var totalVolume: Int
    var totalSets: Int
    var workouts: [WorkoutListItem]
    var selectedTab: Tab
    var navigationPath: [NavigationDestination]
    var plateCalculation: PlateCalculation?
}

struct WorkoutViewModel: Codable, Equatable {
    var id: UUID
    var name: String
    var note: String?
    var duration: Int?
    var exercises: [ExerciseViewModel]
}

struct ExerciseViewModel: Codable, Equatable, Identifiable {
    var id: UUID
    var name: String
    var exerciseType: ExerciseType
    var weightUnit: WeightUnit?
    var sets: [ExerciseSetViewModel]
    var isCompleted: Bool
}

struct ExerciseSetViewModel: Codable, Equatable {
    var id: UUID
    var setType: SetType
    var weightUnit: WeightUnit?
    var suggest: ExerciseSet.Suggest
    var actual: ExerciseSet.Actual
    var isCompleted: Bool
    var setIndex: Int
}

struct WorkoutListItem: Codable, Equatable {
    var id: UUID
    var name: String
    var startTimestamp: Int64
}

enum Tab: String, Codable, Equatable {
    case workout
    case history
}

enum NavigationDestination: Codable, Equatable {
    case workoutDetail(workoutId: UUID)
    case historyDetail(workoutId: UUID)
}

// MARK: - Rust Core Bridge
/// Bridge to Rust/Crux core
/// For now, this is a mock implementation. In production, this would call into the actual Rust FFI.
class RustCore: ObservableObject {
    @Published var viewModel: ViewModel
    
    // Internal model state (managed by Swift side for now)
    private var model: Model
    
    init() {
        self.model = Model()
        // Initialize with default ViewModel, will be updated on first event
        self.viewModel = ViewModel(
            workout: nil,
            isTimerRunning: false,
            formattedTime: "0:00",
            totalVolume: 0,
            totalSets: 0,
            workouts: [],
            selectedTab: .workout,
            navigationPath: [],
            plateCalculation: nil
        )
    }
    
    /// Dispatch an event to the core
    func dispatch(_ event: Event) {
        // For now, process events in Swift
        // In production, this would serialize to JSON and call Rust FFI
        processEvent(event)
        viewModel = getViewModel()
    }
    
    private func processEvent(_ event: Event) {
        // Mock implementation - in production, this would call Rust
        switch event {
        case .startTimer:
            model.isTimerRunning = true
        case .stopTimer:
            model.isTimerRunning = false
        case .toggleTimer:
            model.isTimerRunning.toggle()
        case .timerTick:
            if model.isTimerRunning {
                model.secondsElapsed += 1
                if var workout = model.currentWorkout {
                    workout.duration = model.secondsElapsed
                    model.currentWorkout = workout
                }
            }
        case .createWorkout(let name):
            let workout = Workout(
                id: UUID(),
                name: name,
                note: nil,
                duration: 0,
                startTimestamp: Date(),
                endTimestamp: nil,
                exercises: []
            )
            model.currentWorkout = workout
            model.secondsElapsed = 0
            model.isTimerRunning = true
        case .finishWorkout:
            if var workout = model.currentWorkout {
                workout.endTimestamp = Date()
                workout.duration = model.secondsElapsed
                model.workouts.insert(workout, at: 0)
                model.currentWorkout = nil
                model.isTimerRunning = false
                model.secondsElapsed = 0
            }
        case .discardWorkout:
            model.currentWorkout = nil
            model.isTimerRunning = false
            model.secondsElapsed = 0
        case .updateWorkoutName(let name):
            if var workout = model.currentWorkout {
                workout.name = name
                model.currentWorkout = workout
            }
        case .updateWorkoutNote(let note):
            if var workout = model.currentWorkout {
                workout.note = note
                model.currentWorkout = workout
            }
        case .addExercise(let globalExercise):
            if var workout = model.currentWorkout {
                let exercise = Exercise(
                    id: UUID(),
                    supersetId: nil,
                    workoutId: workout.id,
                    name: globalExercise.name,
                    pinnedNotes: [],
                    notes: [],
                    duration: nil,
                    type: ExerciseType(rawValue: globalExercise.type) ?? .unknown,
                    weightUnit: .lb,
                    defaultWarmUpTime: 60,
                    defaultRestTime: 60,
                    sets: [],
                    bodyPart: nil
                )
                workout.exercises.append(exercise)
                model.currentWorkout = workout
            }
        case .deleteExercise(let exerciseId):
            if var workout = model.currentWorkout {
                workout.exercises.removeAll { $0.id == exerciseId }
                model.currentWorkout = workout
            }
        case .updateExerciseName(let exerciseId, let name):
            if var workout = model.currentWorkout,
               let index = workout.exercises.firstIndex(where: { $0.id == exerciseId }) {
                workout.exercises[index] = Exercise(
                    id: workout.exercises[index].id,
                    supersetId: workout.exercises[index].supersetId,
                    workoutId: workout.exercises[index].workoutId,
                    name: name,
                    pinnedNotes: workout.exercises[index].pinnedNotes,
                    notes: workout.exercises[index].notes,
                    duration: workout.exercises[index].duration,
                    type: workout.exercises[index].type,
                    weightUnit: workout.exercises[index].weightUnit,
                    defaultWarmUpTime: workout.exercises[index].defaultWarmUpTime,
                    defaultRestTime: workout.exercises[index].defaultRestTime,
                    sets: workout.exercises[index].sets,
                    bodyPart: workout.exercises[index].bodyPart
                )
                model.currentWorkout = workout
            }
        case .addSet(let exerciseId):
            if var workout = model.currentWorkout,
               let exerciseIndex = workout.exercises.firstIndex(where: { $0.id == exerciseId }) {
                let set = ExerciseSet(
                    id: UUID(),
                    type: .working,
                    weightUnit: workout.exercises[exerciseIndex].weightUnit,
                    suggest: ExerciseSet.Suggest(),
                    actual: ExerciseSet.Actual(),
                    isCompleted: false,
                    exerciseId: exerciseId,
                    workoutId: workout.id,
                    setIndex: workout.exercises[exerciseIndex].sets.count
                )
                workout.exercises[exerciseIndex].sets.append(set)
                model.currentWorkout = workout
            }
        case .deleteSet(let exerciseId, let setIndex):
            if var workout = model.currentWorkout,
               let exerciseIndex = workout.exercises.firstIndex(where: { $0.id == exerciseId }),
               setIndex < workout.exercises[exerciseIndex].sets.count {
                workout.exercises[exerciseIndex].sets.remove(at: setIndex)
                // Reindex remaining sets
                for (idx, _) in workout.exercises[exerciseIndex].sets.enumerated() {
                    workout.exercises[exerciseIndex].sets[idx].setIndex = idx
                }
                model.currentWorkout = workout
            }
        case .updateSetActual(let exerciseId, let setIndex, let actual):
            if var workout = model.currentWorkout,
               let exerciseIndex = workout.exercises.firstIndex(where: { $0.id == exerciseId }),
               setIndex < workout.exercises[exerciseIndex].sets.count {
                workout.exercises[exerciseIndex].sets[setIndex].actual = ExerciseSet.Actual(
                    weight: actual.weight,
                    reps: actual.reps,
                    duration: actual.duration,
                    rpe: actual.rpe,
                    actualRestTime: actual.actualRestTime
                )
                model.currentWorkout = workout
            }
        case .updateSetSuggest(let exerciseId, let setIndex, let suggest):
            if var workout = model.currentWorkout,
               let exerciseIndex = workout.exercises.firstIndex(where: { $0.id == exerciseId }),
               setIndex < workout.exercises[exerciseIndex].sets.count {
                workout.exercises[exerciseIndex].sets[setIndex].suggest = ExerciseSet.Suggest(
                    weight: suggest.weight,
                    reps: suggest.reps,
                    repRange: suggest.repRange,
                    duration: suggest.duration,
                    rpe: suggest.rpe,
                    restTime: suggest.restTime
                )
                model.currentWorkout = workout
            }
        case .toggleSetCompleted(let exerciseId, let setIndex):
            if var workout = model.currentWorkout,
               let exerciseIndex = workout.exercises.firstIndex(where: { $0.id == exerciseId }),
               setIndex < workout.exercises[exerciseIndex].sets.count {
                workout.exercises[exerciseIndex].sets[setIndex].isCompleted.toggle()
                model.currentWorkout = workout
            }
        case .loadHistory:
            // History loading will be handled by database layer
            break
        case .loadWorkoutDetail(let workoutId):
            if let workout = model.workouts.first(where: { $0.id == workoutId }) {
                model.selectedWorkout = workout
            }
        case .importWorkout(let jsonData):
            if let data = jsonData.data(using: .utf8),
               let workout = try? JSONDecoder().decode(Workout.self, from: data) {
                model.currentWorkout = workout
            }
        case .navigateToWorkout:
            model.selectedTab = .workout
        case .navigateToHistory:
            model.selectedTab = .history
        case .navigateToWorkoutDetail(let workoutId):
            model.navigationPath.append(.workoutDetail(workoutId: workoutId))
        case .navigateToHistoryDetail(let workoutId):
            model.navigationPath.append(.historyDetail(workoutId: workoutId))
        case .calculatePlates(let targetWeight, let barType):
            // Plate calculation logic
            let weightPerSide = (targetWeight - barType.weight) / 2.0
            var remainingWeight = weightPerSide
            var plates: [Plate] = []
            
            for plate in Plate.standard {
                while remainingWeight >= plate.weight {
                    plates.append(Plate(weight: plate.weight))
                    remainingWeight -= plate.weight
                }
            }
            
            model.plateCalculation = PlateCalculation(
                totalWeight: targetWeight,
                barType: barType,
                plates: plates
            )
        case .workoutSaved, .workoutLoaded, .historyLoaded:
            // Database events handled elsewhere
            break
        }
    }
    
    private func getViewModel() -> ViewModel {
        return Self.getViewModel(from: model)
    }
    
    private static func getViewModel(from model: Model) -> ViewModel {
        let minutes = model.secondsElapsed / 60
        let seconds = model.secondsElapsed % 60
        let formattedTime = String(format: "%d:%02d", minutes, seconds)
        
        let workoutVM = model.currentWorkout.map { w in
            WorkoutViewModel(
                id: w.id,
                name: w.name,
                note: w.note,
                duration: w.duration,
                exercises: w.exercises.map { e in
                    ExerciseViewModel(
                        id: e.id,
                        name: e.name,
                        exerciseType: e.type,
                        weightUnit: e.weightUnit,
                        sets: e.sets.map { s in
                            ExerciseSetViewModel(
                                id: s.id,
                                setType: s.type,
                                weightUnit: s.weightUnit,
                                suggest: s.suggest,
                                actual: s.actual,
                                isCompleted: s.isCompleted,
                                setIndex: s.setIndex
                            )
                        },
                        isCompleted: e.isCompleted
                    )
                }
            )
        }
        
        let workouts = model.workouts.map { w in
            WorkoutListItem(
                id: w.id,
                name: w.name,
                startTimestamp: Int64(w.startTimestamp.timeIntervalSince1970)
            )
        }
        
        let totalVolume = model.currentWorkout?.exercises.flatMap { $0.sets }.reduce(0) { $0 + ($1.actual.reps ?? 0) } ?? 0
        let totalSets = model.currentWorkout?.exercises.flatMap { $0.sets }.count ?? 0
        
        return ViewModel(
            workout: workoutVM,
            isTimerRunning: model.isTimerRunning,
            formattedTime: formattedTime,
            totalVolume: totalVolume,
            totalSets: totalSets,
            workouts: workouts,
            selectedTab: model.selectedTab,
            navigationPath: model.navigationPath,
            plateCalculation: model.plateCalculation
        )
    }
}

// MARK: - Internal Model (matches Rust Model)
private struct Model {
    var currentWorkout: Workout?
    var isTimerRunning: Bool = false
    var secondsElapsed: Int = 0
    var workouts: [Workout] = []
    var selectedWorkout: Workout?
    var selectedTab: Tab = .workout
    var navigationPath: [NavigationDestination] = []
    var plateCalculation: PlateCalculation?
}

// MARK: - Future FFI Integration
/*
 When ready to integrate with actual Rust core:
 
 1. Build Rust as static library:
    cargo build --release --target aarch64-apple-ios
    cargo build --release --target x86_64-apple-ios-sim
 
 2. Add library to Xcode:
    - Add libshared.a to project
    - Configure library search paths
    
 3. Create bridging header for C FFI:
    - Use cbindgen to generate C header from Rust
    - Import in bridging header
    
 4. Replace RustCore implementation with FFI calls:
    - Serialize events to JSON
    - Call Rust functions via FFI
    - Deserialize view models from JSON
    - Handle memory management (allocate/free)
 */
