import Dependencies
import SwiftUINavigation
import SwiftUI
import SharingGRDB

@MainActor
@Observable
final class ImportWorkoutModel: HashableObject, Identifiable {
    @ObservationIgnored
    @Dependency(\.apiClient) private var apiClient
    
    @ObservationIgnored
    @Dependency(\.defaultDatabase) private var database
    
    var workoutText: String = ""
    var isImporting: Bool = false
    var isDismissed = false
    var destination: Destination?
    var exercises: [Exercise] = []
    
    @CasePathable
    enum Destination {
        case alert(AlertState<AlertAction>)
    }
    
    enum AlertAction {
        case done
    }
    
    func importButtonTapped() async {
        isImporting = true
        defer { isImporting = false }
        
        do {
            var workout = try await apiClient.apiRequest(
                route: .currentWorkout(rawText: workoutText),
                as: Workout.self
            )
            
            // Show alert
            destination = .alert(.dataPreparation)
            
            // MARK: - TODO
            // Save workout to database with all exercises and sets
//            try await database.write { db in
//                // Save the workout first
//                try workout.save(db)
//                
//                // Save all exercises and their sets
//                for var exercise in workout.exercises {
//                    try exercise.save(db)
//                    
//                    // Save all sets for this exercise
//                    for (index, var exerciseSet) in exercise.sets.enumerated() {
//                        // Make sure the set references this exercise and has the correct index
//                        exerciseSet.setIndex = index
//                        try exerciseSet.save(db)
//                    }
//                }
//            }
//            
        } catch {
            print("Error:", error)
        }
    }
    
    func alertButtonTapped(_ action: AlertAction?) async {
        switch action {
        case .done:
            isDismissed = true
        case nil:
            break
        }
    }
}

struct ImportWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @State var model: ImportWorkoutModel
    
    var body: some View {
        NavigationView {
            VStack {
                TextEditor(text: $model.workoutText)
                    .font(.body)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Import Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        model.isDismissed = true
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Import") {
                        Task {
                            await model.importButtonTapped()
                        }
                    }
                    .disabled(model.workoutText.isEmpty || model.isImporting)
                }
            }
            .onChange(of: model.isDismissed) {
                dismiss()
            }
            .alert($model.destination.alert) { action in
                await model.alertButtonTapped(action)
            }
        }
    }
}

extension AlertState where Action == ImportWorkoutModel.AlertAction {
    static let dataPreparation = Self {
        TextState("We're preparing your data")
    } actions: {
        ButtonState(action: .done) {
            TextState("Done")
        }
    } message: {
        TextState("You'll be notified once your data is downloaded")
    }
}

#Preview {
    ImportWorkoutView(
        model: withDependencies {
            $0.apiClient = .liveValue
        } operation: {
            ImportWorkoutModel()
        }
    )
}
