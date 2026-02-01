# Devtools

Containerized development tools for the cuzzo monorepo, organized by language/purpose.

**No local toolchains required!** All tools run in containers via Dagger.

## Structure

```
devtools/
├── rust/     # Rust toolchain (build-binary, serve-api)
├── node/     # Node.js toolchain (run-dev-server, run-prod-server, build-frontend, sync-deps)
└── db/       # Database toolchain (serve-db)
```

## Quick Start

All commands run from monorepo root using `-m` flag:

```bash
# Run Next.js dev server
dagger -m ./devtools/node call run-dev-server --source=./applications/thiccc/web_frontend up

# Run Rust API server
dagger -m ./devtools/rust call serve-api --source=./applications/thiccc/api_server up

# Run PostgreSQL database
dagger -m ./devtools/db call serve-db up
```

## Full Stack Development

Run all three services for local development:

```bash
# Terminal 1: Database
dagger -m ./devtools/db call serve-db up

# Terminal 2: Backend API
dagger -m ./devtools/rust call serve-api --source=./applications/thiccc/api_server up

# Terminal 3: Frontend
dagger -m ./devtools/node call run-dev-server --source=./applications/thiccc/web_frontend up
```

## IDE Support (No npm required!)

Sync `node_modules` for IDE IntelliSense without installing npm locally:

```bash
dagger -m ./devtools/node call sync-deps --source=./applications/thiccc/web_frontend \
  export --path=./applications/thiccc/web_frontend/node_modules
```

## Functions Reference

### Rust (`devtools/rust`)

| Function | Description |
|----------|-------------|
| `build-binary` | Compile Rust project (debug by default, `--release` for production) |
| `serve-api` | Run Rust API server |

### Node (`devtools/node`)

| Function | Description |
|----------|-------------|
| `run-dev-server` | Run Next.js development server with hot reload |
| `run-prod-server` | Build and run optimized production server |
| `build-frontend` | Create production build (returns `.next` directory) |
| `sync-deps` | Install deps and return `node_modules` for IDE support |

### Database (`devtools/db`)

| Function | Description |
|----------|-------------|
| `serve-db` | Run PostgreSQL 18 database (default: user=postgres, password=postgres) |

## Adding Functions

Each toolchain is a separate Dagger module. To add functions:

1. Edit the appropriate `main.go` (e.g., `devtools/rust/main.go`)
2. Run `dagger develop` in that directory
3. Verify with `dagger functions`
