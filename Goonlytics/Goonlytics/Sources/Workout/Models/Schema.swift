import Dependencies
import Foundation
import GRDB
import SharingGRDB

// MARK: - Workout Database Model

extension Workout: FetchableRecord, MutablePersistableRecord {    
    func encode(to container: inout PersistenceContainer) {
        container["id"] = id
        container["name"] = name
        container["start_timestamp"] = startTimestamp
        container["note"] = note
        container["duration"] = duration
        container["end_timestamp"] = endTimestamp
    }
    
    init(row: Row) throws {
        id = row["id"]
        name = row["name"]
        startTimestamp = row["start_timestamp"]
        note = row["note"]
        duration = row["duration"]
        endTimestamp = row["end_timestamp"]
        exercises = []
    }
}

// MARK: - Exercise Database Model

extension Exercise: FetchableRecord, MutablePersistableRecord {
    static let workoutId = Column("workout_id")
    
    func encode(to container: inout PersistenceContainer) {
        container["id"] = id
        container["workout_id"] = workoutId
        container["superset_id"] = supersetId
        container["name"] = name
        container["duration"] = duration
        container["type"] = type.rawValue
        container["weight_unit"] = weightUnit?.rawValue
        container["default_warm_up_time"] = defaultWarmUpTime
        container["default_rest_time"] = defaultRestTime
        
        // Encode arrays as JSON
        if let pinnedNotesData = try? JSONEncoder().encode(pinnedNotes) {
            container["pinned_notes"] = pinnedNotesData
        }
        
        if let notesData = try? JSONEncoder().encode(notes) {
            container["notes"] = notesData
        }
        
        if let bodyPartData = try? JSONEncoder().encode(bodyPart) {
            container["body_part"] = bodyPartData
        }
    }
    
    init(row: Row) throws {
        id = row["id"]
        workoutId = row["workout_id"]
        supersetId = row["superset_id"]
        name = row["name"]
        duration = row["duration"]
        
        if let typeString = row["type"] as? String,
           let exerciseType = ExerciseType(rawValue: typeString) {
            type = exerciseType
        } else {
            type = .bodyweight
        }
        
        if let weightUnitString = row["weight_unit"] as? String {
            weightUnit = WeightUnit(rawValue: weightUnitString)
        } else {
            weightUnit = nil
        }
        
        defaultWarmUpTime = row["default_warm_up_time"]
        defaultRestTime = row["default_rest_time"]
        
        // Decode arrays from JSON
        if let pinnedNotesData = row["pinned_notes"] as? Data {
            pinnedNotes = (try? JSONDecoder().decode([String].self, from: pinnedNotesData)) ?? []
        } else {
            pinnedNotes = []
        }
        
        if let notesData = row["notes"] as? Data {
            notes = (try? JSONDecoder().decode([String].self, from: notesData)) ?? []
        } else {
            notes = []
        }
        
        if let bodyPartData = row["body_part"] as? Data {
            bodyPart = try? JSONDecoder().decode(BodyPart.self, from: bodyPartData)
        } else {
            bodyPart = nil
        }
        
        sets = [] // Will be populated by associations
    }
}

// MARK: - ExerciseSet Database Model

extension ExerciseSet: FetchableRecord, MutablePersistableRecord {
    static let exerciseId = Column("exercise_id")
    static let setIndex = Column("set_index")
    
    func encode(to container: inout PersistenceContainer) {
        container["exercise_id"] = exerciseId
        container["set_index"] = setIndex
        container["type"] = type.rawValue
        container["weight_unit"] = weightUnit?.rawValue
        
        if let suggestData = try? JSONEncoder().encode(suggest) {
            container["suggest"] = suggestData
        }
        
        if let actualData = try? JSONEncoder().encode(actual) {
            container["actual"] = actualData
        }
    }
    
    init(row: Row) throws {
        exerciseId = row["exercise_id"]
        setIndex = row["set_index"]
        
        if let typeString = row["type"] as? String,
           let setType = SetType(rawValue: typeString) {
            type = setType
        } else {
            type = .working
        }
        
        if let weightUnitString = row["weight_unit"] as? String {
            weightUnit = WeightUnit(rawValue: weightUnitString)
        } else {
            weightUnit = nil
        }
        
        if let suggestData = row["suggest"] as? Data {
            suggest = try? JSONDecoder().decode(SetSuggest.self, from: suggestData)
        } else {
            suggest = nil
        }
        
        if let actualData = row["actual"] as? Data {
            actual = try? JSONDecoder().decode(SetActual.self, from: actualData)
        } else {
            actual = nil
        }
        
        isCompleted = row["is_completed"] ?? false
    }
}


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
        let path = URL.documentsDirectory.appending(component: "workouts.sqlite").path()
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
        // Create workouts table
        try db.create(table: Workout.databaseTableName) { table in
            table.column("id", .text).primaryKey()
            table.column("name", .text).notNull()
            table.column("start_timestamp", .datetime).notNull()
            table.column("note", .text)
            table.column("duration", .integer)
            table.column("end_timestamp", .datetime)
        }
        
        // Create exercises table
        try db.create(table: Exercise.databaseTableName) { table in
            table.column("id", .text).primaryKey()
            table.column("workout_id", .text).notNull()
                .references(Workout.databaseTableName, onDelete: .cascade)
            table.column("superset_id", .integer)
            table.column("name", .text).notNull()
            table.column("pinned_notes", .blob)
            table.column("notes", .blob)
            table.column("duration", .integer)
            table.column("type", .text).notNull()
            table.column("weight_unit", .text)
            table.column("default_warm_up_time", .integer)
            table.column("default_rest_time", .integer)
            table.column("body_part", .blob)
        }
        
        // Create index for exercises table
        try db.create(indexOn: Exercise.databaseTableName, columns: ["workout_id"])
        
        // Create exercise_sets table
        try db.create(table: ExerciseSet.databaseTableName) { table in
            table.autoIncrementedPrimaryKey("id")
            table.column("exercise_id", .text).notNull()
                .references(Exercise.databaseTableName, onDelete: .cascade)
            table.column("set_index", .integer).notNull()
            table.column("type", .text).notNull()
            table.column("weight_unit", .text)
            table.column("suggest", .blob)
            table.column("actual", .blob)
        }
        
        // Create index for exercise_sets table
        try db.create(indexOn: ExerciseSet.databaseTableName, columns: ["exercise_id", "set_index"])
    }
    
    #if DEBUG
    migrator.registerMigration("Insert sample data") { db in
        try db.insertSampleWorkoutData()
    }
    #endif
    
    try migrator.migrate(database)
    
    return database
}

// MARK: - Associations

extension Workout: TableRecord {
    static let exercises = hasMany(Exercise.self)
}

extension Exercise: TableRecord {
    static let workout = belongsTo(Workout.self)
    static let sets = hasMany(ExerciseSet.self)
    
    var exerciseSets: QueryInterfaceRequest<ExerciseSet> {
        request(for: Exercise.sets)
            .order(ExerciseSet.setIndex)
    }
    
    static func byWorkoutId(_ workoutId: String) -> QueryInterfaceRequest<Exercise> {
        return Exercise.filter(Exercise.workoutId == workoutId)
    }
    
    static func byId(_ id: String) -> QueryInterfaceRequest<Exercise> {
        return Exercise.filter(Column("id") == id)
    }
}

extension ExerciseSet: TableRecord {
    static let exercise = belongsTo(Exercise.self)
}

#if DEBUG
extension Database {
    func insertSampleWorkoutData() throws {
        // Sample workout 1
        let workout1ID = UUID()
        let exercise1ID = UUID()

        // Create workout 1
        let workout1 = try Workout(
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
                            type: .working,
                            weightUnit: nil,
                            suggest: SetSuggest(
                                weight: 0,
                                reps: 30,
                                repRange: nil,
                                duration: 1800,
                                rpe: 7.5,
                                restTime: nil
                            ),
                            actual: SetActual(
                                weight: 0,
                                reps: 32,
                                rpe: 8.0
                            ),
                            isCompleted: true,
                            exerciseId: exercise1ID,
                            setIndex: 0
                        )
                    ],
                    bodyPart: nil
                )
            ]
        ).inserted(self)
        
        try workout1.exercises.forEach { exercise in
            _ = try exercise.inserted(self)
            _ = try exercise.sets.forEach {
                _ = try $0.inserted(self)
            }
        }

        // Sample workout 2
        let workout2ID = UUID()
        let exercise2ID = UUID()
        let exercise3ID = UUID()

        // Create workout 2
        let workout2 = try Workout(
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
                            type: .working,
                            weightUnit: .lb,
                            suggest: SetSuggest(
                                weight: 135,
                                reps: 10,
                                repRange: nil,
                                duration: nil,
                                rpe: 7.0,
                                restTime: 90
                            ),
                            actual: SetActual(
                                weight: 135,
                                reps: 12,
                                rpe: 7.5
                            ),
                            isCompleted: true,
                            exerciseId: exercise2ID,
                            setIndex: 0
                        ),
                        ExerciseSet(
                            type: .working,
                            weightUnit: .lb,
                            suggest: SetSuggest(
                                weight: 155,
                                reps: 8,
                                repRange: nil,
                                duration: nil,
                                rpe: 8.0,
                                restTime: 90
                            ),
                            actual: SetActual(
                                weight: 160,
                                reps: 8,
                                rpe: 8.5
                            ),
                            isCompleted: true,
                            exerciseId: exercise2ID,
                            setIndex: 1
                        ),
                        ExerciseSet(
                            type: .working,
                            weightUnit: .lb,
                            suggest: SetSuggest(
                                weight: 175,
                                reps: 6,
                                repRange: nil,
                                duration: nil,
                                rpe: 9.0,
                                restTime: 90
                            ),
                            actual: SetActual(
                                weight: 175,
                                reps: 5,
                                rpe: 9.5
                            ),
                            isCompleted: true,
                            exerciseId: exercise2ID,
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
                            type: .working,
                            weightUnit: nil,
                            suggest: SetSuggest(
                                weight: nil,
                                reps: 12,
                                repRange: nil,
                                duration: nil,
                                rpe: 8.0,
                                restTime: 60
                            ),
                            actual: SetActual(
                                weight: nil,
                                reps: 12,
                                rpe: 8.0
                            ),
                            isCompleted: true,
                            exerciseId: exercise3ID,
                            setIndex: 0
                        ),
                        ExerciseSet(
                            type: .working,
                            weightUnit: nil,
                            suggest: SetSuggest(
                                weight: nil,
                                reps: 10,
                                repRange: nil,
                                duration: nil,
                                rpe: 8.5,
                                restTime: 60
                            ),
                            actual: SetActual(
                                weight: nil,
                                reps: 8,
                                rpe: 8.5
                            ),
                            isCompleted: true,
                            exerciseId: exercise3ID,
                            setIndex: 1
                        ),
                        ExerciseSet(
                            type: .working,
                            weightUnit: nil,
                            suggest: SetSuggest(
                                weight: nil,
                                reps: 8,
                                repRange: nil,
                                duration: nil,
                                rpe: 9.0,
                                restTime: 60
                            ),
                            actual: SetActual(
                                weight: nil,
                                reps: 7,
                                rpe: 9.5
                            ),
                            isCompleted: true,
                            exerciseId: exercise3ID,
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
        ).inserted(self)
        
        try workout2.exercises.forEach { exercise in
            _ = try exercise.inserted(self)
            _ = try exercise.sets.forEach {
                _ = try $0.inserted(self)
            }
        }
    }
}
#endif
