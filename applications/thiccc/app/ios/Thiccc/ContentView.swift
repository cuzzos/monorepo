import SharedTypes
import SwiftUI

/// Main content view with tab navigation.
///
/// Tab selection is synced with the Rust core state via `core.view.selected_tab`.
/// Changing tabs sends `Event.changeTab` to the Rust core.
/// Debug tab is local-only (not synced with core).
struct ContentView: View {
    @Bindable var core: Core
    @State private var workoutPath = NavigationPath()
    @State private var historyPath = NavigationPath()
    @State private var selectedTab: Tab = .workout

    /// Local tab enum that includes debug (not in SharedTypes)
    enum Tab: Hashable {
        case workout
        case history
        case debug
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            // Workout Tab
            NavigationStack(path: $workoutPath) {
                WorkoutPlaceholderView(core: core)
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

            // Debug Tab - For testing capabilities (temporary)
            NavigationStack {
                DebugCapabilitiesView(core: core)
            }
            .tabItem {
                Label("Debug", systemImage: "ladybug")
            }
            .tag(Tab.debug)
        }
        .onChange(of: selectedTab) { _, newTab in
            // Sync workout/history tabs with core (debug is local-only)
            switch newTab {
            case .workout:
                Task { await core.update(.changeTab(tab: .workout)) }
            case .history:
                Task { await core.update(.changeTab(tab: .history)) }
            case .debug:
                break // Debug tab is local-only, don't sync with core
            }
        }
        .onChange(of: core.view.selected_tab) { _, newCoreTab in
            // Sync from core to local (only if not on debug tab)
            if selectedTab != .debug {
                switch newCoreTab {
                case .workout:
                    selectedTab = .workout
                case .history:
                    selectedTab = .history
                }
            }
        }
    }
}

/// Placeholder for the Workout view (Phase 6)
struct WorkoutPlaceholderView: View {
    @Bindable var core: Core

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "figure.run")
                .imageScale(.large)
                .font(.system(size: 60))
                .foregroundStyle(Color.accentColor)

            Text("Thiccc")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Workout Tracker")
                .font(.title3)
                .foregroundStyle(.secondary)

            Spacer()

            Text("Workout view will be implemented in Phase 6")
            Text("Core is connected and ready")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("Tab selection syncs with Rust core")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
        .navigationTitle("Workout")
        .sheet(isPresented: Binding(
            get: { core.view.workout_view.showing_add_exercise },
            set: { if !$0 { Task { await core.update(.dismissAddExerciseView) } } }
        )) {
            AddExercisePlaceholderView(core: core)
        }
        .sheet(isPresented: Binding(
            get: { core.view.workout_view.showing_import },
            set: { if !$0 { Task { await core.update(.dismissImportView) } } }
        )) {
            ImportPlaceholderView(core: core)
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

/// Placeholder for Add Exercise sheet (Phase 6)
struct AddExercisePlaceholderView: View {
    @Bindable var core: Core
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Add Exercise")
                    .font(.title)
                Text("To be implemented in Phase 6")
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Add Exercise")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        Task { await core.update(.dismissAddExerciseView) }
                    }
                }
            }
        }
    }
}

/// Placeholder for Import sheet (Phase 6)
struct ImportPlaceholderView: View {
    @Bindable var core: Core
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Import")
                    .font(.title)
                Text("To be implemented in Phase 6")
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Import")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        Task { await core.update(.dismissImportView) }
                    }
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var core = Core()
    ContentView(core: core)
}
