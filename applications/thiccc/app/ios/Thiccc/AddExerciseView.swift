import SwiftUI
import SharedTypes

struct AddExerciseView: View {
    @Bindable var core: Core
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredExercisesByMuscleGroup, id: \.key) { muscleGroup, exercises in
                    Section(header: Text(muscleGroup)) {
                        ForEach(exercises, id: \.name) { exercise in
                            Button {
                                print("🔍 DEBUG: AddExerciseView - Adding exercise: \(exercise.name)")
                                Task {
                                    await core.update(.addExercise(
                                        name: exercise.name,
                                        exercise_type: exercise.type,
                                        muscle_group: exercise.muscleGroup
                                    ))
                                    print("🔍 DEBUG: AddExerciseView - Event sent for: \(exercise.name)")
                                }
                            } label: {
                                HStack {
                                    Text(exercise.name)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Text(exercise.type)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search exercises")
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        Task { await core.update(.dismissAddExerciseView) }
                    }
                }
            }
        }
    }
    
    private var filteredExercisesByMuscleGroup: [(key: String, value: [ExerciseLibraryItem])] {
        let filtered = searchText.isEmpty ? exerciseLibrary : exerciseLibrary.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.muscleGroup.localizedCaseInsensitiveContains(searchText)
        }
        
        let grouped = Dictionary(grouping: filtered, by: { $0.muscleGroup })
        return grouped.sorted { $0.key < $1.key }
    }
}

// Exercise library data structure
struct ExerciseLibraryItem {
    let name: String
    let type: String
    let muscleGroup: String
}

// Hardcoded exercise library for Phase 6
private let exerciseLibrary: [ExerciseLibraryItem] = [
    // Chest
    ExerciseLibraryItem(name: "Barbell Bench Press", type: "Compound", muscleGroup: "Chest"),
    ExerciseLibraryItem(name: "Dumbbell Bench Press", type: "Compound", muscleGroup: "Chest"),
    ExerciseLibraryItem(name: "Incline Barbell Bench Press", type: "Compound", muscleGroup: "Chest"),
    ExerciseLibraryItem(name: "Incline Dumbbell Bench Press", type: "Compound", muscleGroup: "Chest"),
    ExerciseLibraryItem(name: "Decline Barbell Bench Press", type: "Compound", muscleGroup: "Chest"),
    ExerciseLibraryItem(name: "Dumbbell Fly", type: "Isolation", muscleGroup: "Chest"),
    ExerciseLibraryItem(name: "Cable Fly", type: "Isolation", muscleGroup: "Chest"),
    ExerciseLibraryItem(name: "Push-ups", type: "Bodyweight", muscleGroup: "Chest"),
    
    // Back
    ExerciseLibraryItem(name: "Barbell Row", type: "Compound", muscleGroup: "Back"),
    ExerciseLibraryItem(name: "Dumbbell Row", type: "Compound", muscleGroup: "Back"),
    ExerciseLibraryItem(name: "Pull-ups", type: "Bodyweight", muscleGroup: "Back"),
    ExerciseLibraryItem(name: "Chin-ups", type: "Bodyweight", muscleGroup: "Back"),
    ExerciseLibraryItem(name: "Lat Pulldown", type: "Compound", muscleGroup: "Back"),
    ExerciseLibraryItem(name: "Seated Cable Row", type: "Compound", muscleGroup: "Back"),
    ExerciseLibraryItem(name: "T-Bar Row", type: "Compound", muscleGroup: "Back"),
    ExerciseLibraryItem(name: "Deadlift", type: "Compound", muscleGroup: "Back"),
    ExerciseLibraryItem(name: "Romanian Deadlift", type: "Compound", muscleGroup: "Back"),
    
    // Legs
    ExerciseLibraryItem(name: "Barbell Squat", type: "Compound", muscleGroup: "Legs"),
    ExerciseLibraryItem(name: "Front Squat", type: "Compound", muscleGroup: "Legs"),
    ExerciseLibraryItem(name: "Leg Press", type: "Compound", muscleGroup: "Legs"),
    ExerciseLibraryItem(name: "Leg Extension", type: "Isolation", muscleGroup: "Legs"),
    ExerciseLibraryItem(name: "Leg Curl", type: "Isolation", muscleGroup: "Legs"),
    ExerciseLibraryItem(name: "Bulgarian Split Squat", type: "Compound", muscleGroup: "Legs"),
    ExerciseLibraryItem(name: "Lunges", type: "Compound", muscleGroup: "Legs"),
    ExerciseLibraryItem(name: "Calf Raise", type: "Isolation", muscleGroup: "Legs"),
    
    // Shoulders
    ExerciseLibraryItem(name: "Overhead Press", type: "Compound", muscleGroup: "Shoulders"),
    ExerciseLibraryItem(name: "Dumbbell Shoulder Press", type: "Compound", muscleGroup: "Shoulders"),
    ExerciseLibraryItem(name: "Lateral Raise", type: "Isolation", muscleGroup: "Shoulders"),
    ExerciseLibraryItem(name: "Front Raise", type: "Isolation", muscleGroup: "Shoulders"),
    ExerciseLibraryItem(name: "Rear Delt Fly", type: "Isolation", muscleGroup: "Shoulders"),
    ExerciseLibraryItem(name: "Face Pull", type: "Isolation", muscleGroup: "Shoulders"),
    ExerciseLibraryItem(name: "Shrugs", type: "Isolation", muscleGroup: "Shoulders"),
    
    // Arms
    ExerciseLibraryItem(name: "Barbell Curl", type: "Isolation", muscleGroup: "Arms"),
    ExerciseLibraryItem(name: "Dumbbell Curl", type: "Isolation", muscleGroup: "Arms"),
    ExerciseLibraryItem(name: "Hammer Curl", type: "Isolation", muscleGroup: "Arms"),
    ExerciseLibraryItem(name: "Preacher Curl", type: "Isolation", muscleGroup: "Arms"),
    ExerciseLibraryItem(name: "Tricep Pushdown", type: "Isolation", muscleGroup: "Arms"),
    ExerciseLibraryItem(name: "Overhead Tricep Extension", type: "Isolation", muscleGroup: "Arms"),
    ExerciseLibraryItem(name: "Skull Crushers", type: "Isolation", muscleGroup: "Arms"),
    ExerciseLibraryItem(name: "Dips", type: "Compound", muscleGroup: "Arms"),
    
    // Core
    ExerciseLibraryItem(name: "Plank", type: "Isometric", muscleGroup: "Core"),
    ExerciseLibraryItem(name: "Crunches", type: "Isolation", muscleGroup: "Core"),
    ExerciseLibraryItem(name: "Russian Twists", type: "Isolation", muscleGroup: "Core"),
    ExerciseLibraryItem(name: "Leg Raises", type: "Isolation", muscleGroup: "Core"),
    ExerciseLibraryItem(name: "Cable Woodchop", type: "Isolation", muscleGroup: "Core"),
]

