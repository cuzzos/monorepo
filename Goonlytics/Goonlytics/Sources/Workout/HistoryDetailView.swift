import SwiftUI
import SwiftNavigation

@MainActor
@Observable
final class HistoryDetailModel: HashableObject {
    var workout: Workout
    var destination: Destination?
    
    @CasePathable
    @dynamicMemberLookup
    enum Destination: Hashable {
        case exerciseDetail(Exercise)
    }
    
    init(workout: Workout) {
        self.workout = workout
    }
}

struct HistoryDetailView: View {
    @Bindable var model: HistoryDetailModel
    
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
                    Button {
                        model.destination = .exerciseDetail(exercise)
                    } label: {
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
        }
        .navigationTitle(model.workout.name)
        .navigationDestination(for: HistoryDetailModel.Destination.self) { destination in
            switch destination {
            case let .exerciseDetail(exercise):
                ExerciseDetailView(exercise: exercise)
            }
        }
    }
}

struct ExerciseDetailView: View {
    let exercise: Exercise
    
    var body: some View {
        List {
            Section("Sets") {
                ForEach(exercise.sets) { set in
                    HStack {
                        Text("Set \(set.number)")
                        Spacer()
                        if let reps = set.reps {
                            Text("\(reps) reps")
                        }
                        if let weight = set.weight {
                            Text("\(weight) kg")
                        }
                    }
                }
            }
        }
        .navigationTitle(exercise.exerciseName)
    }
}

#Preview {
    NavigationStack {
        HistoryDetailView(
            model: HistoryDetailModel(
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
