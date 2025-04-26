import Dependencies
import Sharing
import SwiftUI
import Combine
import SwiftUINavigation

// MARK: - View Models
@MainActor
@Observable
class WorkoutModel: HashableObject {
    @ObservationIgnored @Shared(.workout) var workout: Workout
    @ObservationIgnored @Dependency(\.uuid) var uuid
    
    var elapsedTime: Int = 0
    var isTimerRunning: Bool = true
    
    var exercises: [Exercise] {
        get { workout.exercises }
        set { $workout.withLock { $0.exercises = newValue } }
    }
    
    init(workout: Shared<Workout>? = nil) {
        @Dependency(\.uuid) var uuid
        if let workout {
            _workout = workout
        }
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
        for i in exercises.indices where exercises[i].id == exercise.id {
            let newSet = ExerciseSet(
                id: uuid(),
                type: .working,
                weightUnit: .lb,
                suggest: .init(),
                actual: .init(),
                exerciseId: exercise.id,
                workoutId: workout.id
            )
            
            exercises[i].sets.append(newSet)
            return
        }
    }
    
    // Add a GlobalExercise as a new Exercise to the workout
    func addExercise(from global: GlobalExercise) {
        let newExercise = Exercise(
            id: UUID(),
            supersetId: 0,
            workoutId: global.id,
            name: global.name,
            pinnedNotes: [],
            notes: [],
            duration: nil,
            type: .barbell,
            weightUnit: .lb,
            defaultWarmUpTime: 60,
            defaultRestTime: 60,
            sets: [],
            bodyPart: nil
        )
        // Add as flat exercise
        exercises.append(newExercise)
    }
    
    func importWorkout(from jsonData: Data) {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let importedWorkout = try decoder.decode(Workout.self, from: jsonData)
            $workout.withLock { $0 = importedWorkout }
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
    
    // --- Computed Properties ---
    var totalVolume: Int {
        self.workout.exercises.flatMap { $0.sets }.reduce(0) { sum, set in
            sum + (set.actual.reps ?? 0)
        }
    }

    var totalSets: Int {
        self.workout.exercises.flatMap { $0.sets }.count
    }
}
