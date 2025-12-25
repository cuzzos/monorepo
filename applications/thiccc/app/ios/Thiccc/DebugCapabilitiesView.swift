import SwiftUI
import SharedTypes
import GRDB

/// Debug view for testing capabilities.
///
/// This view provides buttons to manually trigger each capability operation
/// and displays console logs for verification.
///
/// **Usage**: Add this view to your app during development to test capabilities.
/// **Note**: Remove or disable in production builds.
struct DebugCapabilitiesView: View {
    @Bindable var core: Core
    @State private var testResult: String = "Tap a button to test"
    @State private var timerSeconds: Int = 0
    @State private var dbStats: DatabaseStats?
    @State private var isLoadingStats = false
    
    var body: some View {
        NavigationStack {
            List {
                // MARK: - Current State
                Section("Current State") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Has Active Workout: \(core.view.workout_view.has_active_workout ? "Yes" : "No")")
                        Text("Timer Running: \(core.view.workout_view.timer_running ? "Yes" : "No")")
                        Text("Duration: \(core.view.workout_view.formatted_duration)")
                        Text("Exercises: \(core.view.workout_view.exercises.count)")
                        Text("History Items: \(core.view.history_view.workouts.count)")
                    }
                    .font(.system(.body, design: .monospaced))
                }
                
                // MARK: - Workout Actions
                Section("Workout Actions") {
                    Button("Start Workout") {
                        Task {
                            await core.update(.startWorkout)
                            testResult = "Started workout"
                        }
                    }
                    
                    Button("Finish Workout") {
                        Task {
                            await core.update(.finishWorkout)
                            testResult = "Finished workout"
                        }
                    }
                    
                    Button("Discard Workout") {
                        Task {
                            await core.update(.discardWorkout)
                            testResult = "Discarded workout"
                        }
                    }
                    
                    Button("Add Exercise (Bench Press)") {
                        Task {
                            await core.update(.addExercise(
                                name: "Bench Press",
                                exercise_type: "barbell",
                                muscle_group: "chest"
                            ))
                            testResult = "Added exercise"
                        }
                    }
                }
                
                // MARK: - Timer Actions
                Section("Timer Actions") {
                    Button("Start Timer") {
                        Task {
                            await core.update(.startTimer)
                            testResult = "Timer started"
                        }
                    }
                    
                    Button("Stop Timer") {
                        Task {
                            await core.update(.stopTimer)
                            testResult = "Timer stopped"
                        }
                    }
                    
                    Button("Toggle Timer") {
                        Task {
                            await core.update(.toggleTimer)
                            testResult = "Timer toggled"
                        }
                    }
                }
                
                // MARK: - Storage Actions
                Section("Storage Actions") {
                    Button("Initialize (Load from Storage)") {
                        Task {
                            await core.update(.initialize)
                            testResult = "Initialized from storage"
                        }
                    }
                    
                    Button("Show File Path") {
                        let fileURL = URL.documentsDirectory.appending(component: "current-workout.json")
                        print("📂 File location: \(fileURL.path)")
                        print("📂 File exists: \(FileManager.default.fileExists(atPath: fileURL.path))")
                        testResult = "Check console for file path"
                    }
                    
                    Button("Read Storage File") {
                        let fileURL = URL.documentsDirectory.appending(component: "current-workout.json")
                        if FileManager.default.fileExists(atPath: fileURL.path) {
                            do {
                                let content = try String(contentsOf: fileURL, encoding: .utf8)
                                print("📄 File content:\n\(content)")
                                testResult = "File content logged to console (\(content.count) bytes)"
                            } catch {
                                testResult = "Failed to read file: \(error)"
                            }
                        } else {
                            testResult = "No file exists"
                        }
                    }
                }
                
                // MARK: - Database Status
                Section("Database Status") {
                    if let stats = dbStats {
                        // Database initialized
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Database Initialized")
                        }
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Path: \(stats.dbPath)", systemImage: "folder")
                                .font(.system(.caption, design: .monospaced))
                            
                            Label("Size: \(stats.dbSize)", systemImage: "doc")
                            
                            Divider()
                            
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("\(stats.workoutCount)")
                                        .font(.system(.title, design: .rounded, weight: .bold))
                                    Text("Workouts")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .leading) {
                                    Text("\(stats.exerciseCount)")
                                        .font(.system(.title, design: .rounded, weight: .bold))
                                    Text("Exercises")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .leading) {
                                    Text("\(stats.setCount)")
                                        .font(.system(.title, design: .rounded, weight: .bold))
                                    Text("Sets")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            if stats.hasSampleData {
                                Divider()
                                HStack {
                                    Image(systemName: "info.circle")
                                        .foregroundStyle(.blue)
                                    Text("Sample data loaded (DEBUG build)")
                                        .font(.caption)
                                }
                            }
                        }
                    } else {
                        HStack {
                            if isLoadingStats {
                                ProgressView()
                            } else {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.yellow)
                                Text("Database not initialized")
                            }
                        }
                    }
                    
                    Button(action: {
                        Task {
                            await refreshDatabaseStats()
                        }
                    }) {
                        Label("Refresh Stats", systemImage: "arrow.clockwise")
                    }
                }
                
                // MARK: - Database Actions
                Section("Database Actions") {
                    Button("Load History") {
                        Task {
                            await core.update(.loadHistory)
                            testResult = "History loaded - \(core.view.history_view.workouts.count) workouts"
                        }
                    }
                    
                    NavigationLink("📊 Database Inspector") {
                        DatabaseInspectorView()
                    }
                    
                    Button("Query Database Directly") {
                        Task {
                            if let db = DatabaseManager.shared.database {
                                do {
                                    let counts = try await db.read { db -> (Int, Int, Int) in
                                        let workouts = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM workouts") ?? 0
                                        let exercises = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM exercises") ?? 0
                                        let sets = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM exerciseSets") ?? 0
                                        return (workouts, exercises, sets)
                                    }
                                    print("🗄️ Direct query results:")
                                    print("   Workouts: \(counts.0)")
                                    print("   Exercises: \(counts.1)")
                                    print("   Sets: \(counts.2)")
                                    testResult = "Query: \(counts.0)W, \(counts.1)E, \(counts.2)S - see console"
                                } catch {
                                    print("❌ Query failed: \(error)")
                                    testResult = "Query failed: \(error.localizedDescription)"
                                }
                            } else {
                                testResult = "Database not initialized"
                            }
                        }
                    }
                }
                
                // MARK: - Test Result
                Section("Test Result") {
                    Text(testResult)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                
                // MARK: - Console Logs (Last 10)
                Section("Recent Console Logs") {
                    ForEach(ConsoleLogger.shared.logs.suffix(10).reversed(), id: \.timestamp) { log in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(log.emoji)
                                Text(log.message)
                                    .font(.system(.caption, design: .monospaced))
                                Spacer()
                            }
                            Text(log.timestamp, style: .time)
                                .font(.system(.caption2))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                    
                    if ConsoleLogger.shared.logs.isEmpty {
                        Text("No logs yet")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Button("Clear Logs") {
                        ConsoleLogger.shared.clear()
                        testResult = "Logs cleared"
                    }
                }
            }
            .navigationTitle("Debug Capabilities")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                Task {
                    await refreshDatabaseStats()
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func refreshDatabaseStats() async {
        isLoadingStats = true
        defer { isLoadingStats = false }
        
        guard let db = DatabaseManager.shared.database else {
            dbStats = nil
            return
        }
        
        do {
            let stats = try await db.read { db -> DatabaseStats in
                let workoutCount = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM workouts") ?? 0
                let exerciseCount = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM exercises") ?? 0
                let setCount = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM exerciseSets") ?? 0
                
                // Check for sample data (sample workouts have predictable IDs)
                let sampleCount = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM workouts WHERE id LIKE 'sample-%'") ?? 0
                
                // Get database file path
                let fileManager = FileManager.default
                let appSupport = try fileManager.url(
                    for: .applicationSupportDirectory,
                    in: .userDomainMask,
                    appropriateFor: nil,
                    create: false
                )
                let dbPath = appSupport.appendingPathComponent("thiccc.sqlite").path
                
                // Get file size
                var dbSize = "Unknown"
                if let attrs = try? fileManager.attributesOfItem(atPath: dbPath),
                   let size = attrs[.size] as? Int64 {
                    let formatter = ByteCountFormatter()
                    formatter.countStyle = .file
                    dbSize = formatter.string(fromByteCount: size)
                }
                
                return DatabaseStats(
                    workoutCount: workoutCount,
                    exerciseCount: exerciseCount,
                    setCount: setCount,
                    hasSampleData: sampleCount > 0,
                    dbPath: dbPath,
                    dbSize: dbSize
                )
            }
            
            dbStats = stats
            print("✅ [Debug] Database stats loaded: \(stats.workoutCount)W, \(stats.exerciseCount)E, \(stats.setCount)S")
            
        } catch {
            print("❌ [Debug] Failed to load database stats: \(error)")
            dbStats = nil
        }
    }
}

// MARK: - Database Stats Model

struct DatabaseStats {
    let workoutCount: Int
    let exerciseCount: Int
    let setCount: Int
    let hasSampleData: Bool
    let dbPath: String
    let dbSize: String
}

// MARK: - Console Logger

@Observable
@MainActor
final class ConsoleLogger {
    static let shared = ConsoleLogger()
    
    struct LogEntry {
        let timestamp: Date
        let message: String
        let emoji: String
    }
    
    var logs: [LogEntry] = []
    
    private init() {}
    
    func log(_ message: String, emoji: String = "📝") {
        let entry = LogEntry(timestamp: Date(), message: message, emoji: emoji)
        logs.append(entry)
        
        // Keep only last 50 logs
        if logs.count > 50 {
            logs.removeFirst(logs.count - 50)
        }
    }
    
    func clear() {
        logs.removeAll()
    }
}

