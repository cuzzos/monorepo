# Rust Code Coverage - Quick Start

## TL;DR

```bash
# Check coverage (required before commit)
make coverage-check

# View coverage report
make coverage-report
```

## What is Required?

**100% line coverage** for all Rust code in `app/shared/src/`

## Quick Commands

```bash
# Run Rust tests only (fast, ~2 seconds)
make test-rust

# Run tests with coverage check (fails if < 100%)
make coverage-check

# Generate HTML coverage report
make coverage

# Open coverage report in browser
make coverage-report
```

## Typical Workflow

### 1. Write Your Code

```rust
// app/shared/src/app.rs
pub enum Event {
    StartWorkout,
    // NEW EVENT
    PauseWorkout,
}

impl Model {
    pub fn update(&mut self, event: Event) {
        match event {
            Event::StartWorkout => {
                self.current_workout = Some(Workout::new());
            }
            // NEW: Must have test!
            Event::PauseWorkout => {
                self.workout_paused = true;
            }
        }
    }
}
```

### 2. Write Tests

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_pause_workout() {
        let mut model = Model::default();
        model.current_workout = Some(Workout::new());
        
        model.update(Event::PauseWorkout);
        
        assert!(model.workout_paused);
    }
}
```

### 3. Check Coverage

```bash
$ make coverage-check
🧪 Running tests with coverage...
🔍 Checking coverage threshold (100% line coverage required)...

Filename                      Lines    Functions
-------------------------------------------------
app/src/app.rs               100.00%   100.00%
app/src/models.rs            100.00%   100.00%
-------------------------------------------------
TOTAL                        100.00%   100.00%

✅ Coverage meets 100% threshold!
```

### 4. If Coverage Fails

```bash
$ make coverage-check
❌ Coverage: 87.5% (below 100%)

# See what's missing
$ make coverage-report
# Opens HTML report showing red (uncovered) lines

# Add tests for red lines
# Repeat until 100%
```

## What Gets Checked?

**Included in coverage:**
- ✅ `app/shared/src/app.rs` - Events, Model, update(), view()
- ✅ `app/shared/src/models.rs` - Domain models
- ✅ `app/shared/src/operations.rs` - Business operations
- ✅ `app/shared/src/id.rs` - Utilities
- ✅ All other `.rs` files in `src/`

**Excluded from coverage:**
- ❌ `app/shared/src/lib.rs` - FFI bridge (auto-generated)
- ❌ `build.rs` - Build scripts

## Common Scenarios

### Missing Test for Error Path

```rust
// Code
pub fn validate_reps(reps: u32) -> Result<(), ValidationError> {
    if reps == 0 {
        return Err(ValidationError::ZeroReps);  // ❌ Not tested!
    }
    Ok(())
}

// Test only happy path (87.5% coverage)
#[test]
fn test_validate_reps_success() {
    assert!(validate_reps(5).is_ok());
}

// Fix: Add error path test (100% coverage)
#[test]
fn test_validate_reps_zero() {
    assert!(matches!(
        validate_reps(0),
        Err(ValidationError::ZeroReps)
    ));
}
```

### Missing Test for Branch

```rust
// Code
pub fn format_weight(weight: f64, use_kg: bool) -> String {
    if use_kg {
        format!("{} kg", weight)          // ✅ Tested
    } else {
        format!("{} lbs", weight)         // ❌ Not tested!
    }
}

// Test only one branch (75% coverage)
#[test]
fn test_format_weight_kg() {
    assert_eq!(format_weight(100.0, true), "100 kg");
}

// Fix: Add test for other branch (100% coverage)
#[test]
fn test_format_weight_lbs() {
    assert_eq!(format_weight(225.0, false), "225 lbs");
}
```

## Integration with Verification Script

The verification script automatically checks coverage:

```bash
$ ./scripts/verify-rust-core.sh

1️⃣  Checking Rust compilation...
✅ Rust compiles

2️⃣  Running Clippy lints...
✅ No Clippy warnings

3️⃣  Running tests...
✅ All tests pass

4️⃣  Verifying 100% code coverage...
✅ 100% code coverage achieved

6️⃣  CRITICAL: Verifying Swift type generation...
✅ Swift types generated successfully

7️⃣  Checking for potential breaking changes...
✅ No breaking changes detected

================================
✅ ALL CHECKS PASSED
================================
```

## Troubleshooting

### `cargo-llvm-cov` not found

```bash
$ make coverage-check
❌ cargo-llvm-cov not found. Installing...
# Wait for installation, then re-run
```

### Coverage below 100%

```bash
# Step 1: See what's missing
make coverage-report

# Step 2: Look at HTML report
# Red lines = not covered
# Green lines = covered

# Step 3: Write tests for red lines

# Step 4: Re-check
make coverage-check
```

### Test runs but still shows uncovered

```bash
# Clean and rebuild
cd app/shared
cargo clean
cd ../..
make coverage-check
```

## Why 100%?

**Benefits:**
- 🐛 **Catches bugs before they ship**
- 🔒 **Prevents regressions** - Changes that break things fail tests
- 📚 **Documents behavior** - Tests are executable specs
- 🔧 **Enables refactoring** - Change confidently
- ⚡ **Fast feedback** - Tests run in ~2 seconds

**For Crux apps:** Since ALL business logic is in Rust (Swift is just UI), 100% Rust coverage means 100% business logic coverage.

## See Also

- **[.cursor/rules/rust-coverage.mdc](../../.cursor/rules/rust-coverage.mdc)** - Full documentation
- **[Makefile](../../Makefile)** - Coverage commands
- **[scripts/verify-rust-core.sh](../../scripts/verify-rust-core.sh)** - Verification script

---

**Last Updated**: December 13, 2025  
**Status**: MANDATORY for all Rust code  
**Quick Help**: Run `make coverage-report` to see what's missing

