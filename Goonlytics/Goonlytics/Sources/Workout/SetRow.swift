import SharingGRDB
import SwiftUI

@MainActor
@Observable
final class SetRowModel {    
    var exerciseSet: ExerciseSet
    
    init(exerciseSet: ExerciseSet) {
        self.exerciseSet = exerciseSet
    }
    
    func updateWeight(_ weight: Double) {
        exerciseSet.actual.weight = weight
    }
    
    func updateReps(_ reps: Int) {
        exerciseSet.actual.reps = reps
    }
    
    func updateRPE(_ rpe: Double) {
        exerciseSet.actual.rpe = rpe
    }
    
    func toggleSetCompleted() {
        exerciseSet.isCompleted.toggle()
    }
}

struct SetRow: View {
    @Bindable var model: SetRowModel

    var body: some View {
        HStack {
            Text("\(model.exerciseSet.setIndex + 1)")
                .font(.subheadline)
                .frame(width: 30, alignment: .leading)
            
//            TextField("Previous", text: <#Binding<String>#>)
            Text("Previous")
                .frame(width: 100, alignment: .leading)
            
            TextField("Weight", value: Binding(
                get: { model.exerciseSet.actual.weight ?? 0 },
                set: { model.updateWeight($0) }
            ), formatter: NumberFormatter())
                .keyboardType(.decimalPad)
                .frame(width: 50)

            TextField("Reps", value: Binding(
                get: { model.exerciseSet.actual.reps ?? 0 },
                set: { model.updateReps($0) }
            ), formatter: NumberFormatter())
                .keyboardType(.numberPad)
                .frame(width: 50)
            
            TextField("RPE", value: Binding(
                get: { model.exerciseSet.actual.rpe ?? 0 },
                set: { model.updateRPE($0) }
            ), formatter: NumberFormatter())
                .keyboardType(.decimalPad)
                .frame(width: 50)
            Button(action: {
                model.toggleSetCompleted()
            }) {
                Image(systemName: model.exerciseSet.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(model.exerciseSet.isCompleted ? .green : .gray)
            }
        }
        .padding(.vertical, 4)
    }
}

//#Preview {
//    SetRow(model: .init(workout: Shared(value: .mock)))
//}
