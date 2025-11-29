# Phase 2: Extract Types

**Goal:** Separate Events, Model, ViewModels, and Effects into dedicated files following Crux conventions.

**Time:** ~1 hour | **Risk:** Medium

---

## Steps

### 1. Create type module files

```bash
cd app/shared/src/app
touch events.rs model.rs view_models.rs effects.rs
```

### 2. Extract Events (lines 23-239 from app.rs)

**Move to `app/events.rs`:**
- `Event` enum (lines 28-165)
- `Tab` enum (lines 179-186)
- `DatabaseResult` enum (lines 195-204)
- `StorageResult` enum (lines 213-222)
- `NavigationDestination` enum (lines 233-239)

**Add imports:**
```rust
use serde::{Deserialize, Serialize};
use crate::models::*;
use crate::id::Id;
```

### 3. Extract Model (lines 244-416 from app.rs)

**Move to `app/model.rs`:**
- `Model` struct (lines 262-310)
- `impl Default for Model` (lines 312-350)
- `impl Model` with all helper methods (lines 352-416)

**Add imports:**
```rust
use super::events::{Tab, NavigationDestination};
use crate::models::*;
use crate::id::Id;
```

### 4. Extract ViewModels (lines 429-682 from app.rs)

**Move to `app/view_models.rs`:**
- All ViewModel structs (ViewModel, WorkoutViewModel, ExerciseViewModel, etc.)

**Add imports:**
```rust
use serde::{Deserialize, Serialize};
use super::events::Tab;
```

### 5. Extract Effects (lines 422-425 from app.rs)

**Move to `app/effects.rs`:**
```rust
use crux_core::{macros::effect, render::RenderOperation};

#[effect(typegen)]
pub enum Effect {
    Render(RenderOperation),
}
```

### 6. Update app/mod.rs

Create/update module declarations:
```rust
pub mod events;
pub mod model;
pub mod view_models;
pub mod effects;

// Re-export for convenience
pub use events::*;
pub use model::*;
pub use view_models::*;
pub use effects::*;

#[cfg(test)]
mod tests;
```

### 7. Update app.rs imports

Replace removed type definitions with:
```rust
use crux_core::{render::render, App, Command};
use crate::id::Id;
use crate::models::*;

// Import from our new modules (via app/mod.rs)
pub use app::*;
```

Keep only:
- View helper methods (lines 694-906)
- App trait implementation (lines 912-1309)

---

## Verify

```bash
cd app/shared

# Check compilation
cargo check

# Run tests
cargo test --lib

# Verify TypeGen still works
cargo build
```

---

## Rollback

```bash
git checkout app/shared/src/app.rs
rm app/shared/src/app/{events,model,view_models,effects}.rs
```

---

## Success Criteria

✅ `cargo check` passes  
✅ All tests pass  
✅ `app.rs` now ~600 lines (App impl + helpers only)  
✅ Types organized in dedicated files  
✅ TypeGen generates Swift bindings correctly  

---

## Next Step

**(Optional)** If `app.rs` update method still feels too large (~400 lines), proceed to [03-SPLIT-UPDATE-LOGIC.md](./03-SPLIT-UPDATE-LOGIC.md)

Otherwise, **you're done!** Your code now follows the Crux framework pattern.

