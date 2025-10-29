//
//  Core.swift
//  Thiccc
//
//  Swift bridge to Rust/Crux core
//

import Foundation
import Combine

/// Events that can be dispatched to the core
/// These match the Event enum in the Rust core
enum Event: Codable {
    case increment
}

/// View model returned from the core for rendering
/// Matches the ViewModel struct in the Rust core
struct ViewModel: Codable, Equatable {
    let count: String
}

/// Mock implementation of the Rust core
/// In production, this would call into the actual Rust FFI
class RustCore: ObservableObject {
    @Published var viewModel: ViewModel
    
    private var count: Int = 0
    
    init() {
        self.viewModel = ViewModel(count: "0")
    }
    
    /// Dispatch an event to the core
    func dispatch(_ event: Event) {
        // Mock implementation that mimics the Rust core logic
        switch event {
        case .increment:
            count += 1
            viewModel = ViewModel(count: String(count))
        }
    }
    
    /// Reset the core state (useful for testing)
    func reset() {
        count = 0
        viewModel = ViewModel(count: "0")
    }
}

// MARK: - Future FFI Integration
/*
 When ready to integrate with actual Rust core:
 
 1. Build Rust as static library:
    cargo build --release --target aarch64-apple-ios
    cargo build --release --target x86_64-apple-ios-sim
 
 2. Add library to Xcode:
    - Add libthiccc.a to project
    - Configure library search paths
    
 3. Create bridging header for C FFI:
    - Use cbindgen to generate C header from Rust
    - Import in bridging header
    
 4. Replace RustCore implementation with FFI calls:
    - Call rust_core_new() in init()
    - Call rust_core_dispatch() in dispatch()
    - Call rust_core_view() to get view model
    - Handle memory management (allocate/free)
 
 Example FFI signatures:
 ```c
 void* rust_core_new(void);
 void rust_core_dispatch(void* core, const char* event_json);
 char* rust_core_view(void* core);
 void rust_core_free(void* core);
 void rust_string_free(char* str);
 ```
*/

