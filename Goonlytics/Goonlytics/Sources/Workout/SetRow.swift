import SwiftUI

struct SetRow: View {
    @State var viewModel: WorkoutModel
    var set: ExerciseSet
    var setIndex: Int
    var exerciseIndex: Int

    var body: some View {
        HStack {
            Text("Set \(setIndex + 1)")
                .font(.subheadline)
                .frame(width: 60, alignment: .leading)
            TextField("Reps", value: Binding(
                get: { set.actual?.reps ?? set.suggest?.reps ?? 0 },
                set: { viewModel.updateReps(for: exerciseIndex, setIndex: setIndex, reps: $0) }
            ), formatter: NumberFormatter())
                .keyboardType(.numberPad)
                .frame(width: 60)
            TextField("RPE", value: Binding(
                get: { set.actual?.rpe ?? set.suggest?.rpe ?? 0 },
                set: { viewModel.updateRPE(for: exerciseIndex, setIndex: setIndex, rpe: $0) }
            ), formatter: NumberFormatter())
                .keyboardType(.decimalPad)
                .frame(width: 60)
            Button(action: {
                viewModel.toggleSetCompleted(for: exerciseIndex, setIndex: setIndex)
            }) {
                Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(set.isCompleted ? .green : .gray)
            }
        }
        .padding(.vertical, 4)
    }
}
