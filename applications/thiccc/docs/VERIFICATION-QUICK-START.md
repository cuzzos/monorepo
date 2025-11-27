# Verification Quick Start

**TL;DR**: Run this before pushing code to iOS engineer:

```bash
./verify-rust-core.sh
```

---

## What This Does

✅ Checks Rust compilation  
✅ Runs lints (Clippy)  
✅ Runs all tests (63 tests)  
✅ Checks code formatting  
✅ **CRITICAL**: Verifies Swift type generation  
✅ Detects breaking changes to Event/ViewModel

---

## Two-Stage Process

### Stage 1: Linux/Devcontainer (You)

**What**: Verify Rust core is solid  
**Where**: This devcontainer  
**How**: `./verify-rust-core.sh`  
**Time**: ~30 seconds

**Checks**:
- Rust compiles ✓
- No Clippy warnings ✓
- All tests pass ✓
- Swift bindings generate ✓

### Stage 2: macOS (Optional but Recommended)

**What**: Verify iOS app builds  
**Where**: Mac with Xcode  
**How**: `./verify-ios-build.sh`  
**Time**: ~2 minutes

**Checks**:
- Builds for iOS targets ✓
- Xcode project compiles ✓
- App runs in simulator ✓

---

## When to Run Each Stage

| Scenario | Stage 1 | Stage 2 |
|----------|---------|---------|
| Agent modified Rust only | ✅ Always | ⚠️ Recommended |
| Agent modified Event enum | ✅ Always | ✅ Required |
| Agent modified ViewModel | ✅ Always | ✅ Required |
| Before every commit | ✅ Always | ⚠️ Good practice |
| Before iOS engineer pulls | ✅ Always | ✅ Required |

---

## What Success Looks Like

```
================================
✅ ALL CHECKS PASSED
================================

✅ Safe to hand off to iOS engineer
```

---

## What Failure Looks Like

### Rust Won't Compile
```
❌ FAILED: Rust compilation errors
```
**Fix**: Check error messages, fix Rust code

### Tests Fail
```
❌ FAILED: Tests failed
```
**Fix**: Fix the broken tests, don't skip them!

### Swift Bindings Fail (CRITICAL)
```
❌ FAILED: Swift type generation failed

⚠️  CRITICAL ERROR: iOS app will crash!
```
**Fix**: See docs/PRE-HANDOFF-VERIFICATION.md for type tracing fixes

### Breaking Changes Detected
```
⚠️  Event enum was modified
   → Swift code using core.update(.event) may need updates

⚠️  ViewModel was modified
   → Swift code accessing core.view.X may need updates
```
**Action**: Run Stage 2 on macOS to verify iOS still builds

---

## Manual Verification (AI Agents)

If you're an AI agent working on this codebase:

1. ✅ Run `./verify-rust-core.sh`
2. ✅ Fill out verification report (see docs/AI-AGENT-HANDOFF-PROTOCOL.md)
3. ✅ Document any breaking changes
4. ✅ Report results before marking task complete

**DO NOT** skip verification. **DO NOT** report "done" until checks pass.

---

## Files Created for You

| File | Purpose |
|------|---------|
| `verify-rust-core.sh` | Automated verification (Linux) |
| `verify-ios-build.sh` | Automated verification (macOS) |
| `docs/PRE-HANDOFF-VERIFICATION.md` | Detailed guide |
| `docs/AI-AGENT-HANDOFF-PROTOCOL.md` | Instructions for AI agents |

---

## Next Steps

### For You (Human Developer)

1. After AI makes changes: Run `./verify-rust-core.sh`
2. If breaking changes: Test on macOS with `./verify-ios-build.sh`
3. If all clear: Notify iOS engineer to pull code

### For iOS Engineer

1. Pull latest code
2. Open `app/ios/Thiccc.xcodeproj`
3. Press ⌘R to build and run
4. Should work immediately (if verification passed)

### For AI Agents

1. Complete your task
2. Run verification script
3. Fill out verification report
4. Document breaking changes
5. Only then report "ready for iOS engineer"

---

## Common Questions

**Q: Do I need to run this every time?**  
A: Yes, if AI modified Rust code. It's fast (<1 minute).

**Q: Can I skip Stage 2 (macOS)?**  
A: Only if there are NO breaking changes to Event/ViewModel.

**Q: What if I don't have macOS?**  
A: Stage 1 catches 95% of issues. iOS engineer will catch the rest.

**Q: The verification script failed, now what?**  
A: Fix the issues it reports. Don't push until it passes.

**Q: Can I automate this?**  
A: Yes! Add to git pre-commit hook or CI/CD. See docs.

---

## Pro Tips

### Tip 1: Auto-format before committing
```bash
cd app/shared && cargo fmt
```

### Tip 2: Fix Clippy warnings automatically
```bash
cd app/shared && cargo clippy --fix --allow-dirty
```

### Tip 3: Run just the critical check
```bash
cd app/shared_types && cargo build
```
If this passes, Swift bindings are valid.

### Tip 4: Add alias to your shell
```bash
alias verify='cd /workspaces/cuzzo_monorepo/applications/thiccc && ./verify-rust-core.sh'
```
Then just run: `verify`

---

## Remember

**Goal**: iOS engineer pulls code and it builds immediately

**Method**: Verify everything before pushing

**Result**: No wasted time debugging preventable issues

**Key**: Swift type generation MUST succeed or app crashes at runtime

