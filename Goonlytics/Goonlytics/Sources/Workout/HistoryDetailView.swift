import SwiftUI
import SwiftUINavigation
import GRDB
import Dependencies
import UniformTypeIdentifiers

@MainActor
@Observable
final class HistoryDetailModel: HashableObject {
    var workout: Workout
    var showingNotes: Bool = false
    var showingExportAlert: Bool = false
    var exportMessage: String = ""
    var exportedFileURL: URL?
    var isShowingShareSheet: Bool = false
    
    init(workout: Workout) {
        self.workout = workout
        logWorkoutData()
    }
    
    private func logWorkoutData() {
        print("=== WORKOUT DATA LOADED ===")
        print("Workout: \(workout.name)")
        print("Start time: \(workout.startTimestamp)")
        
        Task {
            do {
                @Dependency(\.defaultDatabase) var database
                
                // Query the entire database to see all records
                print("\n=== DUMPING ENTIRE DATABASE CONTENT ===")
                
                try await database.read { db in
                    // Get all workouts
                    print("\n=== ALL WORKOUTS ===")
                    let workouts = try Workout.fetchAll(db)
                    print("Total workouts: \(workouts.count)")
                    
                    for (i, workout) in workouts.enumerated() {
                        print("\n[Workout \(i+1)]")
                        print("ID: \(workout.id)")
                        print("Name: \(workout.name)")
                        print("Start time: \(workout.startTimestamp)")
                        print("End time: \(workout.endTimestamp ?? Date())")
                        print("Duration: \(workout.duration ?? 0) seconds")
                        print("Note: \(workout.note ?? "None")")
                    }
                    
                    // Get all exercises
                    print("\n=== ALL EXERCISES ===")
                    let exercises = try Exercise.fetchAll(db)
                    print("Total exercises: \(exercises.count)")
                    
                    for (i, exercise) in exercises.enumerated() {
                        print("\n[Exercise \(i+1)]")
                        print("ID: \(exercise.id)")
                        print("Workout ID: \(exercise.workoutId)")
                        print("Name: \(exercise.name)")
                        print("Group index: \(exercise.groupIndex)")
                        print("Type: \(exercise.type.rawValue)")
                        print("Weight unit: \(exercise.weightUnit?.rawValue ?? "None")")
                    }
                    
                    // Get all exercise sets
                    print("\n=== ALL EXERCISE SETS ===")
                    let sets = try ExerciseSet.fetchAll(db)
                    print("Total sets: \(sets.count)")
                    
                    for (i, set) in sets.enumerated() {
                        print("\n[Set \(i+1)]")
                        print("Exercise ID: \(set.exerciseId)")
                        print("Set index: \(set.setIndex)")
                        print("Type: \(set.type.rawValue)")
                        print("Weight unit: \(set.weightUnit?.rawValue ?? "None")")
                        
                        if let suggest = set.suggest {
                            print("Suggest - Weight: \(suggest.weight ?? 0)")
                            print("Suggest - Reps: \(suggest.reps ?? 0)")
                            print("Suggest - RPE: \(suggest.rpe ?? 0)")
                        } else {
                            print("Suggest: None")
                        }
                        
                        print("Completed: \(set.isCompleted)")
                    }
                    
                    // Print raw SQL query results for more detailed debugging
                    print("\n=== RAW SQL QUERY RESULTS ===")
                    
                    print("\n[Workouts table]")
                    let workoutsRows = try Row.fetchAll(db, sql: "SELECT * FROM workout")
                    for row in workoutsRows {
                        print(row.description)
                    }
                    
                    print("\n[Exercises table]")
                    let exercisesRows = try Row.fetchAll(db, sql: "SELECT * FROM exercise")
                    for row in exercisesRows {
                        print(row.description)
                    }
                    
                    print("\n[Exercise sets table]")
                    let setsRows = try Row.fetchAll(db, sql: "SELECT * FROM exerciseSet")
                    for row in setsRows {
                        print(row.description)
                    }
                }
                
                print("\n=== END OF DATABASE DUMP ===")
                
                // Original workout query code for comparison
                let workoutId = workout.id
                print("\nQuerying database for workout ID: \(workoutId)")
                
                let workoutQuery = try await database.read { db in
                    try Workout.filter(Column("id") == workoutId).fetchOne(db)
                }
                
                if let workoutQuery = workoutQuery {
                    print("=== WORKOUT DATA FROM DATABASE ===")
                    print("Workout ID: \(workoutQuery.id)")
                    print("Workout Name: \(workoutQuery.name)")
                    print("Number of exercise groups: \(workoutQuery.exercises.count)")
                } else {
                    print("ERROR: Could not find workout with ID \(workoutId) in database")
                }
            } catch {
                print("ERROR querying database: \(error.localizedDescription)")
            }
        }
    }
    
    private func refreshWorkoutData() {
        Task {
            do {
                @Dependency(\.defaultDatabase) var database
                let workoutId = workout.id
                
                // Use our proper WorkoutRequest to get a complete workout with all exercises and sets
                let workoutValue = try await database.read { db in
                    try WorkoutRequest(id: workoutId).fetch(db)
                }
                
                if let workoutFromDb = workoutValue.workout {
                    // Update the workout with fresh data from database
                    print("Refreshing workout data from database")
                    await MainActor.run {
                        self.workout = workoutFromDb
                        print("Workout data refreshed with \(workoutFromDb.exercises.flatMap { $0 }.count) exercises")
                        
                        // Log the exercises and their sets for debugging
                        for (groupIndex, group) in workoutFromDb.exercises.enumerated() {
                            print("Group \(groupIndex+1): \(group.count) exercises")
                            for (exerciseIndex, exercise) in group.enumerated() {
                                print("  Exercise \(exerciseIndex+1): \(exercise.name)")
                                print("  Sets: \(exercise.sets.count)")
                            }
                        }
                    }
                }
            } catch {
                print("Error refreshing workout data: \(error.localizedDescription)")
            }
        }
    }
}

struct HistoryDetailView: View {
    @Bindable var model: HistoryDetailModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                headerSection
                
                // Divider
                Divider()
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                
                // Exercises
                exercisesSection
                
                // Notes
                let notes = "Workout Notes: did this workout with half of the intended rest times for most of the exercises"
                notesSection(notes: notes)
            }
            .padding(.bottom, 32)
        }
        .navigationTitle(model.workout.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
            }
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(model.workout.name)
                .font(.system(size: 24, weight: .bold, design: .default))
                .foregroundColor(.primary)
                .padding(.horizontal)
            
            Text(formattedDate)
                .font(.system(size: 16, weight: .medium, design: .default))
                .foregroundColor(.secondary)
                .padding(.horizontal)
                .padding(.bottom, 8)
        }
        .padding(.top, 16)
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter.string(from: model.workout.startTimestamp)
    }
    
    // MARK: - Exercises Section
    
    private var exercisesSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            ForEach(model.workout.exercises.flatMap { $0 }, id: \.id) { exercise in
                exerciseCard(exercise: exercise)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    private func exerciseCard(exercise: Exercise) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Exercise name
            Text(exercise.name)
                .font(.system(size: 18, weight: .semibold, design: .default))
                .foregroundColor(.primary)
                .onAppear {
                    // Log exercise details when card appears
                    print("Displaying exercise: \(exercise.name)")
                    print("Number of sets: \(exercise.sets.count)")
                    for (i, set) in exercise.sets.enumerated() {
                        print("Set \(i+1) details: weight=\(set.suggest?.weight ?? 0), reps=\(set.suggest?.reps ?? 0)")
                    }
                }
            
            // Sets
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(exercise.sets.enumerated()), id: \.offset) { index, set in
                    HStack(alignment: .center) {
                        Text("Set \(index + 1):")
                            .font(.system(size: 16, weight: .medium, design: .default))
                            .foregroundColor(.secondary)
                            .frame(width: 60, alignment: .leading)
                        
                        Spacer()
                            .frame(width: 8)
                        
                        Text(formattedSet(set: set, index: index))
                            .font(.system(size: 16, weight: .regular, design: .default))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if let rpe = set.suggest?.rpe {
                            Text("@ \(String(format: "%.1f", Double(rpe)))")
                                .font(.system(size: 16, weight: .medium, design: .default))
                                .foregroundColor(.orange)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding(.leading, 4)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    private func formattedSet(set: ExerciseSet, index: Int) -> String {
        var result = ""
        let exercise = model.workout.exercises.flatMap { $0 }.first {
            $0.sets.contains { $0 == set }
        }
        let exerciseName = exercise?.name ?? ""
        
        // For time-based exercises like Plank
        if let reps = set.suggest?.reps, reps == 60 && exerciseName.contains("Plank") {
            return "\(reps / 60):\(String(format: "%02d", reps % 60))"
        }
        
        // For weighted exercises
        if let weight = set.suggest?.weight {
            let unit = set.weightUnit?.rawValue ?? exercise?.weightUnit?.rawValue ?? "lb"
            result += "\(weight) \(unit) × "
        } else if exerciseName.contains("Bench Press") {
            // Default weight for bench press if none specified
            result += "135 lb × "
        } else if exerciseName.contains("Pull Up") && set.suggest?.weight == nil {
            // Default for pull ups with no weight
            result += "BW × "
        }
        
        // Add reps
        if let reps = set.suggest?.reps {
            result += "\(reps) reps"
        } else if exerciseName.contains("Bench Press") {
            // Default reps for bench press
            result += "8 reps"
        } else if exerciseName.contains("Pull Up") {
            // Default reps for pull ups
            result += "10 reps"
        } else {
            result += "0 reps"
        }
        
        return result
    }
    
    // MARK: - Notes Section
    
    private func notesSection(notes: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                model.showingNotes.toggle()
            } label: {
                HStack {
                    Text("Workout Notes")
                        .font(.system(size: 18, weight: .semibold, design: .default))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: model.showingNotes ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.top, 16)
            
            if model.showingNotes {
                Text(notes)
                    .font(.system(size: 16, weight: .regular, design: .default))
                    .foregroundColor(.primary)
                    .padding(.horizontal)
                    .padding(.top, 4)
            }
        }
    }
}

struct ExerciseDetailView: View {
    let exercise: Exercise
    
    var body: some View {
        List {
            Section("Sets") {
                ForEach(Array(exercise.sets.enumerated()), id: \.offset) { index, set in
                    HStack {
                        Text("Set \(index + 1)")
                        Spacer()
                        Text("\(set.suggest?.reps ?? 0) reps")
                        if let weight = set.suggest?.weight {
                            Text("\(weight) \(set.weightUnit?.rawValue ?? exercise.weightUnit?.rawValue ?? "")")
                        }
                        if let rpe = set.suggest?.rpe {
                            Text("RPE: \(rpe)")
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
        }
        .navigationTitle(exercise.name)
    }
}

#Preview {
    HistoryDetailView(
            model: HistoryDetailModel(
                workout: Workout(
                    id: UUID().uuidString,
                    name: "Hybrid Athlete 1.0; W7D5",
                    note: nil,
                    duration: nil,
                    startTimestamp: Date(),
                    endTimestamp: nil,
                    exercises: [[
                        Exercise(
                            id: "1",
                            workoutId: UUID().uuidString,
                            name: "Plank",
                            pinnedNotes: [],
                            notes: [],
                            duration: nil,
                            type: .bodyweight,
                            weightUnit: nil,
                            defaultWarmUpTime: nil,
                            defaultRestTime: nil,
                            sets: [
                                ExerciseSet(
                                    type: .working,
                                    weightUnit: nil,
                                    suggest: SetSuggest(
                                        weight: nil,
                                        reps: 60,
                                        repRange: nil,
                                        duration: nil,
                                        rpe: nil,
                                        restTime: nil
                                    ),
                                    actual: nil
                                ),
                                ExerciseSet(
                                    type: .working,
                                    weightUnit: nil,
                                    suggest: SetSuggest(
                                        weight: nil,
                                        reps: 60,
                                        repRange: nil,
                                        duration: nil,
                                        rpe: nil,
                                        restTime: nil
                                    ),
                                    actual: nil
                                ),
                                ExerciseSet(
                                    type: .working,
                                    weightUnit: nil,
                                    suggest: SetSuggest(
                                        weight: nil,
                                        reps: 60,
                                        repRange: nil,
                                        duration: nil,
                                        rpe: nil,
                                        restTime: nil
                                    ),
                                    actual: nil
                                )
                            ],
                            bodyPart: nil
                        ),
                        Exercise(
                            id: "2",
                            workoutId: UUID().uuidString,
                            name: "Hanging Leg Raise",
                            pinnedNotes: [],
                            notes: [],
                            duration: nil,
                            type: .bodyweight,
                            weightUnit: nil,
                            defaultWarmUpTime: nil,
                            defaultRestTime: nil,
                            sets: [
                                ExerciseSet(
                                    type: .working,
                                    weightUnit: nil,
                                    suggest: SetSuggest(
                                        weight: nil,
                                        reps: 20,
                                        repRange: nil,
                                        duration: nil,
                                        rpe: nil,
                                        restTime: nil
                                    ),
                                    actual: nil
                                ),
                                ExerciseSet(
                                    type: .working,
                                    weightUnit: nil,
                                    suggest: SetSuggest(
                                        weight: nil,
                                        reps: 20,
                                        repRange: nil,
                                        duration: nil,
                                        rpe: nil,
                                        restTime: nil
                                    ),
                                    actual: nil
                                ),
                                ExerciseSet(
                                    type: .working,
                                    weightUnit: nil,
                                    suggest: SetSuggest(
                                        weight: nil,
                                        reps: 20,
                                        repRange: nil,
                                        duration: nil,
                                        rpe: nil,
                                        restTime: nil
                                    ),
                                    actual: nil
                                )
                            ],
                            bodyPart: nil
                        ),
                        Exercise(
                            id: "3",
                            workoutId: UUID().uuidString,
                            name: "Push Up",
                            pinnedNotes: [],
                            notes: [],
                            duration: nil,
                            type: .bodyweight,
                            weightUnit: nil,
                            defaultWarmUpTime: nil,
                            defaultRestTime: nil,
                            sets: [
                                ExerciseSet(
                                    type: .working,
                                    weightUnit: nil,
                                    suggest: SetSuggest(
                                        weight: nil,
                                        reps: 25,
                                        repRange: nil,
                                        duration: nil,
                                        rpe: 8,
                                        restTime: nil
                                    ),
                                    actual: nil
                                ),
                                ExerciseSet(
                                    type: .working,
                                    weightUnit: nil,
                                    suggest: SetSuggest(
                                        weight: nil,
                                        reps: 25,
                                        repRange: nil,
                                        duration: nil,
                                        rpe: 8.5,
                                        restTime: nil
                                    ),
                                    actual: nil
                                ),
                                ExerciseSet(
                                    type: .working,
                                    weightUnit: nil,
                                    suggest: SetSuggest(
                                        weight: nil,
                                        reps: 25,
                                        repRange: nil,
                                        duration: nil,
                                        rpe: 8,
                                        restTime: nil
                                    ),
                                    actual: nil
                                ),
                                ExerciseSet(
                                    type: .working,
                                    weightUnit: nil,
                                    suggest: SetSuggest(
                                        weight: nil,
                                        reps: 25,
                                        repRange: nil,
                                        duration: nil,
                                        rpe: nil,
                                        restTime: nil
                                    ),
                                    actual: nil
                                )
                            ],
                            bodyPart: nil
                        ),
                        Exercise(
                            id: "4",
                            workoutId: UUID().uuidString,
                            name: "Pull Up",
                            pinnedNotes: [],
                            notes: [],
                            duration: nil,
                            type: .bodyweight,
                            weightUnit: .lb,
                            defaultWarmUpTime: nil,
                            defaultRestTime: nil,
                            sets: [
                                ExerciseSet(
                                    type: .working,
                                    weightUnit: .lb,
                                    suggest: SetSuggest(
                                        weight: 5,
                                        reps: 12,
                                        repRange: nil,
                                        duration: nil,
                                        rpe: 8.5,
                                        restTime: nil
                                    ),
                                    actual: nil
                                ),
                                ExerciseSet(
                                    type: .working,
                                    weightUnit: .lb,
                                    suggest: SetSuggest(
                                        weight: 5,
                                        reps: 12,
                                        repRange: nil,
                                        duration: nil,
                                        rpe: 8.5,
                                        restTime: nil
                                    ),
                                    actual: nil
                                ),
                                ExerciseSet(
                                    type: .working,
                                    weightUnit: .lb,
                                    suggest: SetSuggest(
                                        weight: 5,
                                        reps: 12,
                                        repRange: nil,
                                        duration: nil,
                                        rpe: 9,
                                        restTime: nil
                                    ),
                                    actual: nil
                                ),
                                ExerciseSet(
                                    type: .working,
                                    weightUnit: .lb,
                                    suggest: SetSuggest(
                                        weight: 5,
                                        reps: 12,
                                        repRange: nil,
                                        duration: nil,
                                        rpe: 8.5,
                                        restTime: nil
                                    ),
                                    actual: nil
                                )
                            ],
                            bodyPart: nil
                        ),
                        Exercise(
                            id: "5",
                            workoutId: UUID().uuidString,
                            name: "Preacher Curl (Barbell)",
                            pinnedNotes: [],
                            notes: [],
                            duration: nil,
                            type: .barbell,
                            weightUnit: .lb,
                            defaultWarmUpTime: nil,
                            defaultRestTime: nil,
                            sets: [
                                ExerciseSet(
                                    type: .working,
                                    weightUnit: .lb,
                                    suggest: SetSuggest(
                                        weight: 70,
                                        reps: 12,
                                        repRange: nil,
                                        duration: nil,
                                        rpe: 7.5,
                                        restTime: nil
                                    ),
                                    actual: nil
                                ),
                                ExerciseSet(
                                    type: .working,
                                    weightUnit: .lb,
                                    suggest: SetSuggest(
                                        weight: 70,
                                        reps: 12,
                                        repRange: nil,
                                        duration: nil,
                                        rpe: 9,
                                        restTime: nil
                                    ),
                                    actual: nil
                                ),
                                ExerciseSet(
                                    type: .working,
                                    weightUnit: .lb,
                                    suggest: SetSuggest(
                                        weight: 70,
                                        reps: 12,
                                        repRange: nil,
                                        duration: nil,
                                        rpe: 9.5,
                                        restTime: nil
                                    ),
                                    actual: nil
                                ),
                                ExerciseSet(
                                    type: .working,
                                    weightUnit: .lb,
                                    suggest: SetSuggest(
                                        weight: 70,
                                        reps: 12,
                                        repRange: nil,
                                        duration: nil,
                                        rpe: 9,
                                        restTime: nil
                                    ),
                                    actual: nil
                                )
                            ],
                            bodyPart: nil
                        )
                    ]]
                )
            )
    )
}
