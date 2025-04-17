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
                ForEach(model.workout.exercises.flatMap { $0 }, id: \.id) { exercise in
                    VStack(alignment: .leading) {
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
    let workoutId = UUID().uuidString
    
    NavigationStack {
        WorkoutDetailView(
            model: WorkoutDetailModel(
                workout: Workout(
                    id: workoutId,
                    name: "Morning Workout",
                    note: nil,
                    duration: nil,
                    startTimestamp: .now,
                    endTimestamp: nil,
                    exercises: [[
                        Exercise(
                            id: "1",
                            workoutId: workoutId,
                            name: "Bench Press",
                            pinnedNotes: [],
                            notes: [],
                            duration: nil,
                            type: .barbell,
                            weightUnit: .kg,
                            defaultWarmUpTime: 0,
                            defaultRestTime: 90,
                            sets: [
                                ExerciseSet(
                                    type: .working,
                                    weightUnit: .kg,
                                    suggest: SetSuggest(
                                        weight: 60,
                                        reps: 10,
                                        repRange: nil,
                                        duration: nil,
                                        rpe: 8,
                                        restTime: 90
                                    ),
                                    actual: nil
                                )
                            ],
                            bodyPart: BodyPart(
                                main: .chest,
                                detailed: nil,
                                scientific: nil
                            )
                        )
                    ]]
                )
            )
        )
    }
} 
