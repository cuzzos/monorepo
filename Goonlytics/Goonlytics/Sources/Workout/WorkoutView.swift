import SwiftUI
import GRDB

// MARK: - Views
struct WorkoutView: View {
    @State private var model = WorkoutModel()
    @State private var showingImportSheet = false
    @State private var showingAddExerciseSheet = false
    @State private var showingStopwatch = false
    @State private var showingRestTimer = false
    @State private var restTimerDuration: Int = 60
    @State private var restTimerForExerciseId: String? = nil
    @State private var timer: Timer? = nil
    @State private var startTime: Date? = nil
    @State private var pendingExercisesToAdd: [GlobalExercise]? = nil

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
                Button(action: model.finishWorkout) {
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
                    Text("\(model.formatTime())")
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
                VStack(alignment: .leading) {
                    Text("Volume")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("\(model.totalVolume) lbs")
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
                VStack(alignment: .leading) {
                    Text("Sets")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("\(model.totalSets)")
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.black))

            // --- Exercise List ---
            ScrollView {
                LazyVStack(spacing: 20, pinnedViews: .sectionHeaders) {
                    ForEach(model.exercises.indices, id: \ .self) { exerciseIdx in
                        ForEach(model.exercises[exerciseIdx], id: \ .id) { exercise in
                            exerciseSection(for: exercise, exerciseIdx: exerciseIdx)
                                .id(exercise.id)
                        }
                    }
                }
            }
            .ignoresSafeArea(edges: .bottom)
        }
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
//                Button(action: $model.discardWorkout) {
                    Text("Discard Workout")
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding()
//                }
            }
        }
        .sheet(isPresented: $showingImportSheet) {
            ImportWorkoutView(model: ImportWorkoutModel())
        }
        .sheet(isPresented: $showingAddExerciseSheet) {
            AddExercise { selectedExercises in
                pendingExercisesToAdd = selectedExercises
            }
        }
        .onChange(of: pendingExercisesToAdd) { newExercises in
            guard let exercises = newExercises else { return }
            for exercise in exercises {
                model.addExercise(from: exercise)
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
            startTime = Date()
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                model.elapsedTime += 1
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    private func exerciseSection(for exercise: Exercise, exerciseIdx: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Exercise Header
            HStack {
                Text(exercise.name)
                    .font(.headline)
                Spacer()
                Button {
                    model.addSet(to: exercise)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            // --- Exercise Headers ---
            HStack {
                Text("SET")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(width: 40, alignment: .leading)
                Text("PREVIOUS")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(width: 70, alignment: .leading)
                Text("REPS")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(width: 40, alignment: .leading)
                Text("RPE")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(width: 40, alignment: .leading)
                Spacer()
            }
            .padding(.horizontal)
            // Sets
            ForEach(exercise.sets.indices, id: \ .self) { setIdx in
                SetRow(viewModel: model, set: exercise.sets[setIdx], setIndex: setIdx, exerciseIndex: exerciseIdx)
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .padding(.horizontal)
    }

    private func startRestTimer(for exerciseId: String, duration: Int = 60) {
        restTimerForExerciseId = exerciseId
        restTimerDuration = duration
        showingRestTimer = true
    }
}
