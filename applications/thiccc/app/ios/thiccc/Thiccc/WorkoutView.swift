import SwiftUI

// MARK: - Views
struct WorkoutView: View {
    @ObservedObject var core: RustCore
    @State private var showingImportSheet = false
    @State private var showingAddExerciseSheet = false
    @State private var showingStopwatch = false
    @State private var showingRestTimer = false
    @State private var restTimerDuration: Int = 60
    @State private var restTimerForExerciseId: String? = nil
    @State private var pendingExercisesToAdd: [GlobalExercise]? = nil
    @State private var timer: Timer?
    
    var body: some View {
        VStack(spacing: 0) {
            // --- Custom Top Bar ---
            HStack {
                Image(systemName: "chevron.down")
                    .font(.title2)
                    .foregroundColor(.white)
                Spacer()
                Text("Log Workout")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Button(action: { showingStopwatch = true }) {
                    Image(systemName: "clock")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                Button(action: { core.dispatch(.finishWorkout) }) {
                    Text("Finish")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .background(Color(.black))
            
            // --- Workout Stats ---
            HStack(spacing: 24) {
                VStack(alignment: .leading) {
                    Text("Duration")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(core.viewModel.formattedTime)
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
                VStack(alignment: .leading) {
                    Text("Volume")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("\(core.viewModel.totalVolume) lbs")
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
                VStack(alignment: .leading) {
                    Text("Sets")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("\(core.viewModel.totalSets)")
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.black))

            // --- Workout Name ---
            Group {
                if let workout = core.viewModel.workout {
                    TextField("Workout Name", text: Binding(
                        get: { workout.name },
                        set: { core.dispatch(.updateWorkoutName(name: $0)) }
                    ))
                    .font(.title)
                    .padding(.horizontal)
                } else {
                    Text("New Workout")
                        .font(.title)
                        .padding(.horizontal)
                        .foregroundColor(.gray)
                }
            }
            
            // --- Exercise List ---
            ScrollView {
                LazyVStack(spacing: 20, pinnedViews: .sectionHeaders) {
                    if let workout = core.viewModel.workout {
                        ForEach(workout.exercises) { exercise in
                            exerciseSection(for: exercise)
                        }
                    } else {
                        Text("No exercises yet")
                            .foregroundColor(.gray)
                            .padding()
                    }
                }
            }
        }
        .background(Color(.systemBackground))
        .safeAreaInset(edge: .bottom) {
            HStack {
                Button {
                    showingImportSheet = true
                } label: {
                    Text("Settings")
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
                Button(action: { core.dispatch(.discardWorkout) }) {
                    Text("Discard Workout")
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
        }
        .sheet(isPresented: $showingImportSheet) {
            ImportWorkoutView(core: core)
        }
        .sheet(isPresented: $showingAddExerciseSheet) {
            AddExerciseView { selectedExercises in
                pendingExercisesToAdd = selectedExercises
            }
        }
        .onChange(of: pendingExercisesToAdd) { _, newExercises in
            guard let exercises = newExercises else { return }
            for exercise in exercises {
                core.dispatch(.addExercise(globalExercise: exercise))
            }
            pendingExercisesToAdd = nil
        }
        .sheet(isPresented: $showingStopwatch) {
            StopwatchModal(isPresented: $showingStopwatch)
        }
        .sheet(isPresented: $showingRestTimer) {
            RestTimerModal(isPresented: $showingRestTimer, duration: restTimerDuration) {
                // Optional: handle completion (e.g., vibrate, show alert)
            }
        }
        .onAppear {
            // Start timer if no workout exists, create one
            if core.viewModel.workout == nil {
                core.dispatch(.createWorkout(name: "New Workout"))
            }
            core.dispatch(.startTimer)
            startTimer()
        }
        .onDisappear {
            stopTimer()
            core.dispatch(.stopTimer)
        }
    }
    
    private func exerciseSection(for exercise: ExerciseViewModel) -> some View {
        return VStack(alignment: .leading, spacing: 8) {
            // Exercise Header
            HStack {
                Text(exercise.name)
                    .font(.headline)
                Spacer()
                Button {
                    core.dispatch(.deleteExercise(exerciseId: exercise.id))
                } label: {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                Button {
                    core.dispatch(.addSet(exerciseId: exercise.id))
                } label: {
                    Text("Add Set")
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color(.blue))
                        .cornerRadius(12)
                        .shadow(radius: 1)
                }
            }
            // --- Exercise Headers ---
            HStack {
                Text("SET")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(width: 30, alignment: .leading)
                Text("PREVIOUS")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(width: 100, alignment: .leading)
                Text("WEIGHT")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(width: 50, alignment: .leading)
                Text("REPS")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(width: 50, alignment: .leading)
                Text("RPE")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(width: 50, alignment: .leading)
            }
            // Sets
            ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { index, exerciseSet in
                SetRow(
                    set: exerciseSet,
                    onUpdate: { actual in
                        core.dispatch(.updateSetActual(exerciseId: exercise.id, setIndex: index, actual: actual))
                    }
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(8)
        .shadow(radius: 1)
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            core.dispatch(.timerTick)
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
        
    private func startRestTimer(for exerciseId: String, duration: Int = 60) {
        restTimerForExerciseId = exerciseId
        restTimerDuration = duration
        showingRestTimer = true
    }
}

#Preview {
    WorkoutView(core: RustCore())
}
