import SharingGRDB
import SwiftUI

@MainActor
@Observable
final class SetRowModel {    
    var exerciseSet: ExerciseSet
    var focus: Field?
    var weightSelection: TextSelection?
    var repsSelection: TextSelection?
    var rpeSelection: TextSelection?
    
    var weightBinding: Binding<String> {
        Binding(
            get: { self.exerciseSet.actual.weight?.description ?? "" },
            set: { self.exerciseSet.actual.weight = Double($0) }
        )
    }

    var rpeBinding: Binding<String> {
        Binding(
            get: { self.exerciseSet.actual.rpe?.description ?? "" },
            set: { self.exerciseSet.actual.rpe = Double($0) }
        )
    }
    
    enum Field: Hashable {
        case weight
        case reps
        case rpe
    }
    
    init(exerciseSet: ExerciseSet) {
        self.exerciseSet = exerciseSet
    }
    
    func toggleSetCompleted() {
        exerciseSet.isCompleted.toggle()
    }
}

struct SetRow: View {
    @Bindable var model: SetRowModel
    @FocusState var focus: SetRowModel.Field?

    var body: some View {
        HStack {
            Text("\(model.exerciseSet.setIndex + 1)")
                .font(.subheadline)
                .frame(width: 30, alignment: .leading)
            
//            TextField("Previous", text: <#Binding<String>#>)
            Text("Previous")
                .frame(width: 100, alignment: .leading)
            
            TextField("Weight", text: model.weightBinding, selection: $model.weightSelection)
            .focused($focus, equals: .weight)
            .keyboardType(.decimalPad)
            .frame(width: 50)
            
            TextField("Reps", text: Binding(
                get: { model.exerciseSet.actual.reps?.description ?? "" },
                set: { model.exerciseSet.actual.reps = Int($0) }
            ), selection: $model.repsSelection)
            .focused($focus, equals: .reps)
            .keyboardType(.numberPad)
            .frame(width: 50)
            
            TextField("RPE", text: model.rpeBinding, selection: $model.rpeSelection)
            .focused($focus, equals: .rpe)
            .keyboardType(.decimalPad)
            .frame(width: 50)
            Button(action: {
                model.toggleSetCompleted()
            }) {
                Image(systemName: model.exerciseSet.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(model.exerciseSet.isCompleted ? .green : .gray)
            }
        }
        .bind($model.focus, to: $focus)
        .onChange(of: focus) { _, newFocus in
            if let newFocus {
                switch newFocus {
                case .weight:
                    if !model.weightBinding.wrappedValue.isEmpty {
                        model.weightSelection = .init(range: model.weightBinding.wrappedValue.startIndex..<model.weightBinding.wrappedValue.endIndex)
                    }
                case .reps:
                    if !(model.exerciseSet.actual.reps?.description ?? "").isEmpty {
                        model.repsSelection = .init(range: (model.exerciseSet.actual.reps?.description ?? "").startIndex..<(model.exerciseSet.actual.reps?.description ?? "").endIndex)
                    }
                case .rpe:
                    if !model.rpeBinding.wrappedValue.isEmpty {
                        model.rpeSelection = .init(range: model.rpeBinding.wrappedValue.startIndex..<model.rpeBinding.wrappedValue.endIndex)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

//#Preview {
//    SetRow(model: .init(exerciseSet: Workout.mock.exercises[0].sets[0]))
//}
// todo: on change of textfield, sync with shared model
