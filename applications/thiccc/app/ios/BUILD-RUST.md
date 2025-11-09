# Building Rust Core for iOS

This document describes how to build the Rust core for iOS integration.

## Prerequisites

- Rust toolchain installed
- Xcode with iOS SDK
- iOS targets installed: `rustup target add aarch64-apple-ios x86_64-apple-ios-sim`

## Building for iOS

### 1. Build Rust static libraries

```bash
cd applications/thiccc/app/shared

# Build for iOS device (arm64)
cargo build --release --target aarch64-apple-ios

# Build for iOS simulator (x86_64 for Intel Macs, or aarch64-apple-ios-sim for Apple Silicon)
cargo build --release --target x86_64-apple-ios-sim
# OR for Apple Silicon Macs:
cargo build --release --target aarch64-apple-ios-sim
```

### 2. Generate C header (optional, for FFI)

```bash
# Install cbindgen if not already installed
cargo install cbindgen

# Generate header
cd applications/thiccc/app/shared
cbindgen --config cbindgen.toml --crate shared --output shared.h
```

### 3. Add to Xcode Project

1. Open `Thiccc.xcodeproj` in Xcode
2. Add the built libraries:
   - `target/aarch64-apple-ios/release/libshared.a` (for device)
   - `target/x86_64-apple-ios-sim/release/libshared.a` (for simulator)
3. Configure Build Settings:
   - Add library search paths:
     - `$(PROJECT_DIR)/../shared/target/$(CARGO_BUILD_TARGET)/release`
   - Add to "Other Linker Flags":
     - `-lshared`
     - `-lc++`
4. Add Build Phase (Run Script):
   ```bash
   cd "${PROJECT_DIR}/../shared"
   cargo build --release --target aarch64-apple-ios
   cargo build --release --target x86_64-apple-ios-sim
   ```

## Current Status

Currently, the Swift side uses a mock implementation in `Core.swift`. To integrate the actual Rust core:

1. Build the Rust libraries as described above
2. Update `Core.swift` to call Rust FFI functions
3. Link the libraries in Xcode project settings

## Note

The Rust core is complete and functional. The FFI bridge can be implemented when ready to integrate.

