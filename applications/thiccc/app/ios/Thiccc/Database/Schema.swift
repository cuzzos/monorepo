import Foundation
import GRDB

// MARK: - Database Schema & Migrations

/// Creates and configures the GRDB database for Thiccc.
///
/// This function:
/// 1. Creates a DatabasePool (connection to SQLite file)
/// 2. Enables foreign keys (for referential integrity)
/// 3. Runs migrations (creates tables on first launch)
/// 4. Inserts sample data in DEBUG builds
///
/// # Database Location
/// - Production: `~/Library/Application Support/com.thiccc.app/thiccc.sqlite`
/// - Test: In-memory database
///
/// # Schema
/// Three tables with foreign key relationships:
/// - `workouts` - Top-level workout container
/// - `exercises` - Exercises within workouts (FK: workoutId)
/// - `exerciseSets` - Sets within exercises (FK: exerciseId, workoutId)
///
/// # Migrations
/// - v1: Create initial schema
/// - DEBUG: Insert sample workout data
///
/// - Returns: DatabaseWriter (DatabasePool or DatabaseQueue for tests)
/// - Throws: DatabaseError if initialization fails
func createAppDatabase() throws -> DatabaseWriter {
    // STEP 1: Configure database connection
    var configuration = Configuration()
    configuration.foreignKeysEnabled = true  // Enable CASCADE DELETE
    
    #if DEBUG
    // In DEBUG: Log all SQL queries for debugging
    configuration.prepareDatabase { db in
        db.trace { print("[SQL] \($0.expandedDescription)") }
    }
    #endif
    
    // STEP 2: Determine database file location
    let fileManager = FileManager.default
    let appSupport = try fileManager.url(
        for: .applicationSupportDirectory,
        in: .userDomainMask,
        appropriateFor: nil,
        create: true  // Create directory if doesn't exist
    )
    
    // Database file: ~/Library/Application Support/com.thiccc.app/thiccc.sqlite
    let dbPath = appSupport.appendingPathComponent("thiccc.sqlite").path
    
    #if DEBUG
    print("📍 [Database] Path: \(dbPath)")
    #endif
    
    // STEP 3: Create database connection
    let database = try DatabasePool(path: dbPath, configuration: configuration)
    
    // STEP 4: Set up migrations
    var migrator = DatabaseMigrator()
    
    #if DEBUG
    // In DEBUG builds: Recreate database when schema changes
    // (Faster iteration during development)
    migrator.eraseDatabaseOnSchemaChange = true
    #endif
    
    // MIGRATION v1: Create initial schema
    migrator.registerMigration("v1_create_tables") { db in
        // TABLE 1: Workouts
        // Top-level container for a workout session
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
        
        // TABLE 2: Exercises
        // Exercises performed within a workout
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
                bodyPart TEXT,
                
                FOREIGN KEY(workoutId) REFERENCES workouts(id) ON DELETE CASCADE
            )
        """)
        
        // INDEX: Speed up queries for exercises by workout
        try db.execute(sql: """
            CREATE INDEX IF NOT EXISTS idx_exercises_workoutId 
            ON exercises(workoutId)
        """)
        
        // TABLE 3: Exercise Sets
        // Individual sets performed within an exercise
        try db.execute(sql: """
            CREATE TABLE IF NOT EXISTS exerciseSets (
                id TEXT PRIMARY KEY NOT NULL,
                exerciseId TEXT NOT NULL,
                workoutId TEXT NOT NULL,
                setIndex INTEGER NOT NULL,
                type TEXT NOT NULL,
                weightUnit TEXT,
                suggest TEXT,
                actual TEXT,
                isCompleted INTEGER NOT NULL DEFAULT 0,
                
                FOREIGN KEY(exerciseId) REFERENCES exercises(id) ON DELETE CASCADE,
                FOREIGN KEY(workoutId) REFERENCES workouts(id) ON DELETE CASCADE
            )
        """)
        
        // INDEX: Speed up queries for sets by exercise
        try db.execute(sql: """
            CREATE INDEX IF NOT EXISTS idx_exerciseSets_exerciseId 
            ON exerciseSets(exerciseId)
        """)
        
        // INDEX: Speed up queries for sets by workout
        try db.execute(sql: """
            CREATE INDEX IF NOT EXISTS idx_exerciseSets_workoutId 
            ON exerciseSets(workoutId)
        """)
        
        print("✅ [Database] Tables created successfully")
    }
    
    #if DEBUG
    // MIGRATION (DEBUG only): Insert sample workout data
    migrator.registerMigration("v1_insert_sample_data") { db in
        try insertSampleWorkoutData(db)
    }
    #endif
    
    // STEP 5: Run migrations
    try migrator.migrate(database)
    
    print("✅ [Database] Initialized successfully")
    return database
}

// MARK: - Sample Data (DEBUG Only)

#if DEBUG
/// Inserts sample workout data for testing and development.
///
/// Creates 2 sample workouts:
/// 1. "Morning Run" - Bodyweight cardio workout
/// 2. "Evening Strength" - Barbell bench press + pull-ups
///
/// - Parameter db: Database connection
/// - Throws: DatabaseError if insertion fails
private func insertSampleWorkoutData(_ db: Database) throws {
    print("📝 [Database] Inserting sample workout data...")
    
    // Check if data already exists
    let count = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM workouts") ?? 0
    if count > 0 {
        print("ℹ️  [Database] Sample data already exists, skipping")
        return
    }
    
    // SAMPLE WORKOUT 1: Morning Run
    let workout1Id = "sample-workout-1"
    let exercise1Id = "sample-exercise-1"
    
    try db.execute(sql: """
        INSERT INTO workouts (id, name, note, duration, startTimestamp, endTimestamp)
        VALUES (?, ?, ?, ?, ?, ?)
    """, arguments: [
        workout1Id,
        "Morning Run",
        "Felt good today",
        1800,  // 30 minutes
        Date().addingTimeInterval(-86400).timeIntervalSince1970,  // Yesterday
        Date().addingTimeInterval(-86400 + 1800).timeIntervalSince1970
    ])
    
    try db.execute(sql: """
        INSERT INTO exercises (id, workoutId, name, type)
        VALUES (?, ?, ?, ?)
    """, arguments: [
        exercise1Id,
        workout1Id,
        "Running",
        "bodyweight"
    ])
    
    try db.execute(sql: """
        INSERT INTO exerciseSets (id, exerciseId, workoutId, setIndex, type, actual, isCompleted)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    """, arguments: [
        "sample-set-1",
        exercise1Id,
        workout1Id,
        0,
        "working",
        #"{"reps":32,"duration":1800,"rpe":8.0}"#,
        1  // true
    ])
    
    // SAMPLE WORKOUT 2: Evening Strength
    let workout2Id = "sample-workout-2"
    let exercise2Id = "sample-exercise-2"
    let exercise3Id = "sample-exercise-3"
    
    try db.execute(sql: """
        INSERT INTO workouts (id, name, note, duration, startTimestamp, endTimestamp)
        VALUES (?, ?, ?, ?, ?, ?)
    """, arguments: [
        workout2Id,
        "Evening Strength",
        "Good session, increased weight on bench",
        3600,  // 60 minutes
        Date().addingTimeInterval(-172800).timeIntervalSince1970,  // 2 days ago
        Date().addingTimeInterval(-172800 + 3600).timeIntervalSince1970
    ])
    
    // Exercise 2: Bench Press (3 sets)
    try db.execute(sql: """
        INSERT INTO exercises (id, workoutId, name, type, weightUnit, defaultRestTime, bodyPart)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    """, arguments: [
        exercise2Id,
        workout2Id,
        "Bench Press",
        "barbell",
        "lb",
        90,
        #"{"main":"chest"}"#
    ])
    
    // Set 1: 135 lbs × 12 reps
    try db.execute(sql: """
        INSERT INTO exerciseSets (id, exerciseId, workoutId, setIndex, type, weightUnit, actual, isCompleted)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    """, arguments: [
        "sample-set-2",
        exercise2Id,
        workout2Id,
        0,
        "working",
        "lb",
        #"{"weight":135,"reps":12,"rpe":7.5}"#,
        1
    ])
    
    // Set 2: 160 lbs × 8 reps
    try db.execute(sql: """
        INSERT INTO exerciseSets (id, exerciseId, workoutId, setIndex, type, weightUnit, actual, isCompleted)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    """, arguments: [
        "sample-set-3",
        exercise2Id,
        workout2Id,
        1,
        "working",
        "lb",
        #"{"weight":160,"reps":8,"rpe":8.5}"#,
        1
    ])
    
    // Set 3: 175 lbs × 5 reps
    try db.execute(sql: """
        INSERT INTO exerciseSets (id, exerciseId, workoutId, setIndex, type, weightUnit, actual, isCompleted)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    """, arguments: [
        "sample-set-4",
        exercise2Id,
        workout2Id,
        2,
        "working",
        "lb",
        #"{"weight":175,"reps":5,"rpe":9.5}"#,
        1
    ])
    
    // Exercise 3: Pull-ups (3 sets)
    try db.execute(sql: """
        INSERT INTO exercises (id, workoutId, supersetId, name, type, defaultRestTime, bodyPart)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    """, arguments: [
        exercise3Id,
        workout2Id,
        0,  // Superset with exercise 2
        "Pull Up",
        "bodyweight",
        60,
        #"{"main":"back"}"#
    ])
    
    // Pull-up sets
    let pullupSets = [(12, 8.0), (8, 8.5), (7, 9.5)]
    for (index, (reps, rpe)) in pullupSets.enumerated() {
        try db.execute(sql: """
            INSERT INTO exerciseSets (id, exerciseId, workoutId, setIndex, type, actual, isCompleted)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        """, arguments: [
            "sample-set-pullup-\(index)",
            exercise3Id,
            workout2Id,
            index,
            "working",
            #"{"reps":\#(reps),"rpe":\#(rpe)}"#,
            1
        ])
    }
    
    print("✅ [Database] Sample data inserted (2 workouts, 2 exercises each)")
}
#endif


