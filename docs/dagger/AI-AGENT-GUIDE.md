# AI Agent Guide: Using Dagger Toolchains

This guide is specifically for AI agents developing features in the cuzzo_monorepo.

## Key Principle

**You do NOT need local installations of:**
- npm / node / pnpm
- cargo / rust / rustc
- postgresql / psql
- Any other development tools

**You ONLY need:**
- Git (to read/write code)
- Dagger CLI (to run toolchains)

## Workflow Overview

1. Read phase documentation (e.g., `applications/thiccc/docs/web/04-PHASE-4-ADMIN-DEBUG.md`)
2. Use Dagger commands to build/test/run
3. Validate using Dagger commands
4. Commit changes

**Never run `npm install`, `cargo build`, etc. directly.** Always use Dagger.

---

## Standard Commands by Task

### When asked to "test the backend"

```bash
dagger call rust-test --source=applications/thiccc/api_server
```

### When asked to "run the backend"

```bash
dagger call rust-serve --source=applications/thiccc/api_server --port=8000
```

### When asked to "test the frontend"

```bash
dagger call node-test --source=applications/thiccc/web_frontend
```

### When asked to "start the frontend dev server"

```bash
dagger call node-dev --source=applications/thiccc/web_frontend --port=3000
```

### When asked to "run database migrations"

```bash
dagger call db-migrate --source=applications/thiccc/api_server
```

### When asked to "run all tests"

```bash
dagger call test-all --source=applications/thiccc
```

---

## Development Workflow

### Phase Start Workflow

When user says "Start working on Phase X":

1. **Read phase doc:**
   ```
   Read: applications/thiccc/docs/web/0X-PHASE-X-[NAME].md
   ```

2. **Read required context files:**
   - Files listed in "Required Context" section
   - Use `@filepath` syntax

3. **Understand the goal:**
   - What feature are we building?
   - What are the success criteria?

4. **Execute tasks sequentially:**
   - Follow tasks in order
   - Use Dagger for all validation
   - Stop at human checkpoints

### Task Execution Pattern

For each task:

1. **Make code changes** (create/modify files)

2. **Validate immediately:**
   ```bash
   # Backend changes
   dagger call rust-test --source=applications/thiccc/web/backend
   
   # Frontend changes
   dagger call node-test --source=applications/thiccc/web/frontend
   ```

3. **If tests fail:**
   - Read error output
   - Fix the issue
   - Re-run validation
   - Repeat until passing

4. **Show user the changes:**
   - Code snippets
   - Test results
   - Next steps

---

## Example: Creating an API Endpoint

User says: "Create a GET /api/workouts endpoint"

### Step 1: Create the endpoint file

```bash
# You would create: applications/thiccc/api_server/src/routes/workouts.rs
```

### Step 2: Write tests first

```bash
# You would create tests in the same file
```

### Step 3: Run tests (they should fail - TDD)

```bash
dagger call rust-test \
  --source=applications/thiccc/api_server \
  --filter=workouts
```

### Step 4: Implement the endpoint

```bash
# Write the actual code
```

### Step 5: Run tests again (should pass now)

```bash
dagger call rust-test \
  --source=applications/thiccc/api_server \
  --filter=workouts
```

### Step 6: Check coverage (must be 100%)

```bash
dagger call rust-coverage --source=applications/thiccc/api_server
```

### Step 7: Show user results

"Endpoint created. Tests passing. Coverage: 100%."

---

## Example: Creating a React Component

User says: "Create a WorkoutCard component"

### Step 1: Create component file

```bash
# You would create: applications/thiccc/web_frontend/components/WorkoutCard.tsx
```

### Step 2: Write component tests

```bash
# You would create: applications/thiccc/web_frontend/components/WorkoutCard.test.tsx
```

### Step 3: Run tests

```bash
dagger call node-test \
  --source=applications/thiccc/web_frontend \
  --filter=WorkoutCard
```

### Step 4: Type check

```bash
dagger call node-typecheck --source=applications/thiccc/web_frontend
```

### Step 5: Lint

```bash
dagger call node-lint --source=applications/thiccc/web_frontend
```

### Step 6: Show user

"Component created. Tests passing. TypeScript happy."

---

## Common Scenarios

### Scenario: Database migration needed

```bash
# 1. Create migration file
# You create: applications/thiccc/api_server/migrations/001_add_workouts.sql

# 2. Apply migration
dagger call db-migrate --source=applications/thiccc/api_server

# 3. Verify schema
dagger call db-query --sql="\\d workouts"
```

### Scenario: Integration test (backend + frontend)

```bash
# 1. Start backend
dagger call rust-serve \
  --source=applications/thiccc/api_server \
  --port=8000 &

# 2. Start frontend
dagger call node-dev \
  --source=applications/thiccc/web_frontend \
  --port=3000 &

# 3. Run E2E tests
dagger call test-e2e \
  --source=applications/thiccc \
  --spec="workouts"

# 4. Stop services
kill %1 %2
```

### Scenario: Debugging failing tests

```bash
# 1. Run with verbose output
dagger call rust-test \
  --source=applications/thiccc/api_server \
  --verbose=true

# 2. Read error message carefully
# 3. Fix the issue
# 4. Re-run test
# 5. Repeat until passing
```

---

## Error Handling

### When Dagger command fails

1. **Read the error output carefully**
2. **Check if it's a code error or infrastructure error**
3. **If code error:** Fix code, re-run
4. **If infrastructure error:** Check Docker, ask user

### When tests fail

1. **Read test output**
2. **Identify which test failed**
3. **Understand why (assertion, panic, timeout, etc.)**
4. **Fix the code**
5. **Re-run tests**
6. **Repeat until all pass**

### When coverage is below 100% (Rust)

```bash
# 1. Generate coverage report
dagger call rust-coverage --source=applications/thiccc/api_server

# 2. Identify uncovered lines
# 3. Write tests for those lines
# 4. Re-run coverage
# 5. Repeat until 100%
```

---

## Best Practices

### DO:
- ✅ Always use Dagger commands
- ✅ Run tests after every change
- ✅ Check coverage (Rust: 100%, Frontend: >80%)
- ✅ Read error messages carefully
- ✅ Follow phase documentation sequentially
- ✅ Stop at human checkpoints

### DON'T:
- ❌ Run `npm install` directly
- ❌ Run `cargo build` directly
- ❌ Assume tests pass without running them
- ❌ Skip validation steps
- ❌ Commit code without tests passing
- ❌ Ignore coverage requirements

---

## Quick Reference

| Task | Command |
|------|---------|
| Test Rust | `dagger call rust-test --source=applications/thiccc/api_server` |
| Test Node | `dagger call node-test --source=applications/thiccc/web_frontend` |
| Run backend | `dagger call rust-serve --source=applications/thiccc/api_server --port=8000` |
| Run frontend | `dagger call node-dev --source=applications/thiccc/web_frontend --port=3000` |
| Migrate DB | `dagger call db-migrate --source=applications/thiccc/api_server` |
| Run all tests | `dagger call test-all --source=applications/thiccc` |
| Coverage | `dagger call rust-coverage --source=applications/thiccc/api_server` |
| Type check | `dagger call node-typecheck --source=applications/thiccc/web_frontend` |

---

## Troubleshooting

### "Cannot connect to Docker daemon"

**Solution:** Ask user to start Docker Desktop

### "Dagger command hanging"

**Solution:** 
1. Check if Docker is running
2. Check if port is already in use
3. Ask user

### "Tests passing locally but failing in Dagger"

**This should never happen** - Dagger ensures consistency. If it does:
1. Check Dagger version
2. Check if cache needs clearing: `dagger cache prune`
3. Ask user

---

## Summary

**Remember:**
- You're an AI agent with access to Git + Dagger
- You don't have npm/cargo/postgres installed locally
- All development happens via Dagger commands
- Follow phase docs sequentially
- Validate after every change
- Stop at human checkpoints

**When in doubt:** Read the phase documentation again.

