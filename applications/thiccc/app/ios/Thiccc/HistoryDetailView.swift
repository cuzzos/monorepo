import SwiftUI
import SharedTypes

/// Detail view for a historical workout.
struct HistoryDetailView: View {
    @Bindable var core: Core
    let workoutId: String

    @State private var showingNotes = false

    var detailView: SharedTypes.HistoryDetailViewModel? {
        core.view.history_detail_view
    }

    var body: some View {
        ScrollView {
            if let detail = detailView {
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    headerSection(detail: detail)

                    Divider()
                        .padding(.horizontal)
                        .padding(.vertical, 8)

                    // Exercises
                    exercisesSection(detail: detail)

                    // Notes
                    if let notes = detail.notes, !notes.isEmpty {
                        notesSection(notes: notes)
                    }
                }
                .padding(.bottom, 32)
            } else {
                VStack {
                    ProgressView()
                    Text("Loading workout details...")
                        .foregroundStyle(.secondary)
                        .padding(.top)
                }
                .frame(maxWidth: .infinity, minHeight: 200)
            }
        }
        .navigationTitle(detailView?.workout_name ?? "Workout")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task { await core.update(.viewHistoryItem(workout_id: workoutId)) }
        }
    }

    private func headerSection(detail: SharedTypes.HistoryDetailViewModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(detail.workout_name)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.primary)
                .padding(.horizontal)

            Text(detail.formatted_date)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            if let duration = detail.duration {
                HStack {
                    Label(duration, systemImage: "clock")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
            }
        }
        .padding(.top, 16)
    }

    private func exercisesSection(detail: SharedTypes.HistoryDetailViewModel) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            ForEach(0..<detail.exercises.count, id: \.self) { index in
                exerciseCard(exercise: detail.exercises[Int(index)])
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private func exerciseCard(exercise: SharedTypes.ExerciseDetailViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Exercise name
            Text(exercise.name)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.primary)

            // Sets
            VStack(alignment: .leading, spacing: 8) {
                ForEach(0..<exercise.sets.count, id: \.self) { index in
                    let set = exercise.sets[Int(index)]
                    HStack(alignment: .center) {
                        Text("Set \(set.set_number):")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.secondary)
                            .frame(width: 60, alignment: .leading)

                        Spacer()
                            .frame(width: 8)

                        Text(set.display_text)
                            .font(.system(size: 16, weight: .regular))
                            .foregroundStyle(.primary)

                        Spacer()
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

    private func notesSection(notes: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                showingNotes.toggle()
            } label: {
                HStack {
                    Text("Workout Notes")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.primary)

                    Spacer()

                    Image(systemName: showingNotes ? "chevron.up" : "chevron.down")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.top, 16)

            if showingNotes {
                Text(notes)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(.primary)
                    .padding(.horizontal)
                    .padding(.top, 4)
            }
        }
    }
}
