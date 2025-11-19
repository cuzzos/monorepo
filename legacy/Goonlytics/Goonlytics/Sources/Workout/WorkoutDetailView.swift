import SharingGRDB
import SwiftUI
import SwiftUINavigation

@MainActor
@Observable
final class WorkoutDetailModel: HashableObject {
    var workout: Workout
    
    init(workout: Workout) {
        self.workout = workout
    }
}

struct WorkoutDetailView: View {
    @Bindable var model: WorkoutDetailModel
    
    var body: some View {
        List {
            Section {
                HStack {
                    Text("Date")
                    Spacer()
                    Text(model.workout.startTimestamp, style: .date)
                        .foregroundStyle(.secondary)
                }
            }
            
            Section("Exercises") {
                ForEach(model.workout.exercises, id: \.id) { exercise in
                    HStack {
                        Text(exercise.name)
                            .font(.headline)
                        if !exercise.sets.isEmpty {
                            Text("\(exercise.sets.count) sets")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle(model.workout.name)
    }
}

#Preview {
    let _ = try! prepareDependencies {
        $0.defaultDatabase = try appDatabase()
    }
    
    @Dependency(\.defaultDatabase) var database
    let workout = try! database.read { db in
        try Workout.limit(1).fetchOne(db)!
    }
    
    return NavigationStack {
        WorkoutDetailView(model: .init(workout: workout))
    }
}
