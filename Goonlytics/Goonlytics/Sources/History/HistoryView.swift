import SwiftUI
import SwiftUINavigation
import SharingGRDB
import Dependencies

@MainActor
@Observable
final class HistoryModel: HashableObject {
    var destination: Destination?
    @ObservationIgnored @SharedReader var workoutsData: WorkoutsRequest.Value
    
    @ObservationIgnored @Dependency(\.defaultDatabase) var database
    
    @CasePathable
    @dynamicMemberLookup
    enum Destination {
        case detail(Workout)
        case importWorkout(ImportWorkoutModel)
    }
    
    init() {
        _workoutsData = SharedReader(
            wrappedValue: WorkoutsRequest.Value(),
            .fetch(WorkoutsRequest(), animation: .default)
        )
    }
    
    var workouts: [Workout] {
        return workoutsData.workouts
    }
    
    // MARK: - Workout Fetch Key Request

    struct WorkoutsRequest: FetchKeyRequest {
        struct Value {
            var workouts: [Workout] = []
        }
        
        func fetch(_ db: Database) throws -> Value {
            // Fetch workouts, most recent first
            let workouts = try Workout
                .all()
                .order(Column("start_timestamp").desc)
                .including(all: Workout.exercises.including(all: Exercise.sets))
                .fetchAll(db)
            
            return Value(workouts: workouts)
        }
    }
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
