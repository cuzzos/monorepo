# Phase 9: Database & Persistence Implementation

## Overview

**Goal**: Fully implement GRDB database schema and persistence layer.

**Phase Duration**: Estimated 2-3 hours  
**Complexity**: High  
**Dependencies**: Phase 3 (Capabilities)  
**Blocks**: Phase 7 (History - needs data), End-to-end testing

## Why This Phase Matters

Without persistence:
- Workouts don't save
- History is empty
- App can't be used for real tracking

This phase makes the app actually useful.

## Task Breakdown

### Task 9.1: Set Up GRDB Database Schema

**Estimated Time**: 1 hour  
**Complexity**: Medium  
**Priority**: Critical

#### Objective
Create SQLite database with proper schema, migrations, and indices.

#### Reference Files
- `legacy/Goonlytics/Goonlytics/Sources/Workout/Models/Schema.swift`

#### Implementation

**File**: `/applications/thiccc/app/ios/Thiccc/Database/DatabaseManager.swift` (new file)

```swift
import Foundation
import GRDB

func createAppDatabase() throws -> DatabaseWriter {
    let database: DatabaseWriter
    var configuration = Configuration()
    configuration.foreignKeysEnabled = true
    
    #if DEBUG
    configuration.prepareDatabase { db in
        db.trace { print("SQL: \($0.expandedDescription)") }
    }
    #endif
    
    let fileManager = FileManager.default
    let appSupport = try fileManager.url(
        for: .applicationSupportDirectory,
        in: .userDomainMask,
        appropriateFor: nil,
        create: true
    )
    let dbPath = appSupport.appendingPathComponent("thiccc.sqlite").path
    
    #if DEBUG
    print("Database path: \(dbPath)")
    #endif
    
    database = try DatabasePool(path: dbPath, configuration: configuration)
    
    var migrator = DatabaseMigrator()
    
    #if DEBUG
    // In debug, erase database when schema changes
    migrator.eraseDatabaseOnSchemaChange = true
    #endif
    
    // Create tables migration
    migrator.registerMigration("v1_create_tables") { db in
        // Workouts table
        try db.execute(sql: """
            CREATE TABLE IF NOT EXISTS workouts (
                id TEXT PRIMARY KEY NOT NULL,
                name TEXT NOT NULL,
                note TEXT,
                duration INTEGER,
                startTimestamp REAL NOT NULL,
                endTimestamp REAL
            )
        """)
        
        // Exercises table
        try db.execute(sql: """
            CREATE TABLE IF NOT EXISTS exercises (
                id TEXT PRIMARY KEY NOT NULL,
                workoutId TEXT NOT NULL,
                supersetId INTEGER,
                name TEXT NOT NULL,
                pinnedNotes TEXT,
                notes TEXT,
                duration INTEGER,
                type TEXT NOT NULL,
                weightUnit TEXT,
                defaultWarmUpTime INTEGER,
                defaultRestTime INTEGER,
                bodyPartMain TEXT,
                bodyPartDetailed TEXT,
                bodyPartScientific TEXT,
                FOREIGN KEY(workoutId) REFERENCES workouts(id) ON DELETE CASCADE
            )
        """)
        
        try db.execute(sql: """
            CREATE INDEX IF NOT EXISTS idx_exercises_workoutId 
            ON exercises(workoutId)
        """)
        
        // Exercise sets table
        try db.execute(sql: """
            CREATE TABLE IF NOT EXISTS exerciseSets (
                id TEXT PRIMARY KEY NOT NULL,
                exerciseId TEXT NOT NULL,
                workoutId TEXT NOT NULL,
                setIndex INTEGER NOT NULL,
                type TEXT NOT NULL,
                weightUnit TEXT,
                suggestWeight REAL,
                suggestReps INTEGER,
                suggestRepRange INTEGER,
                suggestDuration INTEGER,
                suggestRpe REAL,
                suggestRestTime INTEGER,
                actualWeight REAL,
                actualReps INTEGER,
                actualDuration INTEGER,
                actualRpe REAL,
                actualRestTime INTEGER,
                isCompleted INTEGER NOT NULL DEFAULT 0,
                FOREIGN KEY(exerciseId) REFERENCES exercises(id) ON DELETE CASCADE,
                FOREIGN KEY(workoutId) REFERENCES workouts(id) ON DELETE CASCADE
            )
        """)
        
        try db.execute(sql: """
            CREATE INDEX IF NOT EXISTS idx_sets_exerciseId 
            ON exerciseSets(exerciseId)
        """)
        
        try db.execute(sql: """
            CREATE INDEX IF NOT EXISTS idx_sets_workoutId 
            ON exerciseSets(workoutId)
        """)
    }
    
    #if DEBUG
    // Add sample data in debug builds
    migrator.registerMigration("v1_sample_data") { db in
        try insertSampleData(db)
    }
    #endif
    
    try migrator.migrate(database)
    
    return database
}

#if DEBUG
private func insertSampleData(_ db: Database) throws {
    // Sample workout from yesterday
    let workout1Id = UUID().uuidString.lowercased()
    try db.execute(
        sql: """
            INSERT INTO workouts (id, name, note, duration, startTimestamp, endTimestamp)
            VALUES (?, ?, ?, ?, ?, ?)
        """,
        arguments: [
            workout1Id,
            "Morning Push",
            "Felt strong today",
            1800, // 30 minutes
            Date().addingTimeInterval(-86400).timeIntervalSince1970,
            Date().addingTimeInterval(-84600).timeIntervalSince1970
        ]
    )
    
    // Sample exercise
    let exercise1Id = UUID().uuidString.lowercased()
    try db.execute(
        sql: """
            INSERT INTO exercises (id, workoutId, name, type, weightUnit)
            VALUES (?, ?, ?, ?, ?)
        """,
        arguments: [exercise1Id, workout1Id, "Bench Press", "barbell", "lb"]
    )
    
    // Sample sets
    for i in 0..<3 {
        let setId = UUID().uuidString.lowercased()
        try db.execute(
            sql: """
                INSERT INTO exerciseSets (
                    id, exerciseId, workoutId, setIndex, type, weightUnit,
                    actualWeight, actualReps, actualRpe, isCompleted
                )
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            arguments: [
                setId, exercise1Id, workout1Id, i, "working", "lb",
                225.0, 10, 8.0, 1
            ]
        )
    }
}
#endif
```

**Success Criteria**:
- [ ] Database file created
- [ ] All tables created with correct schema
- [ ] Foreign keys enabled
- [ ] Indices created for performance
- [ ] Migrations run successfully
- [ ] Sample data inserted in debug

---

### Task 9.2: Implement Database Operations

**Estimated Time**: 1-1.5 hours  
**Complexity**: High  
**Priority**: Critical

#### Objective
Implement all database operations (save, load, delete workouts).

#### Sub-Tasks

##### Sub-Task 9.2.1: Save Workout Operation

**File**: `/applications/thiccc/app/ios/Thiccc/Database/DatabaseOperations.swift` (new file)

```swift
import Foundation
import GRDB
import SharedTypes

extension DatabaseWriter {
    /// Save a complete workout with all exercises and sets
    func saveWorkout(_ workout: Workout) throws {
        try write { db in
            // Insert workout
            try db.execute(
                sql: """
                    INSERT OR REPLACE INTO workouts 
                    (id, name, note, duration, startTimestamp, endTimestamp)
                    VALUES (?, ?, ?, ?, ?, ?)
                """,
                arguments: [
                    workout.id.uuidString.lowercased(),
                    workout.name,
                    workout.note,
                    workout.duration,
                    workout.startTimestamp.timeIntervalSince1970,
                    workout.endTimestamp?.timeIntervalSince1970
                ]
            )
            
            // Insert exercises
            for exercise in workout.exercises {
                // Helper to encode arrays to JSON string
                let pinnedNotesJSON = try? JSONEncoder().encode(exercise.pinnedNotes)
                    .flatMap { String(data: $0, encoding: .utf8) }
                let notesJSON = try? JSONEncoder().encode(exercise.notes)
                    .flatMap { String(data: $0, encoding: .utf8) }
                let detailedJSON = try? exercise.bodyPart?.detailed
                    .flatMap { try? JSONEncoder().encode($0) }
                    .flatMap { String(data: $0, encoding: .utf8) }
                let scientificJSON = try? exercise.bodyPart?.scientific
                    .flatMap { try? JSONEncoder().encode($0) }
                    .flatMap { String(data: $0, encoding: .utf8) }
                
                try db.execute(
                    sql: """
                        INSERT OR REPLACE INTO exercises
                        (id, workoutId, supersetId, name, pinnedNotes, notes,
                         duration, type, weightUnit, defaultWarmUpTime, defaultRestTime,
                         bodyPartMain, bodyPartDetailed, bodyPartScientific)
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """,
                    arguments: [
                        exercise.id.uuidString.lowercased(),
                        workout.id.uuidString.lowercased(),
                        exercise.supersetId,
                        exercise.name,
                        pinnedNotesJSON,
                        notesJSON,
                        exercise.duration,
                        exercise.exerciseType.rawValue,
                        exercise.weightUnit?.rawValue,
                        exercise.defaultWarmUpTime,
                        exercise.defaultRestTime,
                        exercise.bodyPart?.main.rawValue,
                        detailedJSON,
                        scientificJSON
                    ]
                )
                
                // Insert sets
                for set in exercise.sets {
                    try db.execute(
                        sql: """
                            INSERT OR REPLACE INTO exerciseSets
                            (id, exerciseId, workoutId, setIndex, type, weightUnit,
                             suggestWeight, suggestReps, suggestRepRange, suggestDuration,
                             suggestRpe, suggestRestTime,
                             actualWeight, actualReps, actualDuration, actualRpe, actualRestTime,
                             isCompleted)
                            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                        """,
                        arguments: [
                            set.id.uuidString.lowercased(),
                            exercise.id.uuidString.lowercased(),
                            workout.id.uuidString.lowercased(),
                            set.setIndex,
                            set.setType.rawValue,
                            set.weightUnit?.rawValue,
                            set.suggest.weight,
                            set.suggest.reps,
                            set.suggest.repRange,
                            set.suggest.duration,
                            set.suggest.rpe,
                            set.suggest.restTime,
                            set.actual.weight,
                            set.actual.reps,
                            set.actual.duration,
                            set.actual.rpe,
                            set.actual.actualRestTime,
                            set.isCompleted ? 1 : 0
                        ]
                    )
                }
            }
        }
    }
}
```

##### Sub-Task 9.2.2: Load Workouts Operation

```swift
extension DatabaseReader {
    /// Load all workouts with their exercises and sets
    func loadAllWorkouts() throws -> [Workout] {
        try read { db in
            // Load all workouts
            let workoutRows = try Row.fetchAll(db, sql: "SELECT * FROM workouts ORDER BY startTimestamp DESC")
            
            var workouts: [Workout] = []
            
            for row in workoutRows {
                let workoutId = row["id"] as String
                
                // Load exercises for this workout
                let exerciseRows = try Row.fetchAll(
                    db,
                    sql: "SELECT * FROM exercises WHERE workoutId = ? ORDER BY ROWID",
                    arguments: [workoutId]
                )
                
                var exercises: [Exercise] = []
                
                for exerciseRow in exerciseRows {
                    let exerciseId = exerciseRow["id"] as String
                    
                    // Load sets for this exercise
                    let setRows = try Row.fetchAll(
                        db,
                        sql: "SELECT * FROM exerciseSets WHERE exerciseId = ? ORDER BY setIndex",
                        arguments: [exerciseId]
                    )
                    
                    let sets = try setRows.map { try parseExerciseSet($0) }
                    let exercise = try parseExercise(exerciseRow, sets: sets)
                    exercises.append(exercise)
                }
                
                let workout = try parseWorkout(row, exercises: exercises)
                workouts.append(workout)
            }
            
            return workouts
        }
    }
    
    /// Load a specific workout by ID
    func loadWorkout(id: UUID) throws -> Workout? {
        try read { db in
            guard let row = try Row.fetchOne(
                db,
                sql: "SELECT * FROM workouts WHERE id = ?",
                arguments: [id.uuidString.lowercased()]
            ) else {
                return nil
            }
            
            // Load exercises and sets...
            // (Similar to loadAllWorkouts but for single workout)
            
            return try parseWorkout(row, exercises: [])
        }
    }
    
    // Helper parsers
    private func parseWorkout(_ row: Row, exercises: [Exercise]) throws -> Workout {
        Workout(
            id: UUID(uuidString: row["id"])!,
            name: row["name"],
            note: row["note"],
            duration: row["duration"],
            startTimestamp: Date(timeIntervalSince1970: row["startTimestamp"]),
            endTimestamp: (row["endTimestamp"] as Double?).map { Date(timeIntervalSince1970: $0) },
            exercises: exercises
        )
    }
    
    private func parseExercise(_ row: Row, sets: [ExerciseSet]) throws -> Exercise {
        // Helper to decode JSON strings from TEXT columns
        func decodeJSONArray<T: Decodable>(_ columnName: String) -> [T] {
            guard let jsonString: String = row[columnName],
                  let data = jsonString.data(using: .utf8),
                  let decoded = try? JSONDecoder().decode([T].self, from: data) else {
                return []
            }
            return decoded
        }
        
        Exercise(
            id: UUID(uuidString: row["id"])!,
            supersetId: row["supersetId"],
            workoutId: UUID(uuidString: row["workoutId"])!,
            name: row["name"],
            pinnedNotes: decodeJSONArray("pinnedNotes"),
            notes: decodeJSONArray("notes"),
            duration: row["duration"],
            exerciseType: ExerciseType(rawValue: row["type"])!,
            weightUnit: (row["weightUnit"] as String?).flatMap { WeightUnit(rawValue: $0) },
            defaultWarmUpTime: row["defaultWarmUpTime"],
            defaultRestTime: row["defaultRestTime"],
            sets: sets,
            bodyPart: nil // TODO: Parse bodyPartDetailed and bodyPartScientific using decodeJSONArray
        )
    }
    
    private func parseExerciseSet(_ row: Row) throws -> ExerciseSet {
        ExerciseSet(
            id: UUID(uuidString: row["id"])!,
            setType: SetType(rawValue: row["type"])!,
            weightUnit: (row["weightUnit"] as String?).flatMap { WeightUnit(rawValue: $0) },
            suggest: SetSuggest(
                weight: row["suggestWeight"],
                reps: row["suggestReps"],
                repRange: row["suggestRepRange"],
                duration: row["suggestDuration"],
                rpe: row["suggestRpe"],
                restTime: row["suggestRestTime"]
            ),
            actual: SetActual(
                weight: row["actualWeight"],
                reps: row["actualReps"],
                duration: row["actualDuration"],
                rpe: row["actualRpe"],
                actualRestTime: row["actualRestTime"]
            ),
            isCompleted: (row["isCompleted"] as Int) == 1,
            exerciseId: UUID(uuidString: row["exerciseId"])!,
            workoutId: UUID(uuidString: row["workoutId"])!,
            setIndex: row["setIndex"]
        )
    }
}
```

**Success Criteria**:
- [ ] Can save workout to database
- [ ] Can load all workouts
- [ ] Can load specific workout
- [ ] All exercises loaded
- [ ] All sets loaded
- [ ] Data integrity maintained

---

### Task 9.3: Integrate Database with Capability

**Estimated Time**: 30 minutes  
**Complexity**: Low  
**Priority**: Critical

#### Objective
Wire database operations into DatabaseCapability from Phase 3.

#### Implementation

**File**: `/applications/thiccc/app/ios/Thiccc/Capabilities/DatabaseCapability.swift`

```swift
import Foundation
import GRDB
import SharedTypes

class DatabaseCapability {
    let database: DatabaseWriter
    
    init(database: DatabaseWriter) {
        self.database = database
    }
    
    func handle(_ operation: DatabaseOperation, core: Core) async {
        switch operation {
        case .saveWorkout(let workout):
            do {
                try database.saveWorkout(workout)
                core.handleDatabaseResponse(.workoutSaved)
            } catch {
                core.handleDatabaseResponse(.error(error.localizedDescription))
            }
            
        case .loadAllWorkouts:
            do {
                let workouts = try database.loadAllWorkouts()
                core.handleDatabaseResponse(.workoutsLoaded(workouts))
            } catch {
                core.handleDatabaseResponse(.error(error.localizedDescription))
            }
            
        case .loadWorkoutById(let id):
            do {
                let workout = try database.loadWorkout(id: id)
                core.handleDatabaseResponse(.workoutLoaded(workout))
            } catch {
                core.handleDatabaseResponse(.error(error.localizedDescription))
            }
            
        case .deleteWorkout(let id):
            do {
                try database.write { db in
                    try db.execute(
                        sql: "DELETE FROM workouts WHERE id = ?",
                        arguments: [id.uuidString.lowercased()]
                    )
                }
                core.handleDatabaseResponse(.workoutDeleted)
            } catch {
                core.handleDatabaseResponse(.error(error.localizedDescription))
            }
        }
    }
}
```

**Success Criteria**:
- [ ] Capability handles all operations
- [ ] Success responses sent to core
- [ ] Error responses sent to core
- [ ] All operations work end-to-end

---

## Phase 9 Completion Checklist

Before moving to next phases, verify:

- [ ] Database schema created
- [ ] All tables exist with correct structure
- [ ] Foreign keys working
- [ ] Indices created
- [ ] Can save workouts
- [ ] Can load workouts
- [ ] Can load specific workout
- [ ] Can delete workouts
- [ ] Sample data inserted (debug)
- [ ] Database capability integrated
- [ ] Code compiles without errors
- [ ] Database operations work in simulator

## Testing Phase 9

### Manual Testing

Complete workout flow:
- [ ] Start workout
- [ ] Add exercises and sets
- [ ] Enter data
- [ ] Finish workout
- [ ] Verify saved to database (check file)
- [ ] Open History tab
- [ ] See completed workout
- [ ] Tap workout → see detail
- [ ] All data displays correctly

### Database Verification

```bash
# Find database file
find ~/Library/Developer/CoreSimulator -name "thiccc.sqlite" 2>/dev/null

# Open with sqlite3
sqlite3 /path/to/thiccc.sqlite

# Query workouts
SELECT * FROM workouts;
SELECT * FROM exercises;
SELECT * FROM exerciseSets;
```

## Common Issues & Solutions

### Issue: Foreign key constraint failures
**Solution**: Ensure IDs are lowercase, UUIDs match

### Issue: Data not loading
**Solution**: Check parsers, verify column names match

### Issue: JSON encoding to TEXT columns fails
**Solution**: `JSONEncoder().encode()` returns `Data`, not `String`. TEXT columns require String conversion:
```swift
// ❌ Wrong - Data can't be inserted into TEXT
try? JSONEncoder().encode(array)

// ✅ Correct - Convert Data to String
try? JSONEncoder().encode(array)
    .flatMap { String(data: $0, encoding: .utf8) }
```

### Issue: JSON decoding from TEXT columns fails
**Solution**: TEXT columns return `String`, but `JSONDecoder` expects `Data`. Convert first:
```swift
// ❌ Wrong - row returns String, decoder expects Data
try? JSONDecoder().decode([String].self, from: row["column"])

// ✅ Correct - Convert String to Data first
if let jsonString: String = row["column"],
   let data = jsonString.data(using: .utf8) {
    try? JSONDecoder().decode([String].self, from: data)
}
```

### Issue: Slow queries
**Solution**: Verify indices are created, use EXPLAIN QUERY PLAN

### Issue: Database file not found
**Solution**: Check path, ensure application support directory created

## Next Steps

After completing Phase 9:
- **[Phase 10: Additional Business Logic](./10-PHASE-10-ADDITIONAL-LOGIC.md)** - Stats, calculator
- **[Phase 11: Polish & Testing](./11-PHASE-11-POLISH.md)** - Final touches

---

**Phase Status**: 📋 Ready for Implementation  
**Last Updated**: November 26, 2025

