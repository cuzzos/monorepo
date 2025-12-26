import SwiftUI

@main
struct Sharp9App: App {
    @State private var core = Core(deps: .live)
    
    var body: some Scene {
        WindowGroup {
            ContentView(core: core)
                .preferredColorScheme(.dark)
        }
    }
}
