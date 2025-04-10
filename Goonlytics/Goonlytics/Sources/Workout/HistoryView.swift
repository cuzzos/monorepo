import SwiftUI
import SwiftNavigation

@Observable
class HistoryModel {
    var workouts: [Workout] = []
    var destination: Destination?
    
    @CasePathable
    @dynamicMemberLookup
    enum Destination: Hashable {
        case detail(Workout)
    }
    
    init(workouts: [Workout] = []) {
        self.workouts = workouts
    }
}

struct HistoryView: View {
    @Bindable var model: HistoryModel
    
    var body: some View {
        List {
            ForEach(model.workouts) { workout in
                Button {
                    model.destination = .detail(workout)
                } label: {
                    VStack(alignment: .leading) {
                        Text(workout.name)
                            .font(.headline)
                        Text(workout.date, style: .date)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("History")
        .navigationDestination(for: HistoryModel.Destination.self) { destination in
            switch destination {
            case let .detail(workout):
                HistoryDetailView(model: HistoryDetailModel(workout: workout))
            }
        }
    }
}

#Preview {
    NavigationStack {
        HistoryView(
            model: HistoryModel(
                workouts: [
                    Workout(name: "Morning Run", date: .now),
                    Workout(name: "Evening Workout", date: .now.addingTimeInterval(-86400))
                ]
            )
        )
    }
} 
