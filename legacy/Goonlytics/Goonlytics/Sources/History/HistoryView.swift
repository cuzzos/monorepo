import SwiftUI
import SwiftUINavigation
import SharingGRDB
import Dependencies

@MainActor
@Observable
final class HistoryModel: HashableObject {
    
    var destination: Destination?
    @ObservationIgnored
    @FetchAll(
        Workout
            .order { $0.startTimestamp.desc() }
    )
    var workouts: [Workout]
    
    @ObservationIgnored @Dependency(\.defaultDatabase) var database
    
    @CasePathable
    @dynamicMemberLookup
    enum Destination {
        case detail(Workout)
        case importWorkout(ImportWorkoutModel)
    }
    
    init() {}
}

struct HistoryView: View {
    @Bindable var model: HistoryModel
    
    var body: some View {
        List {
            ForEach(model.workouts, id: \.id) { workout in
                Button {
                    model.destination = .detail(workout)
                } label: {
                    VStack(alignment: .leading) {
                        Text(workout.name)
                            .font(.headline)
                        Text(workout.startTimestamp, style: .date)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("History")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    model.destination = .importWorkout(ImportWorkoutModel())
                } label: {
                    Image(systemName: "square.and.arrow.down")
                        .foregroundColor(.accentColor)
                }
            }
        }
        .sheet(item: $model.destination.importWorkout) { importModel in
            ImportWorkoutView(model: importModel)
        }
        .background {
            EmptyView().navigationDestination(item: $model.destination.detail) { $workout in
                HistoryDetailView(model: HistoryDetailModel(workout: workout))
            }
        }
    }
}

#Preview {
    let _ = try! prepareDependencies {
        $0.defaultDatabase = try appDatabase()
    }
    
    return NavigationStack {
        HistoryView(
            model: HistoryModel()
        )
    }
}
