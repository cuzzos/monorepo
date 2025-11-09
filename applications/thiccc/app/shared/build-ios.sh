#!/bin/bash
# Build script for Rust iOS libraries
# Run this on your local machine with network access

set -e

echo "Building Rust library for iOS..."

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

# Clean old builds to remove .dylib files
echo "Cleaning old builds..."
cargo clean --target aarch64-apple-ios
cargo clean --target aarch64-apple-ios-sim

# Build for iOS device (arm64)
echo "Building for iOS device (aarch64-apple-ios)..."
cargo build --release --target aarch64-apple-ios

# Build for iOS simulator (arm64 - Apple Silicon Macs)
echo "Building for iOS simulator (aarch64-apple-ios-sim)..."
cargo build --release --target aarch64-apple-ios-sim

# Remove any .dylib files that might have been created (shouldn't exist with staticlib, but clean up anyway)
echo "Removing any .dylib files..."
find target/aarch64-apple-ios/release -name "libshared.dylib" -delete 2>/dev/null || true
find target/aarch64-apple-ios-sim/release -name "libshared.dylib" -delete 2>/dev/null || true
find target/aarch64-apple-ios/release/deps -name "libshared.dylib" -delete 2>/dev/null || true
find target/aarch64-apple-ios-sim/release/deps -name "libshared.dylib" -delete 2>/dev/null || true

# Build for iOS simulator (x86_64 - Intel Macs, optional)
echo "Building for iOS simulator (x86_64-apple-ios-sim)..."
cargo build --release --target x86_64-apple-ios-sim || echo "Note: x86_64 build skipped (not needed on Apple Silicon)"

# Verify builds
echo ""
echo "Build complete! Libraries are at:"
ls -lh target/*/release/libshared.a 2>/dev/null || echo "No libraries found"

echo ""
echo "Next steps:"
echo "1. Open Thiccc.xcodeproj in Xcode"
echo "2. Add libshared.a to 'Link Binary With Libraries'"
echo "3. Add library search paths in Build Settings:"
echo "   - \$(PROJECT_DIR)/../shared/target/aarch64-apple-ios/release"
echo "   - \$(PROJECT_DIR)/../shared/target/aarch64-apple-ios-sim/release"
echo "4. Set 'Objective-C Bridging Header' to: Thiccc/shared-Bridging-Header.h"

