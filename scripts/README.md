# Monorepo Scripts

This directory contains monorepo-level scripts for the Cuzzo workspace.

## Development Launcher

### `dev.sh`
**Purpose**: Quick launcher for opening development workspaces

**Usage**:
```bash
# Interactive menu
./scripts/dev.sh

# Direct launch
./scripts/dev.sh thiccc
```

**What it does**:
- Presents a menu of available applications
- Launches the appropriate dev workspace script
- Opens multiple editor windows as needed per application

**Available Applications**:
- `thiccc`: Fitness tracking iOS app

---

## Application-Specific Scripts

Each application has its own `scripts/` directory with specialized tools:

### Thiccc (`applications/thiccc/scripts/`)
- `dev-workspace.sh`: Launch dual-window development environment
- `setup-mac.sh`: Initial macOS environment setup
- `verify-rust-core.sh`: Verify Rust core builds
- `verify-ios-build.sh`: Full iOS build verification

See each application's `scripts/README.md` for detailed documentation.

---

## Quick Start

For new developers:

```bash
# From monorepo root
cd cuzzo_monorepo

# Launch thiccc development
./scripts/dev.sh thiccc

# Or use interactive menu
./scripts/dev.sh
```

---

## Adding New Applications

When adding a new application to the monorepo:

1. Create `applications/your-app/scripts/` directory
2. Add a `dev-workspace.sh` script (or equivalent)
3. Update this `dev.sh` to include the new app
4. Document in this README

---

## Alias Suggestions

Add to your `~/.zshrc` or `~/.bashrc`:

```bash
# Cuzzo development
alias cuzzo='cd ~/personal/cuzzo_monorepo && ./scripts/dev.sh'
alias cuzzo-thiccc='cd ~/personal/cuzzo_monorepo && ./scripts/dev.sh thiccc'
```

Then simply run:
```bash
cuzzo          # Interactive menu
cuzzo-thiccc   # Launch thiccc directly
```


