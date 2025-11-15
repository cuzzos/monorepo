# Quick Start - 5 Minutes to iOS Build

## Prerequisites

- macOS (required for iOS development)
- Docker Desktop (for devcontainer)

## Setup (One-Time, ~5 minutes)

### ⚠️ REQUIRED FIRST STEP - On Your Mac:

```bash
cd /path/to/thiccc
./setup-mac.sh
```

**This MUST be run before opening Xcode!** It:
- ✅ Installs Mint (Swift tool manager)
- ✅ Installs XcodeGen (project generator)
- ✅ Installs Rust (~700MB - for iOS builds only)
- ✅ Adds iOS targets
- ✅ Builds Rust libraries
- ✅ Generates UniFFI Swift bindings (required for compilation)
- ✅ Generates Xcode project

## Daily Workflow

### 1. Develop Rust (Devcontainer)

```bash
# Open VSCode in devcontainer
code .

# Edit Rust code with rust-analyzer
vim app/shared/src/lib.rs

# Run tests
cargo test

# Check compilation
cargo check
```

### 2. Test on iOS (Mac)

```bash
# On your Mac
open app/ios/thiccc/Thiccc.xcodeproj

# Hit ⌘R - That's it!
# Xcode automatically:
#   - Detects if Rust changed
#   - Rebuilds Rust libraries
#   - Regenerates Swift bindings
#   - Builds iOS app
```

## That's It!

**Workflow:**
1. Code Rust in devcontainer (fast, rust-analyzer)
2. Hit ⌘R in Xcode (automatic iOS build)
3. Done!

## Troubleshooting

### "No such module 'SharedCore'"
First build generates it. Just hit ⌘B in Xcode.

### "Rust not found"
Run `./setup-mac.sh` again.

### "Devcontainer not working"
Reinstall Docker Desktop or see [README.md](./README.md).

## Why This Setup?

- **Devcontainer**: Best Rust development experience (rust-analyzer, cargo test)
- **Rust on Mac**: Required for iOS targets (Apple SDK is macOS-only)
- **Automatic workflow**: No manual build steps after initial setup

**Note:** Rust on Mac is ~700MB, similar to Node.js. It's a build tool, like Xcode itself (40GB).

---

**Questions?**
- More info: [README.md](./README.md)
- How it works: [ARCHITECTURE.md](./app/ios/ARCHITECTURE.md)

