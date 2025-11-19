#!/bin/bash
# Initial setup script for Rust iOS libraries
# After first run, Xcode handles builds automatically!

set -e

# Check directory
if [ ! -f "Cargo.toml" ]; then
    echo "❌ Error: Must run from shared directory"
    exit 1
fi

echo "🔨 Building Rust library for iOS..."
echo ""

# Install iOS targets
echo "📦 Installing iOS targets..."
rustup target add aarch64-apple-ios || true
rustup target add aarch64-apple-ios-sim || true

# Build for iOS device (arm64)
echo "🏗️  Building for iOS device..."
cargo build --release --target aarch64-apple-ios

# Build for iOS simulator (arm64)
echo "🏗️  Building for iOS simulator..."
cargo build --release --target aarch64-apple-ios-sim

echo ""
echo "✅ Build complete!"
echo ""
echo "Next: cd ../ios && xcodegen generate && open thiccc/Thiccc.xcodeproj"
echo "Then hit ⌘R - Xcode rebuilds automatically from now on!"
echo ""
