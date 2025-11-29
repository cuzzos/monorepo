import Serde


public struct BodyPart: Hashable {
    @Indirect public var main: SharedTypes.BodyPartMain
    @Indirect public var detailed: [String]?
    @Indirect public var scientific: [String]?

    public init(main: SharedTypes.BodyPartMain, detailed: [String]?, scientific: [String]?) {
        self.main = main
        self.detailed = detailed
        self.scientific = scientific
    }

    public func serialize<S: Serializer>(serializer: S) throws {
        try serializer.increase_container_depth()
        try self.main.serialize(serializer: serializer)
        try serialize_option_vector_str(value: self.detailed, serializer: serializer)
        try serialize_option_vector_str(value: self.scientific, serializer: serializer)
        try serializer.decrease_container_depth()
    }

    public func bincodeSerialize() throws -> [UInt8] {
        let serializer = BincodeSerializer.init();
        try self.serialize(serializer: serializer)
        return serializer.get_bytes()
    }

    public static func deserialize<D: Deserializer>(deserializer: D) throws -> BodyPart {
        try deserializer.increase_container_depth()
        let main = try SharedTypes.BodyPartMain.deserialize(deserializer: deserializer)
        let detailed = try deserialize_option_vector_str(deserializer: deserializer)
        let scientific = try deserialize_option_vector_str(deserializer: deserializer)
        try deserializer.decrease_container_depth()
        return BodyPart.init(main: main, detailed: detailed, scientific: scientific)
    }

    public static func bincodeDeserialize(input: [UInt8]) throws -> BodyPart {
        let deserializer = BincodeDeserializer.init(input: input);
        let obj = try deserialize(deserializer: deserializer)
        if deserializer.get_buffer_offset() < input.count {
            throw DeserializationError.invalidInput(issue: "Some input bytes were not read")
        }
        return obj
    }
}

indirect public enum BodyPartMain: Hashable {
    case chest

    public func serialize<S: Serializer>(serializer: S) throws {
        try serializer.increase_container_depth()
        switch self {
        case .chest:
            try serializer.serialize_variant_index(value: 0)
        }
        try serializer.decrease_container_depth()
    }

    public func bincodeSerialize() throws -> [UInt8] {
        let serializer = BincodeSerializer.init();
        try self.serialize(serializer: serializer)
        return serializer.get_bytes()
    }

    public static func deserialize<D: Deserializer>(deserializer: D) throws -> BodyPartMain {
        let index = try deserializer.deserialize_variant_index()
        try deserializer.increase_container_depth()
        switch index {
        case 0:
            try deserializer.decrease_container_depth()
            return .chest
        default: throw DeserializationError.invalidInput(issue: "Unknown variant index for BodyPartMain: \(index)")
        }
    }

    public static func bincodeDeserialize(input: [UInt8]) throws -> BodyPartMain {
        let deserializer = BincodeDeserializer.init(input: input);
        let obj = try deserialize(deserializer: deserializer)
        if deserializer.get_buffer_offset() < input.count {
            throw DeserializationError.invalidInput(issue: "Some input bytes were not read")
        }
        return obj
    }
}

indirect public enum DatabaseResult: Hashable {
    case workoutSaved
    case historyLoaded(workouts: [SharedTypes.Workout])
    case workoutLoaded(workout: SharedTypes.Workout?)

    public func serialize<S: Serializer>(serializer: S) throws {
        try serializer.increase_container_depth()
        switch self {
        case .workoutSaved:
            try serializer.serialize_variant_index(value: 0)
        case .historyLoaded(let workouts):
            try serializer.serialize_variant_index(value: 1)
            try serialize_vector_Workout(value: workouts, serializer: serializer)
        case .workoutLoaded(let workout):
            try serializer.serialize_variant_index(value: 2)
            try serialize_option_Workout(value: workout, serializer: serializer)
        }
        try serializer.decrease_container_depth()
    }

    public func bincodeSerialize() throws -> [UInt8] {
        let serializer = BincodeSerializer.init();
        try self.serialize(serializer: serializer)
        return serializer.get_bytes()
    }

    public static func deserialize<D: Deserializer>(deserializer: D) throws -> DatabaseResult {
        let index = try deserializer.deserialize_variant_index()
        try deserializer.increase_container_depth()
        switch index {
        case 0:
            try deserializer.decrease_container_depth()
            return .workoutSaved
        case 1:
            let workouts = try deserialize_vector_Workout(deserializer: deserializer)
            try deserializer.decrease_container_depth()
            return .historyLoaded(workouts: workouts)
        case 2:
            let workout = try deserialize_option_Workout(deserializer: deserializer)
            try deserializer.decrease_container_depth()
            return .workoutLoaded(workout: workout)
        default: throw DeserializationError.invalidInput(issue: "Unknown variant index for DatabaseResult: \(index)")
        }
    }

    public static func bincodeDeserialize(input: [UInt8]) throws -> DatabaseResult {
        let deserializer = BincodeDeserializer.init(input: input);
        let obj = try deserialize(deserializer: deserializer)
        if deserializer.get_buffer_offset() < input.count {
            throw DeserializationError.invalidInput(issue: "Some input bytes were not read")
        }
        return obj
    }
}

indirect public enum Effect: Hashable {
    case render(SharedTypes.RenderOperation)

    public func serialize<S: Serializer>(serializer: S) throws {
        try serializer.increase_container_depth()
        switch self {
        case .render(let x):
            try serializer.serialize_variant_index(value: 0)
            try x.serialize(serializer: serializer)
        }
        try serializer.decrease_container_depth()
    }

    public func bincodeSerialize() throws -> [UInt8] {
        let serializer = BincodeSerializer.init();
        try self.serialize(serializer: serializer)
        return serializer.get_bytes()
    }

    public static func deserialize<D: Deserializer>(deserializer: D) throws -> Effect {
        let index = try deserializer.deserialize_variant_index()
        try deserializer.increase_container_depth()
        switch index {
        case 0:
            let x = try SharedTypes.RenderOperation.deserialize(deserializer: deserializer)
            try deserializer.decrease_container_depth()
            return .render(x)
        default: throw DeserializationError.invalidInput(issue: "Unknown variant index for Effect: \(index)")
        }
    }

    public static func bincodeDeserialize(input: [UInt8]) throws -> Effect {
        let deserializer = BincodeDeserializer.init(input: input);
        let obj = try deserialize(deserializer: deserializer)
        if deserializer.get_buffer_offset() < input.count {
            throw DeserializationError.invalidInput(issue: "Some input bytes were not read")
        }
        return obj
    }
}

indirect public enum Event: Hashable {
    case startWorkout
    case finishWorkout
    case discardWorkout
    case updateWorkoutName(name: String)
    case updateWorkoutNotes(notes: String)
    case addExercise(name: String, exercise_type: String, muscle_group: String)
    case deleteExercise(exercise_id: String)
    case moveExercise(from_index: UInt64, to_index: UInt64)
    case showAddExerciseView
    case dismissAddExerciseView
    case addSet(exercise_id: String)
    case deleteSet(exercise_id: String, set_index: UInt64)
    case updateSetActual(set_id: String, actual: SharedTypes.SetActual)
    case toggleSetCompleted(set_id: String)
    case timerTick
    case startTimer
    case stopTimer
    case toggleTimer
    case showStopwatch
    case dismissStopwatch
    case showRestTimer(duration_seconds: Int32)
    case dismissRestTimer
    case loadHistory
    case viewHistoryItem(workout_id: String)
    case navigateBack
    case changeTab(tab: SharedTypes.Tab)
    case importWorkout(json_data: String)
    case showImportView
    case dismissImportView
    case loadWorkoutTemplate
    case calculatePlates(target_weight: Double, bar_weight: Double, use_percentage: Double?)
    case clearPlateCalculation
    case showPlateCalculator
    case dismissPlateCalculator
    case databaseResponse(result: SharedTypes.DatabaseResult)
    case storageResponse(result: SharedTypes.StorageResult)
    case error(message: String)

    public func serialize<S: Serializer>(serializer: S) throws {
        try serializer.increase_container_depth()
        switch self {
        case .startWorkout:
            try serializer.serialize_variant_index(value: 0)
        case .finishWorkout:
            try serializer.serialize_variant_index(value: 1)
        case .discardWorkout:
            try serializer.serialize_variant_index(value: 2)
        case .updateWorkoutName(let name):
            try serializer.serialize_variant_index(value: 3)
            try serializer.serialize_str(value: name)
        case .updateWorkoutNotes(let notes):
            try serializer.serialize_variant_index(value: 4)
            try serializer.serialize_str(value: notes)
        case .addExercise(let name, let exercise_type, let muscle_group):
            try serializer.serialize_variant_index(value: 5)
            try serializer.serialize_str(value: name)
            try serializer.serialize_str(value: exercise_type)
            try serializer.serialize_str(value: muscle_group)
        case .deleteExercise(let exercise_id):
            try serializer.serialize_variant_index(value: 6)
            try serializer.serialize_str(value: exercise_id)
        case .moveExercise(let from_index, let to_index):
            try serializer.serialize_variant_index(value: 7)
            try serializer.serialize_u64(value: from_index)
            try serializer.serialize_u64(value: to_index)
        case .showAddExerciseView:
            try serializer.serialize_variant_index(value: 8)
        case .dismissAddExerciseView:
            try serializer.serialize_variant_index(value: 9)
        case .addSet(let exercise_id):
            try serializer.serialize_variant_index(value: 10)
            try serializer.serialize_str(value: exercise_id)
        case .deleteSet(let exercise_id, let set_index):
            try serializer.serialize_variant_index(value: 11)
            try serializer.serialize_str(value: exercise_id)
            try serializer.serialize_u64(value: set_index)
        case .updateSetActual(let set_id, let actual):
            try serializer.serialize_variant_index(value: 12)
            try serializer.serialize_str(value: set_id)
            try actual.serialize(serializer: serializer)
        case .toggleSetCompleted(let set_id):
            try serializer.serialize_variant_index(value: 13)
            try serializer.serialize_str(value: set_id)
        case .timerTick:
            try serializer.serialize_variant_index(value: 14)
        case .startTimer:
            try serializer.serialize_variant_index(value: 15)
        case .stopTimer:
            try serializer.serialize_variant_index(value: 16)
        case .toggleTimer:
            try serializer.serialize_variant_index(value: 17)
        case .showStopwatch:
            try serializer.serialize_variant_index(value: 18)
        case .dismissStopwatch:
            try serializer.serialize_variant_index(value: 19)
        case .showRestTimer(let duration_seconds):
            try serializer.serialize_variant_index(value: 20)
            try serializer.serialize_i32(value: duration_seconds)
        case .dismissRestTimer:
            try serializer.serialize_variant_index(value: 21)
        case .loadHistory:
            try serializer.serialize_variant_index(value: 22)
        case .viewHistoryItem(let workout_id):
            try serializer.serialize_variant_index(value: 23)
            try serializer.serialize_str(value: workout_id)
        case .navigateBack:
            try serializer.serialize_variant_index(value: 24)
        case .changeTab(let tab):
            try serializer.serialize_variant_index(value: 25)
            try tab.serialize(serializer: serializer)
        case .importWorkout(let json_data):
            try serializer.serialize_variant_index(value: 26)
            try serializer.serialize_str(value: json_data)
        case .showImportView:
            try serializer.serialize_variant_index(value: 27)
        case .dismissImportView:
            try serializer.serialize_variant_index(value: 28)
        case .loadWorkoutTemplate:
            try serializer.serialize_variant_index(value: 29)
        case .calculatePlates(let target_weight, let bar_weight, let use_percentage):
            try serializer.serialize_variant_index(value: 30)
            try serializer.serialize_f64(value: target_weight)
            try serializer.serialize_f64(value: bar_weight)
            try serialize_option_f64(value: use_percentage, serializer: serializer)
        case .clearPlateCalculation:
            try serializer.serialize_variant_index(value: 31)
        case .showPlateCalculator:
            try serializer.serialize_variant_index(value: 32)
        case .dismissPlateCalculator:
            try serializer.serialize_variant_index(value: 33)
        case .databaseResponse(let result):
            try serializer.serialize_variant_index(value: 34)
            try result.serialize(serializer: serializer)
        case .storageResponse(let result):
            try serializer.serialize_variant_index(value: 35)
            try result.serialize(serializer: serializer)
        case .error(let message):
            try serializer.serialize_variant_index(value: 36)
            try serializer.serialize_str(value: message)
        }
        try serializer.decrease_container_depth()
    }

    public func bincodeSerialize() throws -> [UInt8] {
        let serializer = BincodeSerializer.init();
        try self.serialize(serializer: serializer)
        return serializer.get_bytes()
    }

    public static func deserialize<D: Deserializer>(deserializer: D) throws -> Event {
        let index = try deserializer.deserialize_variant_index()
        try deserializer.increase_container_depth()
        switch index {
        case 0:
            try deserializer.decrease_container_depth()
            return .startWorkout
        case 1:
            try deserializer.decrease_container_depth()
            return .finishWorkout
        case 2:
            try deserializer.decrease_container_depth()
            return .discardWorkout
        case 3:
            let name = try deserializer.deserialize_str()
            try deserializer.decrease_container_depth()
            return .updateWorkoutName(name: name)
        case 4:
            let notes = try deserializer.deserialize_str()
            try deserializer.decrease_container_depth()
            return .updateWorkoutNotes(notes: notes)
        case 5:
            let name = try deserializer.deserialize_str()
            let exercise_type = try deserializer.deserialize_str()
            let muscle_group = try deserializer.deserialize_str()
            try deserializer.decrease_container_depth()
            return .addExercise(name: name, exercise_type: exercise_type, muscle_group: muscle_group)
        case 6:
            let exercise_id = try deserializer.deserialize_str()
            try deserializer.decrease_container_depth()
            return .deleteExercise(exercise_id: exercise_id)
        case 7:
            let from_index = try deserializer.deserialize_u64()
            let to_index = try deserializer.deserialize_u64()
            try deserializer.decrease_container_depth()
            return .moveExercise(from_index: from_index, to_index: to_index)
        case 8:
            try deserializer.decrease_container_depth()
            return .showAddExerciseView
        case 9:
            try deserializer.decrease_container_depth()
            return .dismissAddExerciseView
        case 10:
            let exercise_id = try deserializer.deserialize_str()
            try deserializer.decrease_container_depth()
            return .addSet(exercise_id: exercise_id)
        case 11:
            let exercise_id = try deserializer.deserialize_str()
            let set_index = try deserializer.deserialize_u64()
            try deserializer.decrease_container_depth()
            return .deleteSet(exercise_id: exercise_id, set_index: set_index)
        case 12:
            let set_id = try deserializer.deserialize_str()
            let actual = try SharedTypes.SetActual.deserialize(deserializer: deserializer)
            try deserializer.decrease_container_depth()
            return .updateSetActual(set_id: set_id, actual: actual)
        case 13:
            let set_id = try deserializer.deserialize_str()
            try deserializer.decrease_container_depth()
            return .toggleSetCompleted(set_id: set_id)
        case 14:
            try deserializer.decrease_container_depth()
            return .timerTick
        case 15:
            try deserializer.decrease_container_depth()
            return .startTimer
        case 16:
            try deserializer.decrease_container_depth()
            return .stopTimer
        case 17:
            try deserializer.decrease_container_depth()
            return .toggleTimer
        case 18:
            try deserializer.decrease_container_depth()
            return .showStopwatch
        case 19:
            try deserializer.decrease_container_depth()
            return .dismissStopwatch
        case 20:
            let duration_seconds = try deserializer.deserialize_i32()
            try deserializer.decrease_container_depth()
            return .showRestTimer(duration_seconds: duration_seconds)
        case 21:
            try deserializer.decrease_container_depth()
            return .dismissRestTimer
        case 22:
            try deserializer.decrease_container_depth()
            return .loadHistory
        case 23:
            let workout_id = try deserializer.deserialize_str()
            try deserializer.decrease_container_depth()
            return .viewHistoryItem(workout_id: workout_id)
        case 24:
            try deserializer.decrease_container_depth()
            return .navigateBack
        case 25:
            let tab = try SharedTypes.Tab.deserialize(deserializer: deserializer)
            try deserializer.decrease_container_depth()
            return .changeTab(tab: tab)
        case 26:
            let json_data = try deserializer.deserialize_str()
            try deserializer.decrease_container_depth()
            return .importWorkout(json_data: json_data)
        case 27:
            try deserializer.decrease_container_depth()
            return .showImportView
        case 28:
            try deserializer.decrease_container_depth()
            return .dismissImportView
        case 29:
            try deserializer.decrease_container_depth()
            return .loadWorkoutTemplate
        case 30:
            let target_weight = try deserializer.deserialize_f64()
            let bar_weight = try deserializer.deserialize_f64()
            let use_percentage = try deserialize_option_f64(deserializer: deserializer)
            try deserializer.decrease_container_depth()
            return .calculatePlates(target_weight: target_weight, bar_weight: bar_weight, use_percentage: use_percentage)
        case 31:
            try deserializer.decrease_container_depth()
            return .clearPlateCalculation
        case 32:
            try deserializer.decrease_container_depth()
            return .showPlateCalculator
        case 33:
            try deserializer.decrease_container_depth()
            return .dismissPlateCalculator
        case 34:
            let result = try SharedTypes.DatabaseResult.deserialize(deserializer: deserializer)
            try deserializer.decrease_container_depth()
            return .databaseResponse(result: result)
        case 35:
            let result = try SharedTypes.StorageResult.deserialize(deserializer: deserializer)
            try deserializer.decrease_container_depth()
            return .storageResponse(result: result)
        case 36:
            let message = try deserializer.deserialize_str()
            try deserializer.decrease_container_depth()
            return .error(message: message)
        default: throw DeserializationError.invalidInput(issue: "Unknown variant index for Event: \(index)")
        }
    }

    public static func bincodeDeserialize(input: [UInt8]) throws -> Event {
        let deserializer = BincodeDeserializer.init(input: input);
        let obj = try deserialize(deserializer: deserializer)
        if deserializer.get_buffer_offset() < input.count {
            throw DeserializationError.invalidInput(issue: "Some input bytes were not read")
        }
        return obj
    }
}

public struct Exercise: Hashable {
    @Indirect public var id: String
    @Indirect public var superset_id: Int32?
    @Indirect public var workout_id: String
    @Indirect public var name: String
    @Indirect public var pinned_notes: [String]
    @Indirect public var notes: [String]
    @Indirect public var duration: Int32?
    @Indirect public var type: SharedTypes.ExerciseType
    @Indirect public var weight_unit: SharedTypes.WeightUnit?
    @Indirect public var default_warm_up_time: Int32?
    @Indirect public var default_rest_time: Int32?
    @Indirect public var sets: [SharedTypes.ExerciseSet]
    @Indirect public var body_part: SharedTypes.BodyPart?

    public init(id: String, superset_id: Int32?, workout_id: String, name: String, pinned_notes: [String], notes: [String], duration: Int32?, type: SharedTypes.ExerciseType, weight_unit: SharedTypes.WeightUnit?, default_warm_up_time: Int32?, default_rest_time: Int32?, sets: [SharedTypes.ExerciseSet], body_part: SharedTypes.BodyPart?) {
        self.id = id
        self.superset_id = superset_id
        self.workout_id = workout_id
        self.name = name
        self.pinned_notes = pinned_notes
        self.notes = notes
        self.duration = duration
        self.type = type
        self.weight_unit = weight_unit
        self.default_warm_up_time = default_warm_up_time
        self.default_rest_time = default_rest_time
        self.sets = sets
        self.body_part = body_part
    }

    public func serialize<S: Serializer>(serializer: S) throws {
        try serializer.increase_container_depth()
        try serializer.serialize_str(value: self.id)
        try serialize_option_i32(value: self.superset_id, serializer: serializer)
        try serializer.serialize_str(value: self.workout_id)
        try serializer.serialize_str(value: self.name)
        try serialize_vector_str(value: self.pinned_notes, serializer: serializer)
        try serialize_vector_str(value: self.notes, serializer: serializer)
        try serialize_option_i32(value: self.duration, serializer: serializer)
        try self.type.serialize(serializer: serializer)
        try serialize_option_WeightUnit(value: self.weight_unit, serializer: serializer)
        try serialize_option_i32(value: self.default_warm_up_time, serializer: serializer)
        try serialize_option_i32(value: self.default_rest_time, serializer: serializer)
        try serialize_vector_ExerciseSet(value: self.sets, serializer: serializer)
        try serialize_option_BodyPart(value: self.body_part, serializer: serializer)
        try serializer.decrease_container_depth()
    }

    public func bincodeSerialize() throws -> [UInt8] {
        let serializer = BincodeSerializer.init();
        try self.serialize(serializer: serializer)
        return serializer.get_bytes()
    }

    public static func deserialize<D: Deserializer>(deserializer: D) throws -> Exercise {
        try deserializer.increase_container_depth()
        let id = try deserializer.deserialize_str()
        let superset_id = try deserialize_option_i32(deserializer: deserializer)
        let workout_id = try deserializer.deserialize_str()
        let name = try deserializer.deserialize_str()
        let pinned_notes = try deserialize_vector_str(deserializer: deserializer)
        let notes = try deserialize_vector_str(deserializer: deserializer)
        let duration = try deserialize_option_i32(deserializer: deserializer)
        let type = try SharedTypes.ExerciseType.deserialize(deserializer: deserializer)
        let weight_unit = try deserialize_option_WeightUnit(deserializer: deserializer)
        let default_warm_up_time = try deserialize_option_i32(deserializer: deserializer)
        let default_rest_time = try deserialize_option_i32(deserializer: deserializer)
        let sets = try deserialize_vector_ExerciseSet(deserializer: deserializer)
        let body_part = try deserialize_option_BodyPart(deserializer: deserializer)
        try deserializer.decrease_container_depth()
        return Exercise.init(id: id, superset_id: superset_id, workout_id: workout_id, name: name, pinned_notes: pinned_notes, notes: notes, duration: duration, type: type, weight_unit: weight_unit, default_warm_up_time: default_warm_up_time, default_rest_time: default_rest_time, sets: sets, body_part: body_part)
    }

    public static func bincodeDeserialize(input: [UInt8]) throws -> Exercise {
        let deserializer = BincodeDeserializer.init(input: input);
        let obj = try deserialize(deserializer: deserializer)
        if deserializer.get_buffer_offset() < input.count {
            throw DeserializationError.invalidInput(issue: "Some input bytes were not read")
        }
        return obj
    }
}

public struct ExerciseSet: Hashable {
    @Indirect public var id: String
    @Indirect public var type: SharedTypes.SetType
    @Indirect public var weight_unit: SharedTypes.WeightUnit?
    @Indirect public var suggest: SharedTypes.SetSuggest
    @Indirect public var actual: SharedTypes.SetActual
    @Indirect public var is_completed: Bool
    @Indirect public var exercise_id: String
    @Indirect public var workout_id: String
    @Indirect public var set_index: Int32

    public init(id: String, type: SharedTypes.SetType, weight_unit: SharedTypes.WeightUnit?, suggest: SharedTypes.SetSuggest, actual: SharedTypes.SetActual, is_completed: Bool, exercise_id: String, workout_id: String, set_index: Int32) {
        self.id = id
        self.type = type
        self.weight_unit = weight_unit
        self.suggest = suggest
        self.actual = actual
        self.is_completed = is_completed
        self.exercise_id = exercise_id
        self.workout_id = workout_id
        self.set_index = set_index
    }

    public func serialize<S: Serializer>(serializer: S) throws {
        try serializer.increase_container_depth()
        try serializer.serialize_str(value: self.id)
        try self.type.serialize(serializer: serializer)
        try serialize_option_WeightUnit(value: self.weight_unit, serializer: serializer)
        try self.suggest.serialize(serializer: serializer)
        try self.actual.serialize(serializer: serializer)
        try serializer.serialize_bool(value: self.is_completed)
        try serializer.serialize_str(value: self.exercise_id)
        try serializer.serialize_str(value: self.workout_id)
        try serializer.serialize_i32(value: self.set_index)
        try serializer.decrease_container_depth()
    }

    public func bincodeSerialize() throws -> [UInt8] {
        let serializer = BincodeSerializer.init();
        try self.serialize(serializer: serializer)
        return serializer.get_bytes()
    }

    public static func deserialize<D: Deserializer>(deserializer: D) throws -> ExerciseSet {
        try deserializer.increase_container_depth()
        let id = try deserializer.deserialize_str()
        let type = try SharedTypes.SetType.deserialize(deserializer: deserializer)
        let weight_unit = try deserialize_option_WeightUnit(deserializer: deserializer)
        let suggest = try SharedTypes.SetSuggest.deserialize(deserializer: deserializer)
        let actual = try SharedTypes.SetActual.deserialize(deserializer: deserializer)
        let is_completed = try deserializer.deserialize_bool()
        let exercise_id = try deserializer.deserialize_str()
        let workout_id = try deserializer.deserialize_str()
        let set_index = try deserializer.deserialize_i32()
        try deserializer.decrease_container_depth()
        return ExerciseSet.init(id: id, type: type, weight_unit: weight_unit, suggest: suggest, actual: actual, is_completed: is_completed, exercise_id: exercise_id, workout_id: workout_id, set_index: set_index)
    }

    public static func bincodeDeserialize(input: [UInt8]) throws -> ExerciseSet {
        let deserializer = BincodeDeserializer.init(input: input);
        let obj = try deserialize(deserializer: deserializer)
        if deserializer.get_buffer_offset() < input.count {
            throw DeserializationError.invalidInput(issue: "Some input bytes were not read")
        }
        return obj
    }
}

indirect public enum ExerciseType: Hashable {
    case barbell

    public func serialize<S: Serializer>(serializer: S) throws {
        try serializer.increase_container_depth()
        switch self {
        case .barbell:
            try serializer.serialize_variant_index(value: 2)
        }
        try serializer.decrease_container_depth()
    }

    public func bincodeSerialize() throws -> [UInt8] {
        let serializer = BincodeSerializer.init();
        try self.serialize(serializer: serializer)
        return serializer.get_bytes()
    }

    public static func deserialize<D: Deserializer>(deserializer: D) throws -> ExerciseType {
        let index = try deserializer.deserialize_variant_index()
        try deserializer.increase_container_depth()
        switch index {
        case 2:
            try deserializer.decrease_container_depth()
            return .barbell
        default: throw DeserializationError.invalidInput(issue: "Unknown variant index for ExerciseType: \(index)")
        }
    }

    public static func bincodeDeserialize(input: [UInt8]) throws -> ExerciseType {
        let deserializer = BincodeDeserializer.init(input: input);
        let obj = try deserialize(deserializer: deserializer)
        if deserializer.get_buffer_offset() < input.count {
            throw DeserializationError.invalidInput(issue: "Some input bytes were not read")
        }
        return obj
    }
}

public struct ExerciseViewModel: Hashable {
    @Indirect public var id: String
    @Indirect public var name: String
    @Indirect public var sets: [SharedTypes.SetViewModel]

    public init(id: String, name: String, sets: [SharedTypes.SetViewModel]) {
        self.id = id
        self.name = name
        self.sets = sets
    }

    public func serialize<S: Serializer>(serializer: S) throws {
        try serializer.increase_container_depth()
        try serializer.serialize_str(value: self.id)
        try serializer.serialize_str(value: self.name)
        try serialize_vector_SetViewModel(value: self.sets, serializer: serializer)
        try serializer.decrease_container_depth()
    }

    public func bincodeSerialize() throws -> [UInt8] {
        let serializer = BincodeSerializer.init();
        try self.serialize(serializer: serializer)
        return serializer.get_bytes()
    }

    public static func deserialize<D: Deserializer>(deserializer: D) throws -> ExerciseViewModel {
        try deserializer.increase_container_depth()
        let id = try deserializer.deserialize_str()
        let name = try deserializer.deserialize_str()
        let sets = try deserialize_vector_SetViewModel(deserializer: deserializer)
        try deserializer.decrease_container_depth()
        return ExerciseViewModel.init(id: id, name: name, sets: sets)
    }

    public static func bincodeDeserialize(input: [UInt8]) throws -> ExerciseViewModel {
        let deserializer = BincodeDeserializer.init(input: input);
        let obj = try deserialize(deserializer: deserializer)
        if deserializer.get_buffer_offset() < input.count {
            throw DeserializationError.invalidInput(issue: "Some input bytes were not read")
        }
        return obj
    }
}

public struct HistoryItemViewModel: Hashable {
    @Indirect public var id: String
    @Indirect public var name: String
    @Indirect public var date: String
    @Indirect public var exercise_count: UInt64
    @Indirect public var set_count: UInt64
    @Indirect public var total_volume: Int32

    public init(id: String, name: String, date: String, exercise_count: UInt64, set_count: UInt64, total_volume: Int32) {
        self.id = id
        self.name = name
        self.date = date
        self.exercise_count = exercise_count
        self.set_count = set_count
        self.total_volume = total_volume
    }

    public func serialize<S: Serializer>(serializer: S) throws {
        try serializer.increase_container_depth()
        try serializer.serialize_str(value: self.id)
        try serializer.serialize_str(value: self.name)
        try serializer.serialize_str(value: self.date)
        try serializer.serialize_u64(value: self.exercise_count)
        try serializer.serialize_u64(value: self.set_count)
        try serializer.serialize_i32(value: self.total_volume)
        try serializer.decrease_container_depth()
    }

    public func bincodeSerialize() throws -> [UInt8] {
        let serializer = BincodeSerializer.init();
        try self.serialize(serializer: serializer)
        return serializer.get_bytes()
    }

    public static func deserialize<D: Deserializer>(deserializer: D) throws -> HistoryItemViewModel {
        try deserializer.increase_container_depth()
        let id = try deserializer.deserialize_str()
        let name = try deserializer.deserialize_str()
        let date = try deserializer.deserialize_str()
        let exercise_count = try deserializer.deserialize_u64()
        let set_count = try deserializer.deserialize_u64()
        let total_volume = try deserializer.deserialize_i32()
        try deserializer.decrease_container_depth()
        return HistoryItemViewModel.init(id: id, name: name, date: date, exercise_count: exercise_count, set_count: set_count, total_volume: total_volume)
    }

    public static func bincodeDeserialize(input: [UInt8]) throws -> HistoryItemViewModel {
        let deserializer = BincodeDeserializer.init(input: input);
        let obj = try deserialize(deserializer: deserializer)
        if deserializer.get_buffer_offset() < input.count {
            throw DeserializationError.invalidInput(issue: "Some input bytes were not read")
        }
        return obj
    }
}

public struct HistoryViewModel: Hashable {
    @Indirect public var workouts: [SharedTypes.HistoryItemViewModel]
    @Indirect public var is_loading: Bool

    public init(workouts: [SharedTypes.HistoryItemViewModel], is_loading: Bool) {
        self.workouts = workouts
        self.is_loading = is_loading
    }

    public func serialize<S: Serializer>(serializer: S) throws {
        try serializer.increase_container_depth()
        try serialize_vector_HistoryItemViewModel(value: self.workouts, serializer: serializer)
        try serializer.serialize_bool(value: self.is_loading)
        try serializer.decrease_container_depth()
    }

    public func bincodeSerialize() throws -> [UInt8] {
        let serializer = BincodeSerializer.init();
        try self.serialize(serializer: serializer)
        return serializer.get_bytes()
    }

    public static func deserialize<D: Deserializer>(deserializer: D) throws -> HistoryViewModel {
        try deserializer.increase_container_depth()
        let workouts = try deserialize_vector_HistoryItemViewModel(deserializer: deserializer)
        let is_loading = try deserializer.deserialize_bool()
        try deserializer.decrease_container_depth()
        return HistoryViewModel.init(workouts: workouts, is_loading: is_loading)
    }

    public static func bincodeDeserialize(input: [UInt8]) throws -> HistoryViewModel {
        let deserializer = BincodeDeserializer.init(input: input);
        let obj = try deserialize(deserializer: deserializer)
        if deserializer.get_buffer_offset() < input.count {
            throw DeserializationError.invalidInput(issue: "Some input bytes were not read")
        }
        return obj
    }
}

public struct RenderOperation: Hashable {

    public init() {
    }

    public func serialize<S: Serializer>(serializer: S) throws {
        try serializer.increase_container_depth()
        try serializer.decrease_container_depth()
    }

    public func bincodeSerialize() throws -> [UInt8] {
        let serializer = BincodeSerializer.init();
        try self.serialize(serializer: serializer)
        return serializer.get_bytes()
    }

    public static func deserialize<D: Deserializer>(deserializer: D) throws -> RenderOperation {
        try deserializer.increase_container_depth()
        try deserializer.decrease_container_depth()
        return RenderOperation.init()
    }

    public static func bincodeDeserialize(input: [UInt8]) throws -> RenderOperation {
        let deserializer = BincodeDeserializer.init(input: input);
        let obj = try deserialize(deserializer: deserializer)
        if deserializer.get_buffer_offset() < input.count {
            throw DeserializationError.invalidInput(issue: "Some input bytes were not read")
        }
        return obj
    }
}

public struct Request: Hashable {
    @Indirect public var id: UInt32
    @Indirect public var effect: SharedTypes.Effect

    public init(id: UInt32, effect: SharedTypes.Effect) {
        self.id = id
        self.effect = effect
    }

    public func serialize<S: Serializer>(serializer: S) throws {
        try serializer.increase_container_depth()
        try serializer.serialize_u32(value: self.id)
        try self.effect.serialize(serializer: serializer)
        try serializer.decrease_container_depth()
    }

    public func bincodeSerialize() throws -> [UInt8] {
        let serializer = BincodeSerializer.init();
        try self.serialize(serializer: serializer)
        return serializer.get_bytes()
    }

    public static func deserialize<D: Deserializer>(deserializer: D) throws -> Request {
        try deserializer.increase_container_depth()
        let id = try deserializer.deserialize_u32()
        let effect = try SharedTypes.Effect.deserialize(deserializer: deserializer)
        try deserializer.decrease_container_depth()
        return Request.init(id: id, effect: effect)
    }

    public static func bincodeDeserialize(input: [UInt8]) throws -> Request {
        let deserializer = BincodeDeserializer.init(input: input);
        let obj = try deserialize(deserializer: deserializer)
        if deserializer.get_buffer_offset() < input.count {
            throw DeserializationError.invalidInput(issue: "Some input bytes were not read")
        }
        return obj
    }
}

public struct SetActual: Hashable {
    @Indirect public var weight: Double?
    @Indirect public var reps: Int32?
    @Indirect public var duration: Int32?
    @Indirect public var rpe: Double?
    @Indirect public var actual_rest_time: Int32?

    public init(weight: Double?, reps: Int32?, duration: Int32?, rpe: Double?, actual_rest_time: Int32?) {
        self.weight = weight
        self.reps = reps
        self.duration = duration
        self.rpe = rpe
        self.actual_rest_time = actual_rest_time
    }

    public func serialize<S: Serializer>(serializer: S) throws {
        try serializer.increase_container_depth()
        try serialize_option_f64(value: self.weight, serializer: serializer)
        try serialize_option_i32(value: self.reps, serializer: serializer)
        try serialize_option_i32(value: self.duration, serializer: serializer)
        try serialize_option_f64(value: self.rpe, serializer: serializer)
        try serialize_option_i32(value: self.actual_rest_time, serializer: serializer)
        try serializer.decrease_container_depth()
    }

    public func bincodeSerialize() throws -> [UInt8] {
        let serializer = BincodeSerializer.init();
        try self.serialize(serializer: serializer)
        return serializer.get_bytes()
    }

    public static func deserialize<D: Deserializer>(deserializer: D) throws -> SetActual {
        try deserializer.increase_container_depth()
        let weight = try deserialize_option_f64(deserializer: deserializer)
        let reps = try deserialize_option_i32(deserializer: deserializer)
        let duration = try deserialize_option_i32(deserializer: deserializer)
        let rpe = try deserialize_option_f64(deserializer: deserializer)
        let actual_rest_time = try deserialize_option_i32(deserializer: deserializer)
        try deserializer.decrease_container_depth()
        return SetActual.init(weight: weight, reps: reps, duration: duration, rpe: rpe, actual_rest_time: actual_rest_time)
    }

    public static func bincodeDeserialize(input: [UInt8]) throws -> SetActual {
        let deserializer = BincodeDeserializer.init(input: input);
        let obj = try deserialize(deserializer: deserializer)
        if deserializer.get_buffer_offset() < input.count {
            throw DeserializationError.invalidInput(issue: "Some input bytes were not read")
        }
        return obj
    }
}

public struct SetSuggest: Hashable {
    @Indirect public var weight: Double?
    @Indirect public var reps: Int32?
    @Indirect public var rep_range: Int32?
    @Indirect public var duration: Int32?
    @Indirect public var rpe: Double?
    @Indirect public var rest_time: Int32?

    public init(weight: Double?, reps: Int32?, rep_range: Int32?, duration: Int32?, rpe: Double?, rest_time: Int32?) {
        self.weight = weight
        self.reps = reps
        self.rep_range = rep_range
        self.duration = duration
        self.rpe = rpe
        self.rest_time = rest_time
    }

    public func serialize<S: Serializer>(serializer: S) throws {
        try serializer.increase_container_depth()
        try serialize_option_f64(value: self.weight, serializer: serializer)
        try serialize_option_i32(value: self.reps, serializer: serializer)
        try serialize_option_i32(value: self.rep_range, serializer: serializer)
        try serialize_option_i32(value: self.duration, serializer: serializer)
        try serialize_option_f64(value: self.rpe, serializer: serializer)
        try serialize_option_i32(value: self.rest_time, serializer: serializer)
        try serializer.decrease_container_depth()
    }

    public func bincodeSerialize() throws -> [UInt8] {
        let serializer = BincodeSerializer.init();
        try self.serialize(serializer: serializer)
        return serializer.get_bytes()
    }

    public static func deserialize<D: Deserializer>(deserializer: D) throws -> SetSuggest {
        try deserializer.increase_container_depth()
        let weight = try deserialize_option_f64(deserializer: deserializer)
        let reps = try deserialize_option_i32(deserializer: deserializer)
        let rep_range = try deserialize_option_i32(deserializer: deserializer)
        let duration = try deserialize_option_i32(deserializer: deserializer)
        let rpe = try deserialize_option_f64(deserializer: deserializer)
        let rest_time = try deserialize_option_i32(deserializer: deserializer)
        try deserializer.decrease_container_depth()
        return SetSuggest.init(weight: weight, reps: reps, rep_range: rep_range, duration: duration, rpe: rpe, rest_time: rest_time)
    }

    public static func bincodeDeserialize(input: [UInt8]) throws -> SetSuggest {
        let deserializer = BincodeDeserializer.init(input: input);
        let obj = try deserialize(deserializer: deserializer)
        if deserializer.get_buffer_offset() < input.count {
            throw DeserializationError.invalidInput(issue: "Some input bytes were not read")
        }
        return obj
    }
}

indirect public enum SetType: Hashable {
    case working

    public func serialize<S: Serializer>(serializer: S) throws {
        try serializer.increase_container_depth()
        switch self {
        case .working:
            try serializer.serialize_variant_index(value: 1)
        }
        try serializer.decrease_container_depth()
    }

    public func bincodeSerialize() throws -> [UInt8] {
        let serializer = BincodeSerializer.init();
        try self.serialize(serializer: serializer)
        return serializer.get_bytes()
    }

    public static func deserialize<D: Deserializer>(deserializer: D) throws -> SetType {
        let index = try deserializer.deserialize_variant_index()
        try deserializer.increase_container_depth()
        switch index {
        case 1:
            try deserializer.decrease_container_depth()
            return .working
        default: throw DeserializationError.invalidInput(issue: "Unknown variant index for SetType: \(index)")
        }
    }

    public static func bincodeDeserialize(input: [UInt8]) throws -> SetType {
        let deserializer = BincodeDeserializer.init(input: input);
        let obj = try deserialize(deserializer: deserializer)
        if deserializer.get_buffer_offset() < input.count {
            throw DeserializationError.invalidInput(issue: "Some input bytes were not read")
        }
        return obj
    }
}

public struct SetViewModel: Hashable {
    @Indirect public var id: String
    @Indirect public var set_number: Int32
    @Indirect public var previous_display: String
    @Indirect public var weight: String
    @Indirect public var reps: String
    @Indirect public var rpe: String
    @Indirect public var is_completed: Bool

    public init(id: String, set_number: Int32, previous_display: String, weight: String, reps: String, rpe: String, is_completed: Bool) {
        self.id = id
        self.set_number = set_number
        self.previous_display = previous_display
        self.weight = weight
        self.reps = reps
        self.rpe = rpe
        self.is_completed = is_completed
    }

    public func serialize<S: Serializer>(serializer: S) throws {
        try serializer.increase_container_depth()
        try serializer.serialize_str(value: self.id)
        try serializer.serialize_i32(value: self.set_number)
        try serializer.serialize_str(value: self.previous_display)
        try serializer.serialize_str(value: self.weight)
        try serializer.serialize_str(value: self.reps)
        try serializer.serialize_str(value: self.rpe)
        try serializer.serialize_bool(value: self.is_completed)
        try serializer.decrease_container_depth()
    }

    public func bincodeSerialize() throws -> [UInt8] {
        let serializer = BincodeSerializer.init();
        try self.serialize(serializer: serializer)
        return serializer.get_bytes()
    }

    public static func deserialize<D: Deserializer>(deserializer: D) throws -> SetViewModel {
        try deserializer.increase_container_depth()
        let id = try deserializer.deserialize_str()
        let set_number = try deserializer.deserialize_i32()
        let previous_display = try deserializer.deserialize_str()
        let weight = try deserializer.deserialize_str()
        let reps = try deserializer.deserialize_str()
        let rpe = try deserializer.deserialize_str()
        let is_completed = try deserializer.deserialize_bool()
        try deserializer.decrease_container_depth()
        return SetViewModel.init(id: id, set_number: set_number, previous_display: previous_display, weight: weight, reps: reps, rpe: rpe, is_completed: is_completed)
    }

    public static func bincodeDeserialize(input: [UInt8]) throws -> SetViewModel {
        let deserializer = BincodeDeserializer.init(input: input);
        let obj = try deserialize(deserializer: deserializer)
        if deserializer.get_buffer_offset() < input.count {
            throw DeserializationError.invalidInput(issue: "Some input bytes were not read")
        }
        return obj
    }
}

indirect public enum StorageResult: Hashable {
    case currentWorkoutSaved
    case currentWorkoutLoaded(workout: SharedTypes.Workout?)
    case currentWorkoutDeleted

    public func serialize<S: Serializer>(serializer: S) throws {
        try serializer.increase_container_depth()
        switch self {
        case .currentWorkoutSaved:
            try serializer.serialize_variant_index(value: 0)
        case .currentWorkoutLoaded(let workout):
            try serializer.serialize_variant_index(value: 1)
            try serialize_option_Workout(value: workout, serializer: serializer)
        case .currentWorkoutDeleted:
            try serializer.serialize_variant_index(value: 2)
        }
        try serializer.decrease_container_depth()
    }

    public func bincodeSerialize() throws -> [UInt8] {
        let serializer = BincodeSerializer.init();
        try self.serialize(serializer: serializer)
        return serializer.get_bytes()
    }

    public static func deserialize<D: Deserializer>(deserializer: D) throws -> StorageResult {
        let index = try deserializer.deserialize_variant_index()
        try deserializer.increase_container_depth()
        switch index {
        case 0:
            try deserializer.decrease_container_depth()
            return .currentWorkoutSaved
        case 1:
            let workout = try deserialize_option_Workout(deserializer: deserializer)
            try deserializer.decrease_container_depth()
            return .currentWorkoutLoaded(workout: workout)
        case 2:
            try deserializer.decrease_container_depth()
            return .currentWorkoutDeleted
        default: throw DeserializationError.invalidInput(issue: "Unknown variant index for StorageResult: \(index)")
        }
    }

    public static func bincodeDeserialize(input: [UInt8]) throws -> StorageResult {
        let deserializer = BincodeDeserializer.init(input: input);
        let obj = try deserialize(deserializer: deserializer)
        if deserializer.get_buffer_offset() < input.count {
            throw DeserializationError.invalidInput(issue: "Some input bytes were not read")
        }
        return obj
    }
}

indirect public enum Tab: Hashable {
    case workout
    case history

    public func serialize<S: Serializer>(serializer: S) throws {
        try serializer.increase_container_depth()
        switch self {
        case .workout:
            try serializer.serialize_variant_index(value: 0)
        case .history:
            try serializer.serialize_variant_index(value: 1)
        }
        try serializer.decrease_container_depth()
    }

    public func bincodeSerialize() throws -> [UInt8] {
        let serializer = BincodeSerializer.init();
        try self.serialize(serializer: serializer)
        return serializer.get_bytes()
    }

    public static func deserialize<D: Deserializer>(deserializer: D) throws -> Tab {
        let index = try deserializer.deserialize_variant_index()
        try deserializer.increase_container_depth()
        switch index {
        case 0:
            try deserializer.decrease_container_depth()
            return .workout
        case 1:
            try deserializer.decrease_container_depth()
            return .history
        default: throw DeserializationError.invalidInput(issue: "Unknown variant index for Tab: \(index)")
        }
    }

    public static func bincodeDeserialize(input: [UInt8]) throws -> Tab {
        let deserializer = BincodeDeserializer.init(input: input);
        let obj = try deserialize(deserializer: deserializer)
        if deserializer.get_buffer_offset() < input.count {
            throw DeserializationError.invalidInput(issue: "Some input bytes were not read")
        }
        return obj
    }
}

public struct ViewModel: Hashable {
    @Indirect public var selected_tab: SharedTypes.Tab
    @Indirect public var workout_view: SharedTypes.WorkoutViewModel
    @Indirect public var history_view: SharedTypes.HistoryViewModel
    @Indirect public var error_message: String?
    @Indirect public var is_loading: Bool

    public init(selected_tab: SharedTypes.Tab, workout_view: SharedTypes.WorkoutViewModel, history_view: SharedTypes.HistoryViewModel, error_message: String?, is_loading: Bool) {
        self.selected_tab = selected_tab
        self.workout_view = workout_view
        self.history_view = history_view
        self.error_message = error_message
        self.is_loading = is_loading
    }

    public func serialize<S: Serializer>(serializer: S) throws {
        try serializer.increase_container_depth()
        try self.selected_tab.serialize(serializer: serializer)
        try self.workout_view.serialize(serializer: serializer)
        try self.history_view.serialize(serializer: serializer)
        try serialize_option_str(value: self.error_message, serializer: serializer)
        try serializer.serialize_bool(value: self.is_loading)
        try serializer.decrease_container_depth()
    }

    public func bincodeSerialize() throws -> [UInt8] {
        let serializer = BincodeSerializer.init();
        try self.serialize(serializer: serializer)
        return serializer.get_bytes()
    }

    public static func deserialize<D: Deserializer>(deserializer: D) throws -> ViewModel {
        try deserializer.increase_container_depth()
        let selected_tab = try SharedTypes.Tab.deserialize(deserializer: deserializer)
        let workout_view = try SharedTypes.WorkoutViewModel.deserialize(deserializer: deserializer)
        let history_view = try SharedTypes.HistoryViewModel.deserialize(deserializer: deserializer)
        let error_message = try deserialize_option_str(deserializer: deserializer)
        let is_loading = try deserializer.deserialize_bool()
        try deserializer.decrease_container_depth()
        return ViewModel.init(selected_tab: selected_tab, workout_view: workout_view, history_view: history_view, error_message: error_message, is_loading: is_loading)
    }

    public static func bincodeDeserialize(input: [UInt8]) throws -> ViewModel {
        let deserializer = BincodeDeserializer.init(input: input);
        let obj = try deserialize(deserializer: deserializer)
        if deserializer.get_buffer_offset() < input.count {
            throw DeserializationError.invalidInput(issue: "Some input bytes were not read")
        }
        return obj
    }
}

indirect public enum WeightUnit: Hashable {
    case kg
    case lb

    public func serialize<S: Serializer>(serializer: S) throws {
        try serializer.increase_container_depth()
        switch self {
        case .kg:
            try serializer.serialize_variant_index(value: 0)
        case .lb:
            try serializer.serialize_variant_index(value: 1)
        }
        try serializer.decrease_container_depth()
    }

    public func bincodeSerialize() throws -> [UInt8] {
        let serializer = BincodeSerializer.init();
        try self.serialize(serializer: serializer)
        return serializer.get_bytes()
    }

    public static func deserialize<D: Deserializer>(deserializer: D) throws -> WeightUnit {
        let index = try deserializer.deserialize_variant_index()
        try deserializer.increase_container_depth()
        switch index {
        case 0:
            try deserializer.decrease_container_depth()
            return .kg
        case 1:
            try deserializer.decrease_container_depth()
            return .lb
        default: throw DeserializationError.invalidInput(issue: "Unknown variant index for WeightUnit: \(index)")
        }
    }

    public static func bincodeDeserialize(input: [UInt8]) throws -> WeightUnit {
        let deserializer = BincodeDeserializer.init(input: input);
        let obj = try deserialize(deserializer: deserializer)
        if deserializer.get_buffer_offset() < input.count {
            throw DeserializationError.invalidInput(issue: "Some input bytes were not read")
        }
        return obj
    }
}

public struct Workout: Hashable {
    @Indirect public var id: String
    @Indirect public var name: String
    @Indirect public var note: String?
    @Indirect public var duration: Int32?
    @Indirect public var start_timestamp: String
    @Indirect public var end_timestamp: String?
    @Indirect public var exercises: [SharedTypes.Exercise]

    public init(id: String, name: String, note: String?, duration: Int32?, start_timestamp: String, end_timestamp: String?, exercises: [SharedTypes.Exercise]) {
        self.id = id
        self.name = name
        self.note = note
        self.duration = duration
        self.start_timestamp = start_timestamp
        self.end_timestamp = end_timestamp
        self.exercises = exercises
    }

    public func serialize<S: Serializer>(serializer: S) throws {
        try serializer.increase_container_depth()
        try serializer.serialize_str(value: self.id)
        try serializer.serialize_str(value: self.name)
        try serialize_option_str(value: self.note, serializer: serializer)
        try serialize_option_i32(value: self.duration, serializer: serializer)
        try serializer.serialize_str(value: self.start_timestamp)
        try serialize_option_str(value: self.end_timestamp, serializer: serializer)
        try serialize_vector_Exercise(value: self.exercises, serializer: serializer)
        try serializer.decrease_container_depth()
    }

    public func bincodeSerialize() throws -> [UInt8] {
        let serializer = BincodeSerializer.init();
        try self.serialize(serializer: serializer)
        return serializer.get_bytes()
    }

    public static func deserialize<D: Deserializer>(deserializer: D) throws -> Workout {
        try deserializer.increase_container_depth()
        let id = try deserializer.deserialize_str()
        let name = try deserializer.deserialize_str()
        let note = try deserialize_option_str(deserializer: deserializer)
        let duration = try deserialize_option_i32(deserializer: deserializer)
        let start_timestamp = try deserializer.deserialize_str()
        let end_timestamp = try deserialize_option_str(deserializer: deserializer)
        let exercises = try deserialize_vector_Exercise(deserializer: deserializer)
        try deserializer.decrease_container_depth()
        return Workout.init(id: id, name: name, note: note, duration: duration, start_timestamp: start_timestamp, end_timestamp: end_timestamp, exercises: exercises)
    }

    public static func bincodeDeserialize(input: [UInt8]) throws -> Workout {
        let deserializer = BincodeDeserializer.init(input: input);
        let obj = try deserialize(deserializer: deserializer)
        if deserializer.get_buffer_offset() < input.count {
            throw DeserializationError.invalidInput(issue: "Some input bytes were not read")
        }
        return obj
    }
}

public struct WorkoutViewModel: Hashable {
    @Indirect public var has_active_workout: Bool
    @Indirect public var workout_name: String
    @Indirect public var formatted_duration: String
    @Indirect public var total_volume: Int32
    @Indirect public var total_sets: UInt64
    @Indirect public var exercises: [SharedTypes.ExerciseViewModel]
    @Indirect public var timer_running: Bool
    @Indirect public var showing_add_exercise: Bool
    @Indirect public var showing_import: Bool
    @Indirect public var showing_stopwatch: Bool
    @Indirect public var showing_rest_timer: Int32?

    public init(has_active_workout: Bool, workout_name: String, formatted_duration: String, total_volume: Int32, total_sets: UInt64, exercises: [SharedTypes.ExerciseViewModel], timer_running: Bool, showing_add_exercise: Bool, showing_import: Bool, showing_stopwatch: Bool, showing_rest_timer: Int32?) {
        self.has_active_workout = has_active_workout
        self.workout_name = workout_name
        self.formatted_duration = formatted_duration
        self.total_volume = total_volume
        self.total_sets = total_sets
        self.exercises = exercises
        self.timer_running = timer_running
        self.showing_add_exercise = showing_add_exercise
        self.showing_import = showing_import
        self.showing_stopwatch = showing_stopwatch
        self.showing_rest_timer = showing_rest_timer
    }

    public func serialize<S: Serializer>(serializer: S) throws {
        try serializer.increase_container_depth()
        try serializer.serialize_bool(value: self.has_active_workout)
        try serializer.serialize_str(value: self.workout_name)
        try serializer.serialize_str(value: self.formatted_duration)
        try serializer.serialize_i32(value: self.total_volume)
        try serializer.serialize_u64(value: self.total_sets)
        try serialize_vector_ExerciseViewModel(value: self.exercises, serializer: serializer)
        try serializer.serialize_bool(value: self.timer_running)
        try serializer.serialize_bool(value: self.showing_add_exercise)
        try serializer.serialize_bool(value: self.showing_import)
        try serializer.serialize_bool(value: self.showing_stopwatch)
        try serialize_option_i32(value: self.showing_rest_timer, serializer: serializer)
        try serializer.decrease_container_depth()
    }

    public func bincodeSerialize() throws -> [UInt8] {
        let serializer = BincodeSerializer.init();
        try self.serialize(serializer: serializer)
        return serializer.get_bytes()
    }

    public static func deserialize<D: Deserializer>(deserializer: D) throws -> WorkoutViewModel {
        try deserializer.increase_container_depth()
        let has_active_workout = try deserializer.deserialize_bool()
        let workout_name = try deserializer.deserialize_str()
        let formatted_duration = try deserializer.deserialize_str()
        let total_volume = try deserializer.deserialize_i32()
        let total_sets = try deserializer.deserialize_u64()
        let exercises = try deserialize_vector_ExerciseViewModel(deserializer: deserializer)
        let timer_running = try deserializer.deserialize_bool()
        let showing_add_exercise = try deserializer.deserialize_bool()
        let showing_import = try deserializer.deserialize_bool()
        let showing_stopwatch = try deserializer.deserialize_bool()
        let showing_rest_timer = try deserialize_option_i32(deserializer: deserializer)
        try deserializer.decrease_container_depth()
        return WorkoutViewModel.init(has_active_workout: has_active_workout, workout_name: workout_name, formatted_duration: formatted_duration, total_volume: total_volume, total_sets: total_sets, exercises: exercises, timer_running: timer_running, showing_add_exercise: showing_add_exercise, showing_import: showing_import, showing_stopwatch: showing_stopwatch, showing_rest_timer: showing_rest_timer)
    }

    public static func bincodeDeserialize(input: [UInt8]) throws -> WorkoutViewModel {
        let deserializer = BincodeDeserializer.init(input: input);
        let obj = try deserialize(deserializer: deserializer)
        if deserializer.get_buffer_offset() < input.count {
            throw DeserializationError.invalidInput(issue: "Some input bytes were not read")
        }
        return obj
    }
}

func serialize_option_BodyPart<S: Serializer>(value: SharedTypes.BodyPart?, serializer: S) throws {
    if let value = value {
        try serializer.serialize_option_tag(value: true)
        try value.serialize(serializer: serializer)
    } else {
        try serializer.serialize_option_tag(value: false)
    }
}

func deserialize_option_BodyPart<D: Deserializer>(deserializer: D) throws -> SharedTypes.BodyPart? {
    let tag = try deserializer.deserialize_option_tag()
    if tag {
        return try SharedTypes.BodyPart.deserialize(deserializer: deserializer)
    } else {
        return nil
    }
}

func serialize_option_WeightUnit<S: Serializer>(value: SharedTypes.WeightUnit?, serializer: S) throws {
    if let value = value {
        try serializer.serialize_option_tag(value: true)
        try value.serialize(serializer: serializer)
    } else {
        try serializer.serialize_option_tag(value: false)
    }
}

func deserialize_option_WeightUnit<D: Deserializer>(deserializer: D) throws -> SharedTypes.WeightUnit? {
    let tag = try deserializer.deserialize_option_tag()
    if tag {
        return try SharedTypes.WeightUnit.deserialize(deserializer: deserializer)
    } else {
        return nil
    }
}

func serialize_option_Workout<S: Serializer>(value: SharedTypes.Workout?, serializer: S) throws {
    if let value = value {
        try serializer.serialize_option_tag(value: true)
        try value.serialize(serializer: serializer)
    } else {
        try serializer.serialize_option_tag(value: false)
    }
}

func deserialize_option_Workout<D: Deserializer>(deserializer: D) throws -> SharedTypes.Workout? {
    let tag = try deserializer.deserialize_option_tag()
    if tag {
        return try SharedTypes.Workout.deserialize(deserializer: deserializer)
    } else {
        return nil
    }
}

func serialize_option_f64<S: Serializer>(value: Double?, serializer: S) throws {
    if let value = value {
        try serializer.serialize_option_tag(value: true)
        try serializer.serialize_f64(value: value)
    } else {
        try serializer.serialize_option_tag(value: false)
    }
}

func deserialize_option_f64<D: Deserializer>(deserializer: D) throws -> Double? {
    let tag = try deserializer.deserialize_option_tag()
    if tag {
        return try deserializer.deserialize_f64()
    } else {
        return nil
    }
}

func serialize_option_i32<S: Serializer>(value: Int32?, serializer: S) throws {
    if let value = value {
        try serializer.serialize_option_tag(value: true)
        try serializer.serialize_i32(value: value)
    } else {
        try serializer.serialize_option_tag(value: false)
    }
}

func deserialize_option_i32<D: Deserializer>(deserializer: D) throws -> Int32? {
    let tag = try deserializer.deserialize_option_tag()
    if tag {
        return try deserializer.deserialize_i32()
    } else {
        return nil
    }
}

func serialize_option_str<S: Serializer>(value: String?, serializer: S) throws {
    if let value = value {
        try serializer.serialize_option_tag(value: true)
        try serializer.serialize_str(value: value)
    } else {
        try serializer.serialize_option_tag(value: false)
    }
}

func deserialize_option_str<D: Deserializer>(deserializer: D) throws -> String? {
    let tag = try deserializer.deserialize_option_tag()
    if tag {
        return try deserializer.deserialize_str()
    } else {
        return nil
    }
}

func serialize_option_vector_str<S: Serializer>(value: [String]?, serializer: S) throws {
    if let value = value {
        try serializer.serialize_option_tag(value: true)
        try serialize_vector_str(value: value, serializer: serializer)
    } else {
        try serializer.serialize_option_tag(value: false)
    }
}

func deserialize_option_vector_str<D: Deserializer>(deserializer: D) throws -> [String]? {
    let tag = try deserializer.deserialize_option_tag()
    if tag {
        return try deserialize_vector_str(deserializer: deserializer)
    } else {
        return nil
    }
}

func serialize_vector_Exercise<S: Serializer>(value: [SharedTypes.Exercise], serializer: S) throws {
    try serializer.serialize_len(value: value.count)
    for item in value {
        try item.serialize(serializer: serializer)
    }
}

func deserialize_vector_Exercise<D: Deserializer>(deserializer: D) throws -> [SharedTypes.Exercise] {
    let length = try deserializer.deserialize_len()
    var obj : [SharedTypes.Exercise] = []
    for _ in 0..<length {
        obj.append(try SharedTypes.Exercise.deserialize(deserializer: deserializer))
    }
    return obj
}

func serialize_vector_ExerciseSet<S: Serializer>(value: [SharedTypes.ExerciseSet], serializer: S) throws {
    try serializer.serialize_len(value: value.count)
    for item in value {
        try item.serialize(serializer: serializer)
    }
}

func deserialize_vector_ExerciseSet<D: Deserializer>(deserializer: D) throws -> [SharedTypes.ExerciseSet] {
    let length = try deserializer.deserialize_len()
    var obj : [SharedTypes.ExerciseSet] = []
    for _ in 0..<length {
        obj.append(try SharedTypes.ExerciseSet.deserialize(deserializer: deserializer))
    }
    return obj
}

func serialize_vector_ExerciseViewModel<S: Serializer>(value: [SharedTypes.ExerciseViewModel], serializer: S) throws {
    try serializer.serialize_len(value: value.count)
    for item in value {
        try item.serialize(serializer: serializer)
    }
}

func deserialize_vector_ExerciseViewModel<D: Deserializer>(deserializer: D) throws -> [SharedTypes.ExerciseViewModel] {
    let length = try deserializer.deserialize_len()
    var obj : [SharedTypes.ExerciseViewModel] = []
    for _ in 0..<length {
        obj.append(try SharedTypes.ExerciseViewModel.deserialize(deserializer: deserializer))
    }
    return obj
}

func serialize_vector_HistoryItemViewModel<S: Serializer>(value: [SharedTypes.HistoryItemViewModel], serializer: S) throws {
    try serializer.serialize_len(value: value.count)
    for item in value {
        try item.serialize(serializer: serializer)
    }
}

func deserialize_vector_HistoryItemViewModel<D: Deserializer>(deserializer: D) throws -> [SharedTypes.HistoryItemViewModel] {
    let length = try deserializer.deserialize_len()
    var obj : [SharedTypes.HistoryItemViewModel] = []
    for _ in 0..<length {
        obj.append(try SharedTypes.HistoryItemViewModel.deserialize(deserializer: deserializer))
    }
    return obj
}

func serialize_vector_SetViewModel<S: Serializer>(value: [SharedTypes.SetViewModel], serializer: S) throws {
    try serializer.serialize_len(value: value.count)
    for item in value {
        try item.serialize(serializer: serializer)
    }
}

func deserialize_vector_SetViewModel<D: Deserializer>(deserializer: D) throws -> [SharedTypes.SetViewModel] {
    let length = try deserializer.deserialize_len()
    var obj : [SharedTypes.SetViewModel] = []
    for _ in 0..<length {
        obj.append(try SharedTypes.SetViewModel.deserialize(deserializer: deserializer))
    }
    return obj
}

func serialize_vector_Workout<S: Serializer>(value: [SharedTypes.Workout], serializer: S) throws {
    try serializer.serialize_len(value: value.count)
    for item in value {
        try item.serialize(serializer: serializer)
    }
}

func deserialize_vector_Workout<D: Deserializer>(deserializer: D) throws -> [SharedTypes.Workout] {
    let length = try deserializer.deserialize_len()
    var obj : [SharedTypes.Workout] = []
    for _ in 0..<length {
        obj.append(try SharedTypes.Workout.deserialize(deserializer: deserializer))
    }
    return obj
}

func serialize_vector_str<S: Serializer>(value: [String], serializer: S) throws {
    try serializer.serialize_len(value: value.count)
    for item in value {
        try serializer.serialize_str(value: item)
    }
}

func deserialize_vector_str<D: Deserializer>(deserializer: D) throws -> [String] {
    let length = try deserializer.deserialize_len()
    var obj : [String] = []
    for _ in 0..<length {
        obj.append(try deserializer.deserialize_str())
    }
    return obj
}

