# Phase 1: Core Data Models & Type System

## Overview

**Goal**: Create all Rust data structures that represent the app's domain models, matching the Swift models from Goonlytics.

**Phase Duration**: Estimated 2-4 hours  
**Complexity**: Medium  
**Dependencies**: None (foundation phase)  
**Blocks**: Phase 2 (Events & State)

## Why This Phase Matters

All subsequent phases depend on these data models. Getting the types right from the start ensures:
- Type safety across the Rust/Swift boundary
- Consistent data representation
- Proper serialization/deserialization
- Clear domain model for business logic

## Task Breakdown

### Task 1.1: Core Workout Data Models

**Estimated Time**: 1-2 hours  
**Complexity**: Medium  
**Priority**: Critical (blocks everything)

#### Objective
Create the primary workout-related data structures in Rust that mirror the Swift models from Goonlytics.

#### Reference Files
- `legacy/Goonlytics/Goonlytics/Sources/Workout/Models/Workout.swift` (lines 5-180)

#### Sub-Tasks

##### Sub-Task 1.1.1: Create `Workout` struct

**File**: `/applications/thiccc/app/shared/src/models.rs`

**Implementation Details**:
```rust
use serde::{Deserialize, Serialize};
use uuid::Uuid;
use chrono::{DateTime, Utc};

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
pub struct Workout {
    /// Unique identifier for the workout
    pub id: Uuid,
    
    /// User-provided name for the workout
    pub name: String,
    
    /// Optional notes about the workout
    pub note: Option<String>,
    
    /// Duration in seconds
    pub duration: Option<i32>,
    
    /// When the workout started (UTC)
    pub start_timestamp: DateTime<Utc>,
    
    /// When the workout ended (UTC)
    pub end_timestamp: Option<DateTime<Utc>>,
    
    /// Exercises performed in this workout
    pub exercises: Vec<Exercise>,
}

impl Workout {
    /// Create a new empty workout
    pub fn new() -> Self {
        Self {
            id: Uuid::new_v4(),
            name: String::new(),
            note: None,
            duration: None,
            start_timestamp: Utc::now(),
            end_timestamp: None,
            exercises: Vec::new(),
        }
    }
}

impl Default for Workout {
    fn default() -> Self {
        Self::new()
    }
}
```

**Swift Mapping**:
```
Swift (Goonlytics)          →  Rust (Thiccc)
-------------------            ---------------
UUID                       →  Uuid
String                     →  String
String?                    →  Option<String>
Int?                       →  Option<i32>
Date                       →  DateTime<Utc>
Date?                      →  Option<DateTime<Utc>>
IdentifiedArrayOf<Exercise> →  Vec<Exercise>
```

**Success Criteria**:
- [ ] Struct compiles without errors
- [ ] All fields have correct types
- [ ] Derives `Serialize`, `Deserialize`, `Clone`, `Debug`, `PartialEq`
- [ ] Constructor functions provided
- [ ] Doc comments added
- [ ] Can serialize to JSON
- [ ] Can deserialize from JSON

##### Sub-Task 1.1.2: Create `Exercise` struct

**File**: `/applications/thiccc/app/shared/src/models.rs`

**Implementation Details**:
```rust
#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
pub struct Exercise {
    /// Unique identifier for the exercise
    pub id: Uuid,
    
    /// Optional superset grouping ID
    pub superset_id: Option<i32>,
    
    /// ID of the workout this exercise belongs to
    pub workout_id: Uuid,
    
    /// Name of the exercise (e.g., "Bench Press")
    pub name: String,
    
    /// Pinned notes that persist across workouts
    pub pinned_notes: Vec<String>,
    
    /// Session-specific notes
    pub notes: Vec<String>,
    
    /// Duration of this exercise in seconds
    pub duration: Option<i32>,
    
    /// Type of exercise (barbell, dumbbell, etc.)
    pub exercise_type: ExerciseType,
    
    /// Weight unit for this exercise
    pub weight_unit: Option<WeightUnit>,
    
    /// Default warm-up time in seconds
    pub default_warm_up_time: Option<i32>,
    
    /// Default rest time between sets in seconds
    pub default_rest_time: Option<i32>,
    
    /// Sets performed for this exercise
    pub sets: Vec<ExerciseSet>,
    
    /// Body part information
    pub body_part: Option<BodyPart>,
}
```

**Success Criteria**:
- [ ] Struct compiles without errors
- [ ] All fields match Swift equivalent
- [ ] Proper derives added
- [ ] Doc comments added

##### Sub-Task 1.1.3: Create `ExerciseSet` struct

**File**: `/applications/thiccc/app/shared/src/models.rs`

**Implementation Details**:
```rust
#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
pub struct ExerciseSet {
    /// Unique identifier for the set
    pub id: Uuid,
    
    /// Type of set (warm-up, working, drop set, etc.)
    pub set_type: SetType,
    
    /// Weight unit for this set
    pub weight_unit: Option<WeightUnit>,
    
    /// Suggested/planned values
    pub suggest: SetSuggest,
    
    /// Actual performed values
    pub actual: SetActual,
    
    /// Whether this set has been completed
    pub is_completed: bool,
    
    /// ID of the exercise this set belongs to
    pub exercise_id: Uuid,
    
    /// ID of the workout
    pub workout_id: Uuid,
    
    /// Index of this set within the exercise (0-based)
    pub set_index: i32,
}
```

**Success Criteria**:
- [ ] Struct compiles without errors
- [ ] All fields match Swift equivalent
- [ ] Proper derives added
- [ ] Doc comments added

##### Sub-Task 1.1.4: Create `SetSuggest` and `SetActual` structs

**File**: `/applications/thiccc/app/shared/src/models.rs`

**Implementation Details**:
```rust
/// Suggested/planned values for a set
#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, Default)]
pub struct SetSuggest {
    /// Suggested weight
    pub weight: Option<f64>,
    
    /// Suggested rep count
    pub reps: Option<i32>,
    
    /// Suggested rep range (for AMRAP, etc.)
    pub rep_range: Option<i32>,
    
    /// Suggested duration in seconds (for time-based exercises)
    pub duration: Option<i32>,
    
    /// Suggested RPE (Rate of Perceived Exertion, 1-10)
    pub rpe: Option<f64>,
    
    /// Suggested rest time after this set in seconds
    pub rest_time: Option<i32>,
}

/// Actual performed values for a set
#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, Default)]
pub struct SetActual {
    /// Actual weight used
    pub weight: Option<f64>,
    
    /// Actual reps performed
    pub reps: Option<i32>,
    
    /// Actual duration in seconds
    pub duration: Option<i32>,
    
    /// Actual RPE
    pub rpe: Option<f64>,
    
    /// Actual rest time taken after this set
    pub actual_rest_time: Option<i32>,
}
```

**Success Criteria**:
- [ ] Both structs compile without errors
- [ ] All fields match Swift equivalents
- [ ] Proper derives including `Default`
- [ ] Doc comments added

#### Dependencies & Imports Needed

Add to top of `models.rs`:
```rust
use serde::{Deserialize, Serialize};
use uuid::Uuid;
use chrono::{DateTime, Utc};
```

Add to `Cargo.toml` (if not already present):
```toml
[dependencies]
serde = { version = "1.0", features = ["derive"] }
uuid = { version = "1.6", features = ["serde", "v4"] }
chrono = { version = "0.4", features = ["serde"] }
```

#### Agent Prompt Template

Use **Template 1: Rust Data Model Implementation** from AGENT-PROMPT-TEMPLATES.md:

```
I need you to implement Rust data models for workout tracking in the Thiccc app using the Crux framework.

**Context:**
- We're migrating from Goonlytics (pure Swift) to Thiccc (Rust core + Swift shell)
- All business logic and data models must be in Rust
- Models must support Serde serialization for cross-platform communication

**Reference Files:**
Please review these files for the Swift implementation:
- @legacy/Goonlytics/Goonlytics/Sources/Workout/Models/Workout.swift

**Task: Workout, Exercise, and ExerciseSet Models**

Create the following Rust data structures in `/applications/thiccc/app/shared/src/models.rs`:

1. `Workout` struct with fields: id, name, note, duration, start_timestamp, end_timestamp, exercises
2. `Exercise` struct with fields: id, superset_id, workout_id, name, pinned_notes, notes, duration, exercise_type, weight_unit, default_warm_up_time, default_rest_time, sets, body_part
3. `ExerciseSet` struct with fields: id, set_type, weight_unit, suggest, actual, is_completed, exercise_id, workout_id, set_index
4. `SetSuggest` struct with fields: weight, reps, rep_range, duration, rpe, rest_time
5. `SetActual` struct with fields: weight, reps, duration, rpe, actual_rest_time

**Requirements:**
1. All structs must derive: `Serialize`, `Deserialize`, `Clone`, `Debug`, `PartialEq`
2. Use appropriate Rust types:
   - `Uuid` for unique identifiers
   - `Option<T>` for optional fields
   - `Vec<T>` for arrays/lists
   - `DateTime<Utc>` for timestamps
   - `f64` for weight/RPE values
   - `i32` for counts and durations
3. Match Swift model structure exactly (use snake_case for field names)
4. Add comprehensive doc comments for all public items
5. Implement `Default` or constructor functions where appropriate

**Success Criteria:**
- [ ] Code compiles without errors
- [ ] All required derives are present
- [ ] Field types match Swift equivalents
- [ ] Can serialize/deserialize to/from JSON
- [ ] No clippy warnings

Please implement this following the principal engineer standards in the `.cursor/context` file.
```

---

### Task 1.2: Enumeration Types

**Estimated Time**: 30 minutes  
**Complexity**: Low  
**Priority**: Critical (blocks Task 1.1)

#### Objective
Create all enumeration types used by the workout models.

#### Reference Files
- `legacy/Goonlytics/Goonlytics/Sources/Workout/Models/Workout.swift` (lines 54-109)

#### Sub-Tasks

##### Sub-Task 1.2.1: Create Exercise Type Enums

**File**: `/applications/thiccc/app/shared/src/models.rs`

**Implementation Details**:
```rust
/// Type of exercise equipment
#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, Eq, Hash)]
#[serde(rename_all = "lowercase")]
pub enum ExerciseType {
    Dumbbell,
    Kettlebell,
    Barbell,
    Hexbar,
    Bodyweight,
    Machine,
    Unknown,
}

impl Default for ExerciseType {
    fn default() -> Self {
        Self::Unknown
    }
}
```

**Success Criteria**:
- [ ] Enum compiles without errors
- [ ] All variants match Swift equivalent
- [ ] Proper derives added (include `Eq`, `Hash` for enums)
- [ ] Serde rename attribute for lowercase serialization
- [ ] Default implementation

##### Sub-Task 1.2.2: Create Weight Unit Enum

**File**: `/applications/thiccc/app/shared/src/models.rs`

**Implementation Details**:
```rust
/// Unit of weight measurement
#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, Eq, Hash)]
#[serde(rename_all = "lowercase")]
pub enum WeightUnit {
    #[serde(rename = "kg")]
    Kilograms,
    #[serde(rename = "lb")]
    Pounds,
    Bodyweight,
}
```

**Success Criteria**:
- [ ] Enum compiles without errors
- [ ] Serde renames match Swift string values ("kg", "lb")
- [ ] Proper derives added

##### Sub-Task 1.2.3: Create Set Type Enum

**File**: `/applications/thiccc/app/shared/src/models.rs`

**Implementation Details**:
```rust
/// Type of set
#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, Eq, Hash)]
#[serde(rename_all = "camelCase")]
pub enum SetType {
    WarmUp,
    Working,
    DropSet,
    Amrap,
    Failure,
}

impl Default for SetType {
    fn default() -> Self {
        Self::Working
    }
}
```

**Success Criteria**:
- [ ] Enum compiles without errors
- [ ] Serde rename for camelCase serialization
- [ ] Default implementation

##### Sub-Task 1.2.4: Create Body Part Enums

**File**: `/applications/thiccc/app/shared/src/models.rs`

**Implementation Details**:
```rust
/// Main body part categories
#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, Eq, Hash)]
#[serde(rename_all = "lowercase")]
pub enum BodyPartMain {
    Chest,
    Legs,
    Arms,
    Back,
    Calves,
    Shoulders,
    Core,
    Cardio,
    #[serde(rename = "fullBody")]
    FullBody,
    Other,
}

/// Detailed body part information
#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
pub struct BodyPart {
    /// Main body part category
    pub main: BodyPartMain,
    
    /// Detailed muscle names (optional)
    pub detailed: Option<Vec<String>>,
    
    /// Scientific muscle names (optional)
    pub scientific: Option<Vec<String>>,
}
```

**Success Criteria**:
- [ ] Both types compile without errors
- [ ] Proper serde attributes
- [ ] Doc comments added

#### Agent Prompt Template

```
I need you to implement enumeration types for the Thiccc workout tracking app.

**Reference Files:**
- @legacy/Goonlytics/Goonlytics/Sources/Workout/Models/Workout.swift (lines 54-109)

**Task: Create Exercise-Related Enums**

In `/applications/thiccc/app/shared/src/models.rs`, create these enums:

1. `ExerciseType`: Dumbbell, Kettlebell, Barbell, Hexbar, Bodyweight, Machine, Unknown
2. `WeightUnit`: Kilograms ("kg"), Pounds ("lb"), Bodyweight
3. `SetType`: WarmUp, Working, DropSet, Amrap, Failure
4. `BodyPartMain`: Chest, Legs, Arms, Back, Calves, Shoulders, Core, Cardio, FullBody, Other
5. `BodyPart` struct: main (BodyPartMain), detailed (Option<Vec<String>>), scientific (Option<Vec<String>>)

**Requirements:**
1. All enums must derive: `Serialize`, `Deserialize`, `Clone`, `Debug`, `PartialEq`, `Eq`, `Hash`
2. Use serde attributes for proper serialization:
   - `#[serde(rename_all = "lowercase")]` for most enums
   - `#[serde(rename = "...")]` for specific variants that need custom names
3. Implement `Default` for enums where appropriate
4. Add doc comments

**Success Criteria:**
- [ ] All enums compile without errors
- [ ] Serde attributes match Swift string representations
- [ ] Proper derives
- [ ] No clippy warnings
```

---

### Task 1.3: Global Exercise Library Model

**Estimated Time**: 30 minutes  
**Complexity**: Low  
**Priority**: Medium (needed for Task 6.2)

#### Objective
Create the `GlobalExercise` struct used for the exercise library.

#### Reference Files
- `legacy/Goonlytics/Goonlytics/Sources/Workout/AddExerciseView.swift` (lines 6-13)

#### Implementation Details

**File**: `/applications/thiccc/app/shared/src/models.rs`

```rust
/// Exercise from the global exercise library
#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, Eq, Hash)]
pub struct GlobalExercise {
    /// Unique identifier
    pub id: Uuid,
    
    /// Exercise name
    pub name: String,
    
    /// Equipment type
    #[serde(rename = "type")]
    pub exercise_type: String,
    
    /// Additional foreign key (optional, for future use)
    pub additional_fk: Option<String>,
    
    /// Primary muscle group targeted
    pub muscle_group: String,
    
    /// Image asset name
    pub image_name: String,
}
```

#### Success Criteria
- [ ] Struct compiles without errors
- [ ] All fields match Swift equivalent
- [ ] Proper derives (include `Eq`, `Hash` since it will be used in sets)
- [ ] Doc comments added
- [ ] Serde rename for `type` field (reserved keyword in Rust)

#### Agent Prompt Template

```
I need you to implement the `GlobalExercise` struct for the exercise library in the Thiccc app.

**Reference Files:**
- @legacy/Goonlytics/Goonlytics/Sources/Workout/AddExerciseView.swift (lines 6-13)

**Task: Create GlobalExercise Model**

In `/applications/thiccc/app/shared/src/models.rs`, create:

`GlobalExercise` struct with fields:
- id: Uuid
- name: String
- exercise_type: String (use serde rename from "type")
- additional_fk: Option<String>
- muscle_group: String
- image_name: String

**Requirements:**
1. Derive: `Serialize`, `Deserialize`, `Clone`, `Debug`, `PartialEq`, `Eq`, `Hash`
2. Use `#[serde(rename = "type")]` for the exercise_type field (since "type" is a Rust keyword)
3. Add doc comments

**Success Criteria:**
- [ ] Compiles without errors
- [ ] Proper serde rename attribute
- [ ] All required derives
```

---

### Task 1.4: Update Shared Types Code Generation

**Estimated Time**: 15 minutes  
**Complexity**: Low  
**Priority**: Medium (needed before Swift integration)

#### Objective
Ensure new models are exported and Swift types are generated.

#### Files to Modify
- `/applications/thiccc/app/shared/src/lib.rs`
- `/applications/thiccc/app/shared/src/models.rs` (add `pub mod` declaration)

#### Implementation Details

**In `src/lib.rs`**:
```rust
pub mod app;
pub mod models;  // Add this line

pub use models::*;  // Re-export all model types
```

**In `src/models.rs`**:
Ensure all structs and enums are marked `pub`.

#### Build and Verify

Run the build to generate Swift bindings:
```bash
cd applications/thiccc/app/shared
./build-ios.sh
```

Check that Swift types are generated:
```bash
ls -la ../shared_types/generated/swift/SharedTypes/
```

#### Success Criteria
- [ ] Models are exported from lib.rs
- [ ] Build succeeds without errors
- [ ] Swift types are generated in shared_types directory
- [ ] Swift types match Rust types

#### Agent Prompt Template

```
I need you to ensure the new Rust models are properly exported for Swift code generation in the Thiccc app.

**Task: Export Models and Generate Swift Bindings**

1. In `/applications/thiccc/app/shared/src/lib.rs`:
   - Add `pub mod models;`
   - Add `pub use models::*;` to re-export all types

2. Build the project to generate Swift bindings:
   ```bash
   cd /applications/thiccc/app/shared
   ./build-ios.sh
   ```

3. Verify Swift types were generated:
   - Check `/applications/thiccc/app/shared_types/generated/swift/SharedTypes/`
   - Verify Swift files exist for Workout, Exercise, etc.

**Success Criteria:**
- [ ] Models are exported from lib.rs
- [ ] Build succeeds
- [ ] Swift types are generated
- [ ] No build errors or warnings
```

---

## Phase 1 Completion Checklist

Before moving to Phase 2, verify:

- [ ] All Rust models compile without errors
- [ ] All models can serialize/deserialize to/from JSON
- [ ] Swift bindings are generated successfully
- [ ] No clippy warnings: `cargo clippy --all-targets`
- [ ] All doc comments are present
- [ ] Code follows Rust style guidelines: `cargo fmt --check`
- [ ] Models match Swift equivalents in Goonlytics

## Testing Phase 1

### Manual Serialization Test

Add a test to verify serialization works:

```rust
#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_workout_serialization() {
        let workout = Workout::new();
        let json = serde_json::to_string(&workout).expect("Failed to serialize");
        let deserialized: Workout = serde_json::from_str(&json).expect("Failed to deserialize");
        assert_eq!(workout, deserialized);
    }
    
    #[test]
    fn test_exercise_set_with_actual_values() {
        let set = ExerciseSet {
            id: Uuid::new_v4(),
            set_type: SetType::Working,
            weight_unit: Some(WeightUnit::Pounds),
            suggest: SetSuggest::default(),
            actual: SetActual {
                weight: Some(225.0),
                reps: Some(10),
                rpe: Some(8.0),
                ..Default::default()
            },
            is_completed: true,
            exercise_id: Uuid::new_v4(),
            workout_id: Uuid::new_v4(),
            set_index: 0,
        };
        
        let json = serde_json::to_string(&set).expect("Failed to serialize");
        assert!(json.contains("225"));
        assert!(json.contains("10"));
    }
}
```

Run tests:
```bash
cd applications/thiccc/app/shared
cargo test
```

## Common Issues & Solutions

### Issue: Serde serialization errors
**Solution**: Ensure all nested types also derive `Serialize` and `Deserialize`

### Issue: Uuid serialization format mismatch
**Solution**: Use uuid crate with `serde` feature enabled

### Issue: DateTime timezone issues
**Solution**: Always use `DateTime<Utc>` for consistency. Convert to local time in UI layer if needed.

### Issue: Swift binding generation fails
**Solution**: Check that all types are `pub` and properly exported from `lib.rs`

## Next Steps

After completing Phase 1, proceed to:
- **[Phase 2: Events & State](./02-PHASE-2-EVENTS-STATE.md)** - Define all events and app state

---

**Phase Status**: 📋 Ready for Implementation  
**Last Updated**: November 26, 2025

