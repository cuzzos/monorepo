import Foundation

struct BarType: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    let weight: Double
    
    init(id: UUID = UUID(), name: String, weight: Double) {
        self.id = id
        self.name = name
        self.weight = weight
    }
    
    static let olympic = BarType(name: "Olympic", weight: 45)
    static let standard = BarType(name: "Standard", weight: 20)
    static let ezBar = BarType(name: "EZ Bar", weight: 20)
    static let trapBar = BarType(name: "Trap Bar", weight: 45)
    
    static let allBars: [BarType] = [olympic, standard, ezBar, trapBar]
} 