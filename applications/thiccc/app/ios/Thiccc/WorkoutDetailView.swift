import SwiftUI

/// Detail view for a specific workout.
///
/// Placeholder view to be fully implemented in Phase 6.
struct WorkoutDetailView: View {
    @Bindable var core: Core
    let workoutId: String

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Workout Detail")
                    .font(.largeTitle.bold())

                Text("Workout ID: \(workoutId)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("To be implemented in Phase 6")
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationTitle("Workout")
    }
}

#Preview {
    @Previewable @State var core = Core()
    NavigationStack {
        WorkoutDetailView(core: core, workoutId: "preview-123")
    }
}


