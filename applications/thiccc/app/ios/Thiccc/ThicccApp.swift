import SwiftUI

@main
struct ThicccApp: App {
    @State private var core: Core

    init() {
        // Initialize database SYNCHRONOUSLY before anything else
        do {
            try DatabaseManager.shared.setup()
        } catch {
            print("❌ [ThicccApp] Database initialization failed: \(error)")
            fatalError("Database initialization failed: \(error)")
        }

        // Create Core once at app startup
        self._core = State(initialValue: Core())
    }

    var body: some Scene {
        WindowGroup {
            ContentView(core: core)
        }
    }
}
