import SwiftUI

struct ContentView: View {
    @StateObject private var core = Core()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Count: \(core.view.count)")
                .font(.largeTitle)
                .padding()
            
            Button(action: {
                core.update(.increment)
            }) {
                Text("Increment")
                    .font(.title2)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}

