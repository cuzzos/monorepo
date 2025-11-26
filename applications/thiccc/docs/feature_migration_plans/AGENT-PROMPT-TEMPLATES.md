# Cursor Agent Prompt Templates

This document provides templates for prompting Cursor AI agents to complete migration tasks. Each template is designed to provide clear context, requirements, and success criteria.

## How to Use These Templates

1. **Select the appropriate template** for your task type
2. **Fill in the [PLACEHOLDERS]** with specific information
3. **Copy and paste** the completed prompt to Cursor
4. **Attach relevant files** mentioned in the template
5. **Review the output** against success criteria
6. **⚠️ CRITICAL: Run bug check before completing task** (see below)

---

## ⚠️ MANDATORY: Bug Checking Before Task Completion

**EVERY implementation MUST be rigorously checked for bugs before marking complete.**

### Critical Bug Patterns to Check

After implementing ANY feature, systematically check for these common issues:

#### 1. **Unsafe `unwrap()` / `expect()` Usage**
- [ ] Search code for `.unwrap()` - is each one truly safe?
- [ ] Check if `None`/`Err` cases are possible
- [ ] Use `if let`, `match`, or `?` operator instead

**Example Bug:**
```rust
// ❌ BAD - Will panic if current_workout is None
workout_id: model.current_workout.as_ref().unwrap().id,

// ✅ GOOD - Use safe alternative
workout_id: exercise.workout_id, // Get from existing data
// OR
if let Some(workout) = &model.current_workout {
    workout_id: workout.id,
} else {
    return render(); // Handle None case
}
```

#### 2. **Type Mismatches with Database/Serialization**
- [ ] JSON encoding returns `Data`, not `String` - convert before inserting to TEXT columns
- [ ] JSON decoding expects `Data`, not `String` - convert before decoding from TEXT columns
- [ ] Check all database column types match the data being inserted
- [ ] Verify encoding/decoding is symmetrical

**Example Bugs:**
```swift
// ❌ BAD - Data can't be inserted into TEXT column
try? JSONEncoder().encode(array)

// ✅ GOOD - Convert Data to String
try? JSONEncoder().encode(array)
    .flatMap { String(data: $0, encoding: .utf8) }

// ❌ BAD - JSONDecoder expects Data, row returns String
try? JSONDecoder().decode([String].self, from: row["column"])

// ✅ GOOD - Convert String to Data first
if let jsonString: String = row["column"],
   let data = jsonString.data(using: .utf8) {
    try? JSONDecoder().decode([String].self, from: data)
}
```

#### 3. **Index/Bounds Checking**
- [ ] Array accesses are bounds-checked
- [ ] Loop indices don't exceed collection size
- [ ] Off-by-one errors in ranges
- [ ] Empty collection handling

**Example Check:**
```rust
// ❌ BAD - No bounds check
exercises[from_index]

// ✅ GOOD - Bounds checked
if from_index < exercises.len() { /* ... */ }
```

#### 4. **Option/Result Handling**
- [ ] Every `Option` has explicit `None` handling
- [ ] Every `Result` has explicit `Err` handling
- [ ] No silent failures (check for `let _ =`)
- [ ] Errors are propagated or logged appropriately

#### 5. **State Consistency**
- [ ] IDs match between related entities (workout_id, exercise_id)
- [ ] Indices stay sequential after deletions
- [ ] Timestamps are set appropriately
- [ ] Foreign key relationships maintained

#### 6. **Memory/Resource Safety**
- [ ] No memory leaks (circular references, unclosed files)
- [ ] Timer/listener cleanup in destructors
- [ ] Database connections closed
- [ ] File handles released

#### 7. **Edge Cases**
- [ ] Empty lists/collections
- [ ] Zero/negative numbers where unexpected
- [ ] Very large inputs (>1000 items)
- [ ] Concurrent access (if applicable)
- [ ] Network failures (if applicable)

### Bug Check Workflow

**After implementing, BEFORE marking complete:**

1. **Read Through Code Critically**
   - Pretend you're trying to break it
   - What inputs would cause failure?

2. **Run Automated Checks**
   ```bash
   # Rust
   cargo clippy --all-targets
   cargo test
   
   # Swift
   swiftlint (if configured)
   xcodebuild test
   ```

3. **Manual Testing**
   - Test happy path
   - Test edge cases
   - Test error paths
   - Try to make it crash

4. **Code Review Checklist**
   - [ ] No unsafe `unwrap()` without proof of safety
   - [ ] All errors handled explicitly
   - [ ] Type conversions correct
   - [ ] Indices bounds-checked
   - [ ] Edge cases covered
   - [ ] Resources cleaned up

5. **Document Known Issues**
   If you find issues:
   - Fix them immediately (preferred)
   - OR document as TODO with clear description
   - NEVER ignore and hope for the best

### When to Use This

**Check for bugs on EVERY:**
- New function implementation
- Logic change
- Database interaction
- Type conversion
- Collection manipulation
- Event handler
- View rendering logic

### Examples from This Migration

**Real bugs found during planning:**
1. ❌ `unwrap()` on `current_workout` in AddSet handler → would panic
2. ❌ `JSONEncoder().encode()` to TEXT column → type mismatch
3. ❌ `JSONDecoder` from String without conversion → would fail

All caught and fixed BEFORE implementation!

---

## Template 1: Rust Data Model Implementation

```
I need you to implement Rust data models for the Thiccc workout tracking app using the Crux framework.

**Context:**
- We're migrating from Goonlytics (pure Swift) to Thiccc (Rust core + Swift shell)
- All business logic and data models must be in Rust
- Models must support Serde serialization for cross-platform communication

**Reference Files:**
Please review these files for the Swift implementation:
- @legacy/Goonlytics/Goonlytics/Sources/Workout/Models/[SWIFT_FILE]

**Task: [SPECIFIC_MODEL_NAME]**

Create the following Rust data structures in `/applications/thiccc/app/shared/src/models.rs`:

[DETAILED_MODEL_SPECIFICATION]

**Requirements:**
1. All structs must derive: `Serialize`, `Deserialize`, `Clone`, `Debug`
2. Use appropriate Rust types:
   - `Option<T>` for optional fields
   - `Vec<T>` for arrays/lists
   - `uuid::Uuid` for unique identifiers
   - `chrono::DateTime<Utc>` for timestamps
3. Match Swift model structure exactly (field names can be snake_case)
4. Add doc comments for public items
5. Ensure all types are serializable

**Success Criteria:**
- [ ] Code compiles without errors
- [ ] All required derives are present
- [ ] Field types match Swift equivalents
- [ ] Can serialize/deserialize to/from JSON
- [ ] No clippy warnings
- [ ] **⚠️ BUG CHECK PASSED** (see Bug Checking section above)
  - [ ] No unsafe `unwrap()` calls
  - [ ] All Option/Result types properly handled
  - [ ] Type conversions verified correct

**Example Reference:**
The current counter app model is in `/applications/thiccc/app/shared/src/app.rs` lines 22-24.

Please implement this following the principal engineer standards in the `.cursor/context` file.

**⚠️ CRITICAL: Before completing, run the mandatory bug check workflow above.**
```

---

## Template 2: Rust Event Implementation

```
I need you to implement Crux events for [FEATURE_AREA] in the Thiccc app.

**Context:**
- Using Crux framework where all user actions are represented as events
- Events flow from SwiftUI shell → Rust core → update function
- Events must be serializable for cross-platform communication

**Reference Files:**
Please review:
- @legacy/Goonlytics/Goonlytics/Sources/[FEATURE]/[FILE].swift
- Current events in @shared/src/app.rs

**Task: Add [EVENT_TYPE] Events**

Add the following events to the `Event` enum in `/applications/thiccc/app/shared/src/app.rs`:

[LIST_OF_EVENTS]

**Requirements:**
1. All events must derive: `Serialize`, `Deserialize`, `Clone`, `Debug`
2. Use appropriate data types for event payloads
3. Name events using imperative mood (e.g., `AddExercise`, not `ExerciseAdded`)
4. Keep events focused (single responsibility)
5. Add doc comments explaining what each event does

**Example:**
```rust
/// User requested to add a new exercise to the current workout
AddExercise { exercise: GlobalExercise },

/// User requested to delete an exercise from the current workout
DeleteExercise { exercise_id: Uuid },
```

**Success Criteria:**
- [ ] Code compiles without errors
- [ ] All events are properly serializable
- [ ] Events cover all user actions for this feature
- [ ] Event names are clear and descriptive
- [ ] No clippy warnings

Please implement following the Crux patterns and principal engineer standards.
```

---

## Template 3: Rust Update Logic Implementation

```
I need you to implement the update function logic for [FEATURE] in the Thiccc app's Rust core.

**Context:**
- Using Crux framework where `update()` function handles all business logic
- Update receives events, mutates model state, and returns commands
- All business logic MUST be in Rust core (not in Swift shell)

**Reference Files:**
Please review the Swift implementation:
- @legacy/Goonlytics/Goonlytics/Sources/[FEATURE]/[MODEL_FILE].swift

Current update function:
- @shared/src/app.rs (update function)

**Task: Implement [SPECIFIC_FEATURE] Logic**

In the `update` function of `/applications/thiccc/app/shared/src/app.rs`, implement handling for these events:

[LIST_OF_EVENTS_TO_HANDLE]

**Business Logic to Implement:**
[DETAILED_LOGIC_DESCRIPTION]

**Requirements:**
1. Mutate `model` state appropriately
2. Maintain data consistency (e.g., proper IDs, indices)
3. Handle edge cases (empty lists, invalid indices, etc.)
4. Return `render()` command when view needs updating
5. Use capability commands for side effects (database, file I/O, etc.)
6. Add validation where appropriate
7. Use proper error handling patterns

**Example Pattern:**
```rust
Event::AddExercise { exercise } => {
    if let Some(ref mut workout) = model.current_workout {
        let new_exercise = Exercise {
            id: Uuid::new_v4(),
            workout_id: workout.id,
            name: exercise.name.clone(),
            // ... other fields
        };
        workout.exercises.push(new_exercise);
    }
    render()
}
```

**Success Criteria:**
- [ ] Code compiles without errors
- [ ] All events are handled
- [ ] Model state is properly updated
- [ ] Edge cases are handled
- [ ] Tests pass (write tests if needed)
- [ ] No clippy warnings
- [ ] **⚠️ BUG CHECK PASSED** (see Bug Checking section above)
  - [ ] **NO `.unwrap()` on Option types** - use `if let`, `match`, or safe alternatives
  - [ ] **NO `.expect()` without proof of safety** - document why it's safe
  - [ ] **All Option<T> have explicit None handling**
  - [ ] **Array indices are bounds-checked**
  - [ ] **IDs and foreign keys maintained correctly**
  - [ ] **State remains consistent after each event**

Please implement following Crux patterns and principal engineer standards.

**⚠️ CRITICAL: This is business logic - bugs here affect the entire app. Run thorough bug check before completing.**
```

---

## Template 4: Rust View Function Implementation

```
I need you to implement the view function transformation for [VIEW_NAME] in the Thiccc app's Rust core.

**Context:**
- Crux `view()` function transforms Model → ViewModel
- ViewModels contain only what the UI needs to render
- ViewModels must be fully serializable
- Keep view function pure (no side effects)

**Reference Files:**
Current view function:
- @shared/src/app.rs (view function)

Swift UI that will consume this:
- @ios/Thiccc/[VIEW_FILE].swift (planned/existing)

**Task: Create [VIEW_MODEL_NAME] ViewModel**

1. Define the ViewModel struct in `/applications/thiccc/app/shared/src/app.rs`:
```rust
#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct [ViewModelName] {
    // fields
}
```

2. Implement transformation in `view()` function to create this ViewModel from Model.

**ViewModel Should Include:**
[LIST_OF_FIELDS_WITH_DESCRIPTIONS]

**Requirements:**
1. ViewModel must derive: `Serialize`, `Deserialize`, `Clone`, `Debug`
2. Use simple types (String, i32, bool, Vec, etc.)
3. Pre-format data for display (e.g., "5:23" instead of 323 seconds)
4. Pre-calculate computed values (e.g., total volume)
5. Include UI state flags (e.g., `is_loading`, `is_empty`)
6. Keep ViewModels flat when possible

**Example:**
```rust
#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct WorkoutViewModel {
    pub workout_name: String,
    pub formatted_duration: String,  // Pre-formatted as "MM:SS"
    pub total_volume: i32,
    pub total_sets: i32,
    pub exercises: Vec<ExerciseViewModel>,
}
```

**Success Criteria:**
- [ ] ViewModel compiles and is serializable
- [ ] Includes all data needed for UI rendering
- [ ] Data is pre-formatted for display
- [ ] View function properly transforms Model → ViewModel
- [ ] No clippy warnings

Please implement following Crux patterns and principal engineer standards.
```

---

## Template 5: Crux Capability Implementation (Rust Side)

```
I need you to implement a Crux capability for [CAPABILITY_NAME] in the Thiccc app.

**Context:**
- Capabilities are how Rust core requests platform-specific operations
- Core defines capability interface, platform implements it
- Capabilities handle: database, file I/O, HTTP, timers, etc.

**Task: Implement [CAPABILITY_NAME] Capability**

Create capability in `/applications/thiccc/app/shared/src/capabilities/[name].rs`

**Capability Operations Needed:**
[LIST_OF_OPERATIONS]

**Requirements:**
1. Define operation enum with all needed operations
2. Define request and response types
3. All types must be serializable
4. Follow Crux capability patterns
5. Add comprehensive doc comments
6. Handle errors with Result types

**Example Pattern:**
```rust
use crux_core::capability::{CapabilityContext, Operation};
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, Eq)]
pub enum DatabaseOperation {
    SaveWorkout(Workout),
    LoadWorkouts,
    LoadWorkoutById(Uuid),
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, Eq)]
pub enum DatabaseResponse {
    WorkoutSaved,
    WorkoutsLoaded(Vec<Workout>),
    WorkoutLoaded(Option<Workout>),
    Error(String),
}

pub struct Database<Ev> {
    context: CapabilityContext<DatabaseOperation, Ev>,
}

impl<Ev> Database<Ev> {
    pub fn new(context: CapabilityContext<DatabaseOperation, Ev>) -> Self {
        Self { context }
    }

    pub fn save_workout(&self, workout: Workout, event: impl Fn(DatabaseResponse) -> Ev) {
        self.context.request(
            DatabaseOperation::SaveWorkout(workout),
            event
        );
    }
}
```

**Success Criteria:**
- [ ] Code compiles without errors
- [ ] All operations defined
- [ ] Request/response types are serializable
- [ ] Methods are ergonomic to use
- [ ] Doc comments explain usage
- [ ] No clippy warnings

**Next Steps After This:**
After this Rust capability is implemented, the Swift shell side needs to be implemented (use Template 6).

Please implement following Crux capability patterns and principal engineer standards.
```

---

## Template 6: Crux Capability Implementation (Swift Side)

```
I need you to implement the Swift shell side of the [CAPABILITY_NAME] capability for the Thiccc app.

**Context:**
- Rust core sends capability requests via effects
- Swift shell receives requests, performs platform operations, sends responses back
- This is the bridge between Crux core and iOS platform APIs

**Reference Files:**
Rust capability interface:
- @shared/src/capabilities/[capability].rs

Existing Swift shell implementation:
- @ios/Thiccc/core.swift

**Task: Implement [CAPABILITY_NAME] Platform Side**

Create `/applications/thiccc/app/ios/Thiccc/Capabilities/[Name]Capability.swift`

**Operations to Handle:**
[LIST_OF_OPERATIONS_FROM_RUST]

**Requirements:**
1. Parse capability requests from Rust
2. Perform platform operations (e.g., GRDB database calls, FileManager, etc.)
3. Send responses back to Rust core
4. Handle errors gracefully
5. Use Swift async/await where appropriate
6. Follow iOS best practices

**Example Pattern:**
```swift
import Foundation
import GRDB

class DatabaseCapability {
    let database: DatabaseWriter
    
    init(database: DatabaseWriter) {
        self.database = database
    }
    
    func handleRequest(_ operation: DatabaseOperation, core: Core) async {
        switch operation {
        case .saveWorkout(let workout):
            do {
                try await database.write { db in
                    try Workout.insert(workout).execute(db)
                }
                core.handleResponse(DatabaseResponse.workoutSaved)
            } catch {
                core.handleResponse(DatabaseResponse.error(error.localizedDescription))
            }
        // ... other operations
        }
    }
}
```

**Platform APIs to Use:**
[LIST_OF_iOS_APIS_OR_FRAMEWORKS]

**Success Criteria:**
- [ ] Code compiles without errors
- [ ] All operations handled
- [ ] Proper error handling
- [ ] Responses sent back to core
- [ ] Tests pass in iOS simulator
- [ ] Follows iOS best practices
- [ ] **⚠️ BUG CHECK PASSED** (see Bug Checking section above)
  - [ ] **Database/JSON: Data encoded to String for TEXT columns** (not raw Data)
  - [ ] **Database/JSON: String converted to Data before decoding**
  - [ ] **All try/catch blocks have proper error responses**
  - [ ] **Column types match inserted data types**
  - [ ] **Foreign key relationships maintained**
  - [ ] **No force-unwraps without nil checks**

Please implement following iOS best practices and principal engineer standards.

**⚠️ CRITICAL: Database bugs cause data loss. Double-check all type conversions (Data ↔ String) and error handling.**
```

---

## Template 7: SwiftUI View Implementation

```
I need you to implement the [VIEW_NAME] SwiftUI view for the Thiccc app.

**Context:**
- SwiftUI views should be thin and declarative
- Views render ViewModels from Rust core
- User interactions send events to core
- No business logic in views

**Reference Files:**
Goonlytics implementation to match:
- @legacy/Goonlytics/Goonlytics/Sources/[FEATURE]/[VIEW].swift

ViewModel from core:
- @shared/src/app.rs ([ViewModel] struct)

**Task: Create [VIEW_NAME] View**

Create `/applications/thiccc/app/ios/Thiccc/[ViewName].swift`

**View Should Display:**
[LIST_OF_UI_ELEMENTS]

**User Interactions to Handle:**
[LIST_OF_INTERACTIONS_AND_EVENTS]

**Requirements:**
1. Match Goonlytics UI and behavior
2. Use ViewModel from core (no local business logic)
3. Send events to core for all user actions
4. Follow SwiftUI best practices
5. Use iOS 18+ APIs (minimum deployment target)
6. Follow iOS Human Interface Guidelines
7. Include accessibility labels

**Example Pattern:**
```swift
import SwiftUI

struct WorkoutView: View {
    @ObservedObject var core: Core
    
    var body: some View {
        VStack {
            Text(core.view.workoutName)
                .font(.title)
            
            ForEach(core.view.exercises) { exercise in
                ExerciseRow(exercise: exercise) {
                    core.update(.deleteExercise(id: exercise.id))
                }
            }
            
            Button("Add Exercise") {
                core.update(.showAddExercise)
            }
        }
    }
}
```

**UI Components Needed:**
[LIST_OF_COMPONENTS]

**Success Criteria:**
- [ ] Code compiles without errors
- [ ] View matches Goonlytics appearance
- [ ] All interactions send correct events
- [ ] No business logic in view
- [ ] Renders correctly in simulator
- [ ] Follows iOS HIG

Please implement following SwiftUI best practices and principal engineer standards (iOS 18+, no backward compatibility needed).
```

---

## Template 8: Unit Test Implementation

```
I need you to implement unit tests for [MODULE_OR_FEATURE] in the Thiccc app.

**Context:**
- Rust business logic should have comprehensive test coverage
- Tests verify behavior, not implementation
- Use Rust's built-in test framework

**Code to Test:**
- @shared/src/[module].rs

**Task: Write Tests for [SPECIFIC_FUNCTIONALITY]**

Add tests in the appropriate test module (or create `#[cfg(test)]` module).

**Test Cases Needed:**
[LIST_OF_TEST_SCENARIOS]

**Requirements:**
1. Test happy paths
2. Test edge cases
3. Test error conditions
4. Use descriptive test names
5. Follow AAA pattern (Arrange, Act, Assert)
6. Use test fixtures where appropriate

**Example Pattern:**
```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_add_exercise_to_workout() {
        // Arrange
        let mut model = Model::default();
        model.current_workout = Some(Workout::new());
        let exercise = GlobalExercise { name: "Squat".to_string(), /* ... */ };
        
        // Act
        let app = Thiccc::default();
        app.update(Event::AddExercise { exercise }, &mut model, &());
        
        // Assert
        assert_eq!(model.current_workout.unwrap().exercises.len(), 1);
    }

    #[test]
    fn test_add_exercise_fails_when_no_active_workout() {
        // Arrange
        let mut model = Model::default();
        let exercise = GlobalExercise { name: "Squat".to_string(), /* ... */ };
        
        // Act
        let app = Thiccc::default();
        app.update(Event::AddExercise { exercise }, &mut model, &());
        
        // Assert
        assert!(model.current_workout.is_none());
    }
}
```

**Success Criteria:**
- [ ] All tests pass
- [ ] Tests cover happy paths
- [ ] Tests cover edge cases
- [ ] Tests cover error conditions
- [ ] Test names are descriptive
- [ ] No warnings from test runner

Please write comprehensive tests following Rust testing best practices.
```

---

## Template 9: Integration Task (Multiple Components)

```
I need you to implement [FEATURE_NAME] which involves both Rust core and SwiftUI shell components.

**Context:**
This is an integrated feature requiring changes across multiple layers of the Crux architecture.

**Reference Files:**
Goonlytics implementation:
- @legacy/Goonlytics/Goonlytics/Sources/[FEATURE]/

Current codebase:
- @shared/src/app.rs
- @ios/Thiccc/

**Task: Implement [FEATURE_NAME]**

This task involves:
1. [COMPONENT_1_DESCRIPTION]
2. [COMPONENT_2_DESCRIPTION]
3. [COMPONENT_3_DESCRIPTION]

**Detailed Steps:**

### Step 1: [RUST_CORE_CHANGES]
[DETAILED_INSTRUCTIONS]

### Step 2: [SWIFT_VIEW_CHANGES]
[DETAILED_INSTRUCTIONS]

### Step 3: [INTEGRATION]
[DETAILED_INSTRUCTIONS]

**Requirements:**
- Follow Crux architecture (business logic in Rust)
- Match Goonlytics behavior exactly
- Test each component
- Test integration end-to-end

**Success Criteria:**
- [ ] All components implemented
- [ ] Feature works end-to-end in simulator
- [ ] Matches Goonlytics behavior
- [ ] Tests pass
- [ ] No errors or warnings

Please implement this feature following Crux patterns and principal engineer standards. Work through each step systematically.
```

---

## Template 10: Debugging/Troubleshooting

```
I need help debugging [ISSUE_DESCRIPTION] in the Thiccc app.

**Problem:**
[DETAILED_PROBLEM_DESCRIPTION]

**Expected Behavior:**
[WHAT_SHOULD_HAPPEN]

**Actual Behavior:**
[WHAT_ACTUALLY_HAPPENS]

**Reference Implementation:**
The correct behavior can be seen in:
- @legacy/Goonlytics/Goonlytics/Sources/[FEATURE]/[FILE].swift

**Relevant Files:**
- @shared/src/[file].rs
- @ios/Thiccc/[file].swift

**Error Messages (if any):**
```
[ERROR_MESSAGES_OR_LOGS]
```

**Steps to Reproduce:**
1. [STEP_1]
2. [STEP_2]
3. [STEP_3]

**What I've Tried:**
[PREVIOUS_ATTEMPTS]

**Questions:**
1. [SPECIFIC_QUESTION_1]
2. [SPECIFIC_QUESTION_2]

Please help me identify and fix this issue. Focus on the Crux architecture patterns and ensure business logic stays in the Rust core.
```

---

## Common Placeholders Reference

When using these templates, replace these common placeholders:

- `[FEATURE_AREA]` - e.g., "workout tracking", "history", "plate calculator"
- `[VIEW_NAME]` - e.g., "WorkoutView", "HistoryView", "SetRow"
- `[MODEL_NAME]` - e.g., "Workout", "Exercise", "ExerciseSet"
- `[CAPABILITY_NAME]` - e.g., "Database", "FileStorage", "Timer"
- `[EVENT_TYPE]` - e.g., "workout management", "set updates"
- `[SWIFT_FILE]` - Filename from Goonlytics
- `[SPECIFIC_FUNCTIONALITY]` - The exact function/behavior being implemented

---

## Tips for Effective Prompts

1. **Be Specific**: More detail = better results
2. **Provide Context**: Always mention Crux architecture and migration context
3. **Reference Files**: Attach or mention relevant files
4. **Set Clear Criteria**: Define what "done" looks like
5. **Mention Standards**: Reference the principal engineer standards
6. **Break Down Complex Tasks**: Use subtasks for complex features
7. **Test Early**: Ask for tests alongside implementation
8. **⚠️ ALWAYS Run Bug Check**: Before marking any task complete, run the mandatory bug check workflow
9. **Question Unsafe Code**: If the agent uses `unwrap()`, `expect()`, or force-unwraps, ask for justification
10. **Verify Type Conversions**: Double-check any Data↔String, Int↔Float, or similar conversions

### Critical Reminder

**Every template includes bug checking requirements for a reason.** The bugs found during planning (unsafe unwrap, JSON encoding issues) are COMMON patterns. Take bug checking seriously - it prevents production crashes and data loss.

**Before completing ANY task:**
- ✅ Run clippy/linter
- ✅ Run tests
- ✅ Review for unsafe patterns
- ✅ Test edge cases
- ✅ Check the mandatory bug patterns list

---

**Last Updated**: November 26, 2025

