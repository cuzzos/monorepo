# Quick Start - 5 Minutes to iOS Build

## Prerequisites

- macOS (required for iOS development)
- Docker Desktop (for local web development)

## Setup (One-Time, ~5 minutes)

### ⚠️ REQUIRED FIRST STEP - On Your Mac:

```bash
cd /path/to/thiccc
build/scripts/setup-mac.sh
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

### 1. Develop Rust

```bash
# Edit Rust code
vim shared/src/lib.rs

# Run tests
cd shared && cargo test

# Check compilation
cargo check
```

### 2. Test on iOS (Mac)

```bash
# On your Mac
open ios/Thiccc.xcodeproj

# Hit ⌘R - That's it!
# Xcode automatically:
#   - Detects if Rust changed
#   - Rebuilds Rust libraries
#   - Regenerates Swift bindings
#   - Builds iOS app
```

### 3. Web Development

```bash
# Start local stack (DB + API + Frontend)
just thiccc web up

# View logs
just thiccc web logs

# Stop stack
just thiccc web down
```

## That's It!

**iOS Workflow:**
1. Edit Rust code in `shared/`
2. Hit ⌘R in Xcode (automatic iOS build)
3. Done!

**Web Workflow:**
1. Run `just thiccc web up`
2. Edit code (hot reload)
3. Done!

## Troubleshooting

### "No such module 'SharedCore'"
First build generates it. Just hit ⌘B in Xcode.

### "Rust not found"
Run `build/scripts/setup-mac.sh` again.

### "Docker not running"
Start Docker Desktop, then retry.

## Why This Setup?

- **Rust on Mac**: Required for iOS targets (Apple SDK is macOS-only)
- **Docker**: Local web development stack
- **Automatic workflow**: No manual build steps after initial setup

**Note:** Rust on Mac is ~700MB, similar to Node.js. It's a build tool, like Xcode itself (40GB).

---

**Questions?**
- Project structure: [STRUCTURE.md](./STRUCTURE.md)
- More info: [README.md](../README.md)
- How it works: [ARCHITECTURE.md](./ARCHITECTURE.md)

