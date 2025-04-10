import SwiftUI
import SwiftNavigation

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
                    Text(model.workout.date, style: .date)
                        .foregroundStyle(.secondary)
                }
            }
            
            Section("Exercises") {
                ForEach(model.workout.exercises) { exercise in
                    VStack(alignment: .leading) {
                        Text(exercise.exerciseName)
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
    NavigationStack {
        WorkoutDetailView(
            model: WorkoutDetailModel(
                workout: Workout(
                    name: "Morning Workout",
                    date: .now,
                    exercises: [
                        Exercise(
                            exerciseId: "1",
                            exerciseName: "Bench Press",
                            sets: [
                                ExerciseSet(
                                    type: "working",
                                    suggestedWeight: 60,
                                    suggestedReps: 10,
                                    suggestedRPE: 8,
                                    actualWeight: 60,
                                    actualReps: 10
                                )
                            ],
                            weightUnit: "kg",
                            warmUpTime: 0,
                            restTime: 90
                        )
                    ]
                )
            )
        )
    }
} 
