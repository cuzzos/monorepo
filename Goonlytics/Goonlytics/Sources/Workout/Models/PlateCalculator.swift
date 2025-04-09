import Foundation

class PlateCalculator {
    func calculatePlatesForTargetWeight(targetWeight: Double, barType: BarType) -> PlateCalculation {
        let weightPerSide = (targetWeight - barType.weight) / 2
        var remainingWeight = weightPerSide
        var plates: [Plate] = []
        
        for plate in Plate.standard {
            while remainingWeight >= plate.weight {
                plates.append(plate)
                remainingWeight -= plate.weight
            }
        }
        
        return PlateCalculation(
            totalWeight: targetWeight,
            barType: barType,
            plates: plates
        )
    }
    
    func calculateTotalWeight(platesOnOneSide: [Plate], barType: BarType) -> PlateCalculation {
        let weightPerSide = platesOnOneSide.reduce(0) { $0 + $1.weight }
        let totalWeight = (weightPerSide * 2) + barType.weight
        
        return PlateCalculation(
            totalWeight: totalWeight,
            barType: barType,
            plates: platesOnOneSide
        )
    }
} 