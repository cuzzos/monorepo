import SwiftUI
import GRDB

/// Database Inspector - Shows raw database contents for debugging
struct DatabaseInspectorView: View {
    @State private var workouts: [DatabaseWorkoutRow] = []
    @State private var selectedWorkout: DatabaseWorkoutRow?
    @State private var workoutExercises: [DatabaseExerciseRow] = []
    @State private var exerciseSets: [String: [DatabaseSetRow]] = [:]
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var customQuery = ""
    @State private var queryResult = ""
    
    var body: some View {
        List {
            // MARK: - Summary
            Section("Database Summary") {
                HStack {
                    Label("\(workouts.count)", systemImage: "figure.strengthtraining.traditional")
                    Text("Workouts")
                    Spacer()
                    Button("Refresh") {
                        Task { await loadWorkouts() }
                    }
                }
                
                if isLoading {
                    HStack {
                        ProgressView()
                        Text("Loading...")
                    }
                }
                
                if let error = errorMessage {
                    Text("Error: \(error)")
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }
            
            // MARK: - Workouts Table
            Section("Workouts Table") {
                ForEach(workouts, id: \.id) { workout in
                    Button {
                        selectedWorkout = workout
                        Task { await loadWorkoutDetails(workout.id) }
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(workout.name)
                                    .font(.headline)
                                if workout.id == selectedWorkout?.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.blue)
                                }
                                Spacer()
                            }
                            
                            HStack {
                                Text("ID: \(workout.id.prefix(8))...")
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundStyle(.secondary)
                                
                                if let duration = workout.duration {
                                    Text("• \(duration)s")
                                        .font(.caption)
                                }
                            }
                            
                            if let start = workout.startTimestamp {
                                Text(start, style: .date)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
                
                if workouts.isEmpty && !isLoading {
                    Text("No workouts in database")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }
            
            // MARK: - Selected Workout Details
            if let selected = selectedWorkout {
                Section("Workout: \(selected.name)") {
                    VStack(alignment: .leading, spacing: 8) {
                        DetailRow(label: "ID", value: selected.id)
                        DetailRow(label: "Name", value: selected.name)
                        if let note = selected.note {
                            DetailRow(label: "Note", value: note)
                        }
                        if let duration = selected.duration {
                            DetailRow(label: "Duration", value: "\(duration) seconds")
                        }
                        if let start = selected.startTimestamp {
                            DetailRow(label: "Start", value: start.formatted())
                        }
                        if let end = selected.endTimestamp {
                            DetailRow(label: "End", value: end.formatted())
                        }
                    }
                    .font(.system(.caption, design: .monospaced))
                }
                
                // MARK: - Exercises for Selected Workout
                Section("Exercises (\(workoutExercises.count))") {
                    ForEach(workoutExercises, id: \.id) { exercise in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(exercise.name)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Spacer()
                                Text("Order: \(exercise.orderIndex)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Text("ID: \(exercise.id.prefix(8))...")
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundStyle(.secondary)
                            
                            // Sets for this exercise
                            if let sets = exerciseSets[exercise.id] {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Sets (\(sets.count)):")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    
                                    ForEach(sets, id: \.id) { set in
                                        HStack {
                                            Text("Set \(set.orderIndex + 1):")
                                                .font(.caption2)
                                            if let weight = set.weight {
                                                Text("\(Int(weight)) lbs")
                                            }
                                            if let reps = set.reps {
                                                Text("× \(reps)")
                                            }
                                            if let rpe = set.rpe {
                                                Text("RPE: \(Int(rpe))")
                                            }
                                            Text(set.isCompleted ? "✓" : "○")
                                        }
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(.leading, 8)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    if workoutExercises.isEmpty {
                        Text("No exercises for this workout")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                }
            }
            
            // MARK: - Raw SQL Query
            Section("Raw SQL Query") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Execute custom SQL queries")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    TextField("SELECT * FROM workouts", text: $customQuery, axis: .vertical)
                        .font(.system(.caption, design: .monospaced))
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                    
                    Button("Execute Query") {
                        Task { await executeCustomQuery() }
                    }
                    
                    if !queryResult.isEmpty {
                        ScrollView(.horizontal) {
                            Text(queryResult)
                                .font(.system(.caption2, design: .monospaced))
                                .padding(8)
                                .background(Color(.systemGray6))
                                .cornerRadius(4)
                        }
                    }
                }
            }
            
            // MARK: - Quick Queries
            Section("Quick Queries") {
                Button("Count All Tables") {
                    customQuery = """
                    SELECT 'workouts' as table_name, COUNT(*) as count FROM workouts
                    UNION ALL
                    SELECT 'exercises', COUNT(*) FROM exercises
                    UNION ALL
                    SELECT 'exerciseSets', COUNT(*) FROM exerciseSets
                    """
                    Task { await executeCustomQuery() }
                }
                
                Button("Show All Workout IDs") {
                    customQuery = "SELECT id, name, startTimestamp FROM workouts ORDER BY startTimestamp DESC"
                    Task { await executeCustomQuery() }
                }
                
                Button("Show Sample Data Workouts") {
                    customQuery = "SELECT * FROM workouts WHERE id LIKE 'sample-%'"
                    Task { await executeCustomQuery() }
                }
                
                Button("Show Recent Workouts (Last 24h)") {
                    let yesterday = Date().addingTimeInterval(-86400).timeIntervalSince1970
                    customQuery = "SELECT id, name, startTimestamp FROM workouts WHERE startTimestamp > \(yesterday)"
                    Task { await executeCustomQuery() }
                }
            }
        }
        .navigationTitle("Database Inspector")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadWorkouts()
        }
    }
    
    // MARK: - Data Loading
    
    private func loadWorkouts() async {
        guard let db = DatabaseManager.shared.database else {
            errorMessage = "Database not initialized"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            workouts = try await db.read { db in
                try DatabaseWorkoutRow.fetchAll(db, sql: """
                    SELECT id, name, note, duration, startTimestamp, endTimestamp
                    FROM workouts
                    ORDER BY startTimestamp DESC
                    """)
            }
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    private func loadWorkoutDetails(_ workoutId: String) async {
        guard let db = DatabaseManager.shared.database else { return }
        
        do {
            // Load exercises
            workoutExercises = try await db.read { db in
                try DatabaseExerciseRow.fetchAll(db, sql: """
                    SELECT id, workoutId, name, exerciseType, muscleGroup, orderIndex
                    FROM exercises
                    WHERE workoutId = ?
                    ORDER BY orderIndex
                    """, arguments: [workoutId])
            }
            
            // Load sets for each exercise
            exerciseSets = [:]
            for exercise in workoutExercises {
                let sets = try await db.read { db in
                    try DatabaseSetRow.fetchAll(db, sql: """
                        SELECT id, exerciseId, orderIndex, weight, reps, rpe, isCompleted
                        FROM exerciseSets
                        WHERE exerciseId = ?
                        ORDER BY orderIndex
                        """, arguments: [exercise.id])
                }
                exerciseSets[exercise.id] = sets
            }
            
        } catch {
            errorMessage = "Failed to load workout details: \(error.localizedDescription)"
        }
    }
    
    private func executeCustomQuery() async {
        guard let db = DatabaseManager.shared.database else {
            queryResult = "❌ Database not initialized"
            return
        }
        
        guard !customQuery.isEmpty else {
            queryResult = "❌ Enter a query first"
            return
        }
        
        do {
            let rows = try await db.read { db in
                return try Row.fetchAll(db, sql: customQuery)
            }
            
            if rows.isEmpty {
                queryResult = "✅ Query executed successfully (0 rows)"
            } else {
                var result = "✅ Query returned \(rows.count) row(s):\n\n"
                for (index, row) in rows.enumerated() {
                    result += "Row \(index + 1):\n"
                    for column in row.columnNames {
                        let value = row[column]
                        result += "  \(column): \(value ?? "NULL")\n"
                    }
                    result += "\n"
                }
                queryResult = result
            }
            
        } catch {
            queryResult = "❌ Query failed:\n\(error.localizedDescription)"
        }
    }
}

// MARK: - Helper Views

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(label + ":")
                .foregroundStyle(.secondary)
                .frame(width: 80, alignment: .leading)
            Text(value)
                .textSelection(.enabled)
        }
    }
}

// MARK: - Data Models

struct DatabaseWorkoutRow: Decodable, FetchableRecord {
    let id: String
    let name: String
    let note: String?
    let duration: Int?
    let startTimestamp: Date?
    let endTimestamp: Date?
}

struct DatabaseExerciseRow: Decodable, FetchableRecord {
    let id: String
    let workoutId: String
    let name: String
    let exerciseType: String?
    let muscleGroup: String?
    let orderIndex: Int
}

struct DatabaseSetRow: Decodable, FetchableRecord {
    let id: String
    let exerciseId: String
    let orderIndex: Int
    let weight: Double?
    let reps: Int?
    let rpe: Double?
    let isCompleted: Bool
}

#Preview {
    NavigationStack {
        DatabaseInspectorView()
    }
}

