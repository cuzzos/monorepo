import SharingGRDB
import SwiftUI

struct SetRow: View {
    @State var model: WorkoutModel
    var exerciseId: String
    var setIndex: Int

    var body: some View {
        if let exerciseIndex = model.exercises.firstIndex(where: { $0.id.uuidString == exerciseId }),
           model.exercises[exerciseIndex].sets.indices.contains(setIndex) {
            let set = model.exercises[exerciseIndex].sets[setIndex]
            HStack {
                Text("\(setIndex + 1)")
                    .font(.subheadline)
                    .frame(width: 60, alignment: .leading)
                TextField("Reps", value: Binding(
                    get: { set.actual?.reps ?? set.suggest?.reps ?? 0 },
                    set: { model.updateReps(for: exerciseIndex, setIndex: setIndex, reps: $0) }
                ), formatter: NumberFormatter())
                    .keyboardType(.numberPad)
                    .frame(width: 60)
                TextField("RPE", value: Binding(
                    get: { set.actual?.rpe ?? set.suggest?.rpe ?? 0 },
                    set: { model.updateRPE(for: exerciseIndex, setIndex: setIndex, rpe: $0) }
                ), formatter: NumberFormatter())
                    .keyboardType(.decimalPad)
                    .frame(width: 60)
                Button(action: {
                    model.toggleSetCompleted(for: exerciseIndex, setIndex: setIndex)
                }) {
                    Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(set.isCompleted ? .green : .gray)
                }
            }
            .padding(.vertical, 4)
        } else {
            EmptyView()
        }
    }
}

#Preview {
    let _ = try! prepareDependencies {
        $0.defaultDatabase = try appDatabase()
    }
    
    @Dependency(\.defaultDatabase) var database
    let workout = try! database.read { db in
        try Workout.fetchOne(db)!
    }
    
    SetRow(model: .init(workout: workout), exerciseId: workout.exercises[0].id.uuidString, setIndex: 0)
}
