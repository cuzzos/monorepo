import Foundation
import GRDB

// MARK: - Database Manager

/// Manages the GRDB database instance for the Thiccc app.
///
/// This singleton provides access to the database throughout the app.
/// Call `shared.setup()` once during app launch to initialize.
///
/// # Usage
/// ```swift
/// // In ThicccApp.swift:
/// @main
/// struct ThicccApp: App {
///     init() {
///         try? DatabaseManager.shared.setup()
///     }
/// }
///
/// // In capabilities:
/// let db = DatabaseManager.shared.database
/// try await db.write { db in
///     try workout.save(db)
/// }
/// ```
final class DatabaseManager {
    // MARK: - Singleton
    
    /// Shared instance of the database manager.
    ///
    /// Use this singleton to access the database throughout the app.
    static let shared = DatabaseManager()
    
    // MARK: - Properties
    
    /// The GRDB database writer.
    ///
    /// Provides read and write access to the SQLite database.
    /// Nil until `setup()` is called.
    private(set) var database: DatabaseWriter?
    
    // MARK: - Initialization
    
    /// Private initializer (singleton pattern).
    private init() {}
    
    // MARK: - Setup
    
    /// Initializes the database.
    ///
    /// This must be called once during app launch, before any database operations.
    /// Safe to call multiple times (subsequent calls are ignored).
    ///
    /// # What it does:
    /// 1. Creates database file if doesn't exist
    /// 2. Runs migrations (creates tables)
    /// 3. Inserts sample data (DEBUG only)
    ///
    /// - Throws: DatabaseError if initialization fails
    func setup() throws {
        // Skip if already initialized
        guard database == nil else {
            return
        }
        
        do {
            // Create database using schema definition
            database = try createAppDatabase()
        } catch {
            print("❌ [DatabaseManager] Setup failed: \(error)")
            throw error
        }
    }
    
    // MARK: - Test Support
    
    /// Creates an in-memory database for testing.
    ///
    /// Used by unit tests to create isolated test databases.
    /// Each test gets a fresh, empty database.
    ///
    /// # Example
    /// ```swift
    /// func setUp() throws {
    ///     database = try DatabaseManager.shared.createTestDatabase()
    /// }
    /// ```
    ///
    /// - Returns: In-memory DatabaseWriter
    /// - Throws: DatabaseError if creation fails
    func createTestDatabase() throws -> DatabaseWriter {
        print("🧪 [DatabaseManager] Creating test database (in-memory)")
        
        // Create in-memory database
        var configuration = Configuration()
        configuration.foreignKeysEnabled = true
        let testDB = try DatabaseQueue(configuration: configuration)
        
        // Run migrations to create schema
        var migrator = DatabaseMigrator()
        
        migrator.registerMigration("v1_create_tables") { db in
            // Same schema as production (copy from Schema.swift)
            try db.execute(sql: """
                CREATE TABLE workouts (
                    id TEXT PRIMARY KEY NOT NULL,
                    name TEXT NOT NULL,
                    note TEXT,
                    duration INTEGER,
                    startTimestamp REAL NOT NULL,
                    endTimestamp REAL
                )
            """)
            
            try db.execute(sql: """
                CREATE TABLE exercises (
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
            
            try db.execute(sql: """
                CREATE INDEX idx_exercises_workoutId ON exercises(workoutId)
            """)
            
            try db.execute(sql: """
                CREATE TABLE exerciseSets (
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
            
            try db.execute(sql: """
                CREATE INDEX idx_exerciseSets_exerciseId ON exerciseSets(exerciseId)
            """)
            
            try db.execute(sql: """
                CREATE INDEX idx_exerciseSets_workoutId ON exerciseSets(workoutId)
            """)
        }
        
        try migrator.migrate(testDB)
        
        print("✅ [DatabaseManager] Test database ready")
        return testDB
    }
    
    // MARK: - Reset (DEBUG Only)
    
    #if DEBUG
    /// Resets the database by deleting the file and recreating it.
    ///
    /// ⚠️ WARNING: This deletes ALL user data!
    /// Only available in DEBUG builds.
    ///
    /// Useful for:
    /// - Testing migrations
    /// - Clearing test data
    /// - Development iteration
    ///
    /// - Throws: DatabaseError if reset fails
    func resetDatabase() throws {
        print("🗑️  [DatabaseManager] Resetting database...")
        
        // Close current database
        database = nil
        
        // Delete database file
        let fileManager = FileManager.default
        let appSupport = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        )
        let dbPath = appSupport.appendingPathComponent("thiccc.sqlite")
        
        if fileManager.fileExists(atPath: dbPath.path) {
            try fileManager.removeItem(at: dbPath)
            print("🗑️  [DatabaseManager] Database file deleted")
        }
        
        // Recreate database
        try setup()
        
        print("✅ [DatabaseManager] Database reset complete")
    }
    #endif
}


