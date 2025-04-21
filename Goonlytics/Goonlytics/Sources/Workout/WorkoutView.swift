import SwiftUI

// MARK: - Views
struct WorkoutView: View {
    @ObservedObject var viewModel: WorkoutModel
    @State private var showingImportSheet = false
    @State private var showingAddExerciseSheet = false
    
    init(viewModel: WorkoutModel = WorkoutModel()) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Timer and Controls
            timerView
                .padding(.top, 16)
            
            // Exercise List
            exerciseList
                .ignoresSafeArea(edges: .bottom)
        }
        .safeAreaInset(edge: .bottom) {
            HStack {
                Button {
                    showingImportSheet = true
                } label: {
                    Text("Import")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                
                Button {
                    showingAddExerciseSheet = true
                } label: {
                    Text("+ Add Exercise")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
        }
        .sheet(isPresented: $showingImportSheet) {
            ImportWorkoutView(model: ImportWorkoutModel())
        }
        .sheet(isPresented: $showingAddExerciseSheet) {
            AddExercise()
        }
    }
    
    private var timerView: some View {
        HStack(spacing: 32) {
            Button {
                // Handle history action
            } label: {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.title2)
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            Button {
                // Handle apple watch action
            } label: {
                Image(systemName: "applewatch")
                    .font(.title2)
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            Text(viewModel.formatTime())
                .font(.system(size: 32, weight: .medium))
                .monospacedDigit()
                .frame(minWidth: 100)
            
            Button {
                viewModel.finishWorkout()
            } label: {
                Text("Finish")
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(.green)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .fixedSize() // Prevent button label from truncating
        }
        .padding(.horizontal)
        .padding(.bottom, 16)
    }
    
    private var exerciseList: some View {
        ScrollView {
            LazyVStack(spacing: 20, pinnedViews: .sectionHeaders) {
                ForEach(viewModel.exercises, id: \.self) { exerciseGroup in
                    ForEach(exerciseGroup, id: \.id) { exercise in
                        exerciseSection(for: exercise)
                            .id(exercise.id) // Add explicit ID to help with view recycling
                    }
                }
                
                Spacer().frame(height: 80) // Bottom spacing for "Add Exercise" button
            }
        }
    }
    
    private func exerciseSection(for exercise: Exercise) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Exercise Header
            HStack {
                Text(exercise.name)
                    .font(.headline)
                
                Spacer()
                
                Button {
                    viewModel.addSet(to: exercise)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            // Sets
            ForEach(exercise.sets, id: \.self) { set in
                SetRow(set: set, exercise: exercise, viewModel: viewModel)
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .padding(.horizontal)
    }
}

// MARK: - Set Row View
struct SetRow: View {
    let set: ExerciseSet
    let exercise: Exercise
    @ObservedObject var viewModel: WorkoutModel
    
    var body: some View {
        HStack(spacing: 8) {
            Text("\(set.number)")
                .font(.headline)
                .frame(width: 40, alignment: .leading)
            
            HStack(spacing: 1) {
                Text("—")
            }
        }
    }
    
//    var body: some View {
//        HStack(spacing: 8) {
//            // Set Number
//            Text("\(set.number)")
//                .font(.headline)
//                .frame(width: 40, alignment: .center)
//
//            // Previous
//            HStack(spacing: 1) {
//                Text("—")
//            }
//            .frame(maxWidth: .infinity, alignment: .center)
//
//            // Weight TextField
//            TextField("", value: Binding(
//                get: { set.actual?.weight ?? 0 },
//                set: { newValue in
//                    if let index = viewModel.exercises.firstIndex(where: { $0.id == exercise.id }),
//                       let setIndex = viewModel.exercises[index].sets.firstIndex(where: { $0.id == set.id }) {
//                        // Create a new SetActual with the updated weight
//                        let currentActual = viewModel.exercises[index].sets[setIndex].actual
//                        let newActual = SetActual(
//                            weight: newValue,
//                            reps: currentActual?.reps,
//                            duration: currentActual?.duration,
//                            rpe: currentActual?.rpe,
//                            actualRestTime: currentActual?.actualRestTime
//                        )
//                        viewModel.exercises[index].sets[setIndex].actual = newActual
//                    }
//                }
//            ), format: .number)
//            .keyboardType(.decimalPad)
//            .multilineTextAlignment(.center)
//            .padding(8)
//            .background(Color(.systemBackground))
//            .overlay(
//                RoundedRectangle(cornerRadius: 6)
//                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
//            )
//            .frame(width: 60)
//
//            // Reps TextField
//            TextField("", value: Binding(
//                get: { set.actual?.reps ?? 0 },
//                set: { newValue in
//                    if let index = viewModel.exercises.firstIndex(where: { $0.id == exercise.id }),
//                       let setIndex = viewModel.exercises[index].sets.firstIndex(where: { $0.id == set.id }) {
//                        // Create a new SetActual with the updated reps
//                        let currentActual = viewModel.exercises[index].sets[setIndex].actual
//                        let newActual = SetActual(
//                            weight: currentActual?.weight,
//                            reps: newValue,
//                            duration: currentActual?.duration,
//                            rpe: currentActual?.rpe,
//                            actualRestTime: currentActual?.actualRestTime
//                        )
//                        viewModel.exercises[index].sets[setIndex].actual = newActual
//                    }
//                }
//            ), format: .number)
//            .keyboardType(.numberPad)
//            .multilineTextAlignment(.center)
//            .padding(8)
//            .background(Color(.systemBackground))
//            .overlay(
//                RoundedRectangle(cornerRadius: 6)
//                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
//            )
//            .frame(width: 60)
//
//            // Completion Checkmark
//            Button {
//                if let index = viewModel.exercises.firstIndex(where: { $0.id == exercise.id }),
//                   let setIndex = viewModel.exercises[index].sets.firstIndex(where: { $0.id == set.id }) {
//                    viewModel.exercises[index].sets[setIndex].isCompleted.toggle()
//                }
//            } label: {
//                ZStack {
//                    Circle()
//                        .stroke(Color.gray, lineWidth: 1)
//                        .frame(width: 24, height: 24)
//
//                    if set.isCompleted {
//                        Image(systemName: "checkmark")
//                            .font(.system(size: 14, weight: .bold))
//                    }
//                }
//            }
//            .frame(width: 40, alignment: .center)
//        }
//        .padding(.horizontal)
//        .padding(.vertical, 8)
//        .background(Color(.secondarySystemBackground))
//    }
}

// MARK: - Preview
#Preview {
    // Create a ViewModel that will load from the file
    let viewModel = WorkoutModel()
    
    // This would be called when the preview initializes
    return WorkoutView(viewModel: viewModel)
        .navigationTitle("Swolytics")
        .onAppear {
            // Load sample JSON for preview
            Task {
                do {
                    if let url = Bundle.main.url(forResource: "temp", withExtension: "json") {
                        let jsonData = try Data(contentsOf: url)
                        viewModel.importWorkout(from: jsonData)
                    }
                } catch {
                    print("Error loading workout file: \(error)")
                }
            }
        }
}
