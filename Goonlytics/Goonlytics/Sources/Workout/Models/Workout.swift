import Foundation

// MARK: - Models
struct Workout: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var date: Date
    var exercises: [Exercise]
    
    init(id: UUID = UUID(), name: String = "", date: Date = .now, exercises: [Exercise] = []) {
        self.id = id
        self.name = name
        self.date = date
        self.exercises = exercises
    }
}

struct Exercise: Identifiable, Codable, Hashable {
    var id: UUID { UUID(uuidString: exerciseId) ?? UUID() }
    let exerciseId: String
    let exerciseName: String
    var sets: [ExerciseSet]
    let weightUnit: String
    let warmUpTime: Int
    let restTime: Int
    var isCompleted: Bool = false
    
    // Added properties for grouping
    var groupId: UUID?
    var isPartOfSuperset: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case exerciseId = "exercise_id"
        case exerciseName = "exercise_name"
        case sets
        case weightUnit = "weight_unit"
        case warmUpTime = "warm_up_time"
        case restTime = "rest_time"
        // groupId and isPartOfSuperset won't be in the JSON
    }
}

struct ExerciseSet: Identifiable, Codable, Hashable {
    let id = UUID()
    let type: String
    let suggestedWeight: Double
    let suggestedReps: Int
    let suggestedRPE: Int
    var actualWeight: Double?
    var actualReps: Int?
    var actualRPE: Int?
    var isCompleted: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case type
        case suggestedWeight = "suggested_weight"
        case suggestedReps = "suggested_reps"
        case suggestedRPE = "suggested_RPE"
        case actualWeight = "actual_weight"
        case actualReps = "actual_reps"
        case actualRPE = "actual_RPE"
    }
    
    // Helper computed property for UI display
    var number: Int {
        // This would be set by the parent exercise
        0
    }
    
    // Simplified computed properties
    var weight: Double? {
        get { actualWeight }
        set { actualWeight = newValue }
    }
    
    var reps: Int? {
        get { actualReps }
        set { actualReps = newValue }
    }
}
