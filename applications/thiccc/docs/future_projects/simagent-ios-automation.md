# SimAgent: iOS Simulator Automation for AI Agents

## Vision

**SimAgent** is a proposed system that enables AI agents to automatically test iOS applications by controlling the iOS Simulator, capturing results, and providing intelligent visual feedback - creating a fully autonomous development and verification loop.

**Key Differentiator:** Unlike traditional UI testing, SimAgent leverages **AI Vision (GPT-4 Vision)** to automatically detect visual bugs, layout issues, and animation problems that traditional assertions miss.

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

## Implementation Approach

### Maestro-Based (Our Choice)

**Why Maestro is the clear winner:**
- ✅ **Simple YAML syntax** - Easy for AI agents to generate
- ✅ **Fast execution** - 5-7 seconds per test (vs 30-45s for XCTest with compilation)
- ✅ **Video recording built-in** - Captures animations automatically (`maestro test --video`)
- ✅ **More reliable** - Smart waits, less flaky than XCTest UI (which has 5-20% flake rate)
- ✅ **No compilation overhead** - Just run, no build step needed
- ✅ **CLI-based** - Easy to script and automate
- ✅ **Cross-platform ready** - Works on iOS and Android (if we add Android shell later)

**Maestro Workflow:**

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
# 2. macOS agent executes (Phase 3+)
maestro test tests/phase-6-1-1-verify.yaml --video --format html

# 3. Parse output
if [ $? -eq 0 ]; then
    echo "✅ Test passed"
    # Video saved to ~/.maestro/tests/latest/
else
    echo "❌ Test failed"
    # Screenshots and video available for debugging
fi
```

**Performance Metrics:**
- Simple test (5 interactions): ~5-7 seconds
- Complex flow (20+ interactions): ~15-30 seconds
- **No compilation overhead** - tests run immediately

**Benefits:**
- ✅ Simple to implement
- ✅ AI-friendly syntax (YAML is perfect for LLMs)
- ✅ Fast iteration (no build step)
- ✅ Good error messages with screenshots
- ✅ Video recording for animation review
- ✅ More reliable than XCTest UI (built-in smart waits)

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

### Option 3: AI Vision (THE GAME-CHANGER)

Use GPT-4 Vision or similar to analyze screenshots and videos - **this is what makes SimAgent truly autonomous**.

**Basic Screenshot Analysis:**
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

**Advanced Visual Verification (The Real Power):**
```python
# Detailed analysis for bugs traditional assertions miss
prompt = """
Analyze this iOS workout app screenshot for issues:

1. Layout: Are all elements within screen bounds?
2. Colors: Is the primary button iOS blue (#007AFF)?
3. Spacing: Is there consistent padding (16pt)?
4. Typography: Are font sizes readable (body: 17pt, title: 28pt)?
5. Alignment: Are elements properly aligned?
6. Accessibility: Is contrast ratio sufficient (4.5:1 minimum)?

Report any issues found with specific details.
"""

response = openai.ChatCompletion.create(
    model="gpt-4-vision-preview",
    messages=[{
        "role": "user",
        "content": [
            {"type": "text", "text": prompt},
            {"type": "image_url", "image_url": f"file://{screenshot_path}"}
        ]
    }]
)

# Example response:
# "Issue found: Start Workout button extends beyond right screen edge by ~20pt.
#  Primary button color is #808080 (gray) instead of #007AFF (iOS blue)."

if "issue found" in response.choices[0].message.content.lower():
    # Send specific feedback to AI agent for automatic fix
    return {"status": "FAIL", "issues": response.choices[0].message.content}
else:
    return {"status": "PASS"}
```

**Video Analysis for Animations:**
```python
# Analyze Maestro-recorded video
video_path = "~/.maestro/tests/latest/recording.mp4"

prompt = """
Analyze this iOS app UI test video for animation quality:

1. Frame rate: Are animations smooth (60fps)?
2. Transitions: Do views slide in smoothly or jump?
3. Button feedback: Do buttons have proper tap animations?
4. Scrolling: Is list scrolling smooth without jank?
5. Loading states: Are there smooth loading indicators?

Rate animation quality and report any jank or stuttering.
"""

# GPT-4 Vision can analyze video frames
# Returns detailed feedback on animation quality
```

**Why This Is Revolutionary:**

**Traditional Testing:**
```yaml
- tapOn: "Start Workout"
- assertVisible: "Log Workout"  # ✅ Test passes
```
But the button might be:
- Wrong color ❌ (gray instead of blue)
- Outside screen bounds ❌ (extends off right edge)
- Wrong size ❌ (too small to tap easily)
- **Human has to catch these manually**

**AI Vision Testing:**
```yaml
- tapOn: "Start Workout"
- assertVisible: "Log Workout"  # ✅ Test passes
# PLUS AI Vision analysis:
# ❌ Detected: Button color #808080 should be #007AFF
# ❌ Detected: Button extends 20pt beyond screen bounds
# ❌ Detected: Button height 32pt below minimum tap target 44pt
```
**AI agent automatically fixes issues and retests** ✅

## Implementation Phases

### Phase 1: Manual Testing (Current)

**Goal:** Current state - validate 100% Rust coverage works

**Status:** ✅ **Active**

**What works:**
- AI agent writes Rust code
- `make coverage-check` ensures 100% line coverage
- Human manually tests UI in simulator
- Human reports results back
- Agent iterates

**Limitations:**
- Human is bottleneck for UI verification
- Slow iteration (manual clicking)
- No repeatable tests

---

### Phase 2: Semi-Automated with Maestro (Next Milestone)

**Goal:** Validate AI agents can generate good Maestro YAML tests

**Status:** 🎯 **High Priority**

**Implementation:**
1. AI agent generates Maestro YAML tests
2. Human runs: `maestro test tests/maestro/test-name.yaml --video`
3. Test provides clear pass/fail
4. Human reviews video for animation quality
5. Human reports: "✅ passed" or "❌ failed: [error]"

**Success Criteria:**
- AI agent can generate valid Maestro YAML
- Tests are reliable (not flaky)
- Tests catch real bugs
- Video recordings are useful for debugging

**Effort:** 2-4 days
**Benefits:** 
- Repeatable tests (can re-run anytime)
- Faster feedback (one command vs manual testing)
- Executable documentation
- Video artifacts for animation review

**Next Steps:**
- Create first Maestro test for a simple flow
- Document patterns for AI agent to follow
- Build library of common test scenarios

---

### Phase 3: Automated Test Execution (Weeks)

**Goal:** Tests run automatically without human intervention

**Status:** 🔮 **Future**

**Implementation:**
1. File-based communication:
   ```
   .agent-tasks/
   ├── maestro-tests/          ← AI agent writes YAML
   └── results/                ← macOS watcher writes results
       └── test-name/
           ├── status.txt      (PASS/FAIL)
           ├── output.txt      (logs)
           └── video.mp4       (recording)
   ```

2. macOS watcher script detects new tests
3. Automatically builds app: `make xcode-build`
4. Runs Maestro test: `maestro test --video <test.yaml>`
5. Saves results (status, logs, video)
6. AI agent reads results and continues

**Requirements:**
- Shared filesystem (Dropbox, git sync, network share)
- macOS machine always available (can be headless)
- Watcher script running as daemon

**Effort:** 1-2 weeks
**Benefits:**
- No human needed for test execution
- Agent works overnight
- Fast iteration (5-10 seconds per test)
- Video artifacts for debugging

---

### Phase 4: AI Vision Integration (THE GAME-CHANGER)

**Goal:** Fully autonomous development with visual verification

**Status:** 🌟 **Vision (Months)**

**Implementation:**

1. **AI Vision Analysis**
   - Analyze screenshots/videos with GPT-4 Vision
   - Detect layout bugs (elements outside bounds)
   - Verify colors, spacing, typography
   - Check accessibility (contrast ratios)
   - Measure animation quality (detect jank)

2. **Intelligent Feedback Loop**
   ```
   1. AI implements feature
   2. Maestro test runs automatically
   3. Test passes ✅ but...
   4. AI Vision detects: "Button #808080 should be #007AFF"
   5. AI agent fixes color automatically
   6. Retest → Vision confirms: "Color correct" ✅
   ```

3. **Multi-Device Testing**
   - Parallel tests: iPhone SE, iPhone 15 Pro, iPhone 15 Pro Max
   - AI Vision catches: "Layout breaks on iPhone SE (button off-screen)"
   - AI agent fixes responsive layout
   - Retests on all devices

4. **Animation Quality Verification**
   - Analyze Maestro video recordings
   - Detect janky animations (dropped frames)
   - Measure scroll performance
   - Verify smooth transitions

**Effort:** Months (but highest value!)
**Benefits:**
- **Fully autonomous agent** - No human needed for visual QA
- **24/7 development** - Works while you sleep
- **Higher quality** - Catches visual bugs humans miss
- **Scales infinitely** - Test multiple features in parallel
- **Consistent quality** - No "looks good to me" - objective standards

**The Revolutionary Part:**
Without AI Vision: Test passes ✅ but button is wrong color ❌ (human catches later)
With AI Vision: Test passes ✅ AND AI detects color issue ✅ AND fixes automatically ✅

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

## Challenges & Mitigations

### Challenge 1: Requires macOS Machine
- **Reality:** iOS Simulator only runs on macOS
- **Mitigation:** Phase 2-3 can use existing Mac, Phase 4 may need dedicated hardware
- **Cost:** Mac Mini M2 (~$600) can run 24/7

### Challenge 2: Test Flakiness
- **Old problem:** XCTest UI has 5-20% flake rate
- **Our solution:** Maestro has built-in smart waits, much more reliable
- **Mitigation:** Start simple (smoke tests), gradually add complexity

### Challenge 3: Test Maintenance
- **Reality:** UI changes break tests
- **Mitigation:** 
  - Phase 2-3: Update tests manually (low volume)
  - Phase 4: AI agent can regenerate tests automatically
- **Strategy:** Keep tests focused on critical paths only

### Challenge 4: Debugging Agent-Generated Tests
- **Mitigation:** 
  - Maestro YAML is human-readable
  - Video recordings show exactly what happened
  - Clear error messages point to failure point
  - AI Vision (Phase 4) provides specific feedback

### Challenge 5: AI Vision API Costs
- **Reality:** GPT-4 Vision API has per-image costs
- **Mitigation:** 
  - Use selectively (after Maestro test passes)
  - Cache results for unchanged screens
  - Only analyze critical screens
- **Cost estimate:** ~$0.01-0.10 per screenshot (reasonable for high value)

## Current Focus: Phase 2 Implementation

### Immediate Next Steps

1. **Install Maestro** (if not already installed)
   ```bash
   brew install maestro
   maestro --version
   ```

2. **Create First Test** - Simple smoke test
   ```yaml
   # tests/maestro/smoke-test.yaml
   appId: com.cuzzos.Thiccc.Thiccc
   ---
   - launchApp
   - assertVisible: "Workout"
   - tapOn: "Start Workout"
   - assertVisible: "Log Workout"
   ```

3. **Build App and Run Test**
   ```bash
   make xcode-build
   maestro test tests/maestro/smoke-test.yaml --video
   ```

4. **Validate Workflow**
   - Can AI agent generate valid YAML?
   - Are tests reliable?
   - Is video recording useful?

5. **Document Patterns**
   - Common test scenarios (start workout, add exercise, etc.)
   - Accessibility identifier conventions
   - Best practices for stable tests

### Success Metrics for Phase 2

- ✅ AI agent generates valid Maestro YAML 90%+ of the time
- ✅ Tests are reliable (< 5% flake rate)
- ✅ Tests catch real UI bugs
- ✅ Video recordings help debug failures
- ✅ Human time reduced from 5 minutes → 30 seconds per test

### After Phase 2 Success → Phase 3

Once Phase 2 is working well:
- Build watcher script for automated execution
- Set up shared filesystem for agent communication
- Implement file-based protocol

### Long-term Vision → Phase 4

Once Phase 3 is stable:
- Integrate GPT-4 Vision API
- Build intelligent feedback loop
- Enable fully autonomous testing

## Related Documentation

### Testing Strategy
- **[../testing_strategies/README.md](../testing_strategies/README.md)** - Complete testing strategy
- **[../testing_strategies/maestro.md](../testing_strategies/maestro.md)** - Maestro guide and examples
- **[../testing_strategies/COVERAGE-QUICK-START.md](../testing_strategies/COVERAGE-QUICK-START.md)** - Rust coverage requirements

### Current Testing Requirements
- **[../../.cursor/rules/rust-coverage.mdc](../../.cursor/rules/rust-coverage.mdc)** - 100% coverage mandate
- **[../../Makefile](../../Makefile)** - Coverage commands and iOS build targets

### Workflow
- **[development-workflow.md](./development-workflow.md)** - Linux + macOS split workflow
- **[README.md](./README.md)** - Future projects overview and roadmap

---

**Last Updated**: December 13, 2025  
**Status**: Active development - Phase 2 is next milestone  
**Recommendation**: Focus on Maestro YAML generation and validation  
**Key Insight**: AI Vision (Phase 4) is the game-changer that enables true autonomy

