#!/bin/bash
# Build script for Rust iOS libraries with UniFFI
# Run this on your local machine with network access

set -e

echo "Building Rust library for iOS with UniFFI..."

# Check if we're in the right directory
if [ ! -f "Cargo.toml" ]; then
    echo "Error: Must run from shared directory"
    exit 1
fi

# Install iOS targets if not already installed
echo "Installing iOS targets..."
rustup target add aarch64-apple-ios || true
rustup target add aarch64-apple-ios-sim || true
# Also add x86_64 for Intel Macs (optional)
rustup target add x86_64-apple-ios-sim || true

# Clean old builds
echo "Cleaning old builds..."
cargo clean --target aarch64-apple-ios
cargo clean --target aarch64-apple-ios-sim

# Build for iOS device (arm64)
echo "Building for iOS device (aarch64-apple-ios)..."
cargo build --release --target aarch64-apple-ios

# Build for iOS simulator (arm64 - Apple Silicon Macs)
echo "Building for iOS simulator (aarch64-apple-ios-sim)..."
cargo build --release --target aarch64-apple-ios-sim

# Build for iOS simulator (x86_64 - Intel Macs, optional)
echo "Building for iOS simulator (x86_64-apple-ios-sim)..."
cargo build --release --target x86_64-apple-ios-sim || echo "Note: x86_64 build skipped (not needed on Apple Silicon)"

# Generate Swift bindings using uniffi-bindgen
echo ""
echo "Generating Swift bindings with UniFFI..."
cargo run --bin uniffi-bindgen generate \
    --library target/aarch64-apple-ios-sim/release/libshared.a \
    --language swift \
    --out-dir ../ios/thiccc/Thiccc/Generated

echo ""
echo "Build complete!"
echo ""
echo "Generated files:"
echo "  - Swift bindings: ../ios/thiccc/Thiccc/Generated/shared.swift"
echo "  - C header: ../ios/thiccc/Thiccc/Generated/sharedFFI.h"
echo "  - Module map: ../ios/thiccc/Thiccc/Generated/sharedFFI.modulemap"
echo ""
echo "Libraries:"
ls -lh target/*/release/libshared.a 2>/dev/null || echo "No static libraries found"
ls -lh target/*/release/libshared.dylib 2>/dev/null || echo "No dynamic libraries found"
echo ""
echo "Next steps:"
echo "1. Add the Generated folder to your Xcode project"
echo "2. Import SharedCore in your Swift files"
echo "3. Use processEvent() and view() functions from the generated bindings"

