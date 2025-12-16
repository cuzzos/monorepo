import SwiftUI
import SharedTypes

struct ExerciseSection: View {
    let exercise: ExerciseViewModel
    @Bindable var core: Core
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Exercise Header
            exerciseHeader
            
            // Column Headers
            columnHeaders
            
            // Sets
            setsList
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(8)
        .shadow(radius: 1)
    }
    
    private var exerciseHeader: some View {
        HStack(spacing: 12) {
            Text(exercise.name)
                .font(.headline)
            
            Spacer()
            
            Button {
                Task { await core.update(.deleteExercise(exercise_id: exercise.id)) }
            } label: {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
            
            Button {
                Task { await core.update(.addSet(exercise_id: exercise.id)) }
            } label: {
                Text("Add Set")
                    .font(.caption)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .cornerRadius(12)
                    .shadow(radius: 1)
            }
            .buttonStyle(.plain)
        }
    }
    
    private var columnHeaders: some View {
        HStack {
            Text("SET")
                .font(.caption)
                .foregroundColor(.gray)
                .frame(width: 30, alignment: .leading)
            
            Text("PREVIOUS")
                .font(.caption)
                .foregroundColor(.gray)
                .frame(width: 100, alignment: .leading)
            
            Text("WEIGHT")
                .font(.caption)
                .foregroundColor(.gray)
                .frame(width: 50, alignment: .leading)
            
            Text("REPS")
                .font(.caption)
                .foregroundColor(.gray)
                .frame(width: 50, alignment: .leading)
            
            Text("RPE")
                .font(.caption)
                .foregroundColor(.gray)
                .frame(width: 50, alignment: .leading)
        }
    }
    
    private var setsList: some View {
        ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { index, set in
            SetRow(set: set, core: core)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        Task { await core.update(.deleteSet(exercise_id: exercise.id, set_index: UInt64(index))) }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
        }
    }
}

