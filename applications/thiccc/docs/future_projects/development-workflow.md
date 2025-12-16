# Development Workflow: Linux + macOS Split

## Overview

This document explains the current development setup for Thiccc, which involves working across two environments:
- **Linux** (Cursor AI agent, Rust development)
- **macOS** (iOS builds, simulator testing)

## Current Architecture

```
┌────────────────────────────────────────┐
│   Linux Environment (Development)      │
│   - Cursor AI Agent                    │
│   - Rust toolchain (cargo, rustc)      │
│   - Code editor                        │
│   - Git repository                     │
│   - Rust tests                         │
└──────────────┬─────────────────────────┘
               │
               │ Shared Repository
               │ (Git sync or shared filesystem)
               ▼
┌────────────────────────────────────────┐
│   macOS Environment (Building/Testing) │
│   - Xcode                              │
│   - iOS Simulator                      │
│   - Swift compiler                     │
│   - iOS testing tools                  │
│   - Manual verification                │
└────────────────────────────────────────┘
```

## What Works Where

### Linux Environment (Cursor Agent)

**Can Do:**
- ✅ Edit all source files (Rust, Swift, etc.)
- ✅ Compile Rust code (`cargo build`)
- ✅ Run Rust tests (`cargo test`)
- ✅ Run Rust linter (`cargo clippy`)
- ✅ Format Rust code (`cargo fmt`)
- ✅ Generate code (TypeGen, UniFFI)
- ✅ Read build logs
- ✅ Fix Rust compilation errors
- ✅ Update documentation

**Cannot Do:**
- ❌ Build iOS app (requires Xcode)
- ❌ Run iOS Simulator (requires macOS)
- ❌ Compile Swift code (requires macOS SDK)
- ❌ Run XCTest (requires Xcode)
- ❌ Test SwiftUI views
- ❌ See rendered UI
- ❌ Interact with running app

### macOS Environment (Human or Future Agent)

**Can Do:**
- ✅ Build iOS app (Xcode)
- ✅ Run iOS Simulator
- ✅ Test app manually
- ✅ Run XCTest UI tests
- ✅ Debug Swift code
- ✅ Profile app performance
- ✅ Take screenshots
- ✅ Verify UI behavior

**Cannot Do:**
- ❌ AI agent capabilities (unless running Cursor on Mac)

## Current Workflow

### Phase: Feature Implementation

**Step 1: Development (Linux)**

```bash
# Linux agent writes code
# Example: Implementing WorkoutView.swift

# Agent can compile Rust core
cd app/shared
cargo build --release

# Agent can run Rust tests
cargo test

# Agent can check Rust code quality
cargo clippy
```

**Step 2: Build (macOS - Manual)**

```bash
# Human opens Xcode on Mac
cd app/iOS
open Thiccc.xcodeproj

# Build the app (Cmd+B)
# or from command line:
xcodebuild -project Thiccc.xcodeproj \
    -scheme Thiccc \
    -configuration Debug \
    build
```

**Step 3: Verification (macOS - Manual)**

```bash
# Run in simulator (Cmd+R in Xcode)
# Human manually tests:
# 1. Launch app
# 2. Navigate to Workout tab
# 3. Tap "Start Workout"
# 4. Verify UI matches specifications
# 5. Test interactions
# 6. Check for bugs
```

**Step 4: Feedback Loop**

```
macOS (Human) → Observe issue
              ↓
      Report to Linux Agent
              ↓
Linux (Agent) → Fix code
              ↓
      Repeat Step 2-4
```

## Pain Points

### 1. Manual Testing Bottleneck

**Problem:** Every code change requires manual verification

**Impact:**
- Slow iteration cycles
- Human required for each change
- Can't work overnight/unattended
- Tedious for repetitive tests

**Solution:** [SimAgent automation](./simagent-ios-automation.md)

### 2. Build Feedback Delay

**Problem:** Agent can't compile Swift, only sees errors later

**Impact:**
- Agent might write Swift code that doesn't compile
- Discover issues only when building on Mac
- Multiple round trips to fix

**Solution:**
- Agent generates syntactically correct Swift (learns patterns)
- Early validation through code review
- Future: Swift compiler on Linux (experimental)

### 3. No Visual Feedback

**Problem:** Agent can't see rendered UI

**Impact:**
- Can't verify layout
- Can't check colors/fonts
- Can't see spacing issues
- Relies on human description

**Solution:**
- Screenshot capture + AI vision analysis
- Snapshot testing with reference images
- Detailed verification checklists

### 4. Two-Machine Sync

**Problem:** Need to keep code in sync between machines

**Current Solutions:**
- **Git**: Push from Linux, pull on Mac
- **Shared filesystem**: Network drive or sync service
- **Cloud repo**: GitHub/GitLab

**Challenges:**
- Sync delays
- Conflicts
- Forgetting to sync

## Optimization Strategies

### Strategy 1: Fast Rust Feedback (Already Working)

```bash
# Linux agent runs after every change
cargo check    # Fast syntax check (1-2s)
cargo test     # Run unit tests (5-10s)
cargo clippy   # Lint (2-3s)

# This catches 80% of issues before macOS step
```

### Strategy 2: Batch Testing

Instead of verifying after each small change:

```
1. Agent implements Sub-task 6.1.1
2. Agent implements Sub-task 6.1.2
3. Agent implements Sub-task 6.1.3
   ↓
4. Build once on macOS
5. Verify all three sub-tasks together
```

**Pros:** Fewer build cycles
**Cons:** Harder to isolate issues

### Strategy 3: Verification Checklist

Agent provides detailed checklist for human:

```markdown
## Sub-Task 6.1.1 Verification

### Build Steps
1. Open Xcode: `open app/iOS/Thiccc.xcodeproj`
2. Clean build: Cmd+Shift+K
3. Build: Cmd+B
4. Run: Cmd+R

### Expected Results
- [ ] App launches without crash
- [ ] Workout tab visible
- [ ] Empty state shows:
  - [ ] Large "figure.run" icon
  - [ ] "No Active Workout" text
  - [ ] "Start Workout" button (blue, rounded)
- [ ] Tap "Start Workout" → Active view appears
- [ ] Active view shows:
  - [ ] Black top bar with "Log Workout" title
  - [ ] Stats bar: "Duration: 0:00", "Volume: 0 lbs", "Sets: 0"
  - [ ] Text field with placeholder "Workout Name"
  - [ ] Empty exercise list area
  - [ ] Bottom bar with 3 buttons

### Report Back
Reply with: "✅ 6.1.1" or "❌ 6.1.1: [describe issue]"
```

## Future: Automated Workflow

### With SimAgent

```
┌────────────────────────────────────────┐
│   Linux Agent (Development)            │
│   1. Writes code                       │
│   2. Runs Rust tests                   │
│   3. Generates UI test script          │
│   4. Saves to shared location          │
└──────────────┬─────────────────────────┘
               │
               │ Test script + code
               ▼
┌────────────────────────────────────────┐
│   macOS Agent (Automated Testing)      │
│   5. Detects new test                  │
│   6. Builds iOS app                    │
│   7. Launches simulator                │
│   8. Runs UI tests                     │
│   9. Captures screenshots              │
│   10. Saves results                    │
└──────────────┬─────────────────────────┘
               │
               │ Results + screenshots
               ▼
┌────────────────────────────────────────┐
│   Linux Agent (Analysis)               │
│   11. Reads results                    │
│   12. Analyzes success/failure         │
│   13. Fixes issues OR continues        │
└────────────────────────────────────────┘
```

**Result:** Fully automated verification loop!

## Recommendations

### For Current Development (Manual)

1. **Minimize build cycles**
   - Agent implements complete sub-tasks before building
   - Provides comprehensive checklists
   - Groups related changes

2. **Maximize Rust testing**
   - Agent tests all business logic in Rust
   - Catches logic bugs before iOS build
   - Fast feedback loop

3. **Clear communication**
   - Agent provides exact verification steps
   - Human reports precise issues
   - Quick feedback cycles

### For Future (Automated)

1. **Phase 1: Semi-automated**
   - Agent generates Maestro tests
   - Human runs them manually
   - Faster than pure manual testing

2. **Phase 2: Automated**
   - Implement macOS watcher script
   - Automatic test execution
   - Human reviews results only

3. **Phase 3: Fully automated**
   - Complete SimAgent system
   - AI-driven verification
   - Human only for final approval

## Tools for Workflow

### Linux Side

```bash
# Rust development
cargo check              # Fast syntax check
cargo build --release    # Build optimized
cargo test               # Run tests
cargo clippy            # Lint
cargo fmt               # Format

# Project navigation
find . -name "*.rs"     # Find Rust files
find . -name "*.swift"  # Find Swift files
```

### macOS Side

```bash
# Xcode command line
xcodebuild -list                        # List schemes
xcodebuild build -scheme Thiccc         # Build
xcodebuild test -scheme Thiccc          # Run tests

# Simulator control
xcrun simctl list                       # List simulators
xcrun simctl boot "iPhone 15 Pro"       # Start simulator
xcrun simctl launch <bundle-id>         # Launch app
xcrun simctl io booted screenshot s.png # Screenshot

# Maestro (future)
maestro test tests/verify.yaml          # Run UI test
```

### Sync Tools

```bash
# Git
git pull origin main    # Sync from remote
git push origin main    # Push changes

# rsync (if using shared filesystem)
rsync -av linux-machine:/workspace/ /Users/dev/workspace/

# GitHub CLI
gh repo sync            # Sync fork
```

## Example: End-to-End Flow

### Scenario: Implementing Phase 6, Sub-task 6.1.1

**1. Linux Agent (2 minutes)**
```bash
# Write WorkoutView.swift
# Write verification test (Maestro YAML)
# Test Rust code
cargo test

# Generate checklist
# Commit code
git add .
git commit -m "feat: implement WorkoutView empty/active states"
git push origin phase-6-dev
```

**2. macOS Human (5 minutes)**
```bash
# Sync code
git pull origin phase-6-dev

# Build
xcodebuild build -scheme Thiccc

# Run simulator and test
# Follow agent's checklist

# Report back
# Either: "✅ 6.1.1"
# Or: "❌ 6.1.1: Stats bar not showing"
```

**3. Linux Agent (if issues)**
```bash
# Analyze issue
# Fix code
# Repeat
```

**Total:** ~7 minutes per sub-task

**With SimAgent (future):** ~3 minutes, fully automated!

## Related Docs

- [simagent-ios-automation.md](./simagent-ios-automation.md) - Automated testing vision
- [maestro-appium.md](../testing_strategies/maestro-appium.md) - Testing tools
- [xctest-ui-tests.md](../testing_strategies/xctest-ui-tests.md) - UI testing

---

**Last Updated**: December 6, 2025  
**Status**: Current workflow documentation  
**Goal**: Evolve toward fully automated workflow with SimAgent

