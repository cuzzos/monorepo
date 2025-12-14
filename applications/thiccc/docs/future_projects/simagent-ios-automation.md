# SimAgent: iOS Simulator Automation for AI Agents

## Vision

**SimAgent** is a proposed system that would enable AI agents to automatically test iOS applications by controlling the iOS Simulator, capturing results, and providing feedback - creating a fully automated development and verification loop.

## The Problem

Currently, AI agents (like Cursor agents) can:
- ✅ Write code
- ✅ Compile and run unit tests
- ✅ Read logs and fix errors

But they **cannot**:
- ❌ Launch iOS Simulator
- ❌ Interact with the running app
- ❌ See the rendered UI
- ❌ Verify UI behavior automatically

This creates a **verification gap** where manual human testing is required after every code change.

## The Goal

Enable AI agents to:
1. **Generate** code for a feature
2. **Build** the iOS app
3. **Launch** the simulator
4. **Execute** automated UI tests
5. **Capture** screenshots and results
6. **Analyze** the results
7. **Iterate** if tests fail
8. **Report** success to human

All without human intervention until the feature is complete.

## Architecture

### Option A: Multi-Agent System

```
┌──────────────────────────────────────┐
│    Linux Agent (Cursor/Development)  │
│  - Writes Rust + Swift code          │
│  - Runs Rust tests                   │
│  - Generates test scripts            │
│  - Analyzes results                  │
└────────────┬─────────────────────────┘
             │
             │ Files: code, test scripts, commands
             ▼
┌──────────────────────────────────────┐
│      macOS Agent (Test Runner)       │
│  - Builds iOS app                    │
│  - Launches simulator                │
│  - Runs UI tests                     │
│  - Captures screenshots              │
│  - Returns results                   │
└────────────┬─────────────────────────┘
             │
             │ xcrun simctl commands
             ▼
┌──────────────────────────────────────┐
│         iOS Simulator                │
│  - Runs the app                      │
│  - Renders UI                        │
│  - Executes interactions             │
└──────────────────────────────────────┘
```

### Option B: Single macOS Agent

```
┌──────────────────────────────────────┐
│    macOS Agent (All-in-one)          │
│  - Writes code                       │
│  - Compiles Rust + Swift             │
│  - Runs unit tests                   │
│  - Launches simulator                │
│  - Runs UI tests                     │
│  - Captures + analyzes results       │
└────────────┬─────────────────────────┘
             │
             ▼
┌──────────────────────────────────────┐
│         iOS Simulator                │
└──────────────────────────────────────┘
```

## Implementation Approaches

### Approach 1: Maestro-Based (Recommended)

**Why Maestro:**
- ✅ Simple YAML syntax (easy for AI to generate)
- ✅ CLI-based (scriptable)
- ✅ Built-in screenshot capture
- ✅ Clear pass/fail output
- ✅ No code generation needed

**Workflow:**

```yaml
# 1. Linux agent generates test YAML
# tests/phase-6-1-1-verify.yaml
appId: com.thiccc.app
---
- launchApp
- assertVisible: "Workout"
- tapOn: "Start Workout"
- assertVisible: "Log Workout"
- takeScreenshot: "workout-started"
- tapOn: "Add Exercise"
- assertVisible: "Exercise Library"
- takeScreenshot: "exercise-library"
```

```bash
# 2. macOS agent executes
maestro test tests/phase-6-1-1-verify.yaml --format html

# 3. Parse output
if [ $? -eq 0 ]; then
    echo "✅ Test passed"
else
    echo "❌ Test failed"
    # Screenshots available in ~/.maestro/tests/
fi
```

**Benefits:**
- Simple to implement
- AI-friendly syntax
- Fast iteration
- Good error messages

**Limitations:**
- Less powerful than XCTest
- May not handle complex scenarios
- Limited element querying

### Approach 2: XCTest-Based

**Why XCTest:**
- ✅ Most powerful iOS testing framework
- ✅ Deep integration with Xcode
- ✅ Comprehensive element querying
- ✅ Standard Apple tooling

**Workflow:**

```swift
// 1. Linux agent generates Swift test code
// Tests/Generated/Phase6Task1Tests.swift
import XCTest

final class Phase6Task1Tests: XCTestCase {
    func testWorkoutViewLayout() {
        let app = XCUIApplication()
        app.launch()
        
        XCTAssertTrue(app.buttons["Start Workout"].exists)
        app.buttons["Start Workout"].tap()
        XCTAssertTrue(app.staticTexts["Log Workout"].waitForExistence(timeout: 2))
    }
}
```

```bash
# 2. macOS agent builds and runs
xcodebuild test \
    -project Thiccc.xcodeproj \
    -scheme Thiccc \
    -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
    -only-testing:ThicccUITests/Phase6Task1Tests \
    -resultBundlePath results/

# 3. Parse results
xcrun xcresulttool get --path results/ --format json > results.json

# 4. Analyze JSON
if grep -q "\"status\":\"Success\"" results.json; then
    echo "✅ Test passed"
fi
```

**Benefits:**
- Maximum control
- Comprehensive assertions
- Standard workflow
- Good debugging

**Limitations:**
- More complex for AI to generate
- Slower iteration (compile + link)
- Requires Swift code generation

### Approach 3: Appium-Based

**Why Appium:**
- ✅ Cross-platform (if we add Android later)
- ✅ Multiple language bindings (Python, JS)
- ✅ Industry standard
- ✅ WebDriver protocol

**Workflow:**

```python
# 1. Linux agent generates Python test
# tests/phase_6_1_1.py
from appium import webdriver
from appium.webdriver.common.appiumby import AppiumBy

def test_workout_view():
    driver = webdriver.Remote("http://localhost:4723", {
        "platformName": "iOS",
        "deviceName": "iPhone 15 Pro",
        "app": "/path/to/Thiccc.app"
    })
    
    start_btn = driver.find_element(AppiumBy.ACCESSIBILITY_ID, "startWorkoutButton")
    start_btn.click()
    
    title = driver.find_element(AppiumBy.ACCESSIBILITY_ID, "workoutTitle")
    assert title.text == "Log Workout"
    
    driver.quit()
```

```bash
# 2. macOS agent runs Appium server + test
appium &
APPIUM_PID=$!

pytest tests/phase_6_1_1.py --json-report --json-report-file=results.json

kill $APPIUM_PID

# 3. Parse results.json
```

**Benefits:**
- Good for agents (Python is AI-friendly)
- Cross-platform potential
- Flexible

**Limitations:**
- Complex setup (Appium server)
- Slower than native tools
- Overhead

### Approach 4: Hybrid (Best of All Worlds)

**Strategy:**

1. **Maestro for smoke tests** (fast, simple)
2. **XCTest for comprehensive tests** (thorough)
3. **Screenshot comparison for visual verification**

**Workflow:**

```bash
# Quick smoke test with Maestro
maestro test tests/smoke/phase-6-quick.yaml
if [ $? -ne 0 ]; then
    exit 1
fi

# Comprehensive tests with XCTest
xcodebuild test -scheme Thiccc -only-testing:Phase6Tests

# Visual verification with snapshots
# (if implemented)
```

## Communication Protocol

### File-Based Communication

**Simplest approach:** Use shared filesystem

```
project/
├── .agent-tasks/
│   ├── current-task.json       ← Linux agent writes task
│   ├── test-scripts/           ← Linux agent writes test scripts
│   │   ├── phase-6-1-1.yaml
│   │   └── phase-6-1-2.yaml
│   ├── results/                ← macOS agent writes results
│   │   ├── phase-6-1-1/
│   │   │   ├── status.txt     (PASS/FAIL)
│   │   │   ├── output.txt     (logs)
│   │   │   └── screenshots/
│   │   └── phase-6-1-2/
│   └── status.txt              ← macOS agent status
```

**Linux agent writes:**
```json
// .agent-tasks/current-task.json
{
  "task_id": "phase-6-1-1",
  "test_script": "test-scripts/phase-6-1-1.yaml",
  "expected_screenshots": ["workout-empty", "workout-active"],
  "status": "ready_for_testing"
}
```

**macOS agent reads, executes, writes:**
```json
// .agent-tasks/results/phase-6-1-1/result.json
{
  "task_id": "phase-6-1-1",
  "status": "passed",
  "duration_ms": 3421,
  "screenshots": [
    "screenshots/workout-empty.png",
    "screenshots/workout-active.png"
  ],
  "log": "All assertions passed successfully"
}
```

**Linux agent reads and analyzes:**
```
✅ Task phase-6-1-1 verified successfully
   - Duration: 3.4s
   - All assertions passed
   - Screenshots captured
```

### API-Based Communication (Future)

**More sophisticated:** Web API between agents

```
┌─────────────┐                          ┌─────────────┐
│ Linux Agent │ ─HTTP POST /tasks→       │ macOS Agent │
│             │ ←HTTP GET /results/{id}─ │             │
└─────────────┘                          └─────────────┘
```

## Screenshot Analysis

### Option 1: Human-in-the-Loop

Linux agent can READ screenshots but not interpret them:

```bash
# macOS agent captures
maestro test --format html workflow.yaml
# Screenshots saved

# Linux agent presents to human
echo "📸 Screenshots captured. Please verify:"
ls -1 ~/.maestro/tests/latest/*.png
```

### Option 2: Reference Comparison

Compare against baseline screenshots:

```bash
# First run: Save baseline
cp screenshot.png baselines/phase-6-1-1-workout.png

# Subsequent runs: Compare
compare baselines/phase-6-1-1-workout.png \
        screenshot.png \
        -metric RMSE \
        diff.png 2>&1 | awk '{print $1}'

# If RMSE < threshold, pass
```

### Option 3: AI Vision (Advanced)

Use GPT-4 Vision or similar to analyze screenshots:

```python
# macOS agent captures screenshot
screenshot_path = "workout-view.png"

# Send to vision AI
response = openai.ChatCompletion.create(
    model="gpt-4-vision-preview",
    messages=[{
        "role": "user",
        "content": [
            {"type": "text", "text": "Does this iOS app show a workout tracking view with a 'Start Workout' button, stats bar, and exercise list?"},
            {"type": "image_url", "image_url": f"file://{screenshot_path}"}
        ]
    }]
)

if "yes" in response.choices[0].message.content.lower():
    return "PASS"
```

## Implementation Phases

### Phase 1: Manual Trigger (MVP)

**Goal:** Prove the concept works

1. Linux agent generates Maestro YAML
2. Human runs `maestro test` on macOS
3. Human reports results back to Linux agent

**Effort:** 2-4 hours
**Benefits:** Validates approach, no infra needed

### Phase 2: Semi-Automated

**Goal:** Reduce human intervention

1. Linux agent generates tests + saves to file
2. Separate macOS agent (or script) watches for new tests
3. macOS agent auto-runs tests when detected
4. macOS agent saves results to shared directory
5. Linux agent reads results and continues

**Effort:** 1-2 days
**Benefits:** Automated execution, still uses filesystem

### Phase 3: Fully Automated

**Goal:** Complete automation

1. Build proper agent coordination (API or message queue)
2. Implement screenshot analysis
3. Add retry logic
4. Error handling and reporting
5. CI/CD integration

**Effort:** 1-2 weeks
**Benefits:** Production-ready system

### Phase 4: Advanced Features

- AI vision for screenshot verification
- Video recording and analysis
- Performance metrics capture
- Automatic bug report generation
- Multi-device testing (different iPhone models)

## Technical Requirements

### macOS Agent Requirements

**Software:**
- macOS (required for iOS Simulator)
- Xcode + Command Line Tools
- iOS Simulator runtime
- Maestro (or Appium, or both)

**Hardware:**
- Mac with M1/M2/M3 (fast simulators)
- At least 16GB RAM
- SSD storage

**Permissions:**
- Accessibility access (for UI automation)
- Developer mode enabled

### Linux Agent Requirements

- Ability to write files to shared location
- Ability to generate test scripts
- Ability to parse JSON/text results

## Example: Complete Workflow

### Scenario: Verify Phase 6, Sub-Task 6.1.1

**1. Linux Agent (Cursor) implements feature:**
```swift
// WorkoutView.swift created
// (code implementation)
```

**2. Linux Agent generates verification test:**
```yaml
# .agent-tasks/test-scripts/phase-6-1-1.yaml
appId: com.thiccc.app
---
# Test empty state
- launchApp
- tapOn: "Workout"
- assertVisible: "Start Workout"
- takeScreenshot: "empty-state"

# Test starting workout
- tapOn: "Start Workout"
- assertVisible: "Log Workout"
- assertVisible: "Duration"
- assertVisible: "Volume"
- assertVisible: "Sets"
- takeScreenshot: "active-workout"

# Test workout name field
- tapOn: "Workout Name"
- inputText: "Push Day"
- assertVisible: "Push Day"
- takeScreenshot: "workout-named"
```

**3. Linux Agent creates task file:**
```json
// .agent-tasks/current-task.json
{
  "task_id": "phase-6-1-1",
  "description": "Verify main workout view structure",
  "test_script": "test-scripts/phase-6-1-1.yaml",
  "status": "ready",
  "created_at": "2025-12-06T15:30:00Z"
}
```

**4. macOS Agent (watcher script) detects new task:**
```bash
#!/bin/bash
# watch-and-test.sh

while true; do
    if [ -f .agent-tasks/current-task.json ]; then
        TASK_ID=$(jq -r '.task_id' .agent-tasks/current-task.json)
        TEST_SCRIPT=$(jq -r '.test_script' .agent-tasks/current-task.json)
        STATUS=$(jq -r '.status' .agent-tasks/current-task.json)
        
        if [ "$STATUS" == "ready" ]; then
            echo "▶️  Running test for $TASK_ID..."
            
            # Update status
            jq '.status = "running"' .agent-tasks/current-task.json > tmp.json
            mv tmp.json .agent-tasks/current-task.json
            
            # Run test
            maestro test ".agent-tasks/$TEST_SCRIPT" \
                --format html \
                > ".agent-tasks/results/$TASK_ID/output.txt" 2>&1
            
            RESULT=$?
            
            # Save result
            mkdir -p ".agent-tasks/results/$TASK_ID"
            if [ $RESULT -eq 0 ]; then
                echo "PASS" > ".agent-tasks/results/$TASK_ID/status.txt"
            else
                echo "FAIL" > ".agent-tasks/results/$TASK_ID/status.txt"
            fi
            
            # Copy screenshots
            cp -r ~/.maestro/tests/latest/*.png \
                ".agent-tasks/results/$TASK_ID/screenshots/" 2>/dev/null
            
            # Update task status
            jq '.status = "complete"' .agent-tasks/current-task.json > tmp.json
            mv tmp.json .agent-tasks/current-task.json
            
            echo "✅ Test complete for $TASK_ID"
        fi
    fi
    
    sleep 2
done
```

**5. Linux Agent checks results:**
```bash
# Linux agent polls for completion
while [ "$(jq -r '.status' .agent-tasks/current-task.json)" != "complete" ]; do
    sleep 1
done

# Read results
RESULT=$(cat .agent-tasks/results/phase-6-1-1/status.txt)

if [ "$RESULT" == "PASS" ]; then
    echo "✅ Sub-task 6.1.1 verified successfully!"
    echo "📸 Screenshots:"
    ls -1 .agent-tasks/results/phase-6-1-1/screenshots/
    
    # Continue to next sub-task
else
    echo "❌ Sub-task 6.1.1 failed"
    echo "📋 Output:"
    cat .agent-tasks/results/phase-6-1-1/output.txt
    
    # Analyze failure and fix
fi
```

## Benefits

- ✅ **Rapid iteration**: No waiting for human verification
- ✅ **Consistency**: Same tests run every time
- ✅ **Confidence**: Automated verification catches regressions
- ✅ **Documentation**: Tests serve as executable specs
- ✅ **Scalability**: Can run many tests in parallel
- ✅ **24/7 Development**: Agent can work overnight

## Challenges

- ⚠️ **Setup complexity**: Requires macOS machine
- ⚠️ **Flakiness**: UI tests can be unreliable
- ⚠️ **Maintenance**: Tests need updates when UI changes
- ⚠️ **Debugging**: Hard to debug agent-generated tests
- ⚠️ **Cost**: May require dedicated Mac hardware

## Next Steps

1. **Prototype**: Implement Phase 1 (manual trigger)
2. **Validate**: Run a few test scenarios
3. **Iterate**: Build Phase 2 (semi-automated)
4. **Scale**: Add more test coverage
5. **Productionize**: Build Phase 3 (fully automated)

## Related Docs

- [maestro-appium.md](../testing_strategies/maestro-appium.md) - Testing tools overview
- [xctest-ui-tests.md](../testing_strategies/xctest-ui-tests.md) - XCTest details
- [development-workflow.md](./development-workflow.md) - Linux/macOS split workflow

---

**Last Updated**: December 6, 2025  
**Status**: Vision document for future implementation  
**Recommendation**: Start with Maestro-based MVP (Phase 1)

