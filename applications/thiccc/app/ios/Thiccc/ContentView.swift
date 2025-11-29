import SharedTypes
import SwiftUI

// Placeholder view - to be replaced with proper WorkoutView in Phase 6
struct ContentView: View {
    @ObservedObject var core: Core

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "figure.run")
                .imageScale(.large)
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
            
            Text("Thiccc")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Workout Tracker")
                .font(.title3)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text("Core is connected and ready")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Implement tab navigation and workout views to continue")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(core: Core())
    }
}
