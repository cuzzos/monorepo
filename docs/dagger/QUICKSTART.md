# Dagger Quickstart Guide

**Dagger** is a CI/CD as code platform that runs all development tools in containers. This means you don't need to install Rust, Node, PostgreSQL, or any other tools locally.

## Prerequisites

Only 3 things needed:

1. **Git** (you already have this)
2. **Docker** (install from docker.com or `brew install docker`)
3. **Dagger CLI**

## Install Dagger CLI

```bash
# macOS
brew install dagger/tap/dagger

# Or using curl
curl -fsSL https://dl.dagger.io/dagger/install.sh | sh

# Verify installation
dagger version
```

## How It Works

Instead of installing tools locally, you run them through Dagger:

**Traditional way:**
```bash
cargo test           # Requires Rust installed locally
npm run dev          # Requires Node installed locally
```

**Dagger way:**
```bash
dagger call rust-test --source=path/to/project
dagger call node-dev --source=path/to/project
```

Everything runs in containers with exact versions specified.

## Available Toolchains

See `TOOLCHAINS.md` for full list.

**Quick reference:**
- `dagger call rust-test` - Run Rust tests
- `dagger call rust-serve` - Start Rust API server
- `dagger call node-dev` - Start Next.js dev server
- `dagger call db-migrate` - Run database migrations
- `dagger call test-all` - Run all tests

## Example: Developing Thiccc Web App

```bash
# From monorepo root
cd cuzzo_monorepo

# Start backend API (Rust)
dagger call rust-serve \
  --source=applications/thiccc/api_server \
  --port=8000

# Start frontend (Next.js) in another terminal
dagger call node-dev \
  --source=applications/thiccc/web_frontend \
  --port=3000

# Run tests
dagger call rust-test --source=applications/thiccc/api_server
dagger call node-test --source=applications/thiccc/web_frontend
```

## Benefits

- ✅ No local installs (npm, cargo, postgres, etc.)
- ✅ Exact same versions everywhere (local = CI = production)
- ✅ Fast (Dagger caches everything)
- ✅ Works on any machine (macOS, Linux, Windows)
- ✅ AI agents can use it without special setup

## Troubleshooting

### "Cannot connect to Docker daemon"

**Solution:** Start Docker Desktop

```bash
open -a Docker
```

### "Command not found: dagger"

**Solution:** Make sure Dagger is in PATH

```bash
# Add to ~/.zshrc or ~/.bashrc
export PATH="$HOME/.dagger/bin:$PATH"

# Reload shell
source ~/.zshrc
```

### Dagger is slow on first run

**Expected:** First run downloads container images (1-2 GB). Subsequent runs are fast (cached).

## Next Steps

- Read `TOOLCHAINS.md` for all available commands
- See `AI-AGENT-GUIDE.md` for AI-specific workflows
- Check application-specific docs (e.g., `applications/thiccc/docs/web/`)

