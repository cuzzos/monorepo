import SwiftUI

/// Detail view for a historical workout.
///
/// Placeholder view to be fully implemented in Phase 7.
struct HistoryDetailView: View {
    @Bindable var core: Core
    let workoutId: String

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("History Detail")
                    .font(.largeTitle.bold())

                Text("Workout ID: \(workoutId)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("To be implemented in Phase 7")
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationTitle("Workout Detail")
    }
}
