import Foundation

// MARK: - Models (matching Rust types)
// These models are used for serialization/deserialization with the Rust core
// They match the Rust models in shared/src/models.rs

struct Workout: Codable, Hashable, Identifiable {
    let id: UUID
    var name: String
    var note: String?
    var duration: Int?
    var startTimestamp: Date
    var endTimestamp: Date?
    var exercises: [Exercise] = []
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
    var sets: [ExerciseSet] = []
    let bodyPart: BodyPart?
    
    var isCompleted: Bool {
        sets.allSatisfy { $0.isCompleted }
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
    case warmUp
    case working
    case dropSet
    case amrap
    case failure
}

struct BodyPart: Codable, Hashable {
    let main: BodyPartMain
    let detailed: [String]?
    let scientific: [String]?
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
    case fullBody
    case other
}

struct ExerciseSet: Codable, Hashable, Identifiable {
    struct Suggest: Codable, Hashable, Equatable {
        let weight: Double?
        let reps: Int?
        let repRange: Int?
        let duration: Int?
        let rpe: Double?
        let restTime: Int?
        
        init(weight: Double? = nil, reps: Int? = nil, repRange: Int? = nil, duration: Int? = nil, rpe: Double? = nil, restTime: Int? = nil) {
            self.weight = weight
            self.reps = reps
            self.repRange = repRange
            self.duration = duration
            self.rpe = rpe
            self.restTime = restTime
        }
    }
    
    struct Actual: Codable, Hashable, Equatable {
        var weight: Double?
        var reps: Int?
        var duration: Int?
        var rpe: Double?
        var actualRestTime: Int?

        init(weight: Double? = nil, reps: Int? = nil, duration: Int? = nil, rpe: Double? = nil, actualRestTime: Int? = nil) {
            self.weight = weight
            self.reps = reps
            self.duration = duration
            self.rpe = rpe
            self.actualRestTime = actualRestTime
        }
    }
    
    let id: UUID
    var type: SetType
    var weightUnit: WeightUnit?
    var suggest: Suggest
    var actual: Actual
    var isCompleted: Bool = false
    let exerciseId: UUID
    let workoutId: UUID
    var setIndex: Int = 0
}

// MARK: - Type Aliases (for convenience)
typealias SetActual = ExerciseSet.Actual
typealias SetSuggest = ExerciseSet.Suggest

// MARK: - GlobalExercise (for exercise selection)
struct GlobalExercise: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    let type: String
    let additionalFK: String?
    let muscleGroup: String
    let imageName: String
}
