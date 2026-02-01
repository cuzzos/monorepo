import SwiftUI

@main
struct ThicccApp: App {
    init() {
        // Initialize database SYNCHRONOUSLY before anything else
        do {
            try DatabaseManager.shared.setup()
        } catch {
            print("❌ [ThicccApp] Database initialization failed: \(error)")
            fatalError("Database initialization failed: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            // Create Core INSIDE the view hierarchy, not as @State
            // This ensures database is set up first
            ContentView(core: Core())
        }
    }
}
