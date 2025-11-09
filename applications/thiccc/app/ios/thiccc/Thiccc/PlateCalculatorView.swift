import SwiftUI

struct PlateCalculatorView: View {
    @State private var selectedBarType = BarType.olympic
    @State private var targetWeight: String = ""
    @State private var calculation: PlateCalculation?
    @State private var percentage: String = ""
    
    private let plateCalculator = PlateCalculator()
    
    var body: some View {
        VStack(spacing: 20) {
            // Title
            Text("Plate Calculator")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // Bar type selector
            HStack {
                Text("Bar Type:")
                    .fontWeight(.medium)
                
                Picker("Select Bar", selection: $selectedBarType) {
                    ForEach(BarType.allBars, id: \.id) { bar in
                        Text("\(bar.name) (\(Int(bar.weight))lb)")
                            .tag(bar)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            .padding(.horizontal)
            
            // Weight and percentage inputs
            VStack(spacing: 12) {
                HStack {
                    Text("Target Weight:")
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    TextField("Enter weight", text: $targetWeight)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .multilineTextAlignment(.trailing)
                        .frame(width: 120)
                    
                    Text("lbs")
                }
                
                HStack {
                    Text("Use Percentage:")
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    TextField("Enter %", text: $percentage)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                    
                    Text("%")
                }
            }
            .padding(.horizontal)
            
            Button("Calculate Plates") {
                calculatePlates()
            }
            .buttonStyle(.bordered)
            .padding(.top, 8)
            
            // Result display
            if let calculation = calculation {
                resultView(calculation)
            }
            
            Spacer()
        }
        .padding()
        .onDisappear {
            // Clear sensitive data when view disappears
            self.calculation = nil
        }
    }
    
    // Calculate plates
    private func calculatePlates() {
        guard let weight = Double(targetWeight),
              weight > 0 else {
            return
        }
        
        let finalWeight: Double
        if !percentage.isEmpty {
            guard let percentageValue = Double(percentage),
                  percentageValue > 0,
                  percentageValue <= 100 else {
                return
            }
            finalWeight = weight * (percentageValue / 100)
        } else {
            finalWeight = weight
        }
        
        calculation = plateCalculator.calculatePlatesForTargetWeight(
            targetWeight: finalWeight,
            barType: selectedBarType
        )
    }
    
    // Result view
    private func resultView(_ calculation: PlateCalculation) -> some View {
        VStack(spacing: 16) {
            Divider()
                .padding(.vertical, 8)
            
            Text("Results")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Total Weight:")
                        .fontWeight(.medium)
                    
                    Text("Bar Weight:")
                        .fontWeight(.medium)
                    
                    Text("Plates Per Side:")
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\(Int(calculation.totalWeight))lb")
                        .fontWeight(.bold)
                    
                    Text("\(Int(calculation.barType.weight))lb")
                    
                    Text(calculation.formattedPlateDescription)
                }
            }
            .padding(.horizontal)
            
            // Visual representation of bar with plates
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    // Left side plates (reversed)
                    ForEach(calculation.plates.indices.reversed(), id: \.self) { index in
                        let plate = calculation.plates[index]
                        platePic(plate)
                    }
                    
                    // Bar
                    Rectangle()
                        .fill(Color.gray)
                        .frame(width: 120, height: 10)
                    
                    // Right side plates
                    ForEach(calculation.plates.indices, id: \.self) { index in
                        let plate = calculation.plates[index]
                        platePic(plate)
                    }
                }
                .padding()
            }
        }
    }
    
    // Visual representation of a plate
    private func platePic(_ plate: Plate) -> some View {
        let width = max(min(plate.weight / 2, 10), 5)
        
        return Rectangle()
            .fill(plateColor(weight: plate.weight))
            .frame(width: width, height: 60)
    }
    
    // Generate plate colors based on weight
    private func plateColor(weight: Double) -> Color {
        switch weight {
        case 45: return Color.red
        case 35: return Color.blue
        case 25: return Color.green
        case 10: return Color.black
        case 5: return Color.gray
        case 2.5: return Color.purple
        default: return Color.orange
        }
    }
}

// MARK: - Preview
#Preview {
    PlateCalculatorView()
}

// MARK: - One Side Weight View (Obsolete)
struct OneSideWeightView: View {
    @State private var oneSideWeight: String = ""
    @State private var calculation: PlateCalculation?
    @State private var selectedBarType: BarType
    
    private let plateCalculator = PlateCalculator()
    
    init(barType: BarType) {
        _selectedBarType = State(initialValue: barType)
    }
    
    var body: some View {
        VStack {
            Text("Plates on one side:")
                .fontWeight(.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Plate selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(Plate.standard) { plate in
                        PlateButton(plate: plate) {
                            addPlateToOneSide(plate)
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // Selected plates display
            if let oneSidePlates = getOneSidePlates() {
                HStack {
                    Text("Selected:")
                        .fontWeight(.medium)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(oneSidePlates.enumerated().map({ $0 }), id: \.element.id) { index, plate in
                                Text(plate.weight == 2.5 ? "2.5lb" : "\(Int(plate.weight))lb")
                                    .padding(8)
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(8)
                                    .onTapGesture {
                                        removePlateFromOneSide(at: index)
                                    }
                            }
                        }
                    }
                    
                    Button(action: {
                        oneSideWeight = ""
                        calculateTotalWeight()
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal)
            }
            
            Button("Calculate Total Weight") {
                calculateTotalWeight()
            }
            .buttonStyle(.bordered)
            .padding(.top, 8)
        }
    }
    
    // Helper view for displaying a plate button
    private struct PlateButton: View {
        let plate: Plate
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                VStack {
                    Circle()
                        .fill(plateColor(weight: plate.weight))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Text(plate.weight == 2.5 ? "2.5" : "\(Int(plate.weight))")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        )
                }
            }
        }
        
        // Generate colors based on plate weight
        private func plateColor(weight: Double) -> Color {
            switch weight {
            case 45: return Color.red
            case 35: return Color.blue
            case 25: return Color.green
            case 10: return Color.black
            case 5: return Color.gray
            case 2.5: return Color.purple
            default: return Color.orange
            }
        }
    }
    
    // Get plates for one side from the text input
    private func getOneSidePlates() -> [Plate]? {
        guard !oneSideWeight.isEmpty else { return nil }
        
        let weights = oneSideWeight.split(separator: ",")
            .compactMap { Double($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
        
        return weights.map { Plate(weight: $0) }
    }
    
    // Add a plate to the one side input
    private func addPlateToOneSide(_ plate: Plate) {
        if oneSideWeight.isEmpty {
            oneSideWeight = "\(plate.weight)"
        } else {
            oneSideWeight += ", \(plate.weight)"
        }
        
        calculateTotalWeight()
    }
    
    // Remove a plate from the one side input
    private func removePlateFromOneSide(at index: Int) {
        guard var plates = getOneSidePlates(), index < plates.count else {
            return
        }
        
        plates.remove(at: index)
        oneSideWeight = plates.map { "\($0.weight)" }.joined(separator: ", ")
        
        calculateTotalWeight()
    }
    
    // Calculate total weight from plates on one side
    private func calculateTotalWeight() {
        guard let plates = getOneSidePlates(), !plates.isEmpty else {
            calculation = nil
            return
        }
        
        calculation = plateCalculator.calculateTotalWeight(
            platesOnOneSide: plates,
            barType: selectedBarType
        )
    }
}