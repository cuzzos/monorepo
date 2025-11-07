import SwiftUI

@main
struct ThicccApp: App {
    @StateObject private var core = RustCore()
    
    var body: some Scene {
        WindowGroup {
            AppView(core: core)
        }
    }
}

struct AppView: View {
    @ObservedObject var core: RustCore
    
    var body: some View {
        TabView(selection: Binding(
            get: { core.viewModel.selectedTab },
            set: { tab in
                if tab == .workout {
                    core.dispatch(.navigateToWorkout)
                } else {
                    core.dispatch(.navigateToHistory)
                }
            }
        )) {
            NavigationStack {
                WorkoutView(core: core)
            }
            .tag(Tab.workout)
            .tabItem {
                Label("Workout", systemImage: "figure.run")
            }
            
            NavigationStack {
                HistoryView(core: core)
            }
            .tag(Tab.history)
            .tabItem {
                Label("History", systemImage: "clock")
            }
        }
    }
}

#Preview {
    AppView(core: RustCore())
}
