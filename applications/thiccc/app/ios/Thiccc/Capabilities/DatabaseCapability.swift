import Foundation
import SharedTypes
import GRDB

/// Protocol for core communication (allows testing with mocks)
protocol DatabaseCoreProtocol: AnyObject {
    func sendDatabaseResponse(requestId: UInt32, result: SharedTypes.DatabaseResult) async
}

// Make Core conform to the protocol
extension Core: DatabaseCoreProtocol {}

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
    private weak var core: (any DatabaseCoreProtocol)?
    private let database: DatabaseWriter
    
    /// Directory for backup files when database save fails.
    private let backupDirectory: URL
    
    // MARK: - Initialization
    
    /// Initialize database capability with GRDB database.
    ///
    /// - Parameters:
    ///   - core: Reference to Core for sending responses
    ///   - database: GRDB DatabaseWriter from DatabaseManager
    init(core: any DatabaseCoreProtocol, database: DatabaseWriter) {
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
        ConsoleLogger.shared.log("Saving workout (\(workoutJson.count) bytes)", emoji: "💾")
        
        var attempt = 0
        let maxAttempts = 2  // Original + 1 retry
        
        while attempt < maxAttempts {
            attempt += 1
            
            do {
                // ATTEMPT: Save to database
                try await saveWorkoutToDatabase(workoutJson)
                
                // ✅ SUCCESS
                ConsoleLogger.shared.log("Workout saved ✓", emoji: "✅")
                
                // Delete any backup files (no longer needed)
                await tryDeleteBackupFiles()
                
                // Send success response to Rust core
        let result = SharedTypes.DatabaseResult.workoutSaved
        await core?.sendDatabaseResponse(requestId: requestId, result: result)
                return
                
            } catch {
                ConsoleLogger.shared.log("Save failed (attempt \(attempt)): \(error.localizedDescription)", emoji: "❌")
                
                if attempt < maxAttempts {
                    // Wait before retry
                    try? await Task.sleep(nanoseconds: 500_000_000)  // 0.5 seconds
                    continue
                }
                
                // ❌ BOTH ATTEMPTS FAILED - Use backup strategy
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
                    print("❌ [DatabaseCapability] Backup failed: \(error)")
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
            
            // Insert exercises and sets
            if let exercises = workout["exercises"] as? [[String: Any]] {
                for exercise in exercises {
                    let exerciseId = exercise["id"] as? String ?? ""
                    let exerciseName = exercise["name"] as? String ?? "Unknown"
                    let exerciseType = exercise["type"] as? String ?? "unknown"
                    let supersetId = exercise["superset_id"] as? Int
                    let duration = exercise["duration"] as? Int
                    let weightUnit = exercise["weight_unit"] as? String
                    let defaultWarmUpTime = exercise["default_warm_up_time"] as? Int
                    let defaultRestTime = exercise["default_rest_time"] as? Int
                    
                    // Serialize optional arrays/objects to JSON
                    let pinnedNotesJson: String? = {
                        if let notes = exercise["pinned_notes"] as? [String], !notes.isEmpty {
                            return try? String(data: JSONSerialization.data(withJSONObject: notes), encoding: .utf8)
                        }
                        return nil
                    }()
                    
                    let notesJson: String? = {
                        if let notes = exercise["notes"] as? [String], !notes.isEmpty {
                            return try? String(data: JSONSerialization.data(withJSONObject: notes), encoding: .utf8)
                        }
                        return nil
                    }()
                    
                    let bodyPartJson: String? = {
                        if let bodyPart = exercise["body_part"] as? [String: Any] {
                            return try? String(data: JSONSerialization.data(withJSONObject: bodyPart), encoding: .utf8)
                        }
                        return nil
                    }()
                    
                    try db.execute(
                        sql: """
                        INSERT OR REPLACE INTO exercises
                        (id, workoutId, supersetId, name, pinnedNotes, notes, duration, type, weightUnit, defaultWarmUpTime, defaultRestTime, bodyPart)
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                        """,
                        arguments: [
                            exerciseId,
                            workoutId,
                            supersetId,
                            exerciseName,
                            pinnedNotesJson,
                            notesJson,
                            duration,
                            exerciseType,
                            weightUnit,
                            defaultWarmUpTime,
                            defaultRestTime,
                            bodyPartJson
                        ]
                    )
                    if let sets = exercise["sets"] as? [[String: Any]] {
                        for (index, set) in sets.enumerated() {
                            let setId = set["id"] as? String ?? ""
                            let setType = set["type"] as? String ?? "working"
                            let isCompleted = set["is_completed"] as? Bool ?? false
                            let weightUnit = set["weight_unit"] as? String
                            
                            // Serialize suggest and actual objects to JSON
                            let suggestJson: String? = {
                                if let suggest = set["suggest"] as? [String: Any] {
                                    return try? String(data: JSONSerialization.data(withJSONObject: suggest), encoding: .utf8)
                                }
                                return nil
                            }()
                            
                            let actualJson: String? = {
                                if let actual = set["actual"] as? [String: Any] {
                                    return try? String(data: JSONSerialization.data(withJSONObject: actual), encoding: .utf8)
                                }
                                return nil
                            }()
                            
                            try db.execute(
                                sql: """
                                INSERT OR REPLACE INTO exerciseSets
                                (id, exerciseId, workoutId, setIndex, type, weightUnit, suggest, actual, isCompleted)
                                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                                """,
                                arguments: [
                                    setId,
                                    exerciseId,
                                    workoutId,
                                    index,
                                    setType,
                                    weightUnit,
                                    suggestJson,
                                    actualJson,
                                    isCompleted ? 1 : 0
                                ]
                            )
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Backup Strategy
    
    /// Save workout to backup file.
    private func saveWorkoutToBackup(_ workoutJson: String) async throws {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let filename = "workout-backup-\(timestamp).json"
        let fileURL = backupDirectory.appendingPathComponent(filename)
        try workoutJson.write(to: fileURL, atomically: true, encoding: .utf8)
    }
    
    /// Schedule background task to retry backup files.
    private func scheduleBackgroundRetry() async {
        Task {
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            await retryBackupFiles()
        }
    }
    
    /// Retry saving backup files to database.
    private func retryBackupFiles() async {
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: backupDirectory,
                includingPropertiesForKeys: nil
            ).filter { $0.pathExtension == "json" }
            
            guard !fileURLs.isEmpty else { return }
            
            for fileURL in fileURLs {
                do {
                    let workoutJson = try String(contentsOf: fileURL, encoding: .utf8)
                    try await saveWorkoutToDatabase(workoutJson)
                    try FileManager.default.removeItem(at: fileURL)
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
            }
        } catch {
            // Silently ignore - not critical
        }
    }
    
    // MARK: - Load All Workouts
    
    /// Load all workouts for the history view.
    ///
    /// Returns workouts as JSON strings in reverse chronological order.
    private func handleLoadAllWorkouts(requestId: UInt32) async {
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
                    
                    // Load exercises for this workout
                    let exercises = try Row.fetchAll(db, sql: """
                        SELECT id, workoutId, supersetId, name, pinnedNotes, notes, duration, type, weightUnit, defaultWarmUpTime, defaultRestTime, bodyPart
                        FROM exercises WHERE workoutId = ?
                        ORDER BY id
                    """, arguments: [row["id"] as String])

                    var exercisesArray: [[String: Any]] = []
                    for exerciseRow in exercises {
                        var exerciseDict: [String: Any] = [
                            "id": exerciseRow["id"] as String,
                            "workout_id": exerciseRow["workoutId"] as String,
                            "name": exerciseRow["name"] as String,
                            "type": exerciseRow["type"] as String,
                        ]

                    if let supersetId: Int = exerciseRow["supersetId"] { exerciseDict["superset_id"] = supersetId }

                    // Parse pinned notes JSON array
                    if let pinnedNotesJson: String = exerciseRow["pinnedNotes"] {
                        if let pinnedNotesData = pinnedNotesJson.data(using: .utf8),
                           let pinnedNotesArray = try? JSONSerialization.jsonObject(with: pinnedNotesData) as? [String] {
                            exerciseDict["pinned_notes"] = pinnedNotesArray
                        } else {
                            exerciseDict["pinned_notes"] = [String]()
                        }
                    } else {
                        exerciseDict["pinned_notes"] = [String]()
                    }

                    // Parse notes JSON array
                    if let notesJson: String = exerciseRow["notes"] {
                        if let notesData = notesJson.data(using: .utf8),
                           let notesArray = try? JSONSerialization.jsonObject(with: notesData) as? [String] {
                            exerciseDict["notes"] = notesArray
                        } else {
                            exerciseDict["notes"] = [String]()
                        }
                    } else {
                        exerciseDict["notes"] = [String]()
                    }
                        if let duration: Int = exerciseRow["duration"] { exerciseDict["duration"] = duration }
                        if let weightUnit: String = exerciseRow["weightUnit"] { exerciseDict["weight_unit"] = weightUnit }
                        if let defaultWarmUpTime: Int = exerciseRow["defaultWarmUpTime"] { exerciseDict["default_warm_up_time"] = defaultWarmUpTime }
                    if let defaultRestTime: Int = exerciseRow["defaultRestTime"] { exerciseDict["default_rest_time"] = defaultRestTime }

                    // Parse body part JSON object
                    if let bodyPartJson: String = exerciseRow["bodyPart"] {
                        if let bodyPartData = bodyPartJson.data(using: .utf8),
                           let bodyPartDict = try? JSONSerialization.jsonObject(with: bodyPartData) as? [String: Any] {
                            exerciseDict["body_part"] = bodyPartDict
                        }
                    }

                        // Load sets for this exercise
                        let sets = try Row.fetchAll(db, sql: """
                            SELECT id, exerciseId, workoutId, setIndex, type, weightUnit, suggest, actual, isCompleted
                            FROM exerciseSets WHERE exerciseId = ?
                            ORDER BY setIndex
                        """, arguments: [exerciseRow["id"] as String])

                        var setsArray: [[String: Any]] = []
                        for setRow in sets {
                            var setDict: [String: Any] = [
                                "id": setRow["id"] as String,
                                "exercise_id": setRow["exerciseId"] as String,
                                "workout_id": setRow["workoutId"] as String,
                                "set_index": setRow["setIndex"] as Int,
                                "type": setRow["type"] as String,
                                "is_completed": (setRow["isCompleted"] as? Int ?? 0) != 0,
                            ]

                            if let weightUnit: String = setRow["weightUnit"] { setDict["weight_unit"] = weightUnit }

                            // Parse suggest JSON
                            if let suggestJson: String = setRow["suggest"] {
                                if let suggestData = suggestJson.data(using: .utf8),
                                   let suggestDict = try? JSONSerialization.jsonObject(with: suggestData) as? [String: Any] {
                                    setDict["suggest"] = suggestDict
                                }
                            }

                            // Parse actual JSON
                            if let actualJson: String = setRow["actual"] {
                                if let actualData = actualJson.data(using: .utf8),
                                   let actualDict = try? JSONSerialization.jsonObject(with: actualData) as? [String: Any] {
                                    setDict["actual"] = actualDict
                                }
                            }

                            setsArray.append(setDict)
                        }

                        exerciseDict["sets"] = setsArray
                        exercisesArray.append(exerciseDict)
                    }

                    dict["exercises"] = exercisesArray

                    let jsonData = try JSONSerialization.data(withJSONObject: dict)
                    return String(data: jsonData, encoding: .utf8)!
                }
            }
            
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
                
                // Load exercises for this workout
                let exercises = try Row.fetchAll(db, sql: """
                    SELECT id, workoutId, supersetId, name, pinnedNotes, notes, duration, type, weightUnit, defaultWarmUpTime, defaultRestTime, bodyPart
                    FROM exercises WHERE workoutId = ?
                    ORDER BY id
                """, arguments: [id])

                var exercisesArray: [[String: Any]] = []
                for exerciseRow in exercises {
                    var exerciseDict: [String: Any] = [
                        "id": exerciseRow["id"] as String,
                        "workout_id": exerciseRow["workoutId"] as String,
                        "name": exerciseRow["name"] as String,
                        "type": exerciseRow["type"] as String,
                    ]

                    if let supersetId: Int = exerciseRow["supersetId"] { exerciseDict["superset_id"] = supersetId }

                    // Parse pinned notes JSON array
                    if let pinnedNotesJson: String = exerciseRow["pinnedNotes"] {
                        if let pinnedNotesData = pinnedNotesJson.data(using: .utf8),
                           let pinnedNotesArray = try? JSONSerialization.jsonObject(with: pinnedNotesData) as? [String] {
                            exerciseDict["pinned_notes"] = pinnedNotesArray
                        } else {
                            exerciseDict["pinned_notes"] = [String]()
                        }
                    } else {
                        exerciseDict["pinned_notes"] = [String]()
                    }

                    // Parse notes JSON array
                    if let notesJson: String = exerciseRow["notes"] {
                        if let notesData = notesJson.data(using: .utf8),
                           let notesArray = try? JSONSerialization.jsonObject(with: notesData) as? [String] {
                            exerciseDict["notes"] = notesArray
                        } else {
                            exerciseDict["notes"] = [String]()
                        }
                    } else {
                        exerciseDict["notes"] = [String]()
                    }
                    if let duration: Int = exerciseRow["duration"] { exerciseDict["duration"] = duration }
                    if let weightUnit: String = exerciseRow["weightUnit"] { exerciseDict["weight_unit"] = weightUnit }
                    if let defaultWarmUpTime: Int = exerciseRow["defaultWarmUpTime"] { exerciseDict["default_warm_up_time"] = defaultWarmUpTime }
                    if let defaultRestTime: Int = exerciseRow["defaultRestTime"] { exerciseDict["default_rest_time"] = defaultRestTime }

                    // Parse body part JSON object
                    if let bodyPartJson: String = exerciseRow["bodyPart"] {
                        if let bodyPartData = bodyPartJson.data(using: .utf8),
                           let bodyPartDict = try? JSONSerialization.jsonObject(with: bodyPartData) as? [String: Any] {
                            exerciseDict["body_part"] = bodyPartDict
                        }
                    }

                    // Load sets for this exercise
                    let sets = try Row.fetchAll(db, sql: """
                        SELECT id, exerciseId, workoutId, setIndex, type, weightUnit, suggest, actual, isCompleted
                        FROM exerciseSets WHERE exerciseId = ?
                        ORDER BY setIndex
                    """, arguments: [exerciseRow["id"] as String])

                    var setsArray: [[String: Any]] = []
                    for setRow in sets {
                        var setDict: [String: Any] = [
                            "id": setRow["id"] as String,
                            "exercise_id": setRow["exerciseId"] as String,
                            "workout_id": setRow["workoutId"] as String,
                            "set_index": setRow["setIndex"] as Int,
                            "type": setRow["type"] as String,
                            "is_completed": (setRow["isCompleted"] as? Int ?? 0) != 0,
                        ]

                        if let weightUnit: String = setRow["weightUnit"] { setDict["weight_unit"] = weightUnit }

                        // Parse suggest JSON
                        if let suggestJson: String = setRow["suggest"] {
                            if let suggestData = suggestJson.data(using: .utf8),
                               let suggestDict = try? JSONSerialization.jsonObject(with: suggestData) as? [String: Any] {
                                setDict["suggest"] = suggestDict
                            }
                        }

                        // Parse actual JSON
                        if let actualJson: String = setRow["actual"] {
                            if let actualData = actualJson.data(using: .utf8),
                               let actualDict = try? JSONSerialization.jsonObject(with: actualData) as? [String: Any] {
                                setDict["actual"] = actualDict
                            }
                        }

                        setsArray.append(setDict)
                    }

                    exerciseDict["sets"] = setsArray
                    exercisesArray.append(exerciseDict)
                }

                dict["exercises"] = exercisesArray

                let jsonData = try JSONSerialization.data(withJSONObject: dict)
                return String(data: jsonData, encoding: .utf8)
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
        do {
            try await database.write { db in
                try db.execute(sql: "DELETE FROM workouts WHERE id = ?", arguments: [id])
            }
        
        let result = SharedTypes.DatabaseResult.workoutDeleted
        await core?.sendDatabaseResponse(requestId: requestId, result: result)
        
        } catch {
            print("❌ [DatabaseCapability] Delete failed: \(error)")
            let result = SharedTypes.DatabaseResult.error(message: error.localizedDescription)
            await core?.sendDatabaseResponse(requestId: requestId, result: result)
        }
    }
}
