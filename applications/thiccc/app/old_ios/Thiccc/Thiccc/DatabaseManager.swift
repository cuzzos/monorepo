import Foundation
import SQLite3

/// Database manager for persisting workouts, exercises, and sets
/// This is a Swift implementation that matches the Rust database interface
class DatabaseManager {
    private var db: OpaquePointer?
    private let dbPath: String
    
    init() {
        // Get documents directory
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        dbPath = documentsPath.appendingPathComponent("thiccc.db").path
        
        // Initialize database
        if sqlite3_open(dbPath, &db) == SQLITE_OK {
            initSchema()
        } else {
            print("Error opening database: \(String(cString: sqlite3_errmsg(db)))")
        }
    }
    
    deinit {
        if db != nil {
            sqlite3_close(db)
        }
    }
    
    private func initSchema() {
        // Enable foreign keys
        execute("PRAGMA foreign_keys = ON")
        
        // Create workouts table
        execute("""
            CREATE TABLE IF NOT EXISTS workouts (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                startTimestamp INTEGER NOT NULL,
                note TEXT,
                duration INTEGER,
                endTimestamp INTEGER
            )
        """)
        
        // Create exercises table
        execute("""
            CREATE TABLE IF NOT EXISTS exercises (
                id TEXT PRIMARY KEY,
                workoutId TEXT NOT NULL,
                supersetId TEXT,
                name TEXT NOT NULL,
                pinnedNotes TEXT,
                notes TEXT,
                duration INTEGER,
                type TEXT NOT NULL,
                weightUnit TEXT,
                defaultWarmUpTime INTEGER,
                defaultRestTime INTEGER,
                bodyPart TEXT,
                FOREIGN KEY(workoutId) REFERENCES workouts(id) ON DELETE CASCADE
            )
        """)
        
        // Create index on exercises.workoutId
        execute("CREATE INDEX IF NOT EXISTS exercises_workoutId ON exercises(workoutId)")
        
        // Create exerciseSets table
        execute("""
            CREATE TABLE IF NOT EXISTS exerciseSets (
                id TEXT PRIMARY KEY,
                exerciseId TEXT NOT NULL,
                workoutId TEXT NOT NULL,
                setIndex INTEGER NOT NULL,
                type TEXT NOT NULL,
                weightUnit TEXT,
                suggest TEXT,
                actual TEXT,
                isCompleted INTEGER NOT NULL DEFAULT 0,
                FOREIGN KEY(exerciseId) REFERENCES exercises(id) ON DELETE CASCADE
            )
        """)
    }
    
    private func execute(_ sql: String) {
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) != SQLITE_DONE {
                print("Error executing SQL: \(String(cString: sqlite3_errmsg(db)))")
            }
        } else {
            print("Error preparing SQL: \(String(cString: sqlite3_errmsg(db)))")
        }
        sqlite3_finalize(statement)
    }
    
    // MARK: - Workout Operations
    
    func saveWorkout(_ workout: Workout) {
        guard let db = db else { return }
        
        // Begin transaction
        execute("BEGIN TRANSACTION")
        
        defer {
            execute("COMMIT")
        }
        
        // Save workout
        let workoutSQL = """
            INSERT OR REPLACE INTO workouts (id, name, startTimestamp, note, duration, endTimestamp)
            VALUES (?, ?, ?, ?, ?, ?)
        """
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, workoutSQL, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, workout.id.uuidString, -1, nil)
            sqlite3_bind_text(statement, 2, (workout.name as NSString).utf8String, -1, nil)
            sqlite3_bind_int64(statement, 3, Int64(workout.startTimestamp.timeIntervalSince1970))
            if let note = workout.note {
                sqlite3_bind_text(statement, 4, (note as NSString).utf8String, -1, nil)
            } else {
                sqlite3_bind_null(statement, 4)
            }
            sqlite3_bind_int(statement, 5, Int32(workout.duration ?? 0))
            if let endTimestamp = workout.endTimestamp {
                sqlite3_bind_int64(statement, 6, Int64(endTimestamp.timeIntervalSince1970))
            } else {
                sqlite3_bind_null(statement, 6)
            }
            
            if sqlite3_step(statement) != SQLITE_DONE {
                print("Error saving workout: \(String(cString: sqlite3_errmsg(db)))")
            }
        }
        sqlite3_finalize(statement)
        
        // Save exercises
        for exercise in workout.exercises {
            saveExercise(exercise, workoutId: workout.id)
        }
    }
    
    private func saveExercise(_ exercise: Exercise, workoutId: UUID) {
        guard let db = db else { return }
        
        let exerciseSQL = """
            INSERT OR REPLACE INTO exercises (id, workoutId, supersetId, name, pinnedNotes, notes, duration, type, weightUnit, defaultWarmUpTime, defaultRestTime, bodyPart)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, exerciseSQL, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, exercise.id.uuidString, -1, nil)
            sqlite3_bind_text(statement, 2, workoutId.uuidString, -1, nil)
            if let supersetId = exercise.supersetId {
                sqlite3_bind_int(statement, 3, Int32(supersetId))
            } else {
                sqlite3_bind_null(statement, 3)
            }
            sqlite3_bind_text(statement, 4, (exercise.name as NSString).utf8String, -1, nil)
            
            // Serialize pinnedNotes and notes as JSON arrays
            if let pinnedNotesData = try? JSONEncoder().encode(exercise.pinnedNotes),
               let pinnedNotesJSON = String(data: pinnedNotesData, encoding: .utf8) {
                sqlite3_bind_text(statement, 5, pinnedNotesJSON, -1, nil)
            } else {
                sqlite3_bind_null(statement, 5)
            }
            
            if let notesData = try? JSONEncoder().encode(exercise.notes),
               let notesJSON = String(data: notesData, encoding: .utf8) {
                sqlite3_bind_text(statement, 6, notesJSON, -1, nil)
            } else {
                sqlite3_bind_null(statement, 6)
            }
            
            sqlite3_bind_int(statement, 7, Int32(exercise.duration ?? 0))
            sqlite3_bind_text(statement, 8, exercise.type.rawValue, -1, nil)
            sqlite3_bind_text(statement, 9, exercise.weightUnit?.rawValue, -1, nil)
            sqlite3_bind_int(statement, 10, Int32(exercise.defaultWarmUpTime ?? 0))
            sqlite3_bind_int(statement, 11, Int32(exercise.defaultRestTime ?? 0))
            
            // Serialize bodyPart as JSON
            if let bodyPart = exercise.bodyPart,
               let bodyPartData = try? JSONEncoder().encode(bodyPart),
               let bodyPartJSON = String(data: bodyPartData, encoding: .utf8) {
                sqlite3_bind_text(statement, 12, bodyPartJSON, -1, nil)
            } else {
                sqlite3_bind_null(statement, 12)
            }
            
            if sqlite3_step(statement) != SQLITE_DONE {
                print("Error saving exercise: \(String(cString: sqlite3_errmsg(db)))")
            }
        }
        sqlite3_finalize(statement)
        
        // Save sets
        for set in exercise.sets {
            saveSet(set, exerciseId: exercise.id, workoutId: workoutId)
        }
    }
    
    private func saveSet(_ set: ExerciseSet, exerciseId: UUID, workoutId: UUID) {
        guard let db = db else { return }
        
        let setSQL = """
            INSERT OR REPLACE INTO exerciseSets (id, exerciseId, workoutId, setIndex, type, weightUnit, suggest, actual, isCompleted)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        """
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, setSQL, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, set.id.uuidString, -1, nil)
            sqlite3_bind_text(statement, 2, exerciseId.uuidString, -1, nil)
            sqlite3_bind_text(statement, 3, workoutId.uuidString, -1, nil)
            sqlite3_bind_int(statement, 4, Int32(set.setIndex))
            sqlite3_bind_text(statement, 5, set.type.rawValue, -1, nil)
            sqlite3_bind_text(statement, 6, set.weightUnit?.rawValue, -1, nil)
            
            // Serialize suggest and actual as JSON
            if let suggestData = try? JSONEncoder().encode(set.suggest),
               let suggestJSON = String(data: suggestData, encoding: .utf8) {
                sqlite3_bind_text(statement, 7, suggestJSON, -1, nil)
            } else {
                sqlite3_bind_null(statement, 7)
            }
            
            if let actualData = try? JSONEncoder().encode(set.actual),
               let actualJSON = String(data: actualData, encoding: .utf8) {
                sqlite3_bind_text(statement, 8, actualJSON, -1, nil)
            } else {
                sqlite3_bind_null(statement, 8)
            }
            
            sqlite3_bind_int(statement, 9, set.isCompleted ? 1 : 0)
            
            if sqlite3_step(statement) != SQLITE_DONE {
                print("Error saving set: \(String(cString: sqlite3_errmsg(db)))")
            }
        }
        sqlite3_finalize(statement)
    }
    
    func loadWorkouts() -> [Workout] {
        guard let db = db else { return [] }
        
        var workouts: [Workout] = []
        let sql = "SELECT id, name, startTimestamp, note, duration, endTimestamp FROM workouts ORDER BY startTimestamp DESC"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                guard let idString = sqlite3_column_text(statement, 0),
                      let id = UUID(uuidString: String(cString: idString)),
                      let name = sqlite3_column_text(statement, 1) else {
                    continue
                }
                
                let startTimestamp = Date(timeIntervalSince1970: TimeInterval(sqlite3_column_int64(statement, 2)))
                let note = sqlite3_column_text(statement, 3).map { String(cString: $0) }
                let duration = sqlite3_column_int(statement, 4)
                let endTimestamp = sqlite3_column_text(statement, 5).map { _ in
                    Date(timeIntervalSince1970: TimeInterval(sqlite3_column_int64(statement, 5)))
                }
                
                let exercises = loadExercisesForWorkout(workoutId: id)
                
                let workout = Workout(
                    id: id,
                    name: String(cString: name),
                    note: note,
                    duration: duration > 0 ? Int(duration) : nil,
                    startTimestamp: startTimestamp,
                    endTimestamp: endTimestamp,
                    exercises: exercises
                )
                
                workouts.append(workout)
            }
        }
        sqlite3_finalize(statement)
        
        return workouts
    }
    
    private func loadExercisesForWorkout(workoutId: UUID) -> [Exercise] {
        guard let db = db else { return [] }
        
        var exercises: [Exercise] = []
        let sql = """
            SELECT id, supersetId, name, pinnedNotes, notes, duration, type, weightUnit, defaultWarmUpTime, defaultRestTime, bodyPart
            FROM exercises WHERE workoutId = ?
        """
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, workoutId.uuidString, -1, nil)
            
            while sqlite3_step(statement) == SQLITE_ROW {
                guard let idString = sqlite3_column_text(statement, 0),
                      let id = UUID(uuidString: String(cString: idString)),
                      let name = sqlite3_column_text(statement, 2) else {
                    continue
                }
                
                let supersetId = sqlite3_column_type(statement, 1) == SQLITE_NULL ? nil : Int(sqlite3_column_int(statement, 1))
                
                // Deserialize pinnedNotes and notes from JSON
                var pinnedNotes: [String] = []
                if let pinnedNotesJSON = sqlite3_column_text(statement, 3).map({ String(cString: $0) }),
                   let pinnedNotesData = pinnedNotesJSON.data(using: .utf8),
                   let decoded = try? JSONDecoder().decode([String].self, from: pinnedNotesData) {
                    pinnedNotes = decoded
                }
                
                var notes: [String] = []
                if let notesJSON = sqlite3_column_text(statement, 4).map({ String(cString: $0) }),
                   let notesData = notesJSON.data(using: .utf8),
                   let decoded = try? JSONDecoder().decode([String].self, from: notesData) {
                    notes = decoded
                }
                
                let duration = sqlite3_column_int(statement, 5)
                let typeString = String(cString: sqlite3_column_text(statement, 6)!)
                let weightUnitString = sqlite3_column_text(statement, 7).map { String(cString: $0) }
                let defaultWarmUpTime = sqlite3_column_int(statement, 8)
                let defaultRestTime = sqlite3_column_int(statement, 9)
                let bodyPartJSON = sqlite3_column_text(statement, 10).map { String(cString: $0) }
                
                let exerciseType = ExerciseType(rawValue: typeString) ?? .unknown
                let weightUnit = weightUnitString.flatMap { WeightUnit(rawValue: $0) }
                
                // Deserialize bodyPart from JSON
                var bodyPart: BodyPart? = nil
                if let bodyPartJSON = bodyPartJSON,
                   let bodyPartData = bodyPartJSON.data(using: .utf8),
                   let decoded = try? JSONDecoder().decode(BodyPart.self, from: bodyPartData) {
                    bodyPart = decoded
                }
                
                let sets = loadSetsForExercise(exerciseId: id)
                
                let exercise = Exercise(
                    id: id,
                    supersetId: supersetId,
                    workoutId: workoutId,
                    name: String(cString: name),
                    pinnedNotes: pinnedNotes,
                    notes: notes,
                    duration: duration > 0 ? Int(duration) : nil,
                    type: exerciseType,
                    weightUnit: weightUnit,
                    defaultWarmUpTime: defaultWarmUpTime > 0 ? Int(defaultWarmUpTime) : nil,
                    defaultRestTime: defaultRestTime > 0 ? Int(defaultRestTime) : nil,
                    sets: sets,
                    bodyPart: bodyPart
                )
                
                exercises.append(exercise)
            }
        }
        sqlite3_finalize(statement)
        
        return exercises
    }
    
    private func loadSetsForExercise(exerciseId: UUID) -> [ExerciseSet] {
        guard let db = db else { return [] }
        
        var sets: [ExerciseSet] = []
        let sql = """
            SELECT id, setIndex, type, weightUnit, suggest, actual, isCompleted, workoutId
            FROM exerciseSets WHERE exerciseId = ? ORDER BY setIndex
        """
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, exerciseId.uuidString, -1, nil)
            
            while sqlite3_step(statement) == SQLITE_ROW {
                guard let idString = sqlite3_column_text(statement, 0),
                      let id = UUID(uuidString: String(cString: idString)) else {
                    continue
                }
                
                let setIndex = Int(sqlite3_column_int(statement, 1))
                let typeString = String(cString: sqlite3_column_text(statement, 2)!)
                let weightUnitString = sqlite3_column_text(statement, 3).map { String(cString: $0) }
                let suggestJSON = sqlite3_column_text(statement, 4).map { String(cString: $0) }
                let actualJSON = sqlite3_column_text(statement, 5).map { String(cString: $0) }
                let isCompleted = sqlite3_column_int(statement, 6) != 0
                let workoutIdString = String(cString: sqlite3_column_text(statement, 7)!)
                guard let workoutId = UUID(uuidString: workoutIdString) else { continue }
                
                let setType = SetType(rawValue: typeString) ?? .working
                let weightUnit = weightUnitString.flatMap { WeightUnit(rawValue: $0) }
                
                // Deserialize suggest and actual from JSON
                var suggest = ExerciseSet.Suggest()
                if let suggestJSON = suggestJSON,
                   let suggestData = suggestJSON.data(using: .utf8),
                   let decoded = try? JSONDecoder().decode(ExerciseSet.Suggest.self, from: suggestData) {
                    suggest = decoded
                }
                
                var actual = ExerciseSet.Actual()
                if let actualJSON = actualJSON,
                   let actualData = actualJSON.data(using: .utf8),
                   let decoded = try? JSONDecoder().decode(ExerciseSet.Actual.self, from: actualData) {
                    actual = decoded
                }
                
                let set = ExerciseSet(
                    id: id,
                    type: setType,
                    weightUnit: weightUnit,
                    suggest: suggest,
                    actual: actual,
                    isCompleted: isCompleted,
                    exerciseId: exerciseId,
                    workoutId: workoutId,
                    setIndex: setIndex
                )
                
                sets.append(set)
            }
        }
        sqlite3_finalize(statement)
        
        return sets
    }
    
    func loadWorkout(workoutId: UUID) -> Workout? {
        guard let db = db else { return nil }
        
        let sql = "SELECT id, name, startTimestamp, note, duration, endTimestamp FROM workouts WHERE id = ?"
        var statement: OpaquePointer?
        var workout: Workout?
        
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, workoutId.uuidString, -1, nil)
            
            if sqlite3_step(statement) == SQLITE_ROW {
                guard let idString = sqlite3_column_text(statement, 0),
                      let id = UUID(uuidString: String(cString: idString)),
                      let name = sqlite3_column_text(statement, 1) else {
                    sqlite3_finalize(statement)
                    return nil
                }
                
                let startTimestamp = Date(timeIntervalSince1970: TimeInterval(sqlite3_column_int64(statement, 2)))
                let note = sqlite3_column_text(statement, 3).map { String(cString: $0) }
                let duration = sqlite3_column_int(statement, 4)
                let endTimestamp = sqlite3_column_text(statement, 5).map { _ in
                    Date(timeIntervalSince1970: TimeInterval(sqlite3_column_int64(statement, 5)))
                }
                
                let exercises = loadExercisesForWorkout(workoutId: id)
                
                workout = Workout(
                    id: id,
                    name: String(cString: name),
                    note: note,
                    duration: duration > 0 ? Int(duration) : nil,
                    startTimestamp: startTimestamp,
                    endTimestamp: endTimestamp,
                    exercises: exercises
                )
            }
        }
        sqlite3_finalize(statement)
        
        return workout
    }
}

