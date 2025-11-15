import SwiftUI

struct ImportWorkoutView: View {
    @ObservedObject var core: RustCore
    @Environment(\.dismiss) var dismiss
    @State private var workoutText: String = ""
    @State private var isImporting: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    var body: some View {
        NavigationStack {
            VStack {
                TextEditor(text: $workoutText)
                    .padding()
                    .border(Color.gray, width: 1)
                
                Button("Import Workout") {
                    importButtonTapped()
                }
                .disabled(workoutText.isEmpty || isImporting)
                .padding()
            }
            .navigationTitle("Import Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Import Result", isPresented: $showAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    func importButtonTapped() {
        isImporting = true
        core.dispatch(.importWorkout(jsonData: workoutText))
        alertMessage = "Workout imported successfully"
        showAlert = true
        isImporting = false
        dismiss()
    }
}

#Preview {
    ImportWorkoutView(core: RustCoreUniffi())
}
