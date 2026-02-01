import Foundation
import GRDB

// MARK: - Database Schema & Migrations

/// Creates and configures the GRDB database for Thiccc.
///
/// This function:
/// 1. Creates a DatabasePool (connection to SQLite file)
/// 2. Enables foreign keys (for referential integrity)
/// 3. Runs migrations (creates tables on first launch)
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
    
    // STEP 5: Run migrations
    try migrator.migrate(database)
    
    print("✅ [Database] Initialized successfully")
    return database
}
