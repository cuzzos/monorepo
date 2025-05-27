import Dependencies
import IdentifiedCollections
import Sharing
import SwiftUI
import Combine
import SwiftUINavigation
import SharingGRDB

// MARK: - View Models
@MainActor
@Observable
class WorkoutModel: HashableObject {
    @ObservationIgnored @Shared(.workout) var workout: Workout
    @ObservationIgnored @Dependency(\.uuid) var uuid
    @ObservationIgnored @Dependency(\.defaultDatabase) var database
    @ObservationIgnored @Dependency(\.continuousClock) var clock
    @ObservationIgnored @Dependency(\.date.now) var now
    
    var isTimerRunning: Bool = true
    private var timerTask: Task<Void, Never>?
    
    var exercises: IdentifiedArrayOf<Exercise> {
        get { workout.exercises }
        set { $workout.withLock { $0.exercises = newValue } }
    }
    
    var secondsElapsed: Int = 0
    
    init(workout: Shared<Workout>? = nil) {
        @Dependency(\.uuid) var uuid
        if let workout {
            _workout = workout
        }
    }

    func formatTime() -> String {
        let minutes = secondsElapsed / 60
        let seconds = secondsElapsed % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    func startTimer() {
        guard timerTask == nil else { return }
        isTimerRunning = true
        
        timerTask = Task { @MainActor in
            for await _ in clock.timer(interval: .seconds(1)) {
                guard isTimerRunning else { break }
                secondsElapsed += 1
                $workout.withLock {
                    $0.duration = secondsElapsed
                }
            }
        }
    }
    
    func stopTimer() {
        isTimerRunning = false
        timerTask?.cancel()
        timerTask = nil
    }
    
    func toggleTimer() {
        if isTimerRunning {
            stopTimer()
        } else {
            startTimer()
        }
    }
    
    func finishWorkout() {
        $workout.withLock { workout in
            workout.endTimestamp = now
        }
        
        // Save workout to database
        withErrorReporting {
            try database.write { db in
                // Debug: Print the workout ID
                print("Inserting workout with ID: \(workout.id)")
                
                // Save the workout first
                try Workout.insert(workout).execute(db)
                
                // Save all exercises and their sets
                for exercise in workout.exercises {
                    print("Inserting exercise with workoutId: \(exercise.workoutId), workout.id: \(workout.id)")
                    try Exercise.insert(exercise).execute(db)
                    
                    // Save all sets for this exercise
                    for exerciseSet in exercise.sets {
                        try ExerciseSet.insert(exerciseSet).execute(db)
                    }
                }
            }
        }
        
        print("Workout finished and saved to database")
        
        // Clear the current workout
        clearCurrentWorkout()
    }
    
    func discardWorkout() {
        // Simply clear the current workout without saving to database
        clearCurrentWorkout()
        print("Workout discarded")
    }
    
    private func clearCurrentWorkout() {
        // Stop the timer
        stopTimer()
        
        // Delete the current workout JSON file from filesystem
        let workoutFileURL = URL.documentsDirectory.appending(component: "current-workout.json")
        do {
            if FileManager.default.fileExists(atPath: workoutFileURL.path) {
                try FileManager.default.removeItem(at: workoutFileURL)
                print("Current workout file deleted from filesystem")
            }
        } catch {
            print("Error deleting current workout file: \(error)")
        }
    }
    
    func addSet(to exercise: Exercise) {
        for i in exercises.indices where exercises[i].id == exercise.id {
            let setIndex = exercises[i].sets.count
            let newSet = ExerciseSet(
                id: uuid(),
                type: .working,
                weightUnit: .lb,
                suggest: .init(),
                actual: .init(),
                exerciseId: exercise.id,
                workoutId: workout.id,
                setIndex: setIndex
            )
            
            exercises[i].sets.append(newSet)
            return
        }
    }
    
    func deleteSet(exercise: Exercise, at offsets: IndexSet) {
        $workout.withLock {
            $0.exercises[id: exercise.id]?.sets.remove(atOffsets: offsets)
        }
    }
    
    func deleteExercise(exerciseId: UUID) {
        $workout.withLock { $0.exercises.removeAll { $0.id == exerciseId } }
        
    }
    
    // Add a GlobalExercise as a new Exercise to the workout
    func addExercise(from global: GlobalExercise) {
        let newExercise = Exercise(
            id: UUID(),
            supersetId: 0,
            workoutId: workout.id,
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
