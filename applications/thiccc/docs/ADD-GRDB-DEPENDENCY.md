# Adding GRDB Dependency to Thiccc

## Option 1: Via Xcode (Recommended - 2 minutes)

1. **Open project in Xcode:**
   ```bash
   cd /Users/eganm/personal/cuzzo_monorepo/applications/thiccc
   open app/ios/Thiccc.xcodeproj
   ```

2. **Add Swift Package:**
   - In Xcode, select the project "Thiccc" in the navigator
   - Select the "Thiccc" target
   - Go to "General" tab
   - Scroll to "Frameworks, Libraries, and Embedded Content"
   - Click the "+" button
   - Choose "Add Package Dependency..."
   
3. **Enter GRDB URL:**
   ```
   https://github.com/groue/GRDB.swift.git
   ```

4. **Select Version:**
   - Dependency Rule: "Up to Next Major Version"
   - Version: `6.0.0`
   - Click "Add Package"

5. **Add to Target:**
   - Check "Thiccc" target
   - Click "Add Package"

6. **Verify:**
   - You should see "GRDB" listed under "Package Dependencies"
   - Build the project: ⌘B

## Option 2: Manual (If Xcode GUI Unavailable)

Add this to `project.pbxproj` in the `packageReferences` section:

```
XCRemoteSwiftPackageReference "GRDB" = {
    isa = XCRemoteSwiftPackageReference;
    repositoryURL = "https://github.com/groue/GRDB.swift.git";
    requirement = {
        kind = upToNextMajorVersion;
        minimumVersion = 6.0.0;
    };
};
```

Then add to `packageProductDependencies`:

```
XCSwiftPackageProductDependency "GRDB" = {
    isa = XCSwiftPackageProductDependency;
    package = [XCRemoteSwiftPackageReference "GRDB"];
    productName = GRDB;
};
```

## Verification

After adding, verify GRDB is available:

```bash
cd /Users/eganm/personal/cuzzo_monorepo/applications/thiccc
make build
```

Should compile without errors about missing GRDB module.

## Next Steps

Once GRDB is added, proceed with Phase 9 implementation:
1. ✅ GRDB added
2. Create Schema.swift
3. Create DatabaseManager.swift
4. Update DatabaseCapability.swift


