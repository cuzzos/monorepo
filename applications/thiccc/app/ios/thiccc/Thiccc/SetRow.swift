import SwiftUI

struct SetRow: View {
    let set: ExerciseSetViewModel
    let onUpdate: (SetActual) -> Void
    @FocusState var focus: Field?
    @State private var weightText: String = ""
    @State private var repsText: String = ""
    @State private var rpeText: String = ""

    enum Field: Hashable {
        case weight
        case reps
        case rpe
    }
    
    init(set: ExerciseSetViewModel, onUpdate: @escaping (SetActual) -> Void) {
        self.set = set
        self.onUpdate = onUpdate
        _weightText = State(initialValue: set.actual.weight?.description ?? "")
        _repsText = State(initialValue: set.actual.reps?.description ?? "")
        _rpeText = State(initialValue: set.actual.rpe?.description ?? "")
    }

    var body: some View {
        HStack {
            Text("\(set.setIndex + 1)")
                .font(.subheadline)
                .frame(width: 30, alignment: .leading)
            
            Text("Previous")
                .frame(width: 100, alignment: .leading)
            
            TextField("Weight", text: $weightText)
                .focused($focus, equals: .weight)
                .keyboardType(.decimalPad)
                .frame(width: 50)
                .onChange(of: weightText) { _, newValue in
                    let actual = SetActual(
                        weight: Double(newValue),
                        reps: set.actual.reps,
                        duration: set.actual.duration,
                        rpe: set.actual.rpe,
                        actualRestTime: set.actual.actualRestTime
                    )
                    onUpdate(actual)
                }
            
            TextField("Reps", text: $repsText)
                .focused($focus, equals: .reps)
                .keyboardType(.numberPad)
                .frame(width: 50)
                .onChange(of: repsText) { _, newValue in
                    let actual = SetActual(
                        weight: set.actual.weight,
                        reps: Int(newValue),
                        duration: set.actual.duration,
                        rpe: set.actual.rpe,
                        actualRestTime: set.actual.actualRestTime
                    )
                    onUpdate(actual)
                }
            
            TextField("RPE", text: $rpeText)
                .focused($focus, equals: .rpe)
                .keyboardType(.decimalPad)
                .frame(width: 50)
                .onChange(of: rpeText) { _, newValue in
                    let actual = SetActual(
                        weight: set.actual.weight,
                        reps: set.actual.reps,
                        duration: set.actual.duration,
                        rpe: Double(newValue),
                        actualRestTime: set.actual.actualRestTime
                    )
                    onUpdate(actual)
                }
            
            Button(action: {
                onUpdate(SetActual(
                    weight: set.actual.weight,
                    reps: set.actual.reps,
                    duration: set.actual.duration,
                    rpe: set.actual.rpe,
                    actualRestTime: set.actual.actualRestTime
                ))
            }) {
                Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(set.isCompleted ? .green : .gray)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    SetRow(
        set: ExerciseSetViewModel(
            id: UUID(),
            setType: .working,
            weightUnit: .lb,
            suggest: SetSuggest(),
            actual: SetActual(weight: 135, reps: 10, rpe: 7.5),
            isCompleted: false,
            setIndex: 0
        ),
        onUpdate: { _ in }
    )
}
