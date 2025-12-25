import SwiftUI

@main
struct ThicccApp: App {
    // CRITICAL: Initialize database BEFORE @State Core is created
    // Otherwise Core.init() runs before database exists and DatabaseCapability won't initialize
    init() {
        // Initialize database on app launch
        do {
            try DatabaseManager.shared.setup()
            print("✅ [ThicccApp] Database initialized successfully")
        } catch {
            print("❌ [ThicccApp] Database initialization failed: \(error)")
            // App can still launch, but database operations will fail
            // StorageCapability provides basic persistence as fallback
        }
    }
    
    // Now Core can access DatabaseManager.shared.database during initialization
    @State private var core = Core()
    
    var body: some Scene {
        WindowGroup {
            ContentView(core: core)
        }
    }
}


