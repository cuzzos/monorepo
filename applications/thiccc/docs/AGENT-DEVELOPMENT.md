# AI Agent Development Guide for Thiccc

## Overview

This document explains the optimized workflow for developing the Thiccc iOS app using AI agents (Claude, Cursor AI, etc.).

## Quick Start for Agents

### The Golden Rule

**Always use Makefile commands.** They handle complexity and provide clear, actionable feedback.

### The Three Essential Commands

```bash
# 1. After making Rust changes (2-3 seconds)
make test-rust

# 2. Before completing a task (5-10 seconds)
make coverage-check

# 3. Before handoff to user (10-15 seconds)
make verify-agent
```

## Why This Workflow Works for Agents

### Problems with Traditional Development

1. **Complex command sequences** - Agents have to remember: `cd shared && cargo test --all-features && cargo clippy ...`
2. **Directory confusion** - Different commands need different working directories
3. **Missing validation** - Easy to forget coverage checks or type generation
4. **No clear "done" signal** - Agents don't know when work is truly complete

### How Justfiles Solve This

```bash
# Instead of:
cd /Users/eganm/personal/cuzzo_monorepo/applications/thiccc/shared
cargo test --all-features
cd ../shared_types
cargo build
cd ..
cargo clippy --all-targets -- -D warnings

# Agents just run:
just thiccc ios test
```

**Benefits:**
- ✅ Single command, always works
- ✅ Clear success/failure output
- ✅ No directory management needed
- ✅ Handles edge cases (missing tools, etc.)

## The Complete Agent Workflow

### Phase 1: Development

```bash
# Agent receives task: "Add a new Workout model"

# 1. Agent makes changes to Rust code
#    (modifies shared/src/models.rs)

# 2. Agent runs quick validation
just thiccc ios test

# 3. If tests fail, agent fixes and repeats step 2

# 4. Agent adds tests for new model

# 5. Agent verifies coverage
just thiccc ios coverage

# 6. If coverage < 100%, agent adds missing tests
```

### Phase 2: Validation

```bash
# Agent runs complete validation
just thiccc ios verify

# This command runs:
# - All Rust tests
# - Coverage check (100% required)
# - Swift type generation
# All in ~10 seconds

# If this passes → agent can confidently say "Done!"
```

### Phase 3: Handoff (Optional)

```bash
# For extra confidence, agent can run full verification
build/scripts/verify-rust-core.sh

# This includes clippy lints + formatting checks
# Takes ~15-20 seconds
```

## Command Reference Matrix

| Scenario | Command | Time | When to Use |
|----------|---------|------|-------------|
| Made Rust changes | `just thiccc ios test` | 2-3s | After every change (use liberally) |
| Need coverage check | `just thiccc ios coverage` | 5-10s | Before completing task |
| **Agent validation** | `just thiccc ios verify` | 10-15s | **Best "done" check for agents** |
| Full verification | `build/scripts/verify-rust-core.sh` | 15-20s | Extra confidence before handoff |
| Made Swift changes | `just thiccc ios run` | 30-60s | Testing UI changes |
| Made Web changes | `just thiccc web up` | 5-10s | Hot reload dev server |
| Check environment | `just thiccc ios check` | 1s | Debugging setup issues |

## Common Agent Scenarios

### Scenario 1: Adding a New Feature (Rust)

```bash
# Agent workflow:
1. Modify Rust code
2. just thiccc ios test           # Quick validation
3. Add tests
4. just thiccc ios test           # Verify tests work
5. just thiccc ios coverage       # Ensure 100% coverage
6. just thiccc ios verify         # Final validation

# Agent says: "✅ Feature complete. All tests pass, coverage is 100%."
```

### Scenario 2: Fixing a Bug (Rust)

```bash
# Agent workflow:
1. Identify bug in code
2. Write failing test (demonstrates bug)
3. just thiccc ios test           # Verify test fails
4. Fix the bug
5. just thiccc ios test           # Verify test passes
6. just thiccc ios coverage       # Ensure still 100%
7. just thiccc ios verify         # Final validation

# Agent says: "✅ Bug fixed. Added regression test."
```

### Scenario 3: Adding UI Feature (Swift)

```bash
# Agent workflow:
1. Modify SwiftUI code
2. just thiccc ios run            # Build and launch simulator
3. Review logs (automatic after run)
4. If errors, check xcodebuild.log
5. Fix issues, repeat from step 2

# Note: No need for coverage checks (Swift doesn't require 100%)
```

### Scenario 4: Refactoring Rust Code

```bash
# Agent workflow:
1. Make refactoring changes
2. just thiccc ios test           # Verify tests still pass
3. just thiccc ios coverage       # Verify still 100%
4. just thiccc ios verify         # Final validation

# Agent says: "✅ Refactoring complete. No behavior changes."
```

### Scenario 5: Adding Web Feature

```bash
# Agent workflow:
1. Start dev server: just thiccc web up
2. Modify web_frontend/ or api_server/
3. Check browser (hot reload)
4. If API changes, test endpoints with curl

# Agent says: "✅ Web feature complete. Tested in browser."
```

## Error Handling for Agents

### Error: Tests Fail

```bash
# Output looks like:
running 23 tests
test test_workout_creation ... FAILED

# Agent should:
1. Read the failure message
2. Identify which test failed
3. Fix the code
4. Run: just thiccc ios test again
```

### Error: Coverage Below 100%

```bash
# Output looks like:
error: coverage rate 95.5% < 100%

# Agent should:
1. Run: just thiccc ios coverage-report  # Opens HTML in browser
2. Find uncovered lines (shown in red)
3. Add tests for those lines
4. Run: just thiccc ios coverage again
```

### Error: Swift Types Generation Failed

```bash
# Output looks like:
error: could not compile `shared_types`

# Agent should:
1. Read error message carefully
2. Common causes:
   - Missing Default trait on new types
   - Unsupported generic types
   - Circular dependencies
3. Fix the issue
4. Run: cd shared_types && cargo build
```

## Agent Performance Optimization

### Use the Right Command for the Job

```bash
# ❌ DON'T: Always run full verification
just thiccc ios verify  # Every time you make a change

# ✅ DO: Use fast commands during development
just thiccc ios test     # Quick iteration
just thiccc ios test     # Make changes
just thiccc ios test     # More changes
just thiccc ios verify   # Final check
```

### Parallelize When Possible

Agents can't actually parallelize (single-threaded), but they can optimize sequence:

```bash
# ❌ SLOW: Run simulator for every change
edit Swift → just thiccc ios run (30s)
edit Swift → just thiccc ios run (30s)
edit Swift → just thiccc ios run (30s)

# ✅ FAST: Batch changes
edit Swift (change 1)
edit Swift (change 2)
edit Swift (change 3)
just thiccc ios run (30s) # Test all at once
```

## The `ios verify` Command Deep Dive

This is **the most important command for AI agents**.

### What It Does

```bash
just thiccc ios verify

# Runs:
# 1. cargo test --all-features (validates logic)
# 2. cargo llvm-cov (ensures 100% coverage)
# 3. cargo build (generates Swift types)

# All in ~10 seconds with clear output
```

### When to Use It

✅ **DO use `ios verify`:**
- Before telling user "I'm done"
- After completing a feature
- After fixing a bug
- Before committing changes (if agent has git access)

❌ **DON'T use `ios verify`:**
- After every single change (too slow)
- During rapid iteration (use `just thiccc ios test` instead)

### Example Output

```
🤖 Running AI Agent Validation...

1️⃣  Running Rust tests...
✅ Tests passed

2️⃣  Checking code coverage...
✅ 100% coverage achieved

3️⃣  Generating Swift types...
✅ Swift types generated

================================
✅ ALL AGENT CHECKS PASSED
================================

Ready to hand off to user!
```

## Integration with Cursor Rules

The `.cursor/rules/` directory contains:

1. **`context.mdc`** - Overall standards and tech stack requirements
2. **`agent-workflow.mdc`** - Detailed command reference (this guide's companion)
3. **`rust-coverage.mdc`** - Coverage requirements and troubleshooting
4. **`shared-crate.mdc`** - Rust architecture guidance
5. **`swift-ios.mdc`** - Swift/SwiftUI standards

**These rules are automatically loaded by Cursor.** Agents should reference them when needed.

## Decision Tree for Agents

```
┌─────────────────────────────────────┐
│ Did I modify any Rust code?         │
└─────────────┬───────────────────────┘
              │
      ┌───────┴────────┐
      │ YES            │ NO
      ▼                ▼
┌─────────────────┐   ┌─────────────────┐
│ Run:            │   │ Did I modify    │
│ make test-rust  │   │ Swift code?     │
│                 │   └────────┬────────┘
│ Success?        │            │
│ └─YES→ make     │    ┌───────┴────────┐
│   coverage-check│    │ YES            │ NO
│                 │    ▼                ▼
│ Success?        │   ┌──────────┐  ┌────────┐
│ └─YES→ make     │   │ Run:     │  │ Done!  │
│   verify-agent  │   │ make     │  └────────┘
└─────────────────┘   │ run-sim  │
                      └──────────┘
```

## Tips for Multi-Turn Agent Conversations

### Maintain Context

```bash
# At the start of each turn, agent should know:
# - Current working directory
# - What changes were made in previous turns
# - What validation has already passed

# Agent can check context:
pwd                    # Where am I?
git status             # What changed?
git diff shared/       # What exactly changed?
```

### Progressive Validation

```bash
# Turn 1: Agent adds model
just thiccc ios test  # ✅ Pass

# Turn 2: Agent adds tests
just thiccc ios coverage  # ✅ 100%

# Turn 3: Agent asks "Should I validate?"
just thiccc ios verify  # ✅ Final check

# Agent: "All validations passed. Feature is complete."
```

### Clear Communication

```bash
# ❌ BAD: Vague agent response
"I made the changes."

# ✅ GOOD: Clear agent response
"I made the changes. Running validation:
- ✅ make test-rust: 15 tests passed
- ✅ make coverage-check: 100% coverage achieved
- ✅ make verify-agent: All checks passed

The feature is complete and ready for use."
```

## Troubleshooting Common Agent Issues

### Issue: "Command not found"

```bash
# Error: just: command not found

# Solution: Install just
brew install just

# Or wrong working directory
cd /Users/eganm/personal/cuzzo_monorepo/applications/thiccc
just thiccc ios test  # Now works
```

### Issue: "Cargo.toml not found"

```bash
# Error: could not find `Cargo.toml`

# Solution: Agent tried to run cargo directly instead of just
# Use: just thiccc ios test
# Not: cargo test
```

### Issue: "Coverage tool not installed"

```bash
# Error: cargo-llvm-cov not found

# Solution: Install it
cargo install cargo-llvm-cov
```

## Best Practices Summary

### For Rapid Development
1. Use `just thiccc ios test` liberally (it's fast!)
2. Only run `just thiccc ios coverage` when tests are passing
3. Save `just thiccc ios verify` for final validation

### For Reliability
1. Always run `just thiccc ios verify` before saying "done"
2. If in doubt, run `build/scripts/verify-rust-core.sh`
3. Read error messages carefully - they're helpful

### For Performance
1. Batch multiple changes before running simulator
2. Use `just thiccc ios test` during iteration
3. Don't run full builds unless necessary

## Resources

- **Quick commands:** `just thiccc`
- **Project structure:** `docs/STRUCTURE.md`
- **Detailed workflows:** `.cursor/rules/agent-workflow.mdc`
- **Architecture:** `docs/SHARED-CRATE-MAP.md`
- **Verification:** `build/scripts/verify-rust-core.sh`

---

**Last Updated:** December 25, 2025  
**Purpose:** Optimize AI agent workflows for Thiccc iOS development

