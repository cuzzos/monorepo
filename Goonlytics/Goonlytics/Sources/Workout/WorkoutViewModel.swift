import SwiftUI
import Combine

// MARK: - View Models
class WorkoutViewModel: ObservableObject {
    @Published var workout: Workout
    @Published var elapsedTime: Int = 1476 // 24:36 in seconds
    @Published var isTimerRunning: Bool = true
    
    var exercises: [Exercise] {
        get {
            workout.exercises
        }
        set {
            workout.exercises = newValue
        }
    }
    
    init(workout: Workout? = nil) {
        self.workout = workout ?? Workout(exercises: [])
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
        guard let exerciseIndex = exercises.firstIndex(where: { $0.id == exercise.id }) else { return }
        
        let lastSet = exercises[exerciseIndex].sets.last
        let newSet = ExerciseSet(
            type: "Working",
            suggestedWeight: lastSet?.suggestedWeight ?? 0,
            suggestedReps: lastSet?.suggestedReps ?? 0,
            suggestedRPE: lastSet?.suggestedRPE ?? 0,
            actualWeight: lastSet?.actualWeight,
            actualReps: lastSet?.actualReps,
            actualRPE: nil,
            isCompleted: false
        )
        
        exercises[exerciseIndex].sets.append(newSet)
    }
    
    func addExercise() {
        // Add a new exercise with one empty set
        let newExercise = Exercise(
            exerciseId: UUID().uuidString,
            exerciseName: "New Exercise",
            sets: [
                ExerciseSet(
                    type: "Working",
                    suggestedWeight: 0,
                    suggestedReps: 0,
                    suggestedRPE: 0,
                    actualWeight: nil,
                    actualReps: nil,
                    actualRPE: nil,
                    isCompleted: false
                )
            ],
            weightUnit: "lbs",
            warmUpTime: 60,
            restTime: 60
        )
        
        exercises.append(newExercise)
    }
    
    func importWorkout(from jsonData: Data) {
        do {
            let decoder = JSONDecoder()
            let exerciseGroups = try decoder.decode([[Exercise]].self, from: jsonData)
            
            // Process each exercise group
            var allExercises: [Exercise] = []
            
            for (groupIndex, group) in exerciseGroups.enumerated() {
                let groupId = UUID()
                
                // If there's more than one exercise in a group, they form a superset
                let isSuperset = group.count > 1
                
                for var exercise in group {
                    // Tag exercises with group information
                    exercise.groupId = groupId
                    exercise.isPartOfSuperset = isSuperset
                    
                    allExercises.append(exercise)
                }
            }
            
            // Create a single workout with all exercises
            self.workout = Workout(exercises: allExercises)
            
            // Notify any observers that we've updated the data
            objectWillChange.send()
        } catch {
            print("Error importing workout: \(error)")
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