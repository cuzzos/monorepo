import SwiftUI

@main
struct ThicccApp: App {
    @State private var core = Core()
    
    var body: some Scene {
        WindowGroup {
            ContentView(core: core)
        }
    }
}


