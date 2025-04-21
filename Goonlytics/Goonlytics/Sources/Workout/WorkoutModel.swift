import SwiftUI
import Combine
import SwiftUINavigation

// MARK: - View Models
@MainActor
@Observable
class WorkoutModel: HashableObject {
    var workout: Workout
    var elapsedTime: Int = 0
    var isTimerRunning: Bool = true
    
    var exercises: [[Exercise]] {
        get {
            workout.exercises
        }
        set {
            workout.exercises = newValue
        }
    }
    
    init(workout: Workout? = nil) {
        self.workout = workout ?? Workout(
            id: UUID().uuidString,
            name: "New Workout",
            note: nil,
            duration: nil,
            startTimestamp: .now,
            endTimestamp: nil,
            exercises: [[]]
        )
    }
    
    func formatTime() -> String {
        let minutes = elapsedTime / 60
        let seconds = elapsedTime % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    func toggleTimer() {
        isTimerRunning.toggle()
    }
    
    func finishWorkout() {
        // Handle workout completion
        print("Workout finished")
    }
    
    func addSet(to exercise: Exercise) {
        for (groupIndex, group) in exercises.enumerated() {
            if let exerciseIndex = group.firstIndex(where: { $0.id == exercise.id }) {
                let lastSet = exercises[groupIndex][exerciseIndex].sets.last
                
                let newSuggest = SetSuggest(
                    weight: lastSet?.suggest?.weight ?? 0,
                    reps: lastSet?.suggest?.reps ?? 0,
                    repRange: lastSet?.suggest?.repRange,
                    duration: lastSet?.suggest?.duration,
                    rpe: lastSet?.suggest?.rpe,
                    restTime: lastSet?.suggest?.restTime
                )
                
                let newSet = ExerciseSet(
                    type: .working,
                    weightUnit: lastSet?.weightUnit ?? .kg,
                    suggest: newSuggest,
                    actual: nil
                )
                
                exercises[groupIndex][exerciseIndex].sets.append(newSet)
                break
            }
        }
    }
    
    func addExercise() {
        // Add a new exercise with one empty set
        let suggest = SetSuggest(
            weight: 0,
            reps: 0,
            repRange: nil,
            duration: nil,
            rpe: nil,
            restTime: 60
        )
        
        let newExercise = Exercise(
            id: UUID().uuidString,
            workoutId: workout.id,
            name: "New Exercise",
            pinnedNotes: [],
            notes: [],
            duration: nil,
            type: .barbell,
            weightUnit: .kg,
            defaultWarmUpTime: 60,
            defaultRestTime: 60,
            sets: [
                ExerciseSet(
                    type: .working,
                    weightUnit: .kg,
                    suggest: suggest,
                    actual: nil
                )
            ],
            bodyPart: nil
        )
        
        // Add to the first group
        if exercises.isEmpty {
            exercises.append([newExercise])
        } else {
            exercises[0].append(newExercise)
        }
    }
    
    // Add a GlobalExercise as a new Exercise to the workout
    func addExercise(from global: GlobalExercise) {
        let newExercise = Exercise(
            id: UUID().uuidString,
            workoutId: workout.id,
            name: global.name,
            pinnedNotes: [],
            notes: [],
            duration: nil,
            type: .init(rawValue: global.type) ?? .unknown,
            weightUnit: .kg,
            defaultWarmUpTime: 60,
            defaultRestTime: 60,
            sets: [ExerciseSet(
                type: .working,
                weightUnit: .kg,
                suggest: SetSuggest(weight: 0, reps: 0, repRange: nil, duration: nil, rpe: nil, restTime: 60),
                actual: nil
            )],
            bodyPart: nil,
            groupIndex: 0
        )
        // Add as superset of 1
        exercises.append([newExercise])
    }
    
    func importWorkout(from jsonData: Data) {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let importedWorkout = try decoder.decode(Workout.self, from: jsonData)
            self.workout = importedWorkout
        } catch {
            print("Error importing workout:", error)
        }
    }
    
    func importWorkout(from jsonString: String) {
        guard let jsonData = jsonString.data(using: .utf8) else {
            print("Failed to convert string to data")
            return
        }
        
        importWorkout(from: jsonData)
    }
    
    // Method to load workout from a file
    func loadWorkoutFile() {
        do {
            if let fileURL = Bundle.main.url(forResource: "workout_template", withExtension: "json") {
                let jsonData = try Data(contentsOf: fileURL)
                importWorkout(from: jsonData)
            } else {
                print("Workout template file not found")
            }
        } catch {
            print("Error loading workout file: \(error)")
        }
    }
    
    // --- Set Editing Methods ---
    func updateReps(for exerciseIndex: Int, setIndex: Int, reps: Int) {
        guard exercises.indices.contains(exerciseIndex),
              exercises[exerciseIndex].indices.contains(0),
              exercises[exerciseIndex][0].sets.indices.contains(setIndex)
        else { return }
        let group = exerciseIndex
        let exercise = 0
        var set = exercises[group][exercise].sets[setIndex]
        var actual = set.actual ?? SetActual()
        actual.reps = reps
        set.actual = actual
        exercises[group][exercise].sets[setIndex] = set
    }
    
    func updateRPE(for exerciseIndex: Int, setIndex: Int, rpe: Double) {
        guard exercises.indices.contains(exerciseIndex),
              exercises[exerciseIndex].indices.contains(0),
              exercises[exerciseIndex][0].sets.indices.contains(setIndex)
        else { return }
        let group = exerciseIndex
        let exercise = 0
        var set = exercises[group][exercise].sets[setIndex]
        var actual = set.actual ?? SetActual()
        actual.rpe = rpe
        set.actual = actual
        exercises[group][exercise].sets[setIndex] = set
    }
    
    func toggleSetCompleted(for exerciseIndex: Int, setIndex: Int) {
        guard exercises.indices.contains(exerciseIndex),
              exercises[exerciseIndex].indices.contains(0),
              exercises[exerciseIndex][0].sets.indices.contains(setIndex)
        else { return }
        let group = exerciseIndex
        let exercise = 0
        exercises[group][exercise].sets[setIndex].isCompleted.toggle()
    }
    
    // --- Computed Properties ---
    var totalVolume: Int {
        self.workout.exercises.flatMap { $0 }.flatMap { $0.sets }.reduce(0) { sum, set in
            let reps = set.actual?.reps ?? set.suggest?.reps ?? 0
            let weight = Int(set.actual?.weight ?? set.suggest?.weight ?? 0)
            return sum + (reps * weight)
        }
    }

    var totalSets: Int {
        self.workout.exercises.flatMap { $0 }.flatMap { $0.sets }.count
    }
}
