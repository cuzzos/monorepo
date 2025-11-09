# Thiccc iOS App Setup Guide

Complete guide for setting up the Thiccc iOS app with Rust/Crux core integration.

## Overview

This app uses a **Crux architecture** with:
- **Rust core** (`app/shared`) - Business logic and state management
- **SwiftUI** (`app/ios`) - UI layer
- **FFI** - Swift ↔ Rust communication

## Prerequisites

- Rust toolchain installed (`rustup`)
- Xcode with iOS SDK
- macOS with network access (for building Rust libraries)

## Step 1: Build Rust Libraries

Run the build script from your local machine:

```bash
cd /workspaces/Goonlytics/applications/thiccc/app/shared
./build-ios.sh
```

This creates:
- `target/aarch64-apple-ios/release/libshared.a` (for iOS device)
- `target/aarch64-apple-ios-sim/release/libshared.a` (for iOS simulator)

**Note**: The script automatically cleans old builds and removes any `.dylib` files to ensure only static libraries are built.

## Step 2: Configure Xcode Project

### 2.1 Open Project

1. Open `Thiccc.xcodeproj` in Xcode
2. Select the **project** (blue icon at top)
3. Select the **Thiccc** target
4. Go to **Build Settings** tab

### 2.2 Configure Bridging Header

1. Search for: `objective-c bridging header`
2. Set value to:
   ```
   Thiccc/shared-Bridging-Header.h
   ```

### 2.3 Configure Library Linking (Working Solution)

**Important**: Use explicit library paths in Other Linker Flags, not Library Search Paths. This avoids linker confusion between device and simulator builds.

#### Remove Library Search Paths

1. Search for: `library search paths`
2. **Remove all entries** (or leave empty)

#### Configure Other Linker Flags

1. Search for: `other linker flags`
2. Find **"Other Linker Flags"** (under "Linking")
3. **Click the disclosure triangle** to expand per-configuration settings
4. **Remove** `-lshared` if it exists in any configuration

#### Add Explicit Library Paths

**For Simulator Builds:**

1. Find **`Debug-iphonesimulator`** (or `Debug` if building simulator)
   - Click the `+` button if it doesn't exist
   - Double-click the value cell
   - Add this exact path:
   ```
   $(PROJECT_DIR)/../../shared/target/aarch64-apple-ios-sim/release/libshared.a
   ```

2. Find **`Release-iphonesimulator`** (or `Release`)
   - Add the same path:
   ```
   $(PROJECT_DIR)/../../shared/target/aarch64-apple-ios-sim/release/libshared.a
   ```

**For Device Builds:**

1. Find **`Debug-iphoneos`** (or create it)
   - Add:
   ```
   $(PROJECT_DIR)/../../shared/target/aarch64-apple-ios/release/libshared.a
   ```

2. Find **`Release-iphoneos`**
   - Add:
   ```
   $(PROJECT_DIR)/../../shared/target/aarch64-apple-ios/release/libshared.a
   ```

#### Verify Configuration

Your **Other Linker Flags** should look like:

```
Debug-iphonesimulator: $(PROJECT_DIR)/../../shared/target/aarch64-apple-ios-sim/release/libshared.a
Release-iphonesimulator: $(PROJECT_DIR)/../../shared/target/aarch64-apple-ios-sim/release/libshared.a
Debug-iphoneos: $(PROJECT_DIR)/../../shared/target/aarch64-apple-ios/release/libshared.a
Release-iphoneos: $(PROJECT_DIR)/../../shared/target/aarch64-apple-ios/release/libshared.a
```

**Library Search Paths** should be **empty** or removed.

### 2.4 Verify FFI is Enabled

In `Core.swift`, ensure:
```swift
private let useFFI: Bool = true
```

## Step 3: Build and Run

1. **Clean Build Folder**: `Cmd+Shift+K`
2. **Build**: `Cmd+B`
3. **Run**: `Cmd+R`

## Verification

After building, check the linker command in the build log. It should show:
```
.../target/aarch64-apple-ios-sim/release/libshared.a
```

And **NOT** include:
```
-L.../target/aarch64-apple-ios/release
```

The linker will directly reference the `.a` file instead of searching directories.

## Troubleshooting

### Linker Error: "library 'shared' not found"

- Verify the library files exist at the specified paths
- Check that Other Linker Flags contains the full path to `libshared.a`
- Ensure Library Search Paths is empty

### Linker Error: "building for iOS-simulator, but linking in object file built for iOS"

- This means the wrong library path is being used
- Verify per-configuration settings in Other Linker Flags
- Ensure `Debug-iphonesimulator` uses the `-sim` path
- Clean build folder and rebuild

### Blank Screen on Simulator

- Check that `useFFI = true` in `Core.swift`
- Verify FFI functions are being called (check console logs)
- Ensure `core.dispatch(.createWorkout(...))` is called in `WorkoutView.onAppear`

### Build Fails with Rust Errors

- Ensure Rust toolchain is up to date: `rustup update`
- Check that iOS targets are installed: `rustup target list --installed | grep ios`
- Rebuild Rust libraries: `cd app/shared && ./build-ios.sh`

## Alternative: User-Defined Setting

If per-configuration settings are hard to manage, use a User-Defined Setting:

1. **Build Settings** → Click **`+`** → **Add User-Defined Setting**
2. Name: `RUST_LIB_FILE`
3. Set per-configuration:
   - `Debug-iphonesimulator`: `$(PROJECT_DIR)/../../shared/target/aarch64-apple-ios-sim/release/libshared.a`
   - `Release-iphonesimulator`: `$(PROJECT_DIR)/../../shared/target/aarch64-apple-ios-sim/release/libshared.a`
   - `Debug-iphoneos`: `$(PROJECT_DIR)/../../shared/target/aarch64-apple-ios/release/libshared.a`
   - `Release-iphoneos`: `$(PROJECT_DIR)/../../shared/target/aarch64-apple-ios/release/libshared.a`
4. In **Other Linker Flags**, add: `$(RUST_LIB_FILE)`
5. Remove Library Search Paths and `-lshared`

## Long-Term Solution: XCFramework

For a cleaner, more maintainable setup, consider using an XCFramework. See `XCFRAMEWORK-SETUP.md` for details.

## Project Structure

```
applications/thiccc/
├── app/
│   ├── shared/              # Rust core
│   │   ├── src/
│   │   │   ├── lib.rs       # FFI functions
│   │   │   ├── models.rs    # Data models
│   │   │   └── database.rs  # Database layer
│   │   ├── Cargo.toml
│   │   ├── shared.h         # C header for FFI
│   │   └── build-ios.sh     # Build script
│   └── ios/
│       └── Thiccc/
│           ├── Thiccc/
│           │   ├── Core.swift              # Swift bridge to Rust
│           │   ├── shared-Bridging-Header.h
│           │   └── [SwiftUI views]
│           └── Thiccc.xcodeproj
└── SETUP.md                 # This file
```

## Next Steps

- See `BUILD-INSTRUCTIONS.md` for detailed Rust build instructions
- See `XCFRAMEWORK-SETUP.md` for XCFramework approach
- See `app/shared/README.md` for Rust core documentation

