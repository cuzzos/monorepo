# Phase 1: Extract Tests

**Goal:** Move 1150 lines of tests from `app.rs` into a separate `app/tests/` directory.

**Time:** ~30 minutes | **Risk:** Low

---

## Steps

### 1. Create test directory structure
```bash
cd app/shared/src
mkdir -p app/tests
```

### 2. Create test module files

Create `app/tests/mod.rs`:
```rust
// Event serialization tests
mod event_tests;

// Model tests
mod model_tests;

// ViewModel tests
mod view_model_tests;

// Integration tests (update + view cycle)
mod integration_tests;
```

### 3. Move tests from app.rs

**From `app.rs` (lines 1315-2468):**
- Lines 1324-1393 → `app/tests/event_tests.rs` (Event serialization tests)
- Lines 1399-1564 → `app/tests/model_tests.rs` (Model tests)
- Lines 1570-1646 → `app/tests/view_model_tests.rs` (ViewModel tests)
- Lines 1710-2467 → `app/tests/integration_tests.rs` (Integration tests)

**Note:** Each test file needs:
```rust
use super::super::*; // Import from parent app module
```

### 4. Update app.rs

Remove the entire `#[cfg(test)]` module section (lines 1315-2468).

### 5. Update app/mod.rs

Create/update `app/mod.rs` to include tests:
```rust
// Test module
#[cfg(test)]
mod tests;
```

---

## Verify

```bash
cd app/shared
cargo test --lib
```

All tests should pass with **same output** as before.

---

## Rollback

If something goes wrong:
```bash
git checkout app/shared/src/app.rs
rm -rf app/shared/src/app/tests/
```

---

## Success Criteria

✅ All tests pass  
✅ `app.rs` reduced from 2469 → ~1300 lines  
✅ Tests organized in `app/tests/`  
✅ No functional changes  

---

## Next Step

Once complete and verified, proceed to [02-EXTRACT-TYPES.md](./02-EXTRACT-TYPES.md)

