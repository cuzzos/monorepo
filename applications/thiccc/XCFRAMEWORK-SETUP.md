# XCFramework Setup Guide

## Overview

XCFramework is Apple's recommended way to distribute binary frameworks that support multiple platforms and architectures. It automatically selects the correct slice based on the build target, eliminating the need for per-configuration library paths.

## Benefits

1. ✅ **Automatic architecture selection** - Xcode picks the right slice
2. ✅ **No manual path management** - One framework, works for all targets
3. ✅ **Proper framework structure** - Follows Apple's best practices
4. ✅ **Easier distribution** - Can be shared or archived
5. ✅ **No .dylib confusion** - Only static libraries in framework

## Building XCFramework

**Note**: This is a future enhancement. Currently, the project uses explicit library paths in Other Linker Flags (see `SETUP.md`). The XCFramework approach can be implemented when needed.

### Manual Build Steps

To create an XCFramework manually:

1. Build static libraries for both targets (see `BUILD-INSTRUCTIONS.md`)
2. Create framework structures for each platform
3. Use `xcodebuild -create-xcframework` to combine them

A build script (`build-xcframework.sh`) can be created to automate this process.

### Step 2: Add XCFramework to Xcode

1. **Remove** `libshared.a` from "Link Binary With Libraries"
2. **Remove** Library Search Paths
3. **Remove** `-lshared` from Other Linker Flags
4. **Add XCFramework**:
   - Right-click project → "Add Files to 'Thiccc'..."
   - Navigate to `applications/thiccc/app/shared/shared.xcframework`
   - Select it and click "Add"
   - Make sure "Copy items if needed" is **unchecked**
   - Make sure "Add to targets: Thiccc" is **checked**

### Step 3: Configure Framework Settings

1. Go to **Build Phases** → **Frameworks, Libraries, and Embedded Content**
2. Find `shared.xcframework`
3. Set **Embed** to **"Do Not Embed"** (it's a static framework, doesn't need embedding)

### Step 4: Update Bridging Header (if needed)

The bridging header should still work, but verify:
- **Build Settings** → **Objective-C Bridging Header**: `Thiccc/shared-Bridging-Header.h`
- The header should import: `#import <shared/shared.h>` (or keep `#import "shared.h"` if using framework search paths)

### Step 5: Clean and Build

1. **Clean Build Folder**: `Cmd+Shift+K`
2. **Delete Derived Data** (optional)
3. **Build**: `Cmd+B`

## XCFramework Structure

The script creates:
```
shared.xcframework/
├── Info.plist
├── ios-arm64/
│   └── shared.framework/
│       ├── shared (static library)
│       └── Headers/
│           ├── shared.h
│           ├── module.modulemap
│           └── Info.plist
└── ios-arm64-simulator/
    └── shared.framework/
        ├── shared (static library)
        └── Headers/
            ├── shared.h
            ├── module.modulemap
            └── Info.plist
```

Xcode will automatically select the correct slice based on the build target.

## When to Use XCFramework

Consider using XCFramework when:
- You need to distribute the library to other projects
- You want to simplify Xcode configuration (no per-configuration paths)
- You're building for multiple platforms (iOS, macOS, etc.)

For now, the explicit library path approach (see `SETUP.md`) works well and is simpler to set up.

## Troubleshooting

### "No such module 'shared'"
- Make sure the XCFramework is added to the target
- Check Framework Search Paths includes the XCFramework location

### "Undefined symbols"
- Verify the XCFramework was built correctly
- Check that both device and simulator slices exist

### Still linking wrong architecture
- Clean build folder and derived data
- Verify XCFramework structure is correct

