# Scripts

This directory contains automation scripts for the Thiccc iOS application.

## Setup & Installation

### `setup-mac.sh`
**Purpose**: One-command setup for macOS development environment

**What it does**:
- Installs Homebrew (if needed)
- Installs Rust and required iOS targets
- Installs xcodegen via Mint
- Sets up all dependencies

**Usage**:
```bash
./scripts/setup-mac.sh
```

**When to run**:
- First time setting up the project
- After pulling major changes
- When build errors occur

---

## Verification Scripts

### `verify-rust-core.sh`
**Purpose**: Verify Rust core builds and types generate correctly

**What it verifies**:
- ✅ Rust code compiles
- ✅ No Clippy warnings
- ✅ All tests pass
- ✅ Swift type generation succeeds (CRITICAL)

**Usage**:
```bash
./scripts/verify-rust-core.sh
```

**When to run**:
- After modifying `app/shared/` or `app/shared_types/`
- Before committing Rust changes
- During AI-assisted development handoffs

---

### `verify-ios-build.sh`
**Purpose**: Full iOS build verification (macOS only)

**What it verifies**:
- ✅ Everything from `verify-rust-core.sh`
- ✅ iOS app builds successfully
- ✅ Xcode project generates correctly
- ✅ End-to-end build pipeline works

**Usage**:
```bash
./scripts/verify-ios-build.sh
```

**When to run**:
- Before major commits
- When you suspect iOS build issues
- For final verification before deployment

**Note**: Requires macOS with Xcode installed

---

## Quick Reference

| Script | Platform | Duration | Purpose |
|--------|----------|----------|---------|
| `setup-mac.sh` | macOS | 5-10 min | Initial setup |
| `verify-rust-core.sh` | Any | ~30 sec | Quick Rust verification |
| `verify-ios-build.sh` | macOS | ~2 min | Full build verification |

---

## Running from Project Root

All scripts should be run from the project root directory:

```bash
# From anywhere in the project
cd /path/to/cuzzo_monorepo/applications/thiccc

# Then run scripts
./scripts/setup-mac.sh
./scripts/verify-rust-core.sh
./scripts/verify-ios-build.sh
```

---

## Troubleshooting

**Script permission denied**:
```bash
chmod +x scripts/*.sh
```

**Setup script fails**:
- Check internet connection
- Ensure you have sudo access
- Try running individual commands manually

**Verification fails**:
- Read the error output carefully
- Check the specific step that failed
- See main documentation for detailed troubleshooting

