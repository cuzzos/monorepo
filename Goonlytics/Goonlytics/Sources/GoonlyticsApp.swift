import SwiftUI
import SwiftNavigation

@main
struct GoonlyticsApp: App {
    let model = AppModel()
    
    var body: some Scene {
        WindowGroup {
            AppView(model: model)
        }
    }
}

@MainActor
@Observable
class AppModel {
    var path: [Path] {
        didSet { bind() }
    }
    var selectedTab: Tab
    var historyModel: HistoryModel
    
    @CasePathable
    @dynamicMemberLookup
    enum Path: Hashable {
        case workoutDetail(WorkoutDetailModel)
        case historyDetail(HistoryDetailModel)
    }
    
    enum Tab {
        case workout
        case history
    }
    
    init(
        path: [Path] = [],
        selectedTab: Tab = .workout,
        historyModel: HistoryModel = HistoryModel()
    ) {
        self.path = path
        self.selectedTab = selectedTab
        self.historyModel = historyModel
        self.bind()
    }
    
    private func bind() {
        for destination in path {
            switch destination {
            case .workoutDetail, .historyDetail:
                break
            }
        }
    }
}

struct AppView: View {
    @Bindable var model: AppModel
    
    var body: some View {
        TabView(selection: $model.selectedTab) {
            NavigationStack(path: $model.path) {
                WorkoutView()
                    .navigationDestination(for: AppModel.Path.self) { path in
                        switch path {
                        case let .workoutDetail(model):
                            WorkoutDetailView(model: model)
                        case let .historyDetail(model):
                            HistoryDetailView(model: model)
                        }
                    }
            }
            .tag(AppModel.Tab.workout)
            .tabItem {
                Label("Workout", systemImage: "figure.run")
            }
            
            NavigationStack(path: $model.path) {
                HistoryView(model: model.historyModel)
                    .navigationDestination(for: AppModel.Path.self) { path in
                        switch path {
                        case let .workoutDetail(model):
                            WorkoutDetailView(model: model)
                        case let .historyDetail(model):
                            HistoryDetailView(model: model)
                        }
                    }
            }
            .tag(AppModel.Tab.history)
            .tabItem {
                Label("History", systemImage: "clock")
            }
        }
    }
}

#Preview {
    AppView(model: AppModel())
} 
