import SwiftUI
import SwiftUINavigation
import SharingGRDB
import Dependencies
import UniformTypeIdentifiers

@MainActor
@Observable
final class HistoryDetailModel: HashableObject {
    @ObservationIgnored @SharedReader var details: Details.Value
    var showingNotes: Bool = false
    var showingExportAlert: Bool = false
    var exportMessage: String = ""
    var exportedFileURL: URL?
    var isShowingShareSheet: Bool = false
    
    init(workout: Workout) {
        _details = SharedReader(
            wrappedValue: Details.Value(workout: workout),
            .fetch(Details(workout: workout), animation: .default)
        )
    }
    
    struct Details: FetchKeyRequest {
        struct Value {
            var exercises: [Exercise] = []
            var workout: Workout
        }
        
        let workout: Workout
        
        func fetch(_ db: Database) throws -> Value {
            try Value(
                exercises: Exercise
                    .filter(Column("workout_id") == workout.id)
                    .fetchAll(db),
                workout: Workout.fetchOne(db, key: workout.id) ?? workout
            )
        }
    }
}

struct HistoryDetailView: View {
    @Bindable var model: HistoryDetailModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                headerSection
                
                // Divider
                Divider()
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                
                // Exercises
                exercisesSection
                
                // Notes
                notesSection(notes: model.details.workout.note ?? "")
            }
            .padding(.bottom, 32)
        }
        .navigationTitle(model.details.workout.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
            }
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(model.details.workout.name)
                .font(.system(size: 24, weight: .bold, design: .default))
                .foregroundColor(.primary)
                .padding(.horizontal)
            
            Text(formattedDate)
                .font(.system(size: 16, weight: .medium, design: .default))
                .foregroundColor(.secondary)
                .padding(.horizontal)
                .padding(.bottom, 8)
        }
        .padding(.top, 16)
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter.string(from: model.details.workout.startTimestamp)
    }
    
    // MARK: - Exercises Section
    
    private var exercisesSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            ForEach(model.details.workout.exercises.compactMap { $0 }, id: \.id) { exercise in
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
                .onAppear {
                    // Log exercise details when card appears
                    print("Displaying exercise: \(exercise.name)")
                    print("Number of sets: \(exercise.sets.count)")
                    for (i, set) in exercise.sets.enumerated() {
                        print("Set \(i+1) details: weight=\(set.suggest.weight ?? 0), reps=\(set.suggest.reps ?? 0)")
                    }
                }
            
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
                        
                        Text(formattedSet(set: set, index: index))
                            .font(.system(size: 16, weight: .regular, design: .default))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if let rpe = set.suggest.rpe {
                            Text("@ \(String(format: "%.1f", Double(rpe)))")
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
    
    private func formattedSet(set: ExerciseSet, index: Int) -> String {
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
            Button {
                model.showingNotes.toggle()
            } label: {
                HStack {
                    Text("Workout Notes")
                        .font(.system(size: 18, weight: .semibold, design: .default))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: model.showingNotes ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.top, 16)
            
            if model.showingNotes {
                Text(notes)
                    .font(.system(size: 16, weight: .regular, design: .default))
                    .foregroundColor(.primary)
                    .padding(.horizontal)
                    .padding(.top, 4)
            }
        }
    }
}

struct ExerciseDetailView: View {
    let exercise: Exercise
    
    var body: some View {
        List {
            Section("Sets") {
                ForEach(Array(exercise.sets.enumerated()), id: \.offset) { index, set in
                    HStack {
                        Text("Set \(index + 1)")
                        Spacer()
                        Text("\(set.suggest.reps ?? 0) reps")
                        if let weight = set.suggest.weight {
                            Text("\(weight) \(set.weightUnit?.rawValue ?? exercise.weightUnit?.rawValue ?? "")")
                        }
                        if let rpe = set.suggest.rpe {
                            Text("RPE: \(rpe)")
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
        }
        .navigationTitle(exercise.name)
    }
}

#Preview {
    let _ = try! prepareDependencies {
        $0.defaultDatabase = try appDatabase()
    }
    
    @Dependency(\.defaultDatabase) var database
    let workout = try! database.read { db in
        try Workout
            .including(all: Workout.exercises.including(all: Exercise.sets))
            .fetchOne(db)!
    }

    
    return NavigationStack {
        HistoryDetailView(model: .init(workout: workout))
    }
}
