import Foundation
import SharedTypes

// Note: The FFI functions (view, processEvent) are generated as top-level
// functions in generated/shared.swift and are available globally in this module.

@MainActor
class Core: ObservableObject {
    @Published var view: SharedTypes.ViewModel
    
    init() {
        // Get initial view from Rust core via FFI
        // Calls the global view() function from generated/shared.swift
        let viewData = Thiccc.view()
        
        // Convert Data to [UInt8] array for Bincode deserializer
        let viewBytes = Array(viewData)
        
        // Deserialize ViewModel from Bincode bytes
        self.view = try! SharedTypes.ViewModel.bincodeDeserialize(input: viewBytes)
    }
    
    func update(_ event: SharedTypes.Event) {
        // Serialize event to Bincode bytes
        let eventBytes = try! event.bincodeSerialize()
        
        // Convert [UInt8] to Data for FFI call
        let eventData = Data(eventBytes)
        
        // Send event to Rust core and get updated view via FFI
        // Calls the global processEvent() function from generated/shared.swift
        let viewData = Thiccc.processEvent(eventData)
        
        // Convert Data to [UInt8] array for Bincode deserializer
        let viewBytes = Array(viewData)
        
        // Deserialize updated ViewModel
        self.view = try! SharedTypes.ViewModel.bincodeDeserialize(input: viewBytes)
    }
}
