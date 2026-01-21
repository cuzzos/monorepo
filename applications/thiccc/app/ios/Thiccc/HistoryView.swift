import SwiftUI
import SharedTypes

struct HistoryView: View {
    @Bindable var core: Core

    var body: some View {
        Group {
            if core.view.history_view.is_loading {
                loadingView
            } else if core.view.history_view.workouts.isEmpty {
                emptyStateView
            } else {
                workoutsList
            }
        }
        .navigationTitle("History")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task { await core.update(.showImportView) }
                } label: {
                Image(systemName: "square.and.arrow.down")
                    .foregroundStyle(Color.accentColor)
                }
            }
        }
        .onAppear {
            Task { await core.update(.loadHistory) }
        }
    }

    private var loadingView: some View {
        VStack {
            ProgressView()
            Text("Loading workouts...")
                .foregroundStyle(.secondary)
                .padding(.top)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("No Workout History")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Complete your first workout to see it here")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private var workoutsList: some View {
        List {
            ForEach(core.view.history_view.workouts, id: \.id) { workout in
                NavigationLink(value: workout.id) {
                    HistoryItemRow(workout: workout)
                }
                .onTapGesture {
                    Task { await core.update(.viewHistoryItem(workout_id: workout.id)) }
                }
            }
        }
        .listStyle(.plain)
    }
}

struct HistoryItemRow: View {
    let workout: SharedTypes.HistoryItemViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(workout.name)
                .font(.headline)

            HStack {
                Text(workout.date)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Label("\(workout.exercise_count) exercises", systemImage: "figure.run")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Label("\(workout.set_count) sets", systemImage: "square.stack.3d.up")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}