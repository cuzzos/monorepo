import SwiftUI

@main
struct ThicccApp: App {
    init() {
        // Initialize database SYNCHRONOUSLY before anything else
        print("🟦 [ThicccApp] init() starting...")
        do {
            try DatabaseManager.shared.setup()
            print("✅ [ThicccApp] Database initialized successfully")
            print("🟦 [ThicccApp] Database is: \(DatabaseManager.shared.database != nil ? "NOT NIL" : "NIL")")
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
