import Foundation
import IdentifiedCollections
import SharingGRDB

extension UUID: QueryExpression {
    public typealias QueryValue = UUID.LowercasedRepresentation
    
    public var queryFragment: QueryFragment {
        QueryFragment(stringLiteral: self.uuidString.lowercased())
    }
}

// MARK: - Models
@Table
struct Workout: Codable, Hashable, Identifiable {
    static let databaseTableName = "workouts"
    @Column(as: UUID.LowercasedRepresentation.self)
    let id: UUID
    var name: String
    var note: String?
    var duration: Int?
    @Column(as: Date.ISO8601Representation.self)
    var startTimestamp: Date
    @Column(as: Date.ISO8601Representation?.self)
    var endTimestamp: Date?
    @Ephemeral
    var exercises: IdentifiedArrayOf<Exercise> = []
}

@Table
struct Exercise: Identifiable, Codable, Hashable {
    static let databaseTableName = "exercises"
    @Column(as: UUID.LowercasedRepresentation.self)
    let id: UUID
    var supersetId: Int?
    @Column(as: UUID.LowercasedRepresentation.self)
    let workoutId: UUID
    let name: String
    @Column(as: [String].JSONRepresentation.self)
    let pinnedNotes: [String]
    @Column(as: [String].JSONRepresentation.self)
    let notes: [String]
    let duration: Int?
    let type: ExerciseType
    let weightUnit: WeightUnit?
    let defaultWarmUpTime: Int?
    let defaultRestTime: Int?
    @Ephemeral
    var sets: IdentifiedArrayOf<ExerciseSet> = []
    @Column(as: BodyPart.JSONRepresentation?.self)
    let bodyPart: BodyPart?
}

enum ExerciseType: String, CaseIterable, Codable, Identifiable, QueryBindable {
    var id: String { self.rawValue }

    case dumbbell
    case kettlebell
    case barbell
    case hexbar
    case bodyweight
    case machine
    case unknown
}

enum WeightUnit: String, Codable, Hashable, QueryBindable, DatabaseValueConvertible {
    case kg
    case lb
    case bodyweight
}

enum SetType: String, Codable, Hashable, QueryBindable, DatabaseValueConvertible {
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
    case fullBody
    case other
}

@Table
struct ExerciseSet: Codable, Hashable, Identifiable {
    static let databaseTableName = "exerciseSets"
    struct Suggest: Codable, Hashable {
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
    
    struct Actual: Codable, Hashable {
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
    @Column(as: UUID.LowercasedRepresentation.self)
    let id: UUID
    var type: SetType
    var weightUnit: WeightUnit?
    @Column(as: Suggest.JSONRepresentation.self)
    var suggest: Suggest
    @Column(as: Actual.JSONRepresentation.self)
    var actual: Actual
    
    @Ephemeral
    var isCompleted: Bool = false
    
    // For database use
    @Column(as: UUID.LowercasedRepresentation.self)
    let exerciseId: UUID
    @Column(as: UUID.LowercasedRepresentation.self)
    let workoutId: UUID
    var setIndex: Int = 0
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
