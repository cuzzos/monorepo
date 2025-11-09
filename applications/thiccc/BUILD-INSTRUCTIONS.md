# Building Rust Core for iOS

This guide explains how to build the Rust core library for iOS integration.

## Quick Start

Run the automated build script:

```bash
cd /workspaces/Goonlytics/applications/thiccc/app/shared
./build-ios.sh
```

The script will:
1. Install required iOS targets
2. Clean old builds
3. Build static libraries for device and simulator
4. Remove any `.dylib` files (ensures only static libraries)

## Manual Build Steps

If you prefer to build manually:

### 1. Install iOS Targets

```bash
rustup target add aarch64-apple-ios
rustup target add aarch64-apple-ios-sim  # For Apple Silicon Macs
# OR
rustup target add x86_64-apple-ios-sim   # For Intel Macs
```

### 2. Build Libraries

```bash
cd /workspaces/Goonlytics/applications/thiccc/app/shared

# Build for iOS device (arm64)
cargo build --release --target aarch64-apple-ios

# Build for iOS simulator
cargo build --release --target aarch64-apple-ios-sim  # Apple Silicon
# OR
cargo build --release --target x86_64-apple-ios-sim   # Intel
```

### 3. Verify Builds

```bash
ls -lh target/*/release/libshared.a
```

You should see:
- `target/aarch64-apple-ios/release/libshared.a` (~19MB, for device)
- `target/aarch64-apple-ios-sim/release/libshared.a` (~19MB, for simulator)

## Build Configuration

The `Cargo.toml` is configured to build only static libraries:

```toml
[lib]
crate-type = ["staticlib"]
```

This ensures no `.dylib` files are created, only `.a` files.

## Troubleshooting

### Build Fails: "Error loading target specification"

- Ensure iOS targets are installed: `rustup target list --installed | grep ios`
- Install missing targets: `rustup target add <target-name>`

### Build Fails: Network Errors

- Ensure you have network access
- Check Rust toolchain: `rustup show`
- Update toolchain: `rustup update`

### `.dylib` Files Still Exist

- Run `cargo clean --target <target-name>`
- Manually remove: `rm -f target/*/release/*.dylib`
- Rebuild with the script

### Library Size is Unexpected

- Normal size: ~19MB per library
- If much smaller, the build may have failed silently
- Check build output for errors
- Verify all dependencies compiled successfully

## Next Steps

After building, configure Xcode. See `SETUP.md` for complete setup instructions.
