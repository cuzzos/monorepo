#!/bin/bash
# Build script to create shared.xcframework from Rust static libraries
# Run this on your Mac with Xcode installed

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "Building Rust libraries for iOS..."

# Clean old builds
echo "Cleaning old builds..."
cargo clean --target aarch64-apple-ios
cargo clean --target aarch64-apple-ios-sim

# Build for iOS device
echo "Building for iOS device (aarch64-apple-ios)..."
cargo build --release --target aarch64-apple-ios

# Build for iOS simulator
echo "Building for iOS simulator (aarch64-apple-ios-sim)..."
cargo build --release --target aarch64-apple-ios-sim

# Remove any .dylib files
echo "Removing .dylib files..."
find target/aarch64-apple-ios/release -name "*.dylib" -delete 2>/dev/null || true
find target/aarch64-apple-ios-sim/release -name "*.dylib" -delete 2>/dev/null || true

# Create framework directories
FRAMEWORK_NAME="shared"
FRAMEWORK_DIR="shared.xcframework"

# Clean up old framework
rm -rf "$FRAMEWORK_DIR"

echo "Creating XCFramework..."

# Create device framework
DEVICE_FRAMEWORK="$FRAMEWORK_DIR/ios-arm64/shared.framework"
mkdir -p "$DEVICE_FRAMEWORK/Headers"

# Copy static library for device
cp target/aarch64-apple-ios/release/libshared.a "$DEVICE_FRAMEWORK/shared"

# Copy headers
cp shared.h "$DEVICE_FRAMEWORK/Headers/"

# Create Info.plist for device
cat > "$DEVICE_FRAMEWORK/Headers/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleSupportedPlatforms</key>
    <array>
        <string>iPhoneOS</string>
    </array>
    <key>MinimumOSVersion</key>
    <string>13.0</string>
</dict>
</plist>
EOF

# Create module map
cat > "$DEVICE_FRAMEWORK/Headers/module.modulemap" <<EOF
framework module shared {
    umbrella header "shared.h"
    export *
    module * { export * }
}
EOF

# Create simulator framework
SIM_FRAMEWORK="$FRAMEWORK_DIR/ios-arm64-simulator/shared.framework"
mkdir -p "$SIM_FRAMEWORK/Headers"

# Copy static library for simulator
cp target/aarch64-apple-ios-sim/release/libshared.a "$SIM_FRAMEWORK/shared"

# Copy headers
cp shared.h "$SIM_FRAMEWORK/Headers/"

# Create Info.plist for simulator
cat > "$SIM_FRAMEWORK/Headers/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleSupportedPlatforms</key>
    <array>
        <string>iPhoneSimulator</string>
    </array>
    <key>MinimumOSVersion</key>
    <string>13.0</string>
</dict>
</plist>
EOF

# Create module map for simulator
cat > "$SIM_FRAMEWORK/Headers/module.modulemap" <<EOF
framework module shared {
    umbrella header "shared.h"
    export *
    module * { export * }
}
EOF

# Create XCFramework Info.plist
mkdir -p "$FRAMEWORK_DIR"
cat > "$FRAMEWORK_DIR/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>AvailableLibraries</key>
    <array>
        <dict>
            <key>LibraryIdentifier</key>
            <string>ios-arm64</string>
            <key>LibraryPath</key>
            <string>shared.framework</string>
            <key>SupportedArchitectures</key>
            <array>
                <string>arm64</string>
            </array>
            <key>SupportedPlatform</key>
            <string>ios</string>
        </dict>
        <dict>
            <key>LibraryIdentifier</key>
            <string>ios-arm64-simulator</string>
            <key>LibraryPath</key>
            <string>shared.framework</string>
            <key>SupportedArchitectures</key>
            <array>
                <string>arm64</string>
            </array>
            <key>SupportedPlatform</key>
            <string>ios</string>
            <key>SupportedPlatformVariant</key>
            <string>simulator</string>
        </dict>
    </array>
    <key>CFBundlePackageType</key>
    <string>XFWK</string>
    <key>XCFrameworkFormatVersion</key>
    <string>1.0</string>
</dict>
</plist>
EOF

echo ""
echo "✅ XCFramework created at: $FRAMEWORK_DIR"
echo ""
echo "Next steps:"
echo "1. In Xcode, remove libshared.a from 'Link Binary With Libraries'"
echo "2. Remove Library Search Paths"
echo "3. Remove -lshared from Other Linker Flags"
echo "4. Add shared.xcframework to 'Frameworks, Libraries, and Embedded Content'"
echo "5. Set 'Embed' to 'Do Not Embed' (it's a static framework)"





