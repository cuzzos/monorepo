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
                        print("Superset ID: \(exercise.supersetId)")
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
                notesSection(notes: model.workout.note ?? "")
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
        
        // For weighted exercises
        if let weight = set.actual?.weight ?? set.suggest?.weight {
            let unit = set.weightUnit?.rawValue ?? "lb"
            result += "\(weight) \(unit) × "
        }
        
        // Add reps
        if let reps = set.actual?.reps ?? set.suggest?.reps {
            result += "\(reps) reps"
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
    let _ = try! prepareDependencies {
        $0.defaultDatabase = try appDatabase()
    }
    
    @Dependency(\.defaultDatabase) var database
    let workout = try! database.read { db in
        try Workout.fetchOne(db)!
    }
    
    return NavigationStack {
        HistoryDetailView(model: .init(workout: workout))
    }
}
