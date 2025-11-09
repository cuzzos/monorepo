# Thiccc iOS App

A simple counter iOS application built with Rust/Crux core logic and SwiftUI shell.

**Rust Edition**: 2024 (latest stable)  
**Rust Version**: 1.90.0+

## Architecture

This app follows the Crux architecture pattern:

- **`shared/`**: Rust/Crux core containing all business logic
  - Pure Rust, platform-agnostic
  - Contains app state, events, and update logic
  - Testable in isolation

- **`ios/`**: SwiftUI shell for iOS
  - Thin UI layer
  - Bridges to Rust core for state management
  - Renders UI based on view model from core

## Project Structure

```
app/
├── shared/              # Rust/Crux core
│   ├── Cargo.toml
│   └── src/
│       └── lib.rs       # Core app logic
│
└── ios/                 # iOS shell
    ├── thiccc.xcodeproj
    └── thiccc/
        ├── ThicccApp.swift      # App entry point
        ├── ContentView.swift    # Main UI view
        ├── Core.swift           # Swift bridge to Rust
        ├── Info.plist
        └── Assets.xcassets/
```

## Current Features

- Simple counter that increments when button is tapped
- Clean separation of business logic (Rust) and UI (Swift)

## Building the Project

### Prerequisites

- Rust toolchain (installed in devcontainer)
- macOS with Xcode (for iOS development)
- iOS 15.0+ target

### Building the Rust Core

```bash
cd shared
cargo build
cargo test
```

### Building the iOS App

1. Open `ios/thiccc.xcodeproj` in Xcode
2. Select your target device or simulator
3. Click Run (⌘R)

## Future Enhancements

When you're ready to integrate the full Rust/Crux bridge:

1. **Add FFI layer**: Create C bindings in Rust using `cbindgen`
2. **Build Rust as static library**: Compile for iOS targets (arm64, x86_64)
3. **Update Core.swift**: Replace `RustCore` mock with actual FFI calls
4. **Add build script**: Automate Rust compilation in Xcode build phases

Currently, the Swift `RustCore` class is a simple mock implementation that mimics the Rust logic. This allows you to develop and test the iOS UI independently while the full bridge is being set up.

## Development Workflow

1. **Add features to Rust core first**: Update `shared/src/lib.rs`
2. **Test in Rust**: Use `cargo test`
3. **Update Swift types**: Match `Event` and `ViewModel` in `Core.swift`
4. **Update UI**: Modify `ContentView.swift` as needed

This architecture ensures your business logic is portable and testable, while the UI remains platform-specific and native.

