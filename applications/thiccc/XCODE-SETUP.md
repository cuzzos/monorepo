# Xcode Configuration Guide

This guide covers Xcode-specific configuration for integrating the Rust core library.

## Prerequisites

- Rust libraries built (see `BUILD-INSTRUCTIONS.md`)
- Xcode project opened (`Thiccc.xcodeproj`)

## Configuration Steps

### 1. Configure Bridging Header

1. Open `Thiccc.xcodeproj` in Xcode
2. Select the **project** (blue icon at top)
3. Select the **Thiccc** target
4. Go to **Build Settings** tab
5. Search for: `objective-c bridging header`
6. Set value to:
   ```
   Thiccc/shared-Bridging-Header.h
   ```

### 2. Configure Library Linking

**Important**: Use explicit library paths in Other Linker Flags (not Library Search Paths). This is the working solution that avoids linker confusion.

#### Remove Library Search Paths

1. Search for: `library search paths`
2. **Remove all entries** (or leave empty)

#### Configure Other Linker Flags

1. Search for: `other linker flags`
2. Find **"Other Linker Flags"** (under "Linking")
3. **Click the disclosure triangle** to expand per-configuration settings
4. **Remove** `-lshared` if it exists

#### Add Explicit Library Paths

**For Simulator Builds:**

- `Debug-iphonesimulator` (or `Debug`):
  ```
  $(PROJECT_DIR)/../../shared/target/aarch64-apple-ios-sim/release/libshared.a
  ```
- `Release-iphonesimulator` (or `Release`):
  ```
  $(PROJECT_DIR)/../../shared/target/aarch64-apple-ios-sim/release/libshared.a
  ```

**For Device Builds:**

- `Debug-iphoneos`:
  ```
  $(PROJECT_DIR)/../../shared/target/aarch64-apple-ios/release/libshared.a
  ```
- `Release-iphoneos`:
  ```
  $(PROJECT_DIR)/../../shared/target/aarch64-apple-ios/release/libshared.a
  ```

### 3. Verify FFI is Enabled

In `Core.swift`, ensure:
```swift
private let useFFI: Bool = true
```

## Verification

After configuration, your Build Settings should show:

- **Other Linker Flags**:
  - `Debug-iphonesimulator`: `$(PROJECT_DIR)/../../shared/target/aarch64-apple-ios-sim/release/libshared.a`
  - `Release-iphonesimulator`: `$(PROJECT_DIR)/../../shared/target/aarch64-apple-ios-sim/release/libshared.a`
  - `Debug-iphoneos`: `$(PROJECT_DIR)/../../shared/target/aarch64-apple-ios/release/libshared.a`
  - `Release-iphoneos`: `$(PROJECT_DIR)/../../shared/target/aarch64-apple-ios/release/libshared.a`

- **Library Search Paths**: Empty or removed
- **Objective-C Bridging Header**: `Thiccc/shared-Bridging-Header.h`

## Build and Test

1. **Clean Build Folder**: `Cmd+Shift+K`
2. **Build**: `Cmd+B`
3. **Run**: `Cmd+R`

## Troubleshooting

### Linker Error: "library 'shared' not found"

- Verify library files exist at the specified paths
- Check that Other Linker Flags contains the full path to `libshared.a`
- Ensure Library Search Paths is empty

### Linker Error: "building for iOS-simulator, but linking in object file built for iOS"

- Verify per-configuration settings in Other Linker Flags
- Ensure `Debug-iphonesimulator` uses the `-sim` path
- Clean build folder and rebuild

### Can't Find Library Files

- Verify libraries were built: `ls -lh app/shared/target/*/release/libshared.a`
- Check paths use `$(PROJECT_DIR)` (relative to Xcode project)
- Ensure paths point to the correct directory structure

## Alternative: User-Defined Setting

If per-configuration settings are hard to manage:

1. **Build Settings** → Click **`+`** → **Add User-Defined Setting**
2. Name: `RUST_LIB_FILE`
3. Set per-configuration values (same as above)
4. In **Other Linker Flags**, add: `$(RUST_LIB_FILE)`

## Next Steps

- See `SETUP.md` for complete setup guide
- See `XCFRAMEWORK-SETUP.md` for XCFramework approach

