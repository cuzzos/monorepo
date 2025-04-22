import SharingGRDB
import SwiftUI

@MainActor
@Observable
final class SetRowModel {
    var exerciseSet: ExerciseSet
    
    init(exerciseSet: ExerciseSet) {
        self.exerciseSet = exerciseSet
    }
    
    func updateReps(_ reps: Int) {
        exerciseSet.actual?.reps = reps
    }
    
    func updateRPE(_ rpe: Double) {
        exerciseSet.actual?.rpe = rpe
    }
    
    func toggleSetCompleted() {
        
    }
}

struct SetRow: View {
    @State var model: SetRowModel

    var body: some View {
        HStack {
            Text("\(model.exerciseSet.setIndex + 1)")
                .font(.subheadline)
                .frame(width: 60, alignment: .leading)
            TextField("Reps", value: Binding(
                get: { model.exerciseSet.actual?.reps ?? model.exerciseSet.suggest?.reps ?? 0 },
                set: { model.updateReps($0) }
            ), formatter: NumberFormatter())
                .keyboardType(.numberPad)
                .frame(width: 60)
            TextField("RPE", value: Binding(
                get: { model.exerciseSet.actual?.rpe ?? model.exerciseSet.suggest?.rpe ?? 0 },
                set: { model.updateRPE($0) }
            ), formatter: NumberFormatter())
                .keyboardType(.decimalPad)
                .frame(width: 60)
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

#Preview {
    let _ = try! prepareDependencies {
        $0.defaultDatabase = try appDatabase()
    }
    
    @Dependency(\.defaultDatabase) var database
    var workout = try! database.read { db in
        try Workout.fetchOne(db)!
    }
    
    SetRow(model: .init(exerciseSet: ExerciseSet(type: .working, exerciseId: UUID())))
}
