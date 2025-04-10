import Dependencies
import SwiftNavigation
import SwiftUI

@MainActor
@Observable
final class ImportWorkoutModel: HashableObject {
    @ObservationIgnored
    @Dependency(\.apiClient) private var apiClient
    
    var workoutText: String = ""
    var isImporting: Bool = false
    var isDismissed = false
    
    func importButtonTapped() async {
        isImporting = true
        defer { isImporting = false }
        
        do {
            let workout = try await apiClient.apiRequest(
                route: .currentWorkout(rawText: workoutText),
                as: Workout.self
            )
            print("Workout response:", workout)
            isDismissed = true
        } catch {
            print("Error:", error)
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
        }
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
