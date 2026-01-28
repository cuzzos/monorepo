import SwiftUI
import SharedTypes

struct ImportWorkoutView: View {
    @Bindable var core: Core
    @Environment(\.dismiss) private var dismiss
    @State private var jsonText = ""
    @State private var showError = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Paste workout JSON below")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                TextEditor(text: $jsonText)
                    .font(.system(.body, design: .monospaced))
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal)
                
                Button {
                    Task {
                        await core.update(.importWorkout(json_data: jsonText))
                        // Check if there's an error after import
                        if core.view.error_message == nil {
                            // Success - view will be dismissed by the core state change
                        } else {
                            showError = true
                        }
                    }
                } label: {
                    Text("Import Workout")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(jsonText.isEmpty ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(jsonText.isEmpty)
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.vertical)
            .navigationTitle("Import Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        Task { await core.update(.dismissImportView) }
                    }
                }
            }
            .alert("Import Failed", isPresented: $showError) {
                Button("OK") {
                    showError = false
                }
            } message: {
                Text(core.view.error_message ?? "An error occurred while importing the workout")
            }
        }
    }
}

