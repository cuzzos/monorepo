# Thiccc Development Setup

## One-Time Setup for AI Agent Development

This guide ensures your Mac is ready for AI agents to develop the Thiccc iOS app.

## Prerequisites

Your Mac needs these tools installed:

### 1. Install Rust

```bash
# Install Rust (takes 2-3 minutes)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Add Rust to PATH (or restart terminal)
source $HOME/.cargo/env

# Add iOS targets
rustup target add aarch64-apple-ios aarch64-apple-ios-sim

# Verify installation
rustup --version
cargo --version
```

### 2. Install Xcode Command Line Tools

```bash
# Check if already installed
xcode-select -p

# If not installed, run:
xcode-select --install
```

### 3. Install XcodeGen (via Mint)

```bash
# Install Mint (Homebrew package manager for Swift tools)
brew install mint

# Install XcodeGen
mint install yonaskolb/xcodegen

# Verify
mint which xcodegen
```

### 4. Install Code Coverage Tool

```bash
# This is needed for `make verify-agent` and `make coverage-check`
cargo install cargo-llvm-cov

# Verify
cargo-llvm-cov --version
```

## Quick Setup Check

Run this command to verify everything is installed:

```bash
cd /Users/eganm/personal/cuzzo_monorepo/applications/thiccc
just thiccc ios check
```

**Expected output:**
```
🔍 Checking build environment...
✅ Rust/Cargo installed
✅ XcodeGen installed
✅ Xcode Command Line Tools
✅ iOS target (device)
✅ iOS target (simulator)
```

## Test Your Setup

```bash
# Navigate to project
cd /Users/eganm/personal/cuzzo_monorepo/applications/thiccc

# Run tests (should take 2-3 seconds)
just thiccc ios test

# If successful, you'll see:
# ✅ Rust tests passed!
```

## For AI Agents

Once setup is complete, agents can use:

```bash
just thiccc ios test      # Fast validation
just thiccc ios coverage  # Verify 100% coverage
just thiccc ios verify    # Complete validation
just thiccc ios run       # Build and run in simulator
```

## Troubleshooting

### Error: "cargo: command not found"

**Solution:** Rust not installed or not in PATH.

```bash
# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Add to PATH
source $HOME/.cargo/env

# Or restart terminal
```

### Error: "xcodegen: command not found"

**Solution:** XcodeGen not installed.

```bash
# Install Mint first
brew install mint

# Then install XcodeGen
mint install yonaskolb/xcodegen
```

### Error: "cargo-llvm-cov not found"

**Solution:** Coverage tool not installed.

```bash
# Install it
cargo install cargo-llvm-cov

# This takes 2-3 minutes
```

### Error: "target not installed: aarch64-apple-ios"

**Solution:** iOS targets not added.

```bash
rustup target add aarch64-apple-ios aarch64-apple-ios-sim
```

## What Gets Installed Where

| Tool | Location | Purpose |
|------|----------|---------|
| Rust/Cargo | `~/.cargo/` | Rust compiler and package manager |
| cargo-llvm-cov | `~/.cargo/bin/` | Code coverage tool |
| XcodeGen | `~/.mint/` | Generates Xcode projects |
| iOS Targets | `~/.rustup/` | Cross-compile to iOS |

## Disk Space Requirements

- **Rust:** ~500 MB
- **iOS Targets:** ~100 MB
- **cargo-llvm-cov:** ~50 MB
- **XcodeGen:** ~10 MB

**Total:** ~660 MB

## Setup Time

- **Rust installation:** 2-3 minutes
- **iOS targets:** 1 minute
- **cargo-llvm-cov:** 2-3 minutes
- **XcodeGen:** 1 minute

**Total:** ~7-10 minutes

## Keeping Tools Updated

```bash
# Update Rust
rustup update

# Update cargo tools
cargo install cargo-llvm-cov --force

# Update XcodeGen
mint install yonaskolb/xcodegen
```

## Alternative: Skip Coverage Tool (Not Recommended)

If you can't install `cargo-llvm-cov`, you can still develop:

```bash
# Use these commands instead:
make test-rust        # ✅ Works without cargo-llvm-cov
make build            # ✅ Works without cargo-llvm-cov
make run-sim          # ✅ Works without cargo-llvm-cov

# These won't work:
make coverage-check   # ❌ Requires cargo-llvm-cov
make verify-agent     # ❌ Requires cargo-llvm-cov
```

**However:** Coverage is **required** for this project (100% line coverage policy), so you'll need it eventually.

## For Two-Developer Team

Both developers should run this setup on their Macs. This ensures:
- ✅ Consistent build environment
- ✅ Both can run agent-driven development
- ✅ No "works on my machine" issues

## Next Steps

After setup is complete:

1. **Read:** `docs/STRUCTURE.md` - Project structure overview
2. **Read:** `docs/AGENT-QUICK-REF.md` - Quick command reference
3. **Run:** `just thiccc` - See all available commands
4. **Test:** `just thiccc ios verify` - Ensure everything works

---

**Last Updated:** December 25, 2025

