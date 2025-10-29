import Foundation
import Combine

// Swift types matching the Rust types
struct ViewModel: Codable, Equatable {
    let count: String
}

enum Event: Codable {
    case increment
}

// The Core class manages the bridge to Rust
class Core: ObservableObject {
    @Published var view: ViewModel
    
    private var rustCore: RustCore
    
    init() {
        self.rustCore = RustCore()
        self.view = rustCore.view()
    }
    
    func update(_ event: Event) {
        rustCore.update(event)
        self.view = rustCore.view()
    }
}

// Bridge to Rust - this is a simplified version
// In production, you'd use FFI to call into the Rust library
class RustCore {
    private var count: Int32 = 0
    
    func view() -> ViewModel {
        return ViewModel(count: String(count))
    }
    
    func update(_ event: Event) {
        switch event {
        case .increment:
            count += 1
        }
    }
}

