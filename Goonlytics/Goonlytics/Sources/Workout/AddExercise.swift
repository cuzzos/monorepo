import SwiftUI
import SwiftUINavigation
import CustomDump

struct GlobalExercise: Identifiable, Hashable {
    let id: UUID
    let name: String
    let type: String
    let additionalFK: String?
    let muscleGroup: String
    let imageName: String
}

struct AddExercise: View {
    @Environment(\.presentationMode) var presentationMode
    var onAdd: (([GlobalExercise]) -> Void)? = nil
    @State private var searchText: String = ""
    @State private var selectedExercises: Set<GlobalExercise> = []
    @State private var allExercises: [GlobalExercise] = []
    @State private var filterEquipment: String? = nil
    @State private var filterMuscle: String? = nil
    @State private var navSelection: GlobalExercise? = nil

    var filteredExercises: [GlobalExercise] {
        allExercises
            .filter { exercise in
                (searchText.isEmpty || exercise.name.localizedCaseInsensitiveContains(searchText)) &&
                (filterEquipment == nil || exercise.type == filterEquipment) &&
                (filterMuscle == nil || exercise.muscleGroup == filterMuscle)
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search exercise", text: $searchText)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding([.horizontal, .top])

                // Filter buttons
                HStack(spacing: 12) {
                    Button(action: { filterEquipment = nil }) {
                        Text("All Equipment")
                            .fontWeight(filterEquipment == nil ? .bold : .regular)
                            .foregroundColor(.white)
                            .padding(.vertical, 7)
                            .padding(.horizontal, 18)
                            .background(Color(.darkGray).opacity(filterEquipment == nil ? 0.8 : 0.4))
                            .cornerRadius(10)
                    }
                    Button(action: { filterMuscle = nil }) {
                        Text("All Muscles")
                            .fontWeight(filterMuscle == nil ? .bold : .regular)
                            .foregroundColor(.white)
                            .padding(.vertical, 7)
                            .padding(.horizontal, 18)
                            .background(Color(.darkGray).opacity(filterMuscle == nil ? 0.8 : 0.4))
                            .cornerRadius(10)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 6)

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("All Exercises")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                            .padding(.top, 2)
                        ForEach(filteredExercises) { exercise in
                            ExerciseRow(
                                exercise: exercise,
                                selected: selectedExercises.contains(exercise),
                                onTap: { toggleSelection(exercise) },
                                onInfo: {
                                    navSelection = exercise
                                    customDump(navSelection)
                                }
                            )
                        }
                    }
                }
                .background(Color.black)
                .padding(.top, 2)

                Spacer(minLength: 0)

                // Add Button
                if !selectedExercises.isEmpty {
                    Button(action: {
                        onAdd?(Array(selectedExercises))
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Add \(selectedExercises.count) exercise\(selectedExercises.count > 1 ? "s" : "")")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                            .padding([.horizontal, .bottom])
                    }
                    .transition(.move(edge: .bottom))
                }
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .navigationBarTitle("Add Exercise", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() },
                trailing: Button("Create Exercise") {
                    // Handle create exercise
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .onAppear(perform: loadExercises)
            .navigationDestination(item: $navSelection) { exercise in
                ExerciseInfoView(exercise: exercise)
            }
        }
        .accentColor(.white)
    }

    func toggleSelection(_ exercise: GlobalExercise) {
        if selectedExercises.contains(exercise) {
            selectedExercises.remove(exercise)
        } else {
            selectedExercises.insert(exercise)
        }
    }

    func loadExercises() {
        // TODO: Load from local DB or static list for now
        allExercises = [
            GlobalExercise(id: UUID(), name: "Squat (Bodyweight)", type: "bodyweight", additionalFK: nil, muscleGroup: "Quadriceps", imageName: "squat_bodyweight"),
            GlobalExercise(id: UUID(), name: "Squat (Barbell)", type: "barbell", additionalFK: nil, muscleGroup: "Quadriceps", imageName: "squat_barbell"),
            GlobalExercise(id: UUID(), name: "Bench Press (Dumbbell)", type: "dumbbell", additionalFK: nil, muscleGroup: "Chest", imageName: "benchpress_dumbbell"),
            GlobalExercise(id: UUID(), name: "Plank", type: "bodyweight", additionalFK: nil, muscleGroup: "Abdominals", imageName: "plank"),
            GlobalExercise(id: UUID(), name: "Hanging Leg Raise", type: "bodyweight", additionalFK: nil, muscleGroup: "Abdominals", imageName: "hanging_leg_raise"),
            GlobalExercise(id: UUID(), name: "Push Up", type: "bodyweight", additionalFK: nil, muscleGroup: "Chest", imageName: "pushup"),
            GlobalExercise(id: UUID(), name: "Pull Up", type: "bodyweight", additionalFK: nil, muscleGroup: "Back", imageName: "pullup")
        ]
    }
}

struct ExerciseRow: View {
    let exercise: GlobalExercise
    let selected: Bool
    let onTap: () -> Void
    let onInfo: () -> Void

    var body: some View {
        ZStack {
            // Make the entire cell tappable
            Color.clear
            Button(action: onTap) {
                HStack(spacing: 14) {
                    Image(exercise.imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(selected ? Color.blue : Color.clear, lineWidth: 3))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(exercise.name)
                            .foregroundColor(.white)
                            .fontWeight(.medium)
                        Text(exercise.muscleGroup)
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                    Spacer()
                    if selected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                            .imageScale(.large)
                    } else {
                        Button(action: onInfo) {
                            Image(systemName: "info.circle")
                                .foregroundColor(.gray)
                                .imageScale(.large)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal)
                .background(selected ? Color(.systemGray5).opacity(0.15) : Color.clear)
            }
            .buttonStyle(PlainButtonStyle())
            .contentShape(Rectangle()) // Ensures the entire cell is tappable
            .onTapGesture(perform: onTap)
        }
    }
}

struct ExerciseInfoView: View {
    let exercise: GlobalExercise

    var body: some View {
        Text("\(exercise)")
    }
}

#Preview {
    AddExercise()
}

#Preview {
    ExerciseInfoView(exercise: .init(id: UUID(), name: "", type: "", additionalFK: "", muscleGroup: "", imageName: ""))
}
