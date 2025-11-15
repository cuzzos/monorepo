import SwiftUI

struct HistoryView: View {
    @ObservedObject var core: RustCore
    
    var body: some View {
        List {
            ForEach(core.viewModel.workouts, id: \.id) { workoutItem in
                Button {
                    core.dispatch(.navigateToHistoryDetail(workoutId: workoutItem.id))
                } label: {
                    VStack(alignment: .leading) {
                        Text(workoutItem.name)
                            .font(.headline)
                        Text(Date(timeIntervalSince1970: TimeInterval(workoutItem.startTimestamp)), style: .date)
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
                    // Show import workout sheet
                } label: {
                    Image(systemName: "square.and.arrow.down")
                        .foregroundColor(.accentColor)
                }
            }
        }
        .onAppear {
            core.dispatch(.loadHistory)
        }
    }
}

#Preview {
    NavigationStack {
        HistoryView(core: RustCoreUniffi())
    }
}
