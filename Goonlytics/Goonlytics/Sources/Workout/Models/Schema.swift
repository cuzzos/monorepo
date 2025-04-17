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
    static let groupIndex = Column("group_index")
    
    func encode(to container: inout PersistenceContainer) {
        container["id"] = id
        container["workout_id"] = workoutId
        container["group_index"] = groupIndex
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
        groupIndex = row["group_index"]
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
        
        container["is_completed"] = isCompleted
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
            table.column("group_index", .integer).notNull()
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
        try db.create(indexOn: Exercise.databaseTableName, columns: ["workout_id", "group_index"])
        
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
            table.column("is_completed", .boolean).notNull().defaults(to: false)
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

extension Workout {
    static let exercises = hasMany(Exercise.self)
    
    var exerciseGroups: QueryInterfaceRequest<Exercise> {
        request(for: Workout.exercises)
            .order(Exercise.groupIndex)
    }
    
    static func all() -> QueryInterfaceRequest<Workout> {
        return Workout.order(Column("start_timestamp").desc)
    }
    
    static func byId(_ id: String) -> QueryInterfaceRequest<Workout> {
        return Workout.filter(Column("id") == id)
    }
}

extension Exercise {
    static let workout = belongsTo(Workout.self)
    static let sets = hasMany(ExerciseSet.self)
    
    var exerciseSets: QueryInterfaceRequest<ExerciseSet> {
        request(for: Exercise.sets)
            .order(ExerciseSet.setIndex)
    }
    
    static func byWorkoutId(_ workoutId: String) -> QueryInterfaceRequest<Exercise> {
        return Exercise.filter(Exercise.workoutId == workoutId)
            .order(Exercise.groupIndex)
    }
    
    static func byId(_ id: String) -> QueryInterfaceRequest<Exercise> {
        return Exercise.filter(Column("id") == id)
    }
}

extension ExerciseSet {
    static let exercise = belongsTo(Exercise.self)
}

// MARK: - Workout Fetch Key Request

struct WorkoutsRequest: FetchKeyRequest {
    struct Value {
        var workouts: [Workout] = []
    }
    
    func fetch(_ db: Database) throws -> Value {
        // Use GRDB's eager loading with associations for better performance
        var workouts = try Workout.all()
            .including(all: Workout.exercises.order(Exercise.groupIndex)
            .including(all: Exercise.sets.order(ExerciseSet.setIndex)))
            .fetchAll(db)
        
        // Process the fetched workouts to group exercises properly
        for i in 0..<workouts.count {
            let exercises = try workouts[i].request(for: Workout.exercises).fetchAll(db)
            
            // Group exercises by group_index
            var groupedExercises: [[Exercise]] = []
            let groupIndices = Set(exercises.map { $0.groupIndex }).sorted()
            
            for groupIndex in groupIndices {
                var exercisesInGroup = exercises.filter { $0.groupIndex == groupIndex }
                
                // For each exercise, fetch and assign sets
                for j in 0..<exercisesInGroup.count {
                    let sets = try ExerciseSet.filter(ExerciseSet.exerciseId == exercisesInGroup[j].id)
                        .order(ExerciseSet.setIndex)
                        .fetchAll(db)
                    exercisesInGroup[j].sets = sets
                }
                
                groupedExercises.append(exercisesInGroup)
            }
            
            // If no exercises were found, use an empty array with one empty group
            if groupedExercises.isEmpty {
                groupedExercises = [[]]
            }
            
            // Update the workout in our array
            workouts[i].exercises = groupedExercises
        }
        
        return Value(workouts: workouts)
    }
}

struct WorkoutRequest: FetchKeyRequest {
    let id: String
    
    struct Value {
        var workout: Workout?
    }
    
    func fetch(_ db: Database) throws -> Value {
        guard let workout = try Workout.byId(id).fetchOne(db) else {
            return Value(workout: nil)
        }
        
        // We need to properly process the exercises and their sets
        let exercises = try Exercise.byWorkoutId(id).fetchAll(db)
        
        // Group exercises by group_index
        var groupedExercises: [[Exercise]] = []
        let groupIndices = Set(exercises.map { $0.groupIndex }).sorted()
        
        for groupIndex in groupIndices {
            var exercisesInGroup = exercises.filter { $0.groupIndex == groupIndex }
            
            // For each exercise, ensure sets are loaded
            for i in 0..<exercisesInGroup.count {
                let sets = try ExerciseSet.filter(ExerciseSet.exerciseId == exercisesInGroup[i].id)
                    .order(ExerciseSet.setIndex)
                    .fetchAll(db)
                exercisesInGroup[i].sets = sets
            }
            
            groupedExercises.append(exercisesInGroup)
        }
        
        // If no exercises were found, use an empty array with one empty group
        if groupedExercises.isEmpty {
            groupedExercises = [[]]
        }
        
        var completeWorkout = workout
        completeWorkout.exercises = groupedExercises
        
        return Value(workout: completeWorkout)
    }
}

#if DEBUG
extension Database {
    func insertSampleWorkoutData() throws {
        // Sample workout 1
        let workout1ID = UUID().uuidString
        let exercise1ID = UUID().uuidString
        
        // Create workout 1
        let workout1 = try Workout(
            id: workout1ID,
            name: "Morning Run",
            note: "Felt good today",
            duration: 1800, // 30 minutes
            startTimestamp: Date().addingTimeInterval(-86400), // Yesterday
            endTimestamp: Date().addingTimeInterval(-86400).addingTimeInterval(1800),
            exercises: [[]]
        ).inserted(self)
        
        // Create exercise 1
        let exercise1 = try Exercise(
            id: exercise1ID,
            workoutId: workout1.id,
            name: "Running",
            pinnedNotes: [],
            notes: ["Easy pace"],
            duration: 1800,
            type: .bodyweight,
            weightUnit: nil,
            defaultWarmUpTime: nil,
            defaultRestTime: nil,
            sets: [],
            bodyPart: nil,
            groupIndex: 0
        ).inserted(self)
        
        // Add set for exercise 1
        let _ = try ExerciseSet(
            type: .working,
            weightUnit: nil,
            suggest: SetSuggest(
                weight: nil,
                reps: 30,
                repRange: nil,
                duration: 1800,
                rpe: 7.5,
                restTime: nil
            ),
            actual: nil,
            isCompleted: false,
            exerciseId: exercise1.id,
            setIndex: 0
        ).inserted(self)
        
        // Sample workout 2
        let workout2ID = UUID().uuidString
        
        // Create workout 2
        let workout2 = try Workout(
            id: workout2ID,
            name: "Evening Strength",
            note: "Good session, increased weight on bench",
            duration: 3600, // 60 minutes
            startTimestamp: Date().addingTimeInterval(-172800), // 2 days ago
            endTimestamp: Date().addingTimeInterval(-172800).addingTimeInterval(3600),
            exercises: [[]]
        ).inserted(self)
        
        // Create exercise 2
        let exercise2 = try Exercise(
            id: UUID().uuidString,
            workoutId: workout2.id,
            name: "Bench Press",
            pinnedNotes: [],
            notes: ["Focus on form"],
            duration: nil,
            type: .barbell,
            weightUnit: .lb,
            defaultWarmUpTime: 60,
            defaultRestTime: 90,
            sets: [],
            bodyPart: BodyPart(
                main: .chest,
                detailed: nil,
                scientific: nil
            ),
            groupIndex: 0
        ).inserted(self)
        
        // Add sets for exercise 2
        let _ = try ExerciseSet(
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
            actual: nil,
            isCompleted: false,
            exerciseId: exercise2.id,
            setIndex: 0
        ).inserted(self)
        
        let _ = try ExerciseSet(
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
            actual: nil,
            isCompleted: false,
            exerciseId: exercise2.id,
            setIndex: 1
        ).inserted(self)
        
        let _ = try ExerciseSet(
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
            actual: nil,
            isCompleted: false,
            exerciseId: exercise2.id,
            setIndex: 2
        ).inserted(self)
        
        // Create exercise 3
        let exercise3 = try Exercise(
            id: UUID().uuidString,
            workoutId: workout2.id,
            name: "Pull Up",
            pinnedNotes: [],
            notes: [],
            duration: nil,
            type: .bodyweight,
            weightUnit: nil,
            defaultWarmUpTime: 30,
            defaultRestTime: 60,
            sets: [],
            bodyPart: BodyPart(
                main: .back,
                detailed: nil,
                scientific: nil
            ),
            groupIndex: 0
        ).inserted(self)
        
        // Add sets for exercise 3
        let _ = try ExerciseSet(
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
            actual: nil,
            isCompleted: false,
            exerciseId: exercise3.id,
            setIndex: 0
        ).inserted(self)
        
        let _ = try ExerciseSet(
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
            actual: nil,
            isCompleted: false,
            exerciseId: exercise3.id,
            setIndex: 1
        ).inserted(self)
        
        let _ = try ExerciseSet(
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
            actual: nil,
            isCompleted: false,
            exerciseId: exercise3.id,
            setIndex: 2
        ).inserted(self)
    }
}
#endif
