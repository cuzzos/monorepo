import Foundation

struct PlateCalculation: Codable, Equatable {
    let totalWeight: Double
    let barType: BarType
    let plates: [Plate]
    
    var formattedPlateDescription: String {
        let plateCounts = Dictionary(grouping: plates, by: { $0.weight })
            .mapValues { $0.count }
            .sorted { $0.key > $1.key }
        
        return plateCounts.map { weight, count in
            let weightStr = weight == 2.5 ? "2.5" : "\(Int(weight))"
            return "\(count)x\(weightStr)lb"
        }.joined(separator: ", ")
    }
} 