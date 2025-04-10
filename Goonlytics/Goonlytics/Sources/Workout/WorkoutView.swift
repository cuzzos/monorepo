import SwiftUI

// MARK: - Views
struct WorkoutView: View {
    @ObservedObject var viewModel: WorkoutViewModel
    @State private var showingImportSheet = false
    let appName = "Swolytics"
    
    init(viewModel: WorkoutViewModel = WorkoutViewModel()) {
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
                    viewModel.addExercise()
                } label: {
                    Text("+ Add Exercise")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
        }
        .keyboardAware() // Add keyboard awareness
        .sheet(isPresented: $showingImportSheet) {
            ImportWorkoutView(model: ImportWorkoutModel())
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
                ForEach(viewModel.exercises, id: \.id) { exercise in
                    exerciseSection(for: exercise)
                        .id(exercise.id) // Add explicit ID to help with view recycling
                }
                
                Spacer().frame(height: 80) // Bottom spacing for "Add Exercise" button
            }
            .padding(.top)
        }
        .simultaneousGesture(DragGesture().onChanged { _ in
            // Dismiss keyboard when scrolling
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        })
    }
    
    private func exerciseSection(for exercise: Exercise) -> some View {
        Section {
            VStack(spacing: 0) {
                // Exercise Header with Superset Indicator
                HStack {
                    if exercise.isPartOfSuperset {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundColor(.orange)
                            .padding(.leading, 8)
                    }
                    
                    Text(exercise.exerciseName)
                        .font(.title3)
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Button {
                        // Handle link
                    } label: {
                        Image(systemName: "link")
                            .padding(8)
                    }
                    
                    Button {
                        // Handle more actions
                    } label: {
                        Image(systemName: "ellipsis")
                            .padding(8)
                    }
                    .padding(.trailing, 4)
                }
                
                // Set Headers
                HStack(spacing: 8) {
                    Text("Set")
                        .font(.headline)
                        .lineLimit(1)
                        .frame(width: 40, alignment: .center)
                    
                    Text("Previous")
                        .font(.headline)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    Text(exercise.weightUnit)
                        .font(.headline)
                        .lineLimit(1)
                        .frame(width: 60, alignment: .center)
                    
                    Text("Reps")
                        .font(.headline)
                        .lineLimit(1)
                        .frame(width: 60, alignment: .center)
                    
                    Image(systemName: "checkmark")
                        .font(.headline)
                        .frame(width: 40, alignment: .center)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                // Sets
                ForEach(exercise.sets, id: \.id) { set in
                    SetRowView(set: set, exercise: exercise, viewModel: viewModel)
                        .id(set.id)
                }
                
                // Add Set Button
                Button {
                    viewModel.addSet(to: exercise)
                } label: {
                    Text("+ Add Set")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal)
            .overlay(
                exercise.isPartOfSuperset ?
                    RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.orange.opacity(0.4), lineWidth: 2)
                    : nil
            )
        }
    }
}

// MARK: - Supporting Views
struct SetRowView: View {
    let set: ExerciseSet
    let exercise: Exercise
    @ObservedObject var viewModel: WorkoutViewModel
    
    var body: some View {
        HStack(spacing: 8) {
            // Set Number
            Text("\(exercise.sets.firstIndex(where: { $0.id == set.id })?.advanced(by: 1) ?? 0)")
                .font(.headline)
                .frame(width: 40, alignment: .center)
            
            // Previous
            HStack(spacing: 1) {
                if set.suggestedWeight > 0 && set.suggestedReps > 0 {
                    Text("\(String(format: "%.1f", set.suggestedWeight)) \(exercise.weightUnit) × \(set.suggestedReps)")
                        .lineLimit(1)
                } else {
                    Text("—")
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            
            // Weight TextField
            TextField("", value: Binding(
                get: { set.actualWeight ?? 0 },
                set: { newValue in
                    if let index = viewModel.exercises.firstIndex(where: { $0.id == exercise.id }),
                       let setIndex = viewModel.exercises[index].sets.firstIndex(where: { $0.id == set.id }) {
                        viewModel.exercises[index].sets[setIndex].actualWeight = newValue
                    }
                }
            ), format: .number)
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.center)
            .padding(8)
            .background(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
            .frame(width: 60)
            
            // Reps TextField
            TextField("", value: Binding(
                get: { set.actualReps ?? 0 },
                set: { newValue in
                    if let index = viewModel.exercises.firstIndex(where: { $0.id == exercise.id }),
                       let setIndex = viewModel.exercises[index].sets.firstIndex(where: { $0.id == set.id }) {
                        viewModel.exercises[index].sets[setIndex].actualReps = newValue
                    }
                }
            ), format: .number)
            .keyboardType(.numberPad)
            .multilineTextAlignment(.center)
            .padding(8)
            .background(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
            .frame(width: 60)
            
            // Completion Checkmark
            Button {
                if let index = viewModel.exercises.firstIndex(where: { $0.id == exercise.id }),
                   let setIndex = viewModel.exercises[index].sets.firstIndex(where: { $0.id == set.id }) {
                    viewModel.exercises[index].sets[setIndex].isCompleted.toggle()
                }
            } label: {
                ZStack {
                    Circle()
                        .stroke(Color.gray, lineWidth: 1)
                        .frame(width: 24, height: 24)
                    
                    if set.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                    }
                }
            }
            .frame(width: 40, alignment: .center)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

// MARK: - Keyboard Aware Modifier
extension View {
    func keyboardAware() -> some View {
        self.modifier(KeyboardAwareModifier())
    }
}

struct KeyboardAwareModifier: ViewModifier {
    @State private var keyboardHeight: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .padding(.bottom, keyboardHeight)
            .onAppear {
                NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
                    let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect ?? .zero
                    self.keyboardHeight = keyboardFrame.height
                }
                
                NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
                    self.keyboardHeight = 0
                }
            }
    }
}

// MARK: - Preview
#Preview {
    // Create a ViewModel that will load from the file
    let viewModel = WorkoutViewModel()
    
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
