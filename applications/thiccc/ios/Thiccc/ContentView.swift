import SharedTypes
import SwiftUI

/// Main content view with tab navigation.
///
/// Tab selection uses the Rust core as the single source of truth.
/// The debug tab is only shown in DEBUG builds.
struct ContentView: View {
    @Bindable var core: Core
    @State private var workoutPath = NavigationPath()
    @State private var historyPath = NavigationPath()

    var body: some View {
        TabView(selection: Binding(
            get: { core.view.selected_tab },
            set: { newTab in
                Task { await core.update(.changeTab(tab: newTab)) }
            }
        )) {
            // Workout Tab
            NavigationStack(path: $workoutPath) {
                WorkoutView(core: core)
                    .navigationDestination(for: String.self) { workoutId in
                        WorkoutDetailView(core: core, workoutId: workoutId)
                    }
            }
            .tabItem {
                Label("Workout", systemImage: "figure.run")
            }
            .tag(Tab.workout)

            // History Tab
            NavigationStack(path: $historyPath) {
                HistoryPlaceholderView(core: core)
                    .navigationDestination(for: String.self) { workoutId in
                        HistoryDetailView(core: core, workoutId: workoutId)
                    }
            }
            .tabItem {
                Label("History", systemImage: "clock.arrow.circlepath")
            }
            .tag(Tab.history)

            // Debug Tab - Only shown in DEBUG builds
            #if DEBUG
            NavigationStack {
                DebugCapabilitiesView(core: core)
            }
            .tabItem {
                Label("Debug", systemImage: "ladybug")
            }
            .tag(Tab.debug)
            #endif
        }
    }
}


/// Placeholder for the History view (Phase 7)
struct HistoryPlaceholderView: View {
    @Bindable var core: Core

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.arrow.circlepath")
                .imageScale(.large)
                .font(.system(size: 60))
                .foregroundStyle(Color.accentColor)

            Text("History")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Workout History")
                .font(.title3)
                .foregroundStyle(.secondary)

            Spacer()

            Text("History view will be implemented in Phase 7")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
        .navigationTitle("History")
    }
}


