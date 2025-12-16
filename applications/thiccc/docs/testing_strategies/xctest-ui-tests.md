# XCTest UI Tests

## Overview

**XCTest** is Apple's official testing framework for iOS, macOS, watchOS, and tvOS. **UI Tests** are automated tests that interact with your app's user interface like a real user would.

## Pros & Cons

### Advantages

- ✅ **Native integration** - Built into Xcode, no extra setup required
- ✅ **Powerful** - Full access to iOS-specific features and APIs
- ✅ **Fast execution** - Direct communication with app via Accessibility API
- ✅ **Excellent debugging** - Xcode integration, view hierarchy inspector, breakpoints
- ✅ **Stable and mature** - Well-maintained by Apple, battle-tested
- ✅ **Type-safe** - Swift code with full IDE support and autocomplete
- ✅ **CI/CD ready** - Easy to integrate into pipelines with xcodebuild
- ✅ **Comprehensive** - Can test complex interactions and workflows
- ✅ **Official support** - Apple documentation and WWDC sessions

### Limitations

- ❌ **Requires macOS + Xcode** - Cannot run on Linux or Windows
- ❌ **iOS only** - No cross-platform benefits (separate tests needed for Android)
- ❌ **Slower than unit tests** - Must launch full app (5-30 seconds per test)
- ❌ **Can be flaky** - Timing issues, animations, race conditions
- ❌ **Black box testing** - Cannot directly access or set internal app state
- ❌ **Higher maintenance** - UI changes break tests frequently
- ❌ **Not AI agent-friendly** - Requires Swift knowledge and understanding of XCTest APIs
- ❌ **Verbose** - More code required compared to declarative alternatives like Maestro

### Best Use Cases

- Deep iOS-specific testing
- Developer-written tests
- Integration with Xcode workflow
- Complex user flow validation
- Tests requiring fine-grained control

## Architecture

```
┌─────────────────────────────────────┐
│       XCTest UI Test Process        │
│  (Separate process from app)        │
│                                     │
│  • Finds UI elements                │
│  • Simulates user interactions      │
│  • Asserts expected outcomes        │
└──────────────┬──────────────────────┘
               │ Accessibility API
               ▼
┌─────────────────────────────────────┐
│         Your App Process            │
│                                     │
│  • Runs in simulator/device         │
│  • UI elements exposed via          │
│    accessibility identifiers        │
└─────────────────────────────────────┘
```

## Basic Example

```swift
import XCTest

final class ThicccUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    func testStartWorkout() throws {
        // 1. Find the "Start Workout" button
        let startButton = app.buttons["Start Workout"]
        
        // 2. Assert it exists
        XCTAssertTrue(startButton.exists, "Start Workout button should exist")
        
        // 3. Tap it
        startButton.tap()
        
        // 4. Verify the workout view appears
        let workoutTitle = app.staticTexts["Log Workout"]
        XCTAssertTrue(workoutTitle.exists, "Workout title should appear after starting workout")
        
        // 5. Verify stats bar appears
        let durationStat = app.staticTexts["Duration"]
        XCTAssertTrue(durationStat.exists, "Duration stat should be visible")
    }
}
```

## Key Concepts

### 1. UI Element Queries

XCTest finds elements using queries:

```swift
// Buttons
app.buttons["Start Workout"]
app.buttons.element(boundBy: 0) // First button

// Text fields
app.textFields["Workout Name"]
app.textFields.element(matching: .textField, identifier: "exerciseName")

// Static text
app.staticTexts["Log Workout"]

// Tables and cells
app.tables.cells.element(boundBy: 0)
app.tables.cells.containing(.staticText, identifier: "Bench Press")

// Navigation bars
app.navigationBars["Workout"]

// Tabs
app.tabBars.buttons["History"]

// Switches
app.switches["Enable Rest Timer"]

// Sliders
app.sliders["Volume"]

// Pickers
app.pickers["Exercise Type"]
```

### 2. Element Properties

Check element state:

```swift
let button = app.buttons["Finish"]

// Existence
XCTAssertTrue(button.exists)

// Enabled state
XCTAssertTrue(button.isEnabled)

// Selected state
XCTAssertTrue(button.isSelected)

// Hittable (visible and can be tapped)
XCTAssertTrue(button.isHittable)

// Label (accessibility label)
XCTAssertEqual(button.label, "Finish Workout")

// Value (accessibility value)
XCTAssertEqual(app.textFields["reps"].value as? String, "5")
```

### 3. User Interactions

Simulate user actions:

```swift
// Tap
app.buttons["Add Exercise"].tap()

// Double tap
app.cells.element(boundBy: 0).doubleTap()

// Long press
app.cells.element(boundBy: 0).press(forDuration: 2.0)

// Swipe
app.cells.element(boundBy: 0).swipeLeft()
app.swipeUp() // Scroll up

// Type text
let nameField = app.textFields["Workout Name"]
nameField.tap()
nameField.typeText("Leg Day")

// Clear and type
nameField.tap()
nameField.doubleTap() // Select all
app.keys["delete"].tap()
nameField.typeText("Push Day")

// Pinch (zoom)
app.pinch(withScale: 2.0, velocity: 1.0)
```

### 4. Waiting for Elements

UI tests need to wait for asynchronous operations:

```swift
// Wait for element to exist (recommended)
let saveButton = app.buttons["Save"]
let exists = saveButton.waitForExistence(timeout: 5.0)
XCTAssertTrue(exists, "Save button should appear within 5 seconds")

// Legacy: Use expectations
let predicate = NSPredicate(format: "exists == true")
let expectation = XCTNSPredicateExpectation(predicate: predicate, object: saveButton)
wait(for: [expectation], timeout: 5.0)

// Wait for element to disappear
let loadingSpinner = app.activityIndicators["Loading"]
XCTAssertTrue(loadingSpinner.waitForExistence(timeout: 2.0))
wait(for: [XCTNSPredicateExpectation(
    predicate: NSPredicate(format: "exists == false"),
    object: loadingSpinner
)], timeout: 10.0)
```

### 5. Accessibility Identifiers

Best practice: Use explicit accessibility identifiers (not visible text):

```swift
// In SwiftUI
Button("Start Workout") {
    // action
}
.accessibilityIdentifier("startWorkoutButton")

TextField("Workout Name", text: $name)
    .accessibilityIdentifier("workoutNameField")

// In XCTest
app.buttons["startWorkoutButton"].tap()
app.textFields["workoutNameField"].typeText("Leg Day")
```

Why? Text can change (localization, design), but IDs stay stable.

## Complete Test Example for Thiccc

```swift
import XCTest

final class WorkoutFlowUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"] // Optional: flag for test mode
        app.launch()
    }
    
    override func tearDown() {
        app = nil
        super.tearDown()
    }
    
    func testCompleteWorkoutFlow() throws {
        // 1. Start on Workout tab
        XCTAssertTrue(app.tabBars.buttons["Workout"].isSelected)
        
        // 2. Start a new workout
        let startButton = app.buttons["startWorkoutButton"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 2.0))
        startButton.tap()
        
        // 3. Verify active workout UI appears
        let workoutTitle = app.staticTexts["Log Workout"]
        XCTAssertTrue(workoutTitle.waitForExistence(timeout: 2.0))
        
        // 4. Enter workout name
        let nameField = app.textFields["workoutNameField"]
        XCTAssertTrue(nameField.exists)
        nameField.tap()
        nameField.typeText("Push Day")
        
        // 5. Add an exercise
        let addExerciseButton = app.buttons["addExerciseButton"]
        addExerciseButton.tap()
        
        // 6. Wait for exercise library sheet
        let exerciseLibrary = app.navigationBars["Exercise Library"]
        XCTAssertTrue(exerciseLibrary.waitForExistence(timeout: 2.0))
        
        // 7. Select an exercise
        let benchPress = app.tables.cells.containing(.staticText, identifier: "Bench Press").firstMatch
        XCTAssertTrue(benchPress.waitForExistence(timeout: 2.0))
        benchPress.tap()
        
        // 8. Add a set
        let addSetButton = app.buttons.matching(identifier: "addSetButton").firstMatch
        XCTAssertTrue(addSetButton.waitForExistence(timeout: 2.0))
        addSetButton.tap()
        
        // 9. Enter set data
        let weightField = app.textFields["set0_weight"]
        XCTAssertTrue(weightField.exists)
        weightField.tap()
        weightField.typeText("225")
        
        let repsField = app.textFields["set0_reps"]
        repsField.tap()
        repsField.typeText("5")
        
        let rpeField = app.textFields["set0_rpe"]
        rpeField.tap()
        rpeField.typeText("8")
        
        // 10. Mark set complete
        let completeButton = app.buttons["set0_complete"]
        completeButton.tap()
        XCTAssertTrue(completeButton.isSelected)
        
        // 11. Verify stats updated
        let volumeStat = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '1125'")).firstMatch
        XCTAssertTrue(volumeStat.exists, "Volume should show 1125 lbs (225 * 5)")
        
        // 12. Finish workout
        let finishButton = app.buttons["finishWorkoutButton"]
        finishButton.tap()
        
        // 13. Verify back to empty state
        XCTAssertTrue(startButton.waitForExistence(timeout: 2.0))
        
        // 14. Verify workout saved (check History tab)
        app.tabBars.buttons["History"].tap()
        let historyWorkout = app.tables.cells.containing(.staticText, identifier: "Push Day").firstMatch
        XCTAssertTrue(historyWorkout.waitForExistence(timeout: 2.0))
    }
    
    func testTabNavigation() throws {
        // Test tab switching
        let workoutTab = app.tabBars.buttons["Workout"]
        let historyTab = app.tabBars.buttons["History"]
        
        XCTAssertTrue(workoutTab.isSelected)
        
        historyTab.tap()
        XCTAssertTrue(historyTab.isSelected)
        XCTAssertFalse(workoutTab.isSelected)
        
        workoutTab.tap()
        XCTAssertTrue(workoutTab.isSelected)
    }
    
    func testDiscardWorkout() throws {
        // Start workout
        app.buttons["startWorkoutButton"].tap()
        
        // Add exercise (abbreviated)
        app.buttons["addExerciseButton"].tap()
        app.tables.cells.firstMatch.tap()
        
        // Discard
        let discardButton = app.buttons["discardWorkoutButton"]
        discardButton.tap()
        
        // Confirm in alert (if there is one)
        let confirmButton = app.alerts.buttons["Discard"]
        if confirmButton.exists {
            confirmButton.tap()
        }
        
        // Verify back to empty state
        XCTAssertTrue(app.buttons["startWorkoutButton"].waitForExistence(timeout: 2.0))
    }
}
```

## Running UI Tests

### From Xcode
1. Open the project in Xcode
2. Select the test target
3. Press `Cmd + U` to run all tests
4. Or: Click the diamond icon next to a test function to run it individually

### From Command Line
```bash
# Run all UI tests
xcodebuild test \
    -project Thiccc.xcodeproj \
    -scheme Thiccc \
    -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
    -only-testing:ThicccUITests

# Run specific test
xcodebuild test \
    -project Thiccc.xcodeproj \
    -scheme Thiccc \
    -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
    -only-testing:ThicccUITests/WorkoutFlowUITests/testCompleteWorkoutFlow
```

### From Fastlane
```ruby
# Fastfile
lane :test_ui do
  run_tests(
    scheme: "Thiccc",
    devices: ["iPhone 15 Pro"],
    only_testing: ["ThicccUITests"]
  )
end
```

## Best Practices

### 1. Use Accessibility Identifiers
```swift
// ✅ Good
.accessibilityIdentifier("startWorkoutButton")
app.buttons["startWorkoutButton"].tap()

// ❌ Bad (fragile)
app.buttons["Start Workout"].tap() // Breaks if text changes
```

### 2. Wait for Elements
```swift
// ✅ Good
let button = app.buttons["save"]
XCTAssertTrue(button.waitForExistence(timeout: 5.0))
button.tap()

// ❌ Bad (flaky)
app.buttons["save"].tap() // May not exist yet
```

### 3. Single Responsibility Tests
```swift
// ✅ Good - tests one thing
func testStartWorkout() {
    app.buttons["startWorkoutButton"].tap()
    XCTAssertTrue(app.staticTexts["Log Workout"].exists)
}

// ❌ Bad - tests too much
func testEverything() {
    // 100 lines testing entire app
}
```

### 4. Arrange-Act-Assert Pattern
```swift
func testAddExercise() {
    // Arrange: Set up initial state
    app.buttons["startWorkoutButton"].tap()
    
    // Act: Perform the action
    app.buttons["addExerciseButton"].tap()
    app.tables.cells.firstMatch.tap()
    
    // Assert: Verify the outcome
    XCTAssertTrue(app.staticTexts["Bench Press"].exists)
}
```

### 5. Page Object Pattern
Encapsulate UI elements:

```swift
class WorkoutScreen {
    let app: XCUIApplication
    
    init(app: XCUIApplication) {
        self.app = app
    }
    
    var startWorkoutButton: XCUIElement {
        app.buttons["startWorkoutButton"]
    }
    
    var workoutTitle: XCUIElement {
        app.staticTexts["Log Workout"]
    }
    
    var addExerciseButton: XCUIElement {
        app.buttons["addExerciseButton"]
    }
    
    func startWorkout() {
        startWorkoutButton.tap()
    }
    
    func verifyActiveWorkout() {
        XCTAssertTrue(workoutTitle.waitForExistence(timeout: 2.0))
    }
}

// Use in tests
func testWorkoutFlow() {
    let workoutScreen = WorkoutScreen(app: app)
    workoutScreen.startWorkout()
    workoutScreen.verifyActiveWorkout()
}
```

## Limitations

### 1. Requires macOS + Xcode
- Must run on Mac
- Cannot run in Linux environments
- Requires simulator or physical device

### 2. Slower than Unit Tests
- Must launch app
- UI rendering takes time
- Typical test: 5-30 seconds

### 3. Can Be Flaky
- Timing issues
- Animation delays
- Race conditions
- Solution: Use `waitForExistence`, add explicit waits

### 4. Black Box Testing
- Cannot access app internals
- Cannot set internal state directly
- Cannot verify internal logic
- Must observe through UI only

### 5. Maintenance Overhead
- UI changes break tests
- Requires keeping tests in sync
- More brittle than unit tests

## Integration with Thiccc Architecture

### Challenge: Crux Core State
UI tests can't directly set Rust core state.

### Solutions:

**1. Use Launch Arguments**
```swift
// In test
app.launchArguments = ["--uitesting", "--mock-workout"]
app.launch()

// In app (ThicccApp.swift)
if ProcessInfo.processInfo.arguments.contains("--mock-workout") {
    // Initialize core with mock data
}
```

**2. Go Through UI**
Start from empty state, build up through interactions (slower but more realistic).

**3. Separate Test Target**
Create a separate app target for testing with mock data.

## Advantages Over Manual Testing

- ✅ Repeatable
- ✅ Fast feedback (once written)
- ✅ Catches regressions automatically
- ✅ Can run in CI/CD
- ✅ Documents expected behavior
- ✅ Confidence for refactoring

## Resources

- [Apple XCTest Documentation](https://developer.apple.com/documentation/xctest)
- [WWDC: UI Testing in Xcode](https://developer.apple.com/videos/play/wwdc2019/413/)
- [Test Pyramid for Mobile](https://martinfowler.com/articles/practical-test-pyramid.html)

## Related Docs

- [README.md](./README.md) - Overall testing approach
- [maestro.md](./maestro.md) - Simple YAML-based UI testing for smoke tests

---

**Last Updated**: December 6, 2025  
**Status**: Reference documentation for XCTest UI testing

