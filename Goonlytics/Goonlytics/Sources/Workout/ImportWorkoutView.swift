import SwiftUI

struct ImportWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var workoutText: String = ""
    @State private var isImporting: Bool = false
    
    var onImport: (String) -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                TextEditor(text: $workoutText)
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
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Import") {
                        isImporting = true
                        onImport(workoutText)
                        dismiss()
                    }
                    .disabled(workoutText.isEmpty)
                }
            }
        }
    }
}

#Preview {
    ImportWorkoutView(onImport: { _ in })
}
