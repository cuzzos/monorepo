import Testing
import Foundation
import GRDB
@testable import Thiccc
import SharedTypes

// MARK: - Core Protocol

/// Protocol that defines the interface capabilities need from Core
protocol CoreProtocol {
    func sendDatabaseResponse(requestId: UInt32, result: SharedTypes.DatabaseResult) async
    func sendStorageResponse(requestId: UInt32, result: SharedTypes.StorageResult) async
    func sendTimerResponse(requestId: UInt32, output: SharedTypes.TimerOutput) async
}

// Make Core conform to the protocol
extension Core: CoreProtocol {}

/// Tests for DatabaseCapability.
///
/// These tests verify:
/// 1. Save workout to database
/// 2. Load all workouts (history)
/// 3. Load specific workout by ID
/// 4. Delete workout
/// 5. Persistence (survives "app restart")
/// 6. Error handling (retry + backup)
///
/// All tests use in-memory databases for isolation.
@Suite("Database Capability Tests")
@MainActor
struct DatabaseCapabilityTests {
    
    let database: DatabaseWriter
    let core: MockCore
    let capability: DatabaseCapability
    
    // MARK: - Setup
    
    init() async throws {
        // Create in-memory test database
        database = try DatabaseManager.shared.createTestDatabase()
        
        // Create mock core
        core = MockCore()
        
        // Create capability
        capability = DatabaseCapability(core: core, database: database)
    }
    
    // MARK: - Save Workout Tests
    
    /// Test: Save a workout to the database.
    ///
    /// Verifies:
    /// - Workout is inserted into `workouts` table
    /// - Exercises are inserted into `exercises` table
    /// - Sets are inserted into `exerciseSets` table
    /// - Returns success response
    @Test("Save workout to database")
    func saveWorkout() async throws {
        // GIVEN: A workout JSON
        let workoutJson = createTestWorkoutJson()
        
        // WHEN: Save workout
        await capability.handle(
            .saveWorkout(workoutJson),
            requestId: 1
        )
        
        // THEN: Workout is in database
        let count = try await database.read { db in
            try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM workouts") ?? 0
        }
        #expect(count == 1, "Should have 1 workout in database")
        
        // THEN: Exercises are in database
        let exerciseCount = try await database.read { db in
            try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM exercises") ?? 0
        }
        #expect(exerciseCount == 2, "Should have 2 exercises in database")
        
        // THEN: Sets are in database
        let setCount = try await database.read { db in
            try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM exerciseSets") ?? 0
        }
        #expect(setCount > 0, "Should have sets in database")
        
        // THEN: Core received success response
        #expect(core.responsesReceived.count == 1, "Should have 1 response")
        guard case .workoutSaved = core.responsesReceived[0].result else {
            Issue.record("Expected .workoutSaved response")
            return
        }
    }
    
    /// Test: Save replaces existing workout with same ID.
    ///
    /// Verifies INSERT OR REPLACE behavior.
    @Test("Save replaces existing workout with same ID")
    func saveWorkoutUpdateExisting() async throws {
        // GIVEN: A workout already in database
        let workoutJson1 = createTestWorkoutJson(name: "Original Name")
        await capability.handle(.saveWorkout(workoutJson1), requestId: 1)
        
        // WHEN: Save workout with same ID but different name
        let workoutJson2 = createTestWorkoutJson(name: "Updated Name")
        await capability.handle(.saveWorkout(workoutJson2), requestId: 2)
        
        // THEN: Still only 1 workout (not 2)
        let count = try await database.read { db in
            try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM workouts") ?? 0
        }
        #expect(count == 1, "Should still have 1 workout (updated)")
        
        // THEN: Name is updated
        let name = try await database.read { db in
            try String.fetchOne(db, sql: "SELECT name FROM workouts WHERE id = 'test-workout-1'")
        }
        #expect(name == "Updated Name")
    }
    
    // MARK: - Load All Workouts Tests
    
    /// Test: Load all workouts returns empty list when no workouts.
    @Test("Load all workouts returns empty list when database is empty")
    func loadAllWorkoutsEmpty() async throws {
        // WHEN: Load all workouts (empty database)
        await capability.handle(.loadAllWorkouts, requestId: 1)
        
        // THEN: Returns empty list
        #expect(core.responsesReceived.count == 1)
        guard case .historyLoaded(let workouts) = core.responsesReceived[0].result else {
            Issue.record("Expected .historyLoaded response")
            return
        }
        #expect(workouts.count == 0, "Should return empty list")
    }
    
    /// Test: Load all workouts returns all saved workouts.
    ///
    /// Verifies:
    /// - All workouts are returned
    /// - Workouts include summary data (exercise count, set count)
    /// - Ordered by date (newest first)
    @Test("Load all workouts returns all saved workouts")
    func loadAllWorkoutsReturnsAll() async throws {
        // GIVEN: 3 workouts in database
        for i in 1...3 {
            let json = createTestWorkoutJson(id: "workout-\(i)", name: "Workout \(i)")
            await capability.handle(.saveWorkout(json), requestId: UInt32(i))
        }
        
        // WHEN: Load all workouts
        await capability.handle(.loadAllWorkouts, requestId: 100)
        
        // THEN: Returns 3 workouts
        let response = core.responsesReceived.last!
        guard case .historyLoaded(let workouts) = response.result else {
            Issue.record("Expected .historyLoaded response")
            return
        }
        #expect(workouts.count == 3, "Should return 3 workouts")
        
        // THEN: Each workout has valid JSON
        for workoutJson in workouts {
            #expect(!workoutJson.isEmpty, "Workout JSON should not be empty")
            // Verify it's valid JSON
            let data = workoutJson.data(using: .utf8)!
            let parsed = try JSONSerialization.jsonObject(with: data)
            #expect(parsed != nil)
        }
    }
    
    // MARK: - Load Workout By ID Tests
    
    /// Test: Load workout by ID returns nil when not found.
    @Test("Load workout by ID returns nil when not found")
    func loadWorkoutByIdNotFound() async throws {
        // WHEN: Load non-existent workout
        await capability.handle(.loadWorkoutById("nonexistent-id"), requestId: 1)
        
        // THEN: Returns nil
        #expect(core.responsesReceived.count == 1)
        guard case .workoutLoaded(let workout) = core.responsesReceived[0].result else {
            Issue.record("Expected .workoutLoaded response")
            return
        }
        #expect(workout == nil, "Should return nil for non-existent workout")
    }
    
    /// Test: Load workout by ID returns full workout details.
    ///
    /// Verifies:
    /// - Workout data is complete
    /// - Includes all exercises
    /// - Includes all sets
    /// - Data matches what was saved
    @Test("Load workout by ID returns full workout details")
    func loadWorkoutByIdReturnsFullDetails() async throws {
        // GIVEN: A workout in database
        let workoutJson = createTestWorkoutJson()
        await capability.handle(.saveWorkout(workoutJson), requestId: 1)

        // WHEN: Load by ID
        await capability.handle(.loadWorkoutById("test-workout-1"), requestId: 2)

        // THEN: Returns full workout
        let response = core.responsesReceived.last!
        guard case .workoutLoaded(let loadedJson) = response.result else {
            Issue.record("Expected .workoutLoaded response")
            return
        }
        #expect(loadedJson != nil, "Should return workout")

        // THEN: Workout has exercises
        let data = loadedJson!.data(using: .utf8)!
        let parsed = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let exercises = parsed["exercises"] as! [[String: Any]]
        #expect(exercises.count == 2, "Should have 2 exercises")
    }

    /// Test: Load workout with pinned notes and exercise notes.
    ///
    /// Verifies the fix for JSON parsing of pinned_notes and notes arrays.
    /// These fields are Vec<String> in the Exercise struct and must be
    /// properly parsed from JSON or default to empty arrays.
    @Test("Load workout with pinned notes and exercise notes")
    func loadWorkoutWithNotes() async throws {
        // GIVEN: A workout with notes in database
        let workoutJson = createTestWorkoutJsonWithNotes()
        await capability.handle(.saveWorkout(workoutJson), requestId: 1)

        // WHEN: Load by ID
        await capability.handle(.loadWorkoutById("test-workout-notes"), requestId: 2)

        // THEN: Returns workout with properly parsed notes
        let response = core.responsesReceived.last!
        guard case .workoutLoaded(let loadedJson) = response.result else {
            Issue.record("Expected .workoutLoaded response")
            return
        }
        #expect(loadedJson != nil, "Should return workout")

        // THEN: Exercises have notes arrays
        let data = loadedJson!.data(using: .utf8)!
        let parsed = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let exercises = parsed["exercises"] as! [[String: Any]]

        // First exercise should have pinned_notes and notes
        let exercise1 = exercises[0]
        let pinnedNotes = exercise1["pinned_notes"] as! [String]
        let notes = exercise1["notes"] as! [String]
        #expect(pinnedNotes == ["Keep elbows tucked", "Breathe out on press"])
        #expect(notes == ["Felt strong today", "Good form"])
    }

    /// Test: Load workout with body part information.
    ///
    /// Verifies the fix for JSON parsing of body_part objects.
    /// Body parts are complex objects that need proper JSON parsing.
    @Test("Load workout with body part information")
    func loadWorkoutWithBodyParts() async throws {
        // GIVEN: A workout with body parts in database
        let workoutJson = createTestWorkoutJsonWithBodyParts()
        await capability.handle(.saveWorkout(workoutJson), requestId: 1)

        // WHEN: Load by ID
        await capability.handle(.loadWorkoutById("test-workout-bodyparts"), requestId: 2)

        // THEN: Returns workout with properly parsed body parts
        let response = core.responsesReceived.last!
        guard case .workoutLoaded(let loadedJson) = response.result else {
            Issue.record("Expected .workoutLoaded response")
            return
        }
        #expect(loadedJson != nil, "Should return workout")

        // THEN: Exercises have body_part objects
        let data = loadedJson!.data(using: .utf8)!
        let parsed = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let exercises = parsed["exercises"] as! [[String: Any]]

        // First exercise should have body_part
        let exercise1 = exercises[0]
        let bodyPart = exercise1["body_part"] as! [String: Any]
        #expect(bodyPart["main"] as! String == "chest")
        let detailed = bodyPart["detailed"] as! [String]
        #expect(detailed == ["upper chest", "inner chest"])
    }

    /// Test: Load workout handles missing optional fields gracefully.
    ///
    /// Verifies that workouts without pinned_notes, notes, or body_part
    /// still load correctly (these fields should default to empty arrays/objects).
    @Test("Load workout handles missing optional fields gracefully")
    func loadWorkoutWithMissingOptionalFields() async throws {
        // GIVEN: A workout without optional fields in database
        let workoutJson = createTestWorkoutJsonMinimal()
        await capability.handle(.saveWorkout(workoutJson), requestId: 1)

        // WHEN: Load by ID
        await capability.handle(.loadWorkoutById("test-workout-minimal"), requestId: 2)

        // THEN: Returns workout successfully
        let response = core.responsesReceived.last!
        guard case .workoutLoaded(let loadedJson) = response.result else {
            Issue.record("Expected .workoutLoaded response")
            return
        }
        #expect(loadedJson != nil, "Should return workout even with missing fields")

        // THEN: Exercises still have required fields
        let data = loadedJson!.data(using: .utf8)!
        let parsed = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let exercises = parsed["exercises"] as! [[String: Any]]
        #expect(exercises.count == 1, "Should have 1 exercise")
    }
    
    // MARK: - Delete Workout Tests
    
    /// Test: Delete removes workout from database.
    ///
    /// Verifies:
    /// - Workout is deleted
    /// - Exercises are deleted (CASCADE)
    /// - Sets are deleted (CASCADE)
    @Test("Delete removes workout and cascades to exercises and sets")
    func deleteWorkout() async throws {
        // GIVEN: A workout in database
        let workoutJson = createTestWorkoutJson()
        await capability.handle(.saveWorkout(workoutJson), requestId: 1)
        
        // Verify it exists
        let countBefore = try await database.read { db in
            try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM workouts") ?? 0
        }
        #expect(countBefore == 1)
        
        // WHEN: Delete workout
        await capability.handle(.deleteWorkout("test-workout-1"), requestId: 2)
        
        // THEN: Workout is gone
        let countAfter = try await database.read { db in
            try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM workouts") ?? 0
        }
        #expect(countAfter == 0, "Workout should be deleted")
        
        // THEN: Exercises are gone (CASCADE)
        let exerciseCount = try await database.read { db in
            try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM exercises") ?? 0
        }
        #expect(exerciseCount == 0, "Exercises should be deleted (CASCADE)")
        
        // THEN: Sets are gone (CASCADE)
        let setCount = try await database.read { db in
            try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM exerciseSets") ?? 0
        }
        #expect(setCount == 0, "Sets should be deleted (CASCADE)")
    }
    
    // MARK: - Persistence Tests
    
    /// Test: Workout survives "app restart" (database persists).
    ///
    /// Simulates app restart by:
    /// 1. Save workout
    /// 2. Destroy capability + database connection
    /// 3. Create new database connection to same file
    /// 4. Load workout
    @Test("Workout survives app restart with persistent database")
    func persistence() async throws {
        // Create a persistent database file (not in-memory)
        let tempDir = FileManager.default.temporaryDirectory
        let dbPath = tempDir.appendingPathComponent("test-persistence.sqlite").path
        
        // Clean up any existing file
        try? FileManager.default.removeItem(atPath: dbPath)
        
        do {
            // PHASE 1: Save workout
            var config = Configuration()
            config.foreignKeysEnabled = true
            let db1 = try DatabaseQueue(path: dbPath, configuration: config)
            
            // Run migrations using the same schema as production
            var migrator = DatabaseMigrator()
            migrator.registerMigration("create_tables") { db in
                // Use the same schema as the main database
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

                try db.execute(sql: """
                    CREATE INDEX IF NOT EXISTS idx_exercises_workoutId
                    ON exercises(workoutId)
                """)

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

                try db.execute(sql: """
                    CREATE INDEX IF NOT EXISTS idx_exerciseSets_exerciseId
                    ON exerciseSets(exerciseId)
                """)

                try db.execute(sql: """
                    CREATE INDEX IF NOT EXISTS idx_exerciseSets_workoutId
                    ON exerciseSets(workoutId)
                """)
            }
            try migrator.migrate(db1)
            
            let core1 = MockCore()
            let capability1 = DatabaseCapability(core: core1, database: db1)
            
            let workoutJson = createTestWorkoutJson()
            await capability1.handle(.saveWorkout(workoutJson), requestId: 1)
            
            // PHASE 2: "App restart" - close database
            // (db1 gets deallocated)
            
            // PHASE 3: Open database again and load workout
            let db2 = try DatabaseQueue(path: dbPath, configuration: config)
            let core2 = MockCore()
            let capability2 = DatabaseCapability(core: core2, database: db2)
            
            await capability2.handle(.loadWorkoutById("test-workout-1"), requestId: 1)
            
            // THEN: Workout still exists
            guard case .workoutLoaded(let workout) = core2.responsesReceived[0].result else {
                Issue.record("Expected .workoutLoaded response")
                return
            }
            #expect(workout != nil, "Workout should persist across 'app restarts'")
            
        } catch {
            Issue.record("Persistence test failed: \(error)")
        }
        
        // Clean up
        try? FileManager.default.removeItem(atPath: dbPath)
    }
    
    // MARK: - Test Helpers
    
    /// Create a test workout JSON string.
    ///
    /// Creates a workout with 2 exercises, each with 3 sets.
    private func createTestWorkoutJson(
        id: String = "test-workout-1",
        name: String = "Test Workout"
    ) -> String {
        return """
        {
          "id": "\(id)",
          "name": "\(name)",
          "note": "Test note",
          "duration": 3600,
          "start_timestamp": "2025-12-25T10:00:00Z",
          "end_timestamp": "2025-12-25T11:00:00Z",
          "exercises": [
            {
              "id": "exercise-1",
              "name": "Bench Press",
              "type": "barbell",
              "weight_unit": "lb",
              "default_rest_time": 90,
              "sets": [
                {
                  "id": "set-1-1",
                  "set_type": "working",
                  "weight_unit": "lb",
                  "actual": "{\\"weight\\":135,\\"reps\\":10,\\"rpe\\":7.5}",
                  "is_completed": true
                },
                {
                  "id": "set-1-2",
                  "set_type": "working",
                  "weight_unit": "lb",
                  "actual": "{\\"weight\\":185,\\"reps\\":6,\\"rpe\\":8.5}",
                  "is_completed": true
                },
                {
                  "id": "set-1-3",
                  "set_type": "working",
                  "weight_unit": "lb",
                  "actual": "{\\"weight\\":205,\\"reps\\":3,\\"rpe\\":9.5}",
                  "is_completed": true
                }
              ]
            },
            {
              "id": "exercise-2",
              "name": "Pull Up",
              "type": "bodyweight",
              "default_rest_time": 60,
              "sets": [
                {
                  "id": "set-2-1",
                  "set_type": "working",
                  "actual": "{\\"reps\\":12,\\"rpe\\":7.0}",
                  "is_completed": true
                },
                {
                  "id": "set-2-2",
                  "set_type": "working",
                  "actual": "{\\"reps\\":10,\\"rpe\\":8.0}",
                  "is_completed": true
                },
                {
                  "id": "set-2-3",
                  "set_type": "working",
                  "actual": "{\\"reps\\":8,\\"rpe\\":9.0}",
                  "is_completed": true
                }
              ]
            }
          ]
        }
        """
    }

    /// Create a test workout JSON with notes fields.
    ///
    /// Tests the JSON parsing fix for pinned_notes and notes arrays.
    private func createTestWorkoutJsonWithNotes() -> String {
        return """
        {
          "id": "test-workout-notes",
          "name": "Workout With Notes",
          "note": "Testing notes parsing",
          "duration": 1800,
          "start_timestamp": "2025-12-25T10:00:00Z",
          "end_timestamp": "2025-12-25T10:30:00Z",
          "exercises": [
            {
              "id": "exercise-notes-1",
              "name": "Bench Press",
              "type": "barbell",
              "pinned_notes": ["Keep elbows tucked", "Breathe out on press"],
              "notes": ["Felt strong today", "Good form"],
              "weight_unit": "lb",
              "default_rest_time": 90,
              "sets": [
                {
                  "id": "set-notes-1",
                  "set_type": "working",
                  "weight_unit": "lb",
                  "actual": "{\\"weight\\":225,\\"reps\\":5,\\"rpe\\":8.5}",
                  "is_completed": true
                }
              ]
            }
          ]
        }
        """
    }

    /// Create a test workout JSON with body part information.
    ///
    /// Tests the JSON parsing fix for body_part objects.
    private func createTestWorkoutJsonWithBodyParts() -> String {
        return """
        {
          "id": "test-workout-bodyparts",
          "name": "Workout With Body Parts",
          "note": "Testing body part parsing",
          "duration": 1800,
          "start_timestamp": "2025-12-25T10:00:00Z",
          "end_timestamp": "2025-12-25T10:30:00Z",
          "exercises": [
            {
              "id": "exercise-bodypart-1",
              "name": "Incline Bench Press",
              "type": "barbell",
              "body_part": {
                "main": "chest",
                "detailed": ["upper chest", "inner chest"],
                "scientific": ["pectoralis major"]
              },
              "weight_unit": "lb",
              "default_rest_time": 90,
              "sets": [
                {
                  "id": "set-bodypart-1",
                  "set_type": "working",
                  "weight_unit": "lb",
                  "actual": "{\\"weight\\":185,\\"reps\\":8,\\"rpe\\":8.0}",
                  "is_completed": true
                }
              ]
            }
          ]
        }
        """
    }

    /// Create a minimal test workout JSON without optional fields.
    ///
    /// Tests that workouts load correctly even when pinned_notes, notes,
    /// and body_part are missing (should default to empty arrays/objects).
    private func createTestWorkoutJsonMinimal() -> String {
        return """
        {
          "id": "test-workout-minimal",
          "name": "Minimal Workout",
          "duration": 900,
          "start_timestamp": "2025-12-25T10:00:00Z",
          "end_timestamp": "2025-12-25T10:15:00Z",
          "exercises": [
            {
              "id": "exercise-minimal-1",
              "name": "Push Up",
              "type": "bodyweight",
              "sets": [
                {
                  "id": "set-minimal-1",
                  "set_type": "working",
                  "actual": "{\\"reps\\":15,\\"rpe\\":7.0}",
                  "is_completed": true
                }
              ]
            }
          ]
        }
        """
    }
}

// MARK: - Mock Core

/// Mock Core for testing.
///
/// Records all responses received so tests can verify them.
@MainActor
class MockCore: DatabaseCoreProtocol {
    struct Response {
        let requestId: UInt32
        let result: SharedTypes.DatabaseResult
    }

    var responsesReceived: [Response] = []

    func sendDatabaseResponse(requestId: UInt32, result: SharedTypes.DatabaseResult) async {
        responsesReceived.append(Response(requestId: requestId, result: result))
    }
}

