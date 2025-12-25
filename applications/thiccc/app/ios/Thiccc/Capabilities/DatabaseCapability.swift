import Foundation
import SharedTypes
import GRDB

/// Handles database operations for persisting workout data.
///
/// The database stores completed workouts with their exercises and sets using GRDB (SQLite).
/// Implements a three-tier error handling strategy:
/// 1. **Normal case:** Direct database save
/// 2. **Transient failure:** Immediate retry (0.5s delay)
/// 3. **Persistent failure:** Backup to file + schedule background retry
///
/// # Architecture
/// - Receives JSON-encoded workout data from Rust core
/// - Parses JSON and inserts into SQLite using raw SQL
/// - Returns JSON strings back to Rust core (maintains clean separation)
/// - All business logic remains in Rust (this is just I/O)
@MainActor
class DatabaseCapability {
    private weak var core: Core?
    private let database: DatabaseWriter
    
    /// Directory for backup files when database save fails.
    private let backupDirectory: URL
    
    // MARK: - Initialization
    
    /// Initialize database capability with GRDB database.
    ///
    /// - Parameters:
    ///   - core: Reference to Core for sending responses
    ///   - database: GRDB DatabaseWriter from DatabaseManager
    init(core: Core, database: DatabaseWriter) {
        self.core = core
        self.database = database
        
        // Setup backup directory
        self.backupDirectory = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0].appendingPathComponent("workout-backups", isDirectory: true)
        
        // Create backup directory if doesn't exist
        try? FileManager.default.createDirectory(
            at: backupDirectory,
            withIntermediateDirectories: true
        )
        
        print("🗄️ [DatabaseCapability] Initialized with GRDB")
        print("📁 [DatabaseCapability] Backup directory: \(backupDirectory.path)")
    }
    
    // MARK: - Operation Handling
    
    /// Handle a database operation from the Rust core.
    func handle(_ operation: SharedTypes.DatabaseOperation, requestId: UInt32) async {
        switch operation {
        case .saveWorkout(let workoutJson):
            await handleSaveWorkout(workoutJson: workoutJson, requestId: requestId)
            
        case .loadAllWorkouts:
            await handleLoadAllWorkouts(requestId: requestId)
            
        case .loadWorkoutById(let id):
            await handleLoadWorkoutById(id: id, requestId: requestId)
            
        case .deleteWorkout(let id):
            await handleDeleteWorkout(id: id, requestId: requestId)
        }
    }
    
    // MARK: - Save Workout (with Retry + Backup)
    
    /// Save a completed workout to the database.
    ///
    /// Implements three-tier error handling:
    /// 1. Try database save
    /// 2. On failure, retry once (0.5s delay)
    /// 3. On retry failure, save to backup file
    private func handleSaveWorkout(workoutJson: String, requestId: UInt32) async {
        print("💾 [DatabaseCapability] Save workout requested")
        print("📄 [DatabaseCapability] JSON length: \(workoutJson.count) bytes")
        
        // Log to in-app console
        await ConsoleLogger.shared.log("Save workout requested (\(workoutJson.count) bytes)", emoji: "💾")
        
        var attempt = 0
        let maxAttempts = 2  // Original + 1 retry
        
        while attempt < maxAttempts {
            attempt += 1
            print("🔄 [DatabaseCapability] Save attempt \(attempt) of \(maxAttempts)")
            
            do {
                // ATTEMPT: Save to database
                try await saveWorkoutToDatabase(workoutJson)
                
                // ✅ SUCCESS
                print("✅ [DatabaseCapability] Workout saved successfully (attempt \(attempt))")
                await ConsoleLogger.shared.log("Workout saved to DB ✓", emoji: "✅")
                
                // Delete any backup files (no longer needed)
                await tryDeleteBackupFiles()
                
                // Send success response to Rust core
        let result = SharedTypes.DatabaseResult.workoutSaved
        await core?.sendDatabaseResponse(requestId: requestId, result: result)
                return
                
            } catch {
                print("❌ [DatabaseCapability] Save failed (attempt \(attempt)): \(error.localizedDescription)")
                await ConsoleLogger.shared.log("Save failed (attempt \(attempt)): \(error.localizedDescription)", emoji: "❌")
                
                if attempt < maxAttempts {
                    // Wait before retry
                    print("⏳ [DatabaseCapability] Waiting 0.5s before retry...")
                    try? await Task.sleep(nanoseconds: 500_000_000)  // 0.5 seconds
                    continue
                }
                
                // ❌ BOTH ATTEMPTS FAILED - Use backup strategy
                print("⚠️  [DatabaseCapability] All attempts failed, creating backup...")
                
                do {
                    // Save to backup file
                    try await saveWorkoutToBackup(workoutJson)
                    
                    // Tell Rust core: Saved to backup, will retry later
                    let result = SharedTypes.DatabaseResult.error(
                        message: "Workout saved to backup. Will sync to database soon."
                    )
                    await core?.sendDatabaseResponse(requestId: requestId, result: result)
                    
                    // Schedule background retry
                    await scheduleBackgroundRetry()
                    
                } catch {
                    // Even backup failed - this is bad
                    print("❌ [DatabaseCapability] Backup also failed: \(error)")
                    let result = SharedTypes.DatabaseResult.error(
                        message: "Failed to save workout. Please try finishing again."
                    )
                    await core?.sendDatabaseResponse(requestId: requestId, result: result)
                }
            }
        }
    }
    
    /// Save workout to database using GRDB.
    ///
    /// Parses JSON and inserts into workouts/exercises/exerciseSets tables.
    private func saveWorkoutToDatabase(_ workoutJson: String) async throws {
        // Parse JSON to extract basic fields for database
        guard let jsonData = workoutJson.data(using: .utf8),
              let workout = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw NSError(domain: "DatabaseCapability", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Failed to parse workout JSON"
            ])
        }
        
        let workoutId = workout["id"] as? String ?? ""
        let name = workout["name"] as? String ?? "Unnamed Workout"
        let note = workout["note"] as? String
        let duration = workout["duration"] as? Int
        
        // Parse timestamps
        let startTimestamp: Date
        let endTimestamp: Date?
        
        if let startStr = workout["start_timestamp"] as? String {
            let formatter = ISO8601DateFormatter()
            startTimestamp = formatter.date(from: startStr) ?? Date()
        } else {
            startTimestamp = Date()
        }
        
        if let endStr = workout["end_timestamp"] as? String {
            let formatter = ISO8601DateFormatter()
            endTimestamp = formatter.date(from: endStr)
        } else {
            endTimestamp = nil
        }
        
        // Insert into database (transaction ensures atomicity)
        try await database.write { db in
            // Insert workout
            try db.execute(
                sql: """
                INSERT OR REPLACE INTO workouts 
                (id, name, note, duration, startTimestamp, endTimestamp)
                VALUES (?, ?, ?, ?, ?, ?)
                """,
                arguments: [
                    workoutId,
                    name,
                    note,
                    duration,
                    startTimestamp.timeIntervalSince1970,
                    endTimestamp?.timeIntervalSince1970
                ]
            )
            
            // Parse and insert exercises
            if let exercises = workout["exercises"] as? [[String: Any]] {
                for exercise in exercises {
                    let exerciseId = exercise["id"] as? String ?? ""
                    let exerciseName = exercise["name"] as? String ?? "Unknown"
                    let exerciseType = exercise["type"] as? String ?? "unknown"
                    
                    try db.execute(
                        sql: """
                        INSERT OR REPLACE INTO exercises
                        (id, workoutId, name, type)
                        VALUES (?, ?, ?, ?)
                        """,
                        arguments: [exerciseId, workoutId, exerciseName, exerciseType]
                    )
                    
                    // Parse and insert sets
                    if let sets = exercise["sets"] as? [[String: Any]] {
                        for (index, set) in sets.enumerated() {
                            let setId = set["id"] as? String ?? ""
                            let setType = set["set_type"] as? String ?? "working"
                            let isCompleted = set["is_completed"] as? Bool ?? false
                            
                            try db.execute(
                                sql: """
                                INSERT OR REPLACE INTO exerciseSets
                                (id, exerciseId, workoutId, setIndex, type, isCompleted)
                                VALUES (?, ?, ?, ?, ?, ?)
                                """,
                                arguments: [
                                    setId,
                                    exerciseId,
                                    workoutId,
                                    index,
                                    setType,
                                    isCompleted ? 1 : 0
                                ]
                            )
                        }
                    }
                }
            }
        }
        
        print("✅ [DatabaseCapability] Inserted workout: \(workoutId)")
    }
    
    // MARK: - Backup Strategy
    
    /// Save workout to backup file.
    private func saveWorkoutToBackup(_ workoutJson: String) async throws {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let filename = "workout-backup-\(timestamp).json"
        let fileURL = backupDirectory.appendingPathComponent(filename)
        
        try workoutJson.write(to: fileURL, atomically: true, encoding: .utf8)
        
        print("💾 [DatabaseCapability] Backup saved: \(filename)")
    }
    
    /// Schedule background task to retry backup files.
    private func scheduleBackgroundRetry() async {
        print("⏰ [DatabaseCapability] Scheduling background retry in 5 seconds...")
        
        Task {
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            await retryBackupFiles()
        }
    }
    
    /// Retry saving backup files to database.
    private func retryBackupFiles() async {
        print("🔄 [DatabaseCapability] Retrying backup files...")
        
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: backupDirectory,
                includingPropertiesForKeys: nil
            ).filter { $0.pathExtension == "json" }
            
            guard !fileURLs.isEmpty else {
                print("ℹ️  [DatabaseCapability] No backup files to retry")
                return
            }
            
            print("📂 [DatabaseCapability] Found \(fileURLs.count) backup file(s)")
            
            for fileURL in fileURLs {
                do {
                    let workoutJson = try String(contentsOf: fileURL, encoding: .utf8)
                    try await saveWorkoutToDatabase(workoutJson)
                    
                    // Success! Delete backup file
                    try FileManager.default.removeItem(at: fileURL)
                    print("✅ [DatabaseCapability] Backup file processed: \(fileURL.lastPathComponent)")
                } catch {
                    print("❌ [DatabaseCapability] Failed to process backup: \(error)")
                }
            }
        } catch {
            print("❌ [DatabaseCapability] Failed to list backups: \(error)")
        }
    }
    
    /// Delete all backup files.
    private func tryDeleteBackupFiles() async {
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: backupDirectory,
                includingPropertiesForKeys: nil
            ).filter { $0.pathExtension == "json" }
            
            for fileURL in fileURLs {
                try FileManager.default.removeItem(at: fileURL)
                print("🗑️  [DatabaseCapability] Deleted backup: \(fileURL.lastPathComponent)")
            }
        } catch {
            print("⚠️  [DatabaseCapability] Could not delete backups: \(error)")
        }
    }
    
    // MARK: - Load All Workouts
    
    /// Load all workouts for the history view.
    ///
    /// Returns workouts as JSON strings in reverse chronological order.
    private func handleLoadAllWorkouts(requestId: UInt32) async {
        print("📖 [DatabaseCapability] Load all workouts requested")
        
        do {
            let workoutJsons = try await database.read { db -> [String] in
                let rows = try Row.fetchAll(db, sql: """
                    SELECT id, name, note, duration, startTimestamp, endTimestamp
                    FROM workouts
                    ORDER BY startTimestamp DESC
                """)
                
                return try rows.map { row -> String in
                    var dict: [String: Any] = [
                        "id": row["id"] as String,
                        "name": row["name"] as String,
                        "start_timestamp": ISO8601DateFormatter().string(from: Date(timeIntervalSince1970: row["startTimestamp"])),
                    ]
                    
                    if let note: String = row["note"] { dict["note"] = note }
                    if let duration: Int = row["duration"] { dict["duration"] = duration }
                    if let endTs: Double = row["endTimestamp"] {
                        dict["end_timestamp"] = ISO8601DateFormatter().string(from: Date(timeIntervalSince1970: endTs))
                    }
                    
                    dict["exercises"] = []
                    
                    let jsonData = try JSONSerialization.data(withJSONObject: dict)
                    return String(data: jsonData, encoding: .utf8)!
                }
            }
            
            print("✅ [DatabaseCapability] Loaded \(workoutJsons.count) workouts")
            
            let result = SharedTypes.DatabaseResult.historyLoaded(workouts_json: workoutJsons)
        await core?.sendDatabaseResponse(requestId: requestId, result: result)
        
        } catch {
            print("❌ [DatabaseCapability] Load failed: \(error)")
            let result = SharedTypes.DatabaseResult.error(message: error.localizedDescription)
            await core?.sendDatabaseResponse(requestId: requestId, result: result)
        }
    }
    
    // MARK: - Load Workout By ID
    
    /// Load a specific workout by its ID.
    private func handleLoadWorkoutById(id: String, requestId: UInt32) async {
        print("📖 [DatabaseCapability] Load workout by ID: \(id)")
        
        do {
            let workoutJson = try await database.read { db -> String? in
                guard let workoutRow = try Row.fetchOne(db, sql: """
                    SELECT id, name, note, duration, startTimestamp, endTimestamp
                    FROM workouts WHERE id = ?
                """, arguments: [id]) else {
                    return nil
                }
                
                var dict: [String: Any] = [
                    "id": workoutRow["id"] as String,
                    "name": workoutRow["name"] as String,
                    "start_timestamp": ISO8601DateFormatter().string(from: Date(timeIntervalSince1970: workoutRow["startTimestamp"])),
                ]
                
                if let note: String = workoutRow["note"] { dict["note"] = note }
                if let duration: Int = workoutRow["duration"] { dict["duration"] = duration }
                if let endTs: Double = workoutRow["endTimestamp"] {
                    dict["end_timestamp"] = ISO8601DateFormatter().string(from: Date(timeIntervalSince1970: endTs))
                }
                
                dict["exercises"] = []
                
                let jsonData = try JSONSerialization.data(withJSONObject: dict)
                return String(data: jsonData, encoding: .utf8)
            }
            
            if workoutJson != nil {
                print("✅ [DatabaseCapability] Loaded workout: \(id)")
            } else {
                print("ℹ️  [DatabaseCapability] Workout not found: \(id)")
            }
            
            let result = SharedTypes.DatabaseResult.workoutLoaded(workout_json: workoutJson)
        await core?.sendDatabaseResponse(requestId: requestId, result: result)
        
        } catch {
            print("❌ [DatabaseCapability] Load failed: \(error)")
            let result = SharedTypes.DatabaseResult.error(message: error.localizedDescription)
            await core?.sendDatabaseResponse(requestId: requestId, result: result)
        }
    }
    
    // MARK: - Delete Workout
    
    /// Delete a workout from the database.
    ///
    /// CASCADE DELETE ensures exercises and sets are also deleted.
    private func handleDeleteWorkout(id: String, requestId: UInt32) async {
        print("🗑️  [DatabaseCapability] Delete workout: \(id)")
        
        do {
            try await database.write { db in
                try db.execute(sql: "DELETE FROM workouts WHERE id = ?", arguments: [id])
            }
            
            print("✅ [DatabaseCapability] Workout deleted: \(id)")
        
        let result = SharedTypes.DatabaseResult.workoutDeleted
        await core?.sendDatabaseResponse(requestId: requestId, result: result)
        
        } catch {
            print("❌ [DatabaseCapability] Delete failed: \(error)")
            let result = SharedTypes.DatabaseResult.error(message: error.localizedDescription)
            await core?.sendDatabaseResponse(requestId: requestId, result: result)
        }
    }
}
