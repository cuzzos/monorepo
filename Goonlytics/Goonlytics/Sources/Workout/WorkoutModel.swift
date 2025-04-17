import SwiftUI
import Combine

// MARK: - View Models
class WorkoutModel: ObservableObject {
    @Published var workout: Workout
    @Published var elapsedTime: Int = 1476 // 24:36 in seconds
    @Published var isTimerRunning: Bool = true
    
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
}
