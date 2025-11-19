import Dependencies
import Foundation
import GRDB
import SharingGRDB

// MARK: - Database Setup

func appDatabase() throws -> any DatabaseWriter {
    let database: any DatabaseWriter
    var configuration = Configuration()
    configuration.foreignKeysEnabled = true
    configuration.prepareDatabase { db in
        #if DEBUG
        db.trace(options: .profile) {
            print($0.expandedDescription)
        }
        #endif
    }
    
    @Dependency(\.context) var context
    if context == .live {
        let path = URL.documentsDirectory.appending(component: "db.sqlite").path()
        print("open", path)
        database = try DatabasePool(path: path, configuration: configuration)
    } else {
        database = try DatabaseQueue(configuration: configuration)
    }
    
    var migrator = DatabaseMigrator()
    #if DEBUG
    migrator.eraseDatabaseOnSchemaChange = true
    #endif
    
    migrator.registerMigration("Create tables") { db in
        try #sql("""
            CREATE TABLE "workouts" (
                "id" TEXT PRIMARY KEY,
                "name" TEXT NOT NULL,
                "startTimestamp" DATETIME NOT NULL,
                "note" TEXT,
                "duration" INTEGER,
                "endTimestamp" DATETIME
            )
        """).execute(db)
        
        try #sql("""
            CREATE TABLE "exercises" (
                "id" TEXT PRIMARY KEY,
                "workoutId" TEXT NOT NULL,
                "supersetId" INTEGER,
                "name" TEXT NOT NULL,
                "pinnedNotes" BLOB,
                "notes" BLOB,
                "duration" INTEGER,
                "type" TEXT NOT NULL,
                "weightUnit" TEXT,
                "defaultWarmUpTime" INTEGER,
                "defaultRestTime" INTEGER,
                "bodyPart" TEXT,
                
                FOREIGN KEY("workoutId") REFERENCES "workouts"("id") ON DELETE CASCADE
            )
        """).execute(db)
        
        try #sql("""
            CREATE INDEX "exercises_workoutId" ON "exercises"("workoutId")
        """).execute(db)
        
        try #sql("""
            CREATE TABLE "exerciseSets" (
                "id" TEXT PRIMARY KEY,
                "exerciseId" TEXT NOT NULL,
                "workoutId" TEXT NOT NULL,
                "setIndex" INTEGER NOT NULL,
                "type" TEXT NOT NULL,
                "weightUnit" TEXT,
                "suggest" TEXT,
                "actual" TEXT,
                
                FOREIGN KEY("exerciseId") REFERENCES "exercises"("id") ON DELETE CASCADE
            )
        """).execute(db)
        
//        try #sql("""
//            CREATE INDEX "exerciseSetsExerciseIdSetIndex" ON "exerciseSets"("exerciseId", "setIndex")
//        """).execute(db)
    }
    
    #if DEBUG
    migrator.registerMigration("Insert sample data") { db in
        try db.insertSampleWorkoutData()
    }
    #endif
    
    try migrator.migrate(database)
    
    return database
}

#if DEBUG
extension Workout {
    static let mock = {
        @Dependency(\.uuid) var uuid
        // Sample workout 1
        let workout1ID = uuid()
        let exercise1ID = uuid()
        
        return Workout(
            id: workout1ID,
            name: "Morning Run",
            note: "Felt good today",
            duration: 1800, // 30 minutes
            startTimestamp: Date().addingTimeInterval(-86400), // Yesterday
            endTimestamp: Date().addingTimeInterval(-86400).addingTimeInterval(1800),
            exercises: [
                Exercise(
                    id: exercise1ID,
                    supersetId: nil,
                    workoutId: workout1ID,
                    name: "Running",
                    pinnedNotes: [],
                    notes: ["Easy pace"],
                    duration: 1800,
                    type: .bodyweight,
                    weightUnit: nil,
                    defaultWarmUpTime: nil,
                    defaultRestTime: nil,
                    sets: [
                        ExerciseSet(
                            id: uuid(),
                            type: .working,
                            weightUnit: nil,
                            suggest: .init(
                                weight: 0,
                                reps: 30,
                                repRange: nil,
                                duration: 1800,
                                rpe: 7.5,
                                restTime: nil
                            ),
                            actual: .init(
                                weight: 0,
                                reps: 32,
                                rpe: 8.0
                            ),
                            isCompleted: true,
                            exerciseId: exercise1ID,
                            workoutId: workout1ID,
                            setIndex: 0
                        )
                    ],
                    bodyPart: nil
                )
            ]
        )
    }()
}

extension Database {
    func insertSampleWorkoutData() throws {
        @Dependency(\.uuid) var uuid
        // Sample workout 1
        // Create workout 1
        let workout1 = try Workout.mock
    
        // Sample workout 2
        let workout2ID = uuid()
        let exercise2ID = uuid()
        let exercise3ID = uuid()

        // Create workout 2
        let workout2 = Workout(
            id: workout2ID,
            name: "Evening Strength",
            note: "Good session, increased weight on bench",
            duration: 3600, // 60 minutes
            startTimestamp: Date().addingTimeInterval(-172800), // 2 days ago
            endTimestamp: Date().addingTimeInterval(-172800).addingTimeInterval(3600),
            exercises: [
                Exercise(
                    id: exercise2ID,
                    supersetId: nil,
                    workoutId: workout2ID,
                    name: "Bench Press",
                    pinnedNotes: [],
                    notes: ["Focus on form"],
                    duration: nil,
                    type: .barbell,
                    weightUnit: .lb,
                    defaultWarmUpTime: 60,
                    defaultRestTime: 90,
                    sets: [
                        ExerciseSet(
                            id: uuid(),
                            type: .working,
                            weightUnit: .lb,
                            suggest: .init(
                                weight: 135,
                                reps: 10,
                                repRange: nil,
                                duration: nil,
                                rpe: 7.0,
                                restTime: 90
                            ),
                            actual: .init(
                                weight: 135,
                                reps: 12,
                                rpe: 7.5
                            ),
                            isCompleted: true,
                            exerciseId: exercise2ID,
                            workoutId: workout2ID,
                            setIndex: 0
                        ),
                        ExerciseSet(
                            id: uuid(),
                            type: .working,
                            weightUnit: .lb,
                            suggest: .init(
                                weight: 155,
                                reps: 8,
                                repRange: nil,
                                duration: nil,
                                rpe: 8.0,
                                restTime: 90
                            ),
                            actual: .init(
                                weight: 160,
                                reps: 8,
                                rpe: 8.5
                            ),
                            isCompleted: true,
                            exerciseId: exercise2ID,
                            workoutId: workout2ID,
                            setIndex: 1
                        ),
                        ExerciseSet(
                            id: uuid(),
                            type: .working,
                            weightUnit: .lb,
                            suggest: .init(
                                weight: 175,
                                reps: 6,
                                repRange: nil,
                                duration: nil,
                                rpe: 9.0,
                                restTime: 90
                            ),
                            actual: .init(
                                weight: 175,
                                reps: 5,
                                rpe: 9.5
                            ),
                            isCompleted: true,
                            exerciseId: exercise2ID,
                            workoutId: workout2ID,
                            setIndex: 2
                        )
                    ],
                    bodyPart: BodyPart(
                        main: .chest,
                        detailed: nil,
                        scientific: nil
                    )
                ),
                Exercise(
                    id: exercise3ID,
                    supersetId: 0, // Example supersetId usage
                    workoutId: workout2ID,
                    name: "Pull Up",
                    pinnedNotes: [],
                    notes: [],
                    duration: nil,
                    type: .bodyweight,
                    weightUnit: nil,
                    defaultWarmUpTime: 60,
                    defaultRestTime: 60,
                    sets: [
                        ExerciseSet(
                            id: uuid(),
                            type: .working,
                            weightUnit: nil,
                            suggest: .init(
                                weight: nil,
                                reps: 12,
                                repRange: nil,
                                duration: nil,
                                rpe: 8.0,
                                restTime: 60
                            ),
                            actual: .init(
                                weight: nil,
                                reps: 12,
                                rpe: 8.0
                            ),
                            isCompleted: true,
                            exerciseId: exercise3ID,
                            workoutId: workout2ID,
                            setIndex: 0
                        ),
                        ExerciseSet(
                            id: uuid(),
                            type: .working,
                            weightUnit: nil,
                            suggest: .init(
                                weight: nil,
                                reps: 10,
                                repRange: nil,
                                duration: nil,
                                rpe: 8.5,
                                restTime: 60
                            ),
                            actual: .init(
                                weight: nil,
                                reps: 8,
                                rpe: 8.5
                            ),
                            isCompleted: true,
                            exerciseId: exercise3ID,
                            workoutId: workout2ID,
                            setIndex: 1
                        ),
                        ExerciseSet(
                            id: uuid(),
                            type: .working,
                            weightUnit: nil,
                            suggest: .init(
                                weight: nil,
                                reps: 8,
                                repRange: nil,
                                duration: nil,
                                rpe: 9.0,
                                restTime: 60
                            ),
                            actual: .init(
                                weight: nil,
                                reps: 7,
                                rpe: 9.5
                            ),
                            isCompleted: true,
                            exerciseId: exercise3ID,
                            workoutId: workout2ID,
                            setIndex: 2
                        )
                    ],
                    bodyPart: BodyPart(
                        main: .back,
                        detailed: nil,
                        scientific: nil
                    )
                )
            ]
        )
        
        
        try seed {
            for workout in [workout1, workout2] {
                workout
                for exercise in workout.exercises {
                    exercise
                    for exerciseSet in exercise.sets {
                        exerciseSet
                    }
                }
            }
        }
    }
}
#endif
