import Foundation

// MARK: - Models
struct Workout: Codable, Hashable, Identifiable {
    let id: UUID
    var name: String
    var note: String?
    var duration: Int?
    var startTimestamp: Date
    var endTimestamp: Date?
    var exercises: [Exercise]
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case note
        case duration
        case startTimestamp = "start_timestamp"
        case endTimestamp = "end_timestamp"
        case exercises
    }
}


struct Exercise: Identifiable, Codable, Hashable {
    let id: UUID
    var supersetId: Int?
    let workoutId: UUID
    let name: String
    let pinnedNotes: [String]
    let notes: [String]
    let duration: Int?
    let type: ExerciseType
    let weightUnit: WeightUnit?
    let defaultWarmUpTime: Int?
    let defaultRestTime: Int?
    var sets: [ExerciseSet]
    let bodyPart: BodyPart?
    
    enum CodingKeys: String, CodingKey {
        case id
        case supersetId = "superset_id"
        case workoutId = "workout_id"
        case name
        case pinnedNotes = "pinned_notes"
        case notes
        case duration
        case type
        case weightUnit = "weight_unit"
        case defaultWarmUpTime = "default_warm_up_time"
        case defaultRestTime = "default_rest_time"
        case sets
        case bodyPart = "body_part"
    }
}

enum ExerciseType: String, CaseIterable, Codable, Identifiable {
    var id: String { self.rawValue }

    case dumbbell
    case kettlebell
    case barbell
    case hexbar
    case bodyweight
    case machine
    case unknown
}

enum WeightUnit: String, Codable, Hashable {
    case kg
    case lb
    case bodyweight
}

enum SetType: String, Codable, Hashable {
    case warmUp = "warm_up"
    case working
    case dropSet = "drop_set"
    case amrap
    case failure
}

struct BodyPart: Codable, Hashable {
    let main: BodyPartMain
    let detailed: [String]?
    let scientific: [String]?
    
    enum CodingKeys: String, CodingKey {
        case main
        case detailed
        case scientific
    }
    
    init(main: BodyPartMain, detailed: [String]? = nil, scientific: [String]? = nil) {
        self.main = main
        self.detailed = detailed
        self.scientific = scientific
    }
}

enum BodyPartMain: String, Codable, Hashable {
    case chest
    case legs
    case arms
    case back
    case calves
    case shoulders
    case core
    case cardio
    case fullBody = "full_body"
    case other
}

struct ExerciseSet: Codable, Hashable {
    var type: SetType
    var weightUnit: WeightUnit?
    var suggest: SetSuggest?
    var actual: SetActual?
    
    // Local state
    var isCompleted: Bool = false
    
    // For database use
    let exerciseId: UUID
    var setIndex: Int = 0
    
    enum CodingKeys: String, CodingKey {
        case type
        case weightUnit = "weight_unit"
        case suggest
        case actual
        case exerciseId
    }
}

struct SetSuggest: Codable, Hashable {
    let weight: Double?
    let reps: Int?
    let repRange: Int?
    let duration: Int?
    let rpe: Double?
    let restTime: Int?
    
    enum CodingKeys: String, CodingKey {
        case weight
        case reps
        case repRange = "rep_range"
        case duration
        case rpe
        case restTime = "rest_time"
    }
    
    init(weight: Double? = nil, reps: Int? = nil, repRange: Int? = nil, duration: Int? = nil, rpe: Double? = nil, restTime: Int? = nil) {
        self.weight = weight
        self.reps = reps
        self.repRange = repRange
        self.duration = duration
        self.rpe = rpe
        self.restTime = restTime
    }
}

struct SetActual: Codable, Hashable {
    var weight: Double?
    var reps: Int?
    var duration: Int?
    var rpe: Double?
    var actualRestTime: Int?
    
    enum CodingKeys: String, CodingKey {
        case weight
        case reps
        case duration
        case rpe
        case actualRestTime = "actual_rest_time"
    }
    
    init(weight: Double? = nil, reps: Int? = nil, duration: Int? = nil, rpe: Double? = nil, actualRestTime: Int? = nil) {
        self.weight = weight
        self.reps = reps
        self.duration = duration
        self.rpe = rpe
        self.actualRestTime = actualRestTime
    }
}

// MARK: - Extensions
extension Exercise {
    var isCompleted: Bool {
        sets.allSatisfy(\.isCompleted)
    }
}

extension ExerciseSet {
    // Helper computed property for UI display
    var number: Int {
        // This would be set by the parent exercise
        0
    }
}
