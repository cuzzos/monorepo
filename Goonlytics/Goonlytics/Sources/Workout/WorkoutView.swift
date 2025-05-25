import SwiftUI
import SharingGRDB

// MARK: - Views
struct WorkoutView: View {
    @State var model: WorkoutModel
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
                    ForEach(Array(model.exercises.enumerated()), id: \.element.id) { i, exercise in
                        exerciseSection(for: i)
                            .id(exercise.id)
                    }
                }
            }
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
            AddExerciseView { selectedExercises in
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
//                model.elapsedTime += 1
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    private func exerciseSection(for exerciseIndex: Int) -> some View {
        let exercise = model.exercises[exerciseIndex]
        
        return VStack(alignment: .leading, spacing: 8) {
            // Exercise Header
            HStack {
                Text(exercise.name)
                    .font(.headline)
                Spacer()
                Button {
                    model.addSet(to: exercise)
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
            ForEach(exercise.sets.indices, id: \.self) { si in
                SetRow(model: .init(exerciseIndex: exerciseIndex, setIndex: si, workout: model.$workout))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(8)
        .shadow(radius: 1)
    }

    private func startRestTimer(for exerciseId: String, duration: Int = 60) {
        restTimerForExerciseId = exerciseId
        restTimerDuration = duration
        showingRestTimer = true
    }
}

extension SharedReaderKey where Self == FileStorageKey<Workout>.Default {
    static var workout: Self {
        @Dependency(\.uuid) var uuid
        return Self[
            .fileStorage(dump(URL.documentsDirectory.appending(component: "current-workout.json"))),
            default: isTesting || ProcessInfo.processInfo.environment["UI_TEST_NAME"] != nil ? .mock : Workout(
                id: uuid(),
                name: "New Workout",
                note: nil,
                duration: nil,
                startTimestamp: .now,
                endTimestamp: nil,
                exercises: []
            )
        ]
    }
}

#Preview {
    WorkoutView(model: .init(workout: Shared(value: .mock)))
}
