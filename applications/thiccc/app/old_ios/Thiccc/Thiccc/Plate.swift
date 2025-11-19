import Foundation

struct Plate: Identifiable, Codable, Hashable {
    let id: UUID
    let weight: Double
    
    init(id: UUID = UUID(), weight: Double) {
        self.id = id
        self.weight = weight
    }
    
    static let standard: [Plate] = [
        Plate(weight: 45),
        Plate(weight: 35),
        Plate(weight: 25),
        Plate(weight: 10),
        Plate(weight: 5),
        Plate(weight: 2.5)
    ]
} 