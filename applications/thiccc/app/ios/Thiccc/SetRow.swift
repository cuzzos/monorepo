import SwiftUI
import SharedTypes

struct SetRow: View {
    let set: SetViewModel
    @Bindable var core: Core
    
    @FocusState private var focusedField: Field?
    @State private var weightText: String
    @State private var repsText: String
    @State private var rpeText: String
    @State private var weightSelection: TextSelection?
    @State private var repsSelection: TextSelection?
    @State private var rpeSelection: TextSelection?
    
    enum Field {
        case weight, reps, rpe
    }
    
    init(set: SetViewModel, core: Core) {
        self.set = set
        self.core = core
        // Initialize state values from the set
        self._weightText = State(initialValue: set.weight)
        self._repsText = State(initialValue: set.reps)
        self._rpeText = State(initialValue: set.rpe)
    }
    
    var body: some View {
        HStack {
            // Set Number
            Text("\(set.set_number)")
                .font(.subheadline)
                .frame(width: 30, alignment: .leading)
            
            // Previous
            Text(set.previous_display)
                .font(.caption)
                .frame(width: 100, alignment: .leading)
                .foregroundColor(.secondary)
            
            // Weight
            TextField("0", text: $weightText, selection: $weightSelection)
                .keyboardType(.decimalPad)
                .focused($focusedField, equals: .weight)
                .frame(width: 50)
                .onChange(of: focusedField) { _, newFocus in
                    if newFocus == .weight && !weightText.isEmpty {
                        weightSelection = .init(range: weightText.startIndex..<weightText.endIndex)
                    } else if newFocus != .weight {
                        // Update on blur
                        updateActual()
                    }
                }
            
            // Reps
            TextField("0", text: $repsText, selection: $repsSelection)
                .keyboardType(.numberPad)
                .focused($focusedField, equals: .reps)
                .frame(width: 50)
                .onChange(of: focusedField) { oldFocus, newFocus in
                    if newFocus == .reps && !repsText.isEmpty {
                        repsSelection = .init(range: repsText.startIndex..<repsText.endIndex)
                    } else if oldFocus == .reps && newFocus != .reps {
                        // Update on blur
                        updateActual()
                    }
                }
            
            // RPE
            TextField("0", text: $rpeText, selection: $rpeSelection)
                .keyboardType(.decimalPad)
                .focused($focusedField, equals: .rpe)
                .frame(width: 50)
                .onChange(of: focusedField) { oldFocus, newFocus in
                    if newFocus == .rpe && !rpeText.isEmpty {
                        rpeSelection = .init(range: rpeText.startIndex..<rpeText.endIndex)
                    } else if oldFocus == .rpe && newFocus != .rpe {
                        // Update on blur
                        updateActual()
                    }
                }
            
            // Completion Checkmark
            Button {
                Task { await core.update(.toggleSetCompleted(set_id: set.id)) }
            } label: {
                Image(systemName: set.is_completed ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(set.is_completed ? .green : .gray)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func updateActual() {
        // Parse values and send update event
        let weight = Double(weightText)
        let reps = Int32(repsText)
        let rpe = Double(rpeText)
        
        let actual = SetActual(
            weight: weight,
            reps: reps,
            duration: nil,
            rpe: rpe,
            actual_rest_time: nil
        )
        
        Task { await core.update(.updateSetActual(set_id: set.id, actual: actual)) }
    }
}

