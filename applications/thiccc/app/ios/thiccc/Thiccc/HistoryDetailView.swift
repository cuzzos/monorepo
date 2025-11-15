import SwiftUI

struct HistoryDetailView: View {
    @ObservedObject var core: RustCore
    let workoutId: UUID
    
    // For now, we'll get workout from the core's selectedWorkout
    // In production, this would be loaded from database
    private var workout: Workout? {
        // This would come from core.viewModel or a loaded workout
        // For now, we'll need to pass it or load it
        nil
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if let workout = workout {
                    // Header
                    headerSection(workout: workout)
                    
                    // Divider
                    Divider()
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    
                    // Exercises
                    exercisesSection(workout: workout)
                    
                    // Notes
                    notesSection(notes: workout.note ?? "")
                } else {
                    Text("Loading workout...")
                        .foregroundStyle(.secondary)
                        .padding()
                }
            }
            .padding(.bottom, 32)
        }
        .navigationTitle(workout?.name ?? "Workout")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            core.dispatch(.loadWorkoutDetail(workoutId: workoutId))
        }
    }
    
    // MARK: - Header Section
    
    private func headerSection(workout: Workout) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(workout.name)
                .font(.system(size: 24, weight: .bold, design: .default))
                .foregroundColor(.primary)
                .padding(.horizontal)
            
            Text(formattedDate(workout: workout))
                .font(.system(size: 16, weight: .medium, design: .default))
                .foregroundColor(.secondary)
                .padding(.horizontal)
                .padding(.bottom, 8)
        }
        .padding(.top, 16)
    }
    
    private func formattedDate(workout: Workout) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter.string(from: workout.startTimestamp)
    }
    
    // MARK: - Exercises Section
    
    private func exercisesSection(workout: Workout) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            ForEach(workout.exercises, id: \.id) { exercise in
                exerciseCard(exercise: exercise)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    private func exerciseCard(exercise: Exercise) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Exercise name
            Text(exercise.name)
                .font(.system(size: 18, weight: .semibold, design: .default))
                .foregroundColor(.primary)
            
            // Sets
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(exercise.sets.enumerated()), id: \.offset) { index, set in
                    HStack(alignment: .center) {
                        Text("Set \(index + 1):")
                            .font(.system(size: 16, weight: .medium, design: .default))
                            .foregroundColor(.secondary)
                            .frame(width: 60, alignment: .leading)
                        
                        Spacer()
                            .frame(width: 8)
                        
                        Text(formattedSet(set: set))
                            .font(.system(size: 16, weight: .regular, design: .default))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if let rpe = set.suggest.rpe {
                            Text("@ \(String(format: "%.1f", rpe))")
                                .font(.system(size: 16, weight: .medium, design: .default))
                                .foregroundColor(.orange)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding(.leading, 4)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    private func formattedSet(set: ExerciseSet) -> String {
        var result = ""
        
        // For weighted exercises
        if let weight = set.actual.weight ?? set.suggest.weight {
            let unit = set.weightUnit?.rawValue ?? "lb"
            result += "\(weight) \(unit) × "
        }
        
        // Add reps
        if let reps = set.actual.reps ?? set.suggest.reps {
            result += "\(reps) reps"
        } else {
            result += "0 reps"
        }
        
        return result
    }
    
    // MARK: - Notes Section
    
    private func notesSection(notes: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if !notes.isEmpty {
                Text("Workout Notes")
                    .font(.system(size: 18, weight: .semibold, design: .default))
                    .foregroundColor(.primary)
                    .padding(.horizontal)
                    .padding(.top, 16)
                
                Text(notes)
                    .font(.system(size: 16, weight: .regular, design: .default))
                    .foregroundColor(.primary)
                    .padding(.horizontal)
                    .padding(.top, 4)
            }
        }
    }
}

#Preview {
    NavigationStack {
        HistoryDetailView(core: RustCoreUniffi(), workoutId: UUID())
    }
}
