# Testing Strategies for Thiccc

This directory contains comprehensive documentation about testing strategies, tools, and best practices for the Thiccc iOS workout tracking application.

## Overview

Thiccc uses a **simplified, high-confidence testing approach** that combines:
- **Rust unit tests** for business logic (**100% line coverage required**)
- **Maestro tests** for UI smoke testing and video-based animation review

**Explicitly NOT used:**
- ❌ Swift integration tests (redundant with 100% Rust coverage)
- ❌ XCTest UI tests (too flaky, Maestro is better suited for our needs)

## Documents in This Directory

### Active Testing Approaches

#### [maestro.md](./maestro.md)
**What:** Simple, declarative mobile UI testing framework using YAML  
**Use for:** Smoke tests, AI agent-generated tests, animation review with video recording  
**Platform:** macOS for iOS testing, Linux for Android  

**Pros:** Extremely easy, AI agent-friendly, fast to write, video recording, cross-platform  
**Cons:** Less powerful than native tools, limited flexibility  

**Status:** ✅ **PRIMARY UI testing tool**  
**Key Takeaway:** Used for ALL UI testing - smoke tests, critical flows, and animation review.

---

### Reference Documentation (Not Used)

#### [xctest-ui-tests.md](./xctest-ui-tests.md)
**Status:** ❌ **NOT USED** - Too flaky, maintenance burden not worth it  
**Kept for reference only** in case future needs change

---

## Testing Philosophy

**Our approach:**
1. **100% Rust test coverage** ensures all business logic is bulletproof
2. **Maestro for UI** catches UI regressions and enables AI agent automation
3. **Keep it simple** - fewer tools, less maintenance, more confidence

**Why we skip XCTest UI:**
- 5-20% flakiness rate in real-world usage
- Maintenance burden too high
- Maestro is simpler and "good enough" for our needs

**Why we skip Swift integration tests:**
- Redundant with 100% Rust coverage
- Adds minimal value (just testing FFI serialization)
- Requires macOS for every test run

---

## Testing Strategy Matrix

| Test Type | Tool | Location | Speed | Coverage | Purpose |
|-----------|------|----------|-------|----------|---------|
| **Unit (Business Logic)** | Rust `#[test]` | `app/shared/src/` | ⚡ Very Fast | **100% required** | Test ALL core logic |
| **UI (Smoke Tests)** | Maestro | `tests/maestro/` | 🏃 Fast | Critical paths | Quick validation |
| **UI (Critical Flows)** | Maestro | `tests/maestro/` | 🏃 Fast | Main features | End-to-end flows |
| **Animation Review** | Maestro (video) | `tests/maestro/` | 🏃 Fast | Visual QA | Capture animations |

**Note:** This is a simplified, two-layer approach focused on high confidence with low maintenance.

## Rust Testing Workflow (100% Coverage Required)

### Quick Commands

```bash
# Run all Rust tests (fast)
make test-rust

# Run tests with coverage report
make coverage

# Open coverage HTML report
make coverage-report

# Verify 100% coverage (CI-ready, fails if below 100%)
make coverage-check
```

### Detailed Workflow

```bash
# 1. Write your code
# 2. Write tests for ALL code paths

# 3. Check coverage
cd app/shared
cargo test                    # Verify tests pass
make coverage-check           # Verify 100% coverage

# 4. If coverage < 100%, see what's missing
make coverage-report          # Opens HTML report in browser
# Look for red (uncovered) lines

# 5. Add tests for uncovered lines
# 6. Repeat until 100%
```

**Write tests for:**
- ✅ State transitions (events → model changes)
- ✅ Calculations (volume, stats, timers)
- ✅ Validation (input checking, constraints)
- ✅ Edge cases (empty state, maximum values)
- ✅ Error paths (every `Err` branch)
- ✅ **EVERY line of code** (100% coverage)

### For UI Testing (Maestro)

```yaml
# tests/maestro/complete-workout-flow.yaml
appId: com.cuzzos.Thiccc.Thiccc
---
# Launch app
- launchApp

# Start workout
- tapOn: "Start Workout"
- assertVisible: "Log Workout"

# Add exercise
- tapOn: "Add Exercise"
- assertVisible: "Exercise Library"
- tapOn: "Bench Press"

# Add set and complete
- tapOn: "Add Set"
- tapOn:
    id: "set_0_complete"

# Finish workout
- tapOn: "Finish"
- assertVisible: "Start Workout"
```

**Run from command line:**
```bash
# Install Maestro (once)
brew install maestro

# Run test
maestro test tests/maestro/complete-workout-flow.yaml

# Run with video recording (for animation review)
maestro test --video tests/maestro/complete-workout-flow.yaml
```

## Current Limitations

### What We Can't Do Yet (But Will!)

1. **Automated UI Verification**
   - Currently: Manual testing in simulator
   - Future: Automated via [SimAgent](../future_projects/simagent-ios-automation.md)

2. **Animation Quality Assessment**
   - Currently: Manual visual inspection and Maestro video recording
   - Future: Automated animation performance metrics

3. **Cross-Platform Testing**
   - Currently: iOS only
   - Future: Android shell (Crux supports it!)

4. **Performance Testing**
   - Currently: Ad-hoc testing
   - Future: Automated performance benchmarks

## Testing Checklist for New Features

When implementing a new feature:

- [ ] **Rust tests** for business logic
  - [ ] Happy path
  - [ ] Error cases
  - [ ] Edge cases
  - [ ] **100% line coverage verified** (`make coverage-check`)
- [ ] **Maestro test** for critical user flow (if UI feature)
  - [ ] Smoke test (basic interaction)
  - [ ] Complete flow test (if applicable)
  - [ ] Video recording for animation review
- [ ] **Manual verification** in simulator
  - [ ] iPhone SE (small screen)
  - [ ] iPhone 15 Pro (standard)
  - [ ] iPhone 15 Pro Max (large)
  - [ ] Light mode
  - [ ] Dark mode
  - [ ] Large text (accessibility)

## Best Practices

### 1. Test Pyramid (Simplified)

```
        /\
       /  \  Few Maestro tests (smoke + critical flows)
      /────\
     /      \
    /        \
   /          \ Many Rust Unit Tests (100% coverage)
  /────────────\
```

**Our ratio:**
- **~95%** Rust unit tests - ALL business logic (100% line coverage)
- **~5%** Maestro UI tests - Smoke tests + critical flows only

**Why this works:**
- Crux architecture means ALL logic is in Rust
- Swift is just a thin UI shell (minimal logic to test)
- UI testing catches regressions without excessive maintenance

### 2. Arrange-Act-Assert

```rust
#[test]
fn test_add_set() {
    // Arrange: Set up initial state
    let mut model = Model::with_active_workout();
    let caps = MockCapabilities::new();
    
    // Act: Perform action
    app.update(Event::AddSet { exercise_id: "ex1" }, &mut model, &caps);
    
    // Assert: Verify outcome
    assert_eq!(model.current_workout.unwrap().exercises[0].sets.len(), 1);
}
```

### 3. Descriptive Test Names

```rust
// ❌ Bad
#[test]
fn test1() { ... }

// ✅ Good
#[test]
fn test_adding_set_updates_total_volume() { ... }

#[test]
fn test_finishing_workout_without_exercises_shows_error() { ... }
```

### 4. Test One Thing

```rust
// ❌ Bad - tests too much
#[test]
fn test_everything() {
    // 100 lines testing entire workflow
}

// ✅ Good - focused tests
#[test]
fn test_start_workout_creates_new_workout() { ... }

#[test]
fn test_add_exercise_to_active_workout() { ... }

#[test]
fn test_finish_workout_saves_to_database() { ... }
```

### 5. Mock External Dependencies

```rust
// Don't hit real database in tests
struct MockCapabilities {
    database_operations: RefCell<Vec<DatabaseOp>>,
}

#[test]
fn test_save_workout() {
    let caps = MockCapabilities::new();
    
    // ... trigger save
    
    let ops = caps.database_operations();
    assert_eq!(ops.len(), 1);
    assert!(matches!(ops[0], DatabaseOp::SaveWorkout(_)));
}
```

## Debugging Failed Tests

### Rust Tests

```bash
# Run with output
cargo test -- --nocapture

# Run specific test with backtrace
RUST_BACKTRACE=1 cargo test test_name

# Run in release mode (faster)
cargo test --release
```

### XCTest UI Tests

1. **Set breakpoint** in test code
2. **Run test** in Xcode
3. **Use UI Inspector** (Debug → View Debugging → Capture View Hierarchy)
4. **Check accessibility identifiers** match
5. **Add explicit waits** if flaky

### Common Issues

**Rust test panics:**
```
thread 'tests::test_add_set' panicked at 'assertion failed: `(left == right)`
  left: `0`,
 right: `1`', src/app/mod.rs:123:5
```
→ Check your assertion logic

**UI test element not found:**
```
Failed to find element matching [.button, "startWorkoutButton"]
```
→ Check accessibility identifier is set correctly in SwiftUI

**Maestro test failure:**
```
Flow failed at step 5: Element "Start Workout" not found
```
→ Check element exists, add explicit wait, or review video recording

## Resources

### Official Documentation
- [XCTest - Apple](https://developer.apple.com/documentation/xctest)
- [Rust Testing - rust-lang.org](https://doc.rust-lang.org/book/ch11-00-testing.html)

### Third-Party Tools
- [Maestro - mobile.dev](https://maestro.mobile.dev/)

### Community
- [r/rust - Reddit](https://reddit.com/r/rust)
- [r/swift - Reddit](https://reddit.com/r/swift)
- [Swift Forums](https://forums.swift.org/)

## Future Projects

See [../future_projects/](../future_projects/) for:
- [SimAgent: iOS Simulator Automation](../future_projects/simagent-ios-automation.md)
- [Development Workflow: Linux + macOS](../future_projects/development-workflow.md)

---

**Last Updated**: December 6, 2025  
**Maintained by**: Development team + AI agents  
**Questions?** Open an issue or discuss in team chat

