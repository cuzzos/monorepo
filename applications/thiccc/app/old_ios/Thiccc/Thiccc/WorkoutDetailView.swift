import SwiftUI

struct WorkoutDetailView: View {
    @ObservedObject var core: RustCore
    let workoutId: UUID
    
    var body: some View {
        Group {
            if let workout = core.viewModel.workouts.first(where: { $0.id == workoutId }) {
                List {
                    Section {
                        HStack {
                            Text("Date")
                            Spacer()
                            Text(Date(timeIntervalSince1970: TimeInterval(workout.startTimestamp)), style: .date)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Section("Exercises") {
                        // Note: Full exercise details would come from selectedWorkout in the model
                        // For now, showing basic info
                        Text("Exercise details will be loaded from database")
                            .foregroundStyle(.secondary)
                    }
                }
                .navigationTitle(workout.name)
            } else {
                Text("Workout not found")
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear {
            core.dispatch(.loadWorkoutDetail(workoutId: workoutId))
        }
    }
}

#Preview {
    NavigationStack {
        WorkoutDetailView(core: RustCore(), workoutId: UUID())
    }
}
