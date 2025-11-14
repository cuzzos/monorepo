#!/bin/bash
# Initial setup script for Rust iOS libraries with UniFFI
#
# NOTE: With XcodeGen automatic workflow, you DON'T need to run this manually!
# This is only for initial setup or if you need to rebuild libraries manually.
#
# Normal workflow: Just hit ⌘R in Xcode - it handles everything automatically!

set -e

echo "🔨 Building Rust library for iOS with UniFFI (Initial Setup)..."
echo ""
echo "⚠️  NOTE: If you're using XcodeGen, this runs AUTOMATICALLY in Xcode."
echo "   You only need to run this script for initial setup."
echo ""

# Check if we're in the right directory
if [ ! -f "Cargo.toml" ]; then
    echo "❌ Error: Must run from shared directory"
    exit 1
fi

# Install iOS targets if not already installed
echo "📦 Installing iOS targets..."
rustup target add aarch64-apple-ios || true
rustup target add aarch64-apple-ios-sim || true

# Build for iOS device (arm64)
echo "🏗️  Building for iOS device (aarch64-apple-ios)..."
cargo build --release --target aarch64-apple-ios

# Build for iOS simulator (arm64 - Apple Silicon Macs)
echo "🏗️  Building for iOS simulator (aarch64-apple-ios-sim)..."
cargo build --release --target aarch64-apple-ios-sim

echo ""
echo "✅ Build complete!"
echo ""
echo "📖 Next steps:"
echo "   1. cd ../ios"
echo "   2. xcodegen generate"
echo "   3. open thiccc/Thiccc.xcodeproj"
echo "   4. Hit ⌘R - Xcode will auto-generate bindings from now on!"
echo ""

