# Thiccc AI Agent Quick Reference

> **TL;DR:** Use Makefile commands. Run `make verify-agent` before saying "done."

## The Three Commands You Need

```bash
make test-rust        # Fast validation (2-3s) - use constantly
make coverage-check   # Ensure 100% coverage (5-10s) - before completing tasks  
make verify-agent     # Complete validation (10-15s) - before handoff
```

## Workflow Cheat Sheet

| I changed... | Run this... |
|--------------|-------------|
| Rust code | `make test-rust` → `make coverage-check` → `make verify-agent` |
| Swift UI | `make run-sim` |
| Not sure | `make help` |

## Common Patterns

### Adding Rust Feature
```bash
1. Edit app/shared/src/*.rs
2. make test-rust
3. Add tests
4. make coverage-check  
5. make verify-agent
```

### Fixing Rust Bug
```bash
1. Write failing test
2. make test-rust  # Should fail
3. Fix bug
4. make test-rust  # Should pass
5. make verify-agent
```

### Swift Changes
```bash
1. Edit app/ios/Thiccc/*.swift
2. make run-sim  # Watch logs
```

## Error Recovery

| Error | Solution |
|-------|----------|
| Tests fail | Fix code, run `make test-rust` again |
| Coverage < 100% | Run `make coverage-report`, add tests for red lines |
| Swift types fail | Check `cd app/shared_types && cargo build` error |
| Build fails | Check `cat xcodebuild.log` |

## Files to Edit

| Task | File | Command After |
|------|------|---------------|
| Add model | `app/shared/src/models.rs` | `make test-rust` |
| Add event | `app/shared/src/app.rs` | `make test-rust` |
| Add UI | `app/ios/Thiccc/*.swift` | `make run-sim` |

## Before Saying "Done"

```bash
make verify-agent

# If this passes:
# ✅ All tests passed
# ✅ 100% coverage
# ✅ Swift types generated

# You can confidently hand off to user!
```

## Full Documentation

- Commands: `make help`
- Workflow: `.cursor/rules/agent-workflow.mdc`
- Architecture: `docs/SHARED-CRATE-MAP.md`
- This guide: `docs/AGENT-DEVELOPMENT.md`

---

**Working Directory:** Always `cd` to `/Users/eganm/personal/cuzzo_monorepo/applications/thiccc` first!

