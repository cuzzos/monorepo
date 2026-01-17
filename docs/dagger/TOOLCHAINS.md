# Dagger Toolchains Reference

This document lists all available Dagger toolchains and their commands.

## Rust Toolchain

**Tools included:** cargo, clippy, rustfmt, sqlx-cli, cargo-nextest

### Commands

#### Test Rust code
```bash
dagger call rust-test --source=path/to/rust/project

# With filter
dagger call rust-test --source=path/to/rust/project --filter=workout

# With coverage
dagger call rust-coverage --source=path/to/rust/project
```

#### Run Rust server
```bash
dagger call rust-serve --source=path/to/rust/project --port=8000
```

#### Lint Rust code
```bash
dagger call rust-lint --source=path/to/rust/project

# Auto-fix
dagger call rust-lint --source=path/to/rust/project --fix=true
```

#### Format Rust code
```bash
dagger call rust-format --source=path/to/rust/project
```

#### Build Rust project
```bash
dagger call rust-build --source=path/to/rust/project --release=true
```

---

## Node Toolchain

**Tools included:** Node 20, pnpm, prettier, eslint, typescript

### Commands

#### Development server
```bash
dagger call node-dev --source=path/to/nextjs/project --port=3000
```

#### Test
```bash
dagger call node-test --source=path/to/nextjs/project

# Watch mode
dagger call node-test --source=path/to/nextjs/project --watch=true
```

#### Build for production
```bash
dagger call node-build --source=path/to/nextjs/project
```

#### Lint
```bash
dagger call node-lint --source=path/to/nextjs/project

# Auto-fix
dagger call node-lint --source=path/to/nextjs/project --fix=true
```

#### Format
```bash
dagger call node-format --source=path/to/nextjs/project
```

#### Type check
```bash
dagger call node-typecheck --source=path/to/nextjs/project
```

---

## Database Toolchain

**Tools included:** PostgreSQL 16, psql, pg_dump

### Commands

#### Run migrations
```bash
dagger call db-migrate --source=path/to/backend
```

#### Create new migration
```bash
dagger call db-create-migration --name="add_users_table"
```

#### Reset database
```bash
dagger call db-reset --source=path/to/backend
```

#### Seed database
```bash
dagger call db-seed --source=path/to/backend
```

#### Run SQL query
```bash
dagger call db-query --sql="SELECT * FROM workouts LIMIT 10"
```

#### Start PostgreSQL server
```bash
dagger call db-serve --port=5432
```

---

## Testing Toolchain

**Tools included:** Playwright, cargo-nextest

### Commands

#### Run integration tests
```bash
dagger call test-integration --source=path/to/app
```

#### Run E2E tests
```bash
dagger call test-e2e --source=path/to/app --spec="workouts"
```

#### Run all tests
```bash
dagger call test-all --source=path/to/app
```

---

## CI/CD Workflows

### Commands

#### Development workflow
```bash
# Start all services for development
dagger call dev-start --source=applications/thiccc
```

#### Full test suite
```bash
# Run all tests across backend + frontend
dagger call ci-test --source=applications/thiccc
```

#### Build for production
```bash
dagger call ci-build --source=applications/thiccc
```

---

## Common Patterns

### Thiccc Web Backend (Rust API)

```bash
# Test
dagger call rust-test --source=applications/thiccc/api_server

# Run locally
dagger call rust-serve --source=applications/thiccc/api_server --port=8000

# Lint
dagger call rust-lint --source=applications/thiccc/api_server

# Coverage
dagger call rust-coverage --source=applications/thiccc/api_server
```

### Thiccc Web Frontend (Next.js)

```bash
# Dev server
dagger call node-dev --source=applications/thiccc/web_frontend --port=3000

# Test
dagger call node-test --source=applications/thiccc/web_frontend

# Build
dagger call node-build --source=applications/thiccc/web_frontend

# Type check
dagger call node-typecheck --source=applications/thiccc/web_frontend
```

### Full Stack Development

```bash
# Terminal 1: Backend
dagger call rust-serve --source=applications/thiccc/api_server --port=8000

# Terminal 2: Frontend
dagger call node-dev --source=applications/thiccc/web_frontend --port=3000

# Terminal 3: Database
dagger call db-serve --port=5432

# Terminal 4: Run tests
dagger call test-all --source=applications/thiccc
```

---

## Performance Tips

### Caching

Dagger automatically caches:
- Downloaded dependencies
- Build artifacts
- Container images

First run is slow (~5 minutes), subsequent runs are fast (~30 seconds).

### Parallel execution

Run multiple commands in parallel:

```bash
# Run backend and frontend tests simultaneously
dagger call rust-test --source=applications/thiccc/web/backend &
dagger call node-test --source=applications/thiccc/web/frontend &
wait
```

---

## Troubleshooting

### Out of disk space

**Clear Dagger cache:**
```bash
dagger cache prune
```

### Command hanging

**Check Docker:**
```bash
docker ps
docker stats
```

### Slow builds

**Check if Docker has enough resources:**
- Docker Desktop → Settings → Resources
- Allocate at least: 4 CPU, 8GB RAM

---

## Adding New Toolchains

See `dagger/toolchains/` for implementation examples.

To add a new toolchain:
1. Create `dagger/toolchains/newtool.go`
2. Implement commands
3. Document here
4. Update `dagger/main.go`

