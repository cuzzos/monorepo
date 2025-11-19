import Foundation

struct BarType: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let weight: Double
    
    static let olympic = BarType(name: "Olympic", weight: 45)
    static let standard = BarType(name: "Standard", weight: 20)
    static let ezBar = BarType(name: "EZ Bar", weight: 20)
    static let trapBar = BarType(name: "Trap Bar", weight: 45)
    
    static let allBars: [BarType] = [olympic, standard, ezBar, trapBar]
} 