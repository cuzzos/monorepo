import SharedTypes
import SwiftUI

/// Main content view with tab navigation.
///
/// During Phase 3 development, this includes a Debug tab for testing capabilities.
/// The main Workout and History views will be implemented in later phases.
/// To be replaced with proper WorkoutView in Phase 6
struct ContentView: View {
    @ObservedObject var core: Core
    @State private var selectedTab: Tab = .workout

    enum Tab {
        case workout
        case history
        case debug
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            // Workout Tab - Placeholder
            WorkoutPlaceholderView()
                .tabItem {
                    Label("Workout", systemImage: "figure.run")
                }
                .tag(Tab.workout)
            
            // History Tab - Placeholder
            HistoryPlaceholderView()
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
                .tag(Tab.history)
            
            // Debug Tab - For testing capabilities
            DebugCapabilitiesView(core: core)
                .tabItem {
                    Label("Debug", systemImage: "ladybug")
                }
                .tag(Tab.debug)
        }
    }
}

/// Placeholder for the Workout view (Phase 6)
struct WorkoutPlaceholderView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "figure.run")
                .imageScale(.large)
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
            
            Text("Thiccc")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Workout Tracker")
                .font(.title3)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text("Workout view will be implemented in Phase 6")
            Text("Core is connected and ready")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Implement tab navigation and workout views to continue")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}

/// Placeholder for the History view (Phase 7)
struct HistoryPlaceholderView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.arrow.circlepath")
                .imageScale(.large)
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
            
            Text("History")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Workout History")
                .font(.title3)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text("History view will be implemented in Phase 7")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(core: Core())
    }
}
