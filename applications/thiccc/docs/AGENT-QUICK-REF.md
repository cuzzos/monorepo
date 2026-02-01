# Thiccc AI Agent Quick Reference

> **TL;DR:** Use `just` commands. Run `just thiccc ios verify` before saying "done."

## The Three Commands You Need

```bash
just thiccc ios test      # Fast validation (2-3s) - use constantly
just thiccc ios coverage  # Ensure 100% coverage (5-10s) - before completing tasks  
just thiccc ios verify    # Complete validation (10-15s) - before handoff
```

## Workflow Cheat Sheet

| I changed... | Run this... |
|--------------|-------------|
| Rust code | `just thiccc ios test` → `just thiccc ios coverage` → `just thiccc ios verify` |
| Swift UI | `just thiccc ios run` |
| Web code | `just thiccc web up` |
| Not sure | `just thiccc` |

## Common Patterns

### Adding Rust Feature
```bash
1. Edit shared/src/*.rs
2. just thiccc ios test
3. Add tests
4. just thiccc ios coverage  
5. just thiccc ios verify
```

### Fixing Rust Bug
```bash
1. Write failing test
2. just thiccc ios test  # Should fail
3. Fix bug
4. just thiccc ios test  # Should pass
5. just thiccc ios verify
```

### Swift Changes
```bash
1. Edit ios/Thiccc/*.swift
2. just thiccc ios run  # Watch logs
```

### Web Changes
```bash
1. Edit web_frontend/ or api_server/
2. just thiccc web up  # Hot reload
```

## Error Recovery

| Error | Solution |
|-------|----------|
| Tests fail | Fix code, run `just thiccc ios test` again |
| Coverage < 100% | Run `just thiccc ios coverage-report`, add tests for red lines |
| Swift types fail | Check `cd shared_types && cargo build` error |
| Build fails | Check `cat xcodebuild.log` |

## Files to Edit

| Task | File | Command After |
|------|------|---------------|
| Add model | `shared/src/models.rs` | `just thiccc ios test` |
| Add event | `shared/src/app/mod.rs` | `just thiccc ios test` |
| Add iOS UI | `ios/Thiccc/*.swift` | `just thiccc ios run` |
| Add Web UI | `web_frontend/app/*.tsx` | `just thiccc web up` |
| Add API endpoint | `api_server/src/*.rs` | `just thiccc web up` |

## Before Saying "Done"

```bash
just thiccc ios verify

# If this passes:
# ✅ All tests passed
# ✅ 100% coverage
# ✅ Swift types generated

# You can confidently hand off to user!
```

## Full Documentation

- Commands: `just thiccc`
- Project structure: `docs/STRUCTURE.md`
- Workflow: `.cursor/rules/agent-workflow.mdc`
- Architecture: `docs/SHARED-CRATE-MAP.md`
- This guide: `docs/AGENT-DEVELOPMENT.md`

---

**Working Directory:** Always `cd` to `/Users/eganm/personal/cuzzo_monorepo/applications/thiccc` first!

