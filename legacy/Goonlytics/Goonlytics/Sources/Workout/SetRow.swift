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
            get: { 
                if let weight = self.exerciseSet.actual.weight, weight > 0 {
                    return String(Int(weight))
                }
                return ""
            },
            set: { newValue in
                if newValue.isEmpty {
                    self.exerciseSet.actual.weight = nil
                } else {
                    self.exerciseSet.actual.weight = Double(newValue)
                }
            }
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
            
            TextField("0", text: model.weightBinding, selection: $model.weightSelection)
            .focused($focus, equals: .weight)
            .keyboardType(.decimalPad)
            .frame(width: 50)
            
            TextField("0", text: Binding(
                get: { 
                    if let reps = model.exerciseSet.actual.reps, reps > 0 {
                        return String(reps)
                    }
                    return ""
                },
                set: { newValue in
                    if newValue.isEmpty {
                        model.exerciseSet.actual.reps = nil
                    } else {
                        model.exerciseSet.actual.reps = Int(newValue)
                    }
                }
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
                    if let reps = model.exerciseSet.actual.reps, reps > 0 {
                        let repsString = String(reps)
                        model.repsSelection = .init(range: repsString.startIndex..<repsString.endIndex)
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

#if DEBUG
#Preview {
    SetRow(model: .init(exerciseSet: Workout.mock.exercises[0].sets[0]))
}
#endif
// todo: on change of textfield, sync with shared model
