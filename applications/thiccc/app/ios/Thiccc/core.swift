import Foundation
import Observation
import SharedTypes

// Note: The FFI functions (view, processEvent, handleResponse) are generated as
// top-level functions in generated/shared.swift and are available globally in this module.

/// Core handles the interaction between the SwiftUI shell and the Rust core.
///
/// The Core class:
/// 1. Sends events to the Rust core via `processEvent`
/// 2. Receives and processes effects (requests for platform operations)
/// 3. Routes effects to the appropriate capability handlers
/// 4. Sends responses back to the core via `handleResponse`
/// 5. Publishes the updated ViewModel for SwiftUI views to observe
@Observable
@MainActor
final class Core {
    var view: SharedTypes.ViewModel

    // Capability handlers
    private var databaseCapability: DatabaseCapability?
    private var storageCapability: StorageCapability?
    private var timerCapability: TimerCapability?

    init() {
        // Get initial view from Rust core via FFI
        let viewData = Thiccc.view()
        let viewBytes = Array(viewData)
        self.view = try! SharedTypes.ViewModel.bincodeDeserialize(input: viewBytes)

        // Initialize capabilities
        // Database capability requires DatabaseManager to be set up first (done in ThicccApp.init)
        if let database = DatabaseManager.shared.database {
            self.databaseCapability = DatabaseCapability(core: self, database: database)
            ConsoleLogger.shared.log("DatabaseCapability initialized ✅", emoji: "🗄️")
        } else {
            print("❌ [Core] CRITICAL: Database unavailable - DatabaseCapability disabled")
            self.databaseCapability = nil
            ConsoleLogger.shared.log("CRITICAL: Database unavailable!", emoji: "❌")
        }
        
        self.storageCapability = StorageCapability(core: self)
        self.timerCapability = TimerCapability(core: self)
        
        // Send Initialize event to load any saved workout
        Task {
            await update(.initialize)
        }
    }
    
    /// Send an event to the Rust core and process any resulting effects.
    ///
    /// This is the main entry point for UI interactions. It:
    /// 1. Serializes the event
    /// 2. Sends it to the Rust core
    /// 3. Receives and deserializes effects (requests)
    /// 4. Routes each effect to the appropriate capability handler
    /// 5. Updates the view
    func update(_ event: SharedTypes.Event) async {
        ConsoleLogger.shared.log("Event: \(String(describing: event))", emoji: "🟢")

        // Serialize event to Bincode bytes
        let eventBytes = try! event.bincodeSerialize()
        let eventData = Data(eventBytes)

        // Send event to Rust core and get effects
        let effectsData = Thiccc.processEvent(eventData)
        let effectsBytes = Array(effectsData)

        // Process effects (requests from core)
        await processEffects(effectsBytes)
        // Update the view
        refreshView()
    }
    
    /// Process effects returned from the Rust core.
    ///
    /// Effects are platform operation requests. Each effect has an ID that
    /// must be sent back with the response via `handleResponse`.
    private func processEffects(_ bytes: [UInt8]) async {
        // Deserialize the list of requests
        guard !bytes.isEmpty else { return }
        
        do {
            let requests = try [Request].bincodeDeserialize(input: bytes)
            
            for request in requests {
                await handleRequest(request)
            }
        } catch {
            print("❌ [Core] Failed to deserialize effects: \(error)")
        }
    }
    
    /// Handle a single request (effect) from the Rust core.
    private func handleRequest(_ request: Request) async {
        let requestId = request.id
        
        switch request.effect {
        case .render:
            // Render is handled automatically - just refresh the view
            refreshView()
            
        case .database(let operation):
            ConsoleLogger.shared.log("DB operation: \(String(describing: operation))", emoji: "🗄️")
            if let databaseCapability = databaseCapability {
                await databaseCapability.handle(operation, requestId: requestId)
            } else {
                ConsoleLogger.shared.log("ERROR: DatabaseCapability not initialized!", emoji: "❌")
                let errorResult = SharedTypes.DatabaseResult.error(message: "Database not available")
                await sendDatabaseResponse(requestId: requestId, result: errorResult)
            }
            
        case .storage(let operation):
            if let storageCapability = storageCapability {
                await storageCapability.handle(operation, requestId: requestId)
            }
            
        case .timer(let operation):
            if let timerCapability = timerCapability {
                await timerCapability.handle(operation, requestId: requestId)
            }
        }
    }
    
    /// Send a database response back to the Rust core.
    func sendDatabaseResponse(requestId: UInt32, result: SharedTypes.DatabaseResult) async {
        let bytes = try! result.bincodeSerialize()
        let data = Data(bytes)
        
        let effectsData = Thiccc.handleResponse(requestId, data)
        let effectsBytes = Array(effectsData)
        
        await processEffects(effectsBytes)
        refreshView()
    }
    
    /// Send a storage response back to the Rust core.
    func sendStorageResponse(requestId: UInt32, result: SharedTypes.StorageResult) async {
        let bytes = try! result.bincodeSerialize()
        let data = Data(bytes)
        
        let effectsData = Thiccc.handleResponse(requestId, data)
        let effectsBytes = Array(effectsData)
        
        await processEffects(effectsBytes)
        refreshView()
    }
    
    /// Send a timer response back to the Rust core.
    func sendTimerResponse(requestId: UInt32, output: SharedTypes.TimerOutput) async {
        let bytes = try! output.bincodeSerialize()
        let data = Data(bytes)
        
        let effectsData = Thiccc.handleResponse(requestId, data)
        let effectsBytes = Array(effectsData)
        
        await processEffects(effectsBytes)
        refreshView()
    }

    /// Refresh the view from the Rust core.
    private func refreshView() {
        let viewData = Thiccc.view()
        let viewBytes = Array(viewData)
        self.view = try! SharedTypes.ViewModel.bincodeDeserialize(input: viewBytes)
    }
}
