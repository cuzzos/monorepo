#!/bin/bash
# One-time setup script for macOS
# Run this on your Mac to set up iOS development

set -e

echo "🍎 Thiccc - macOS Setup"
echo ""

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ Error: This script must run on macOS"
    exit 1
fi

echo "📦 Installing dependencies..."
echo ""

# Check for Homebrew (needed for Mint)
if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo "✅ Homebrew already installed"
fi

# Install Mint (Swift tool manager)
if ! command -v mint &> /dev/null; then
    echo "Installing Mint (Swift tool manager)..."
    brew install mint
else
    echo "✅ Mint already installed ($(mint version))"
fi

# Install XcodeGen via Mint (uses Mintfile for version)
echo "Installing/updating XcodeGen via Mint..."
mint bootstrap
echo "✅ XcodeGen installed (version specified in Mintfile)"

# Check for Rust
if ! command -v rustc &> /dev/null; then
    echo "Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
else
    echo "✅ Rust already installed ($(rustc --version))"
fi

# Add iOS targets
echo ""
echo "📱 Adding iOS targets..."
rustup target add aarch64-apple-ios || true
rustup target add aarch64-apple-ios-sim || true

# Build Rust libraries
echo ""
echo "🔨 Building Rust libraries..."
cd "$(dirname "$0")/app/shared"
./build-ios.sh

# Generate Xcode project
echo ""
echo "🏗️  Generating Xcode project..."
cd ../ios
mint run xcodegen xcodegen generate

echo ""
echo "✅ Setup complete!"
echo ""
echo "📖 Next steps:"
echo "   1. open app/ios/thiccc/Thiccc.xcodeproj"
echo "   2. Select your Team in Signing & Capabilities"
echo "   3. Hit ⌘R to build and run!"
echo ""
echo "💡 Daily workflow:"
echo "   - Edit Rust in devcontainer (or anywhere)"
echo "   - Open Xcode on Mac and hit ⌘R"
echo "   - Xcode automatically rebuilds Rust and regenerates bindings"
echo ""

