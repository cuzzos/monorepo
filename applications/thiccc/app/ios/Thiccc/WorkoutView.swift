import SwiftUI
import SharedTypes

struct WorkoutView: View {
    @Bindable var core: Core
    
    var body: some View {
        ZStack {
            if core.view.workout_view.has_active_workout {
                activeWorkoutView
            } else {
                emptyStateView
            }
        }
        .sheet(isPresented: .init(
            get: { core.view.workout_view.showing_add_exercise },
            set: {
                if !$0 {
                    Task { await core.update(.dismissAddExerciseView) }
                }
            }
        )) {
            AddExerciseView(core: core)
        }
        .sheet(isPresented: .init(
            get: { core.view.workout_view.showing_import },
            set: { if !$0 { Task { await core.update(.dismissImportView) } } }
        )) {
            ImportWorkoutView(core: core)
        }
    }
    
    private var activeWorkoutView: some View {
        VStack(spacing: 0) {
            // Custom Top Bar
            topBar
            
            // Workout Stats
            statsBar
            
            // Workout Name
            workoutNameField
            
            // Exercise List
            exerciseList
        }
        .safeAreaInset(edge: .bottom) {
            bottomActionBar
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "figure.run")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Active Workout")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Start a new workout to begin tracking")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Start Workout") {
                print("🔍 DEBUG: WorkoutView - Start Workout button tapped")
                Task {
                    await core.update(.startWorkout)
                    print("🔍 DEBUG: WorkoutView - Start Workout event sent")
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    private var topBar: some View {
        HStack {
            Image(systemName: "chevron.down")
                .font(.title2)
                .foregroundColor(.white)
            
            Spacer()
            
            Text("Log Workout")
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
            
            Button {
                Task { await core.update(.showStopwatch) }
            } label: {
                Image(systemName: "clock")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            
            Button {
                Task { await core.update(.finishWorkout) }
            } label: {
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
        .background(Color.black)
    }
    
    private var statsBar: some View {
        HStack(spacing: 24) {
            StatView(
                title: "Duration",
                value: core.view.workout_view.formatted_duration
            )
            
            StatView(
                title: "Volume",
                value: "\(core.view.workout_view.total_volume) lbs"
            )
            
            StatView(
                title: "Sets",
                value: "\(core.view.workout_view.total_sets)"
            )
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.black)
    }
    
    private var workoutNameField: some View {
        TextField("Workout Name", text: .init(
            get: { core.view.workout_view.workout_name },
            set: { newValue in
                Task { await core.update(.updateWorkoutName(name: newValue)) }
            }
        ))
        .font(.title)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var exerciseList: some View {
        List {
            ForEach(core.view.workout_view.exercises, id: \.id) { exercise in
                ExerciseSection(exercise: exercise, core: core)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
            }
            .onMove { from, to in
                if let fromIndex = from.first {
                    Task { await core.update(.moveExercise(from_index: UInt64(fromIndex), to_index: UInt64(to))) }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
    
    private var bottomActionBar: some View {
        HStack(spacing: 0) {
            Button {
                Task { await core.update(.showImportView) }
            } label: {
                Text("Settings")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.bordered)
            
            Button {
                Task { await core.update(.showAddExerciseView) }
            } label: {
                Text("+ Add Exercise")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.bordered)
            
            Button {
                Task { await core.update(.discardWorkout) }
            } label: {
                Text("Discard Workout")
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.bordered)
        }
        .background(.ultraThinMaterial)
    }
}

struct StatView: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            Text(value)
                .font(.subheadline)
                .foregroundColor(.white)
        }
    }
}

