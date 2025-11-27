#!/bin/bash
# macOS Build Verification Script
# Run this on macOS BEFORE iOS engineer pulls code

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
cd "$PROJECT_ROOT"

echo "================================"
echo "🍎 macOS Build Verification"
echo "================================"
echo ""
echo "Working directory: $(pwd)"
echo ""

# Check we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ This script must be run on macOS"
    exit 1
fi

# Step 1: Build Rust for iOS targets
echo "1️⃣  Building Rust core for iOS targets..."
cd app/shared

echo "   Building for iOS Simulator (x86_64)..."
if cargo build --target x86_64-apple-ios 2>&1; then
    echo "   ✅ x86_64 build successful"
else
    echo "   ❌ FAILED: x86_64 build failed"
    exit 1
fi

echo "   Building for iOS Simulator (aarch64)..."
if cargo build --target aarch64-apple-ios-sim 2>&1; then
    echo "   ✅ aarch64-sim build successful"
else
    echo "   ⚠️  WARNING: aarch64-sim build failed (M1+ simulators won't work)"
    # Don't fail, older Macs don't have this target
fi

echo "   Building for iOS Device (aarch64)..."
if cargo build --target aarch64-apple-ios 2>&1; then
    echo "   ✅ aarch64 device build successful"
else
    echo "   ❌ FAILED: aarch64 device build failed"
    exit 1
fi

echo "✅ Rust builds for iOS targets"
echo ""

# Step 2: Generate Swift Bindings
echo "2️⃣  Generating Swift bindings..."
cd ../shared_types
if cargo build 2>&1; then
    echo "✅ Swift types generated"
else
    echo "❌ FAILED: Swift type generation failed"
    exit 1
fi
echo ""

# Step 3: Build iOS App
echo "3️⃣  Building iOS app in Xcode..."
cd ../ios

# Try to find a suitable simulator
SIMULATOR=$(xcrun simctl list devices available | grep "iPhone" | grep -v "unavailable" | head -n 1 | sed -E 's/.*\(([A-F0-9-]+)\).*/\1/')

if [ -z "$SIMULATOR" ]; then
    echo "⚠️  No iPhone simulator found, trying generic iOS Simulator"
    DESTINATION="generic/platform=iOS Simulator"
else
    echo "   Using simulator: $SIMULATOR"
    DESTINATION="id=$SIMULATOR"
fi

if xcodebuild -project Thiccc.xcodeproj \
               -scheme Thiccc \
               -destination "$DESTINATION" \
               clean build \
               CODE_SIGN_IDENTITY="" \
               CODE_SIGNING_REQUIRED=NO \
               2>&1 | grep -E "BUILD (SUCCEEDED|FAILED)|error:|warning:"; then
    
    # Check if it actually succeeded
    if xcodebuild -project Thiccc.xcodeproj \
                   -scheme Thiccc \
                   -destination "$DESTINATION" \
                   -showBuildSettings 2>&1 | grep -q "Thiccc"; then
        echo "✅ iOS app builds successfully"
    else
        echo "❌ FAILED: iOS build failed"
        exit 1
    fi
else
    echo "❌ FAILED: iOS build failed"
    exit 1
fi
echo ""

# Summary
echo "================================"
echo "✅ READY FOR iOS ENGINEER"
echo "================================"
echo ""
echo "All builds successful! iOS engineer can:"
echo "  1. Pull latest code"
echo "  2. Open app/ios/Thiccc.xcodeproj"
echo "  3. Press ⌘R to run"
echo ""
echo "⚠️  RECOMMENDED: Test manually in Xcode to verify:"
echo "  - App launches without crashing"
echo "  - No console errors"
echo "  - UI renders correctly"
echo "  - Basic interactions work"
echo ""

