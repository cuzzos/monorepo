# Maestro - Mobile UI Testing

## Overview

**Maestro** is a simple, declarative mobile UI testing framework that uses **YAML** instead of code. It's designed to be easy to read, write, and maintain.

**Website:** https://maestro.mobile.dev/  
**GitHub:** https://github.com/mobile-dev-inc/maestro

Maestro is ideal for AI agent-generated tests, smoke tests, and capturing animations on video for review.

## Pros & Cons

### Advantages

- ✅ **Extremely easy to learn** - YAML syntax is readable by non-programmers
- ✅ **Fast to write** - Very concise test definitions
- ✅ **AI agent-friendly** - Perfect for LLM-generated tests
- ✅ **Cross-platform** - Same tests work on iOS and Android with minimal changes
- ✅ **CLI-based** - Easy to automate in scripts and CI/CD pipelines
- ✅ **Built-in smart waits** - Handles async operations and animations well
- ✅ **Visual reports** - Generates HTML reports with screenshots automatically
- ✅ **Video recording** - Captures animations and interactions for review
- ✅ **Low maintenance** - Simple YAML is easy to update when UI changes
- ✅ **No coding required** - Non-developers can write tests
- ✅ **Quick setup** - Install via Homebrew, start testing immediately

### Limitations

- ❌ **Less powerful** - Not as feature-rich as XCTest for complex scenarios
- ❌ **Limited flexibility** - YAML constraints make complex logic difficult
- ❌ **Harder debugging** - No breakpoints, less visibility into failures
- ❌ **Limited element selection** - Fewer query options compared to native tools
- ❌ **Newer tool** - Smaller community and fewer resources than XCTest
- ❌ **Still requires macOS** - For iOS testing (though works on Linux for Android)
- ❌ **YAML verbosity** - Complex flows can result in messy YAML files
- ❌ **Limited assertions** - Basic visibility checks, not comprehensive validations

### Best Use Cases

- ✅ Smoke tests and sanity checks
- ✅ Critical path validation
- ✅ Quick verification after deployments
- ✅ AI agent-generated tests
- ✅ Animation review via video recording
- ✅ Non-technical team member contributions
- ✅ Cross-platform testing scenarios (if Android shell is added later)

## Installation

```bash
# Install via Homebrew (macOS)
brew tap mobile-dev-inc/tap
brew install maestro

# Or via curl
curl -Ls "https://get.maestro.mobile.dev" | bash

# Verify installation
maestro --version
```

## Basic Example

```yaml
# workout-flow.yaml
appId: com.thiccc.app
---
# Launch the app
- launchApp

# Start a workout
- tapOn: "Start Workout"
- assertVisible: "Log Workout"

# Enter workout name
- tapOn: "Workout Name"
- inputText: "Leg Day"

# Add an exercise
- tapOn: "Add Exercise"
- assertVisible: "Exercise Library"
- tapOn: "Bench Press"

# Add a set
- tapOn: "Add Set"
- assertVisible: 
    id: "set_0_weight"

# Enter weight
- tapOn:
    id: "set_0_weight"
- inputText: "225"

# Enter reps
- tapOn:
    id: "set_0_reps"
- inputText: "5"

# Mark complete
- tapOn:
    id: "set_0_complete"

# Verify stats updated
- assertVisible: "Volume"
- assertVisible: "1125 lbs"

# Finish workout
- tapOn: "Finish"
- assertVisible: "Start Workout"

# Verify in history
- tapOn: "History"
- assertVisible: "Leg Day"
```

## Running Tests

```bash
# Run a test flow
maestro test workout-flow.yaml

# Run all tests in a directory
maestro test flows/

# Run on specific device
maestro test --device "iPhone 15 Pro" workout-flow.yaml

# Record video while testing (IMPORTANT for animation review!)
maestro test --video workout-flow.yaml

# Generate HTML report
maestro test --format html workout-flow.yaml

# Continuous mode (watch for changes)
maestro test --continuous workout-flow.yaml
```

## Advanced Features

### Conditional Logic

```yaml
- tapOn: "Start Workout"
- assertVisible:
    text: "Log Workout"
    timeout: 5000  # Wait up to 5 seconds

# If element exists, do something
- runFlow:
    when:
      visible: "Add Exercise"
    commands:
      - tapOn: "Add Exercise"
```

### Scrolling

```yaml
# Scroll until element is visible
- scrollUntilVisible:
    element:
      text: "Bench Press"
    direction: DOWN
    timeout: 10000

# Scroll in specific container
- scrollUntilVisible:
    element:
      text: "Squats"
    container:
      id: "exerciseList"
```

### Variables and Loops

```yaml
# Define variables
- tapOn: "Workout Name"
- inputText: "${WORKOUT_NAME}"

# Run commands multiple times
- repeat:
    times: 3
    commands:
      - tapOn: "Add Set"
      - inputText: "225"
```

### Screenshots

```yaml
# Take a screenshot at any point
- takeScreenshot: "workout-started"

# Screenshots are automatically saved in test reports
```

### Wait for Element

```yaml
# Wait for element to appear
- assertVisible:
    text: "Loading..."
    timeout: 2000

# Wait for element to disappear
- assertNotVisible:
    text: "Loading..."
    timeout: 10000
```

## Use Cases for Thiccc

### 1. Smoke Tests

Quick validation that core features work:

```yaml
# smoke-test.yaml - Quick validation that core features work
appId: com.thiccc.app
---
- launchApp
- assertVisible: "Workout"
- assertVisible: "History"
- tapOn: "Start Workout"
- assertVisible: "Log Workout"
- tapOn: "Discard Workout"
- assertVisible: "Start Workout"
```

### 2. Animation Review

Capture animations for manual review:

```yaml
# animation-review.yaml
appId: com.thiccc.app
---
- launchApp
- takeScreenshot: "initial-state"

# Test workout start animation
- tapOn: "Start Workout"
- takeScreenshot: "workout-started"

# Test adding exercise animation
- tapOn: "Add Exercise"
- takeScreenshot: "exercise-sheet"
- tapOn: "Bench Press"
- takeScreenshot: "exercise-added"

# Test completing set animation
- tapOn: "Add Set"
- tapOn:
    id: "set_0_complete"
- takeScreenshot: "set-completed"
```

Run with video:
```bash
maestro test --video animation-review.yaml
# Review the video to check animation quality!
```

### 3. Critical User Flow

Test the complete workout flow:

```yaml
# complete-workout-flow.yaml
appId: com.thiccc.app
---
- launchApp

# Start workout
- tapOn: "Start Workout"
- assertVisible: "Log Workout"

# Add exercise
- tapOn: "Add Exercise"
- tapOn: "Bench Press"

# Add 3 sets
- repeat:
    times: 3
    commands:
      - tapOn: "Add Set"
      - tapOn:
          id: "set_${index}_weight"
      - inputText: "225"
      - tapOn:
          id: "set_${index}_reps"
      - inputText: "5"
      - tapOn:
          id: "set_${index}_complete"

# Finish workout
- tapOn: "Finish"
- assertVisible: "Start Workout"

# Verify in history
- tapOn: "History"
- assertVisible: "Bench Press"
```

## AI Agent Integration

Maestro is perfect for AI agent automation:

### Workflow

1. **Agent generates YAML test:**

```yaml
appId: com.thiccc.app
---
- launchApp
- tapOn: "Start Workout"
- assertVisible: "Log Workout"
```

2. **Save to file:** `tests/maestro/verify-phase-6-1-1.yaml`

3. **macOS agent runs:**

```bash
maestro test tests/maestro/verify-phase-6-1-1.yaml
```

4. **Parse output:**

```
✅ Flow completed successfully
```

5. **Report back:**
"✅ Sub-task 6.1.1 verified automatically"

### Benefits for Agents

- YAML is easy for LLMs to generate
- Simple CLI interface
- Clear pass/fail output
- Screenshot artifacts for debugging
- Video recording for animation verification

## CI/CD Integration

```yaml
# .github/workflows/test.yml
name: Maestro Tests
on: [push, pull_request]

jobs:
  maestro-tests:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install Maestro
        run: |
          brew tap mobile-dev-inc/tap
          brew install maestro
      
      - name: Run Maestro tests
        run: |
          maestro test tests/maestro/
      
      - name: Upload test results
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: maestro-results
          path: |
            **/*.mp4
            **/*.png
```

## Getting Started with Thiccc

```bash
# 1. Install Maestro
brew install maestro

# 2. Create test directory
mkdir -p tests/maestro

# 3. Create your first test
cat > tests/maestro/smoke-test.yaml << 'EOF'
appId: com.thiccc.app
---
- launchApp
- assertVisible: "Workout"
- tapOn: "Start Workout"
- assertVisible: "Log Workout"
- tapOn: "Discard Workout"
EOF

# 4. Build and run your app in the simulator

# 5. Run the test
maestro test tests/maestro/smoke-test.yaml

# 6. Run with video to review animations
maestro test --video tests/maestro/smoke-test.yaml
```

## Troubleshooting

### Element Not Found

```yaml
# Problem: Element not found
- tapOn: "Start Workout"

# Solution 1: Add explicit wait
- assertVisible:
    text: "Start Workout"
    timeout: 10000
- tapOn: "Start Workout"

# Solution 2: Use accessibility ID
- tapOn:
    id: "startWorkoutButton"
```

### Timing Issues

```yaml
# Problem: Animation hasn't finished
- tapOn: "Add Exercise"
- tapOn: "Bench Press"  # Might fail if sheet is still animating

# Solution: Wait for specific element
- tapOn: "Add Exercise"
- assertVisible:
    text: "Exercise Library"
    timeout: 5000
- tapOn: "Bench Press"
```

### Test Flakiness

1. **Add explicit waits** for animations
2. **Use accessibility IDs** instead of text
3. **Increase timeout** for slow operations
4. **Check video recordings** to see what actually happened

## Best Practices

### 1. Use Accessibility Identifiers

```yaml
# ✅ Good - stable
- tapOn:
    id: "startWorkoutButton"

# ❌ Bad - breaks if text changes
- tapOn: "Start Workout"
```

### 2. Test One Thing Per Flow

```yaml
# ✅ Good - focused
# test-start-workout.yaml
- launchApp
- tapOn: "Start Workout"
- assertVisible: "Log Workout"

# ❌ Bad - too much
# test-everything.yaml (200 lines)
```

### 3. Record Videos for Animation Review

```bash
# ALWAYS use --video when testing animations
maestro test --video animation-test.yaml
```

### 4. Use Descriptive File Names

```
tests/maestro/
├── smoke-test.yaml
├── complete-workout-flow.yaml
├── add-multiple-exercises.yaml
├── discard-workout.yaml
└── animation-review.yaml
```

### 5. Add Comments

```yaml
appId: com.thiccc.app
---
# Verify app launches
- launchApp

# Start a new workout
- tapOn: "Start Workout"
- assertVisible: "Log Workout"

# Clean up
- tapOn: "Discard Workout"
```

## Resources

- [Official Documentation](https://maestro.mobile.dev/getting-started/installation)
- [Examples Repository](https://github.com/mobile-dev-inc/maestro/tree/main/maestro-test)
- [Best Practices](https://maestro.mobile.dev/best-practices)
- [Maestro Cloud](https://cloud.mobile.dev/) - Cloud-based test execution

## Related Docs

- [xctest-ui-tests.md](./xctest-ui-tests.md) - Native iOS testing for deeper test coverage
- [README.md](./README.md) - Overall testing strategy

---

**Last Updated**: December 7, 2025  
**Status**: Recommended testing tool for Thiccc  
**Recommendation**: Primary tool for smoke tests, AI agent verification, and animation review


