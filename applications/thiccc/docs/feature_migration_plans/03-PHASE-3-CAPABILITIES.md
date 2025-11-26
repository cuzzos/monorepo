# Phase 3: Capabilities (Platform Integration)

## Overview

**Goal**: Implement Crux capabilities for platform-specific operations (database, file storage, timers).

**Phase Duration**: Estimated 3-5 hours  
**Complexity**: High  
**Dependencies**: Phase 2 (Events & State)  
**Blocks**: Phase 4 (Business Logic), Phase 9 (Database Implementation)

## Why This Phase Matters

Capabilities are the bridge between Rust core and platform-specific functionality. They enable:
- Database operations (GRDB on iOS)
- File I/O for current workout persistence
- Timer functionality for workout duration tracking
- Clean separation between pure logic and platform code

## Important Notes

⚠️ **Complexity Warning**: This is one of the more complex phases. Capabilities require:
- Understanding Crux capability patterns
- Rust request/response types
- Swift shell integration
- Async handling

💡 **Recommendation**: Start with the simplest capability (FileStorage) before tackling Database.

📚 **Reference**: Review Crux capability examples at https://github.com/redbadger/crux/tree/master/examples

## Task Breakdown

### Task 3.1: Database Capability

**Estimated Time**: 2-3 hours  
**Complexity**: High  
**Priority**: Critical (for persistence)

#### Objective
Create capability for all database operations (save/load workouts).

#### Sub-Tasks

##### Sub-Task 3.1.1: Define Database Capability (Rust Side)

**File**: `/applications/thiccc/app/shared/src/capabilities/database.rs` (new file)

**Implementation Details**:
```rust
use crux_core::capability::{CapabilityContext, Operation};
use serde::{Deserialize, Serialize};
use uuid::Uuid;
use crate::models::Workout;

/// Database operations
#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
pub enum DatabaseOperation {
    /// Save a completed workout to database
    SaveWorkout(Workout),
    
    /// Load all workouts from database (for history view)
    LoadAllWorkouts,
    
    /// Load a specific workout by ID (with all exercises and sets)
    LoadWorkoutById(Uuid),
    
    /// Delete a workout by ID
    DeleteWorkout(Uuid),
}

/// Database operation responses
#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
pub enum DatabaseResponse {
    /// Workout successfully saved
    WorkoutSaved,
    
    /// Workouts loaded
    WorkoutsLoaded(Vec<Workout>),
    
    /// Single workout loaded
    WorkoutLoaded(Option<Workout>),
    
    /// Workout deleted
    WorkoutDeleted,
    
    /// Database operation failed
    Error(String),
}

/// Database capability
pub struct Database<Ev> {
    context: CapabilityContext<DatabaseOperation, Ev>,
}

impl<Ev> Database<Ev>
where
    Ev: 'static,
{
    pub fn new(context: CapabilityContext<DatabaseOperation, Ev>) -> Self {
        Self { context }
    }

    /// Save a workout to the database
    pub fn save_workout(&self, workout: Workout, make_event: impl Fn(DatabaseResponse) -> Ev + Send + 'static) {
        self.context.spawn({
            let context = self.context.clone();
            async move {
                context.request_from_shell(DatabaseOperation::SaveWorkout(workout)).await;
            }
        });
        
        // Alternative simpler pattern (if Crux supports it):
        // self.context.request(
        //     DatabaseOperation::SaveWorkout(workout),
        //     make_event,
        // );
    }

    /// Load all workouts
    pub fn load_all_workouts(&self, make_event: impl Fn(DatabaseResponse) -> Ev + Send + 'static) {
        self.context.spawn({
            let context = self.context.clone();
            async move {
                context.request_from_shell(DatabaseOperation::LoadAllWorkouts).await;
            }
        });
    }

    /// Load a specific workout by ID
    pub fn load_workout_by_id(&self, id: Uuid, make_event: impl Fn(DatabaseResponse) -> Ev + Send + 'static) {
        self.context.spawn({
            let context = self.context.clone();
            async move {
                context.request_from_shell(DatabaseOperation::LoadWorkoutById(id)).await;
            }
        });
    }
}

// Implement Operation trait
impl Operation for DatabaseOperation {
    type Output = DatabaseResponse;
}
```

**Notes**:
- The exact capability pattern may vary based on Crux version
- Consult latest Crux documentation for current patterns
- The `spawn` and `request_from_shell` pattern shown is simplified
- You may need to adjust based on actual Crux API

**Success Criteria**:
- [ ] Code compiles without errors
- [ ] All operations defined
- [ ] Request/response types are serializable
- [ ] Follows Crux capability patterns
- [ ] Doc comments added

##### Sub-Task 3.1.2: Integrate Database Capability into App

**File**: `/applications/thiccc/app/shared/src/app.rs`

**Add capability to Effect enum**:
```rust
use crate::capabilities::database::{Database, DatabaseOperation, DatabaseResponse};

#[derive(crux_core::macros::Effect)]
pub enum Effect {
    Render(crux_core::render::RenderOperation),
    Database(DatabaseOperation),
    // More capabilities will be added...
}
```

**Add capability to Capabilities struct** (or however Crux structures it in latest version):
```rust
pub struct Capabilities {
    pub render: Render<Event>,
    pub database: Database<Event>,
    // More capabilities...
}
```

**Success Criteria**:
- [ ] Capability integrated into app
- [ ] Compiles without errors
- [ ] Can call database operations from update function

##### Sub-Task 3.1.3: Implement Database Capability (Swift Side)

**File**: `/applications/thiccc/app/ios/Thiccc/Capabilities/DatabaseCapability.swift` (new file)

**Implementation Details**:
```swift
import Foundation
import GRDB
import SharedTypes

/// Handles database capability requests from Rust core
class DatabaseCapability {
    let database: DatabaseWriter
    
    init(database: DatabaseWriter) {
        self.database = database
    }
    
    /// Handle a database operation request from core
    func handle(_ operation: DatabaseOperation, core: Core) async {
        switch operation {
        case .saveWorkout(let workout):
            await handleSaveWorkout(workout, core: core)
            
        case .loadAllWorkouts:
            await handleLoadAllWorkouts(core: core)
            
        case .loadWorkoutById(let id):
            await handleLoadWorkoutById(id, core: core)
            
        case .deleteWorkout(let id):
            await handleDeleteWorkout(id, core: core)
        }
    }
    
    private func handleSaveWorkout(_ workout: Workout, core: Core) async {
        do {
            try await database.write { db in
                // Save workout
                try db.execute(
                    sql: """
                        INSERT INTO workouts (id, name, note, duration, startTimestamp, endTimestamp)
                        VALUES (?, ?, ?, ?, ?, ?)
                    """,
                    arguments: [
                        workout.id.uuidString.lowercased(),
                        workout.name,
                        workout.note,
                        workout.duration,
                        workout.startTimestamp.timeIntervalSince1970,
                        workout.endTimestamp?.timeIntervalSince1970
                    ]
                )
                
                // Save exercises and sets
                for exercise in workout.exercises {
                    try db.execute(
                        sql: """
                            INSERT INTO exercises (id, workoutId, name, type, weightUnit, ...)
                            VALUES (?, ?, ?, ?, ?, ...)
                        """,
                        arguments: [/* exercise fields */]
                    )
                    
                    for set in exercise.sets {
                        try db.execute(
                            sql: """
                                INSERT INTO exerciseSets (id, exerciseId, workoutId, ...)
                                VALUES (?, ?, ?, ...)
                            """,
                            arguments: [/* set fields */]
                        )
                    }
                }
            }
            
            // Send success response
            let response = DatabaseResponse.workoutSaved
            core.handleDatabaseResponse(response)
            
        } catch {
            // Send error response
            let response = DatabaseResponse.error(error.localizedDescription)
            core.handleDatabaseResponse(response)
        }
    }
    
    private func handleLoadAllWorkouts(core: Core) async {
        do {
            let workouts = try await database.read { db in
                // Load all workouts with exercises and sets
                // This is simplified - actual implementation needs joins
                try Workout.fetchAll(db)
            }
            
            let response = DatabaseResponse.workoutsLoaded(workouts)
            core.handleDatabaseResponse(response)
            
        } catch {
            let response = DatabaseResponse.error(error.localizedDescription)
            core.handleDatabaseResponse(response)
        }
    }
    
    // Similar implementations for loadWorkoutById and deleteWorkout...
}
```

**Note**: The exact Core integration will depend on how the Swift bridge is set up. You'll need to wire the capability into the Core's effect handling.

**Success Criteria**:
- [ ] Swift code compiles
- [ ] Can handle all database operations
- [ ] Proper error handling
- [ ] Sends responses back to core
- [ ] Uses GRDB correctly

#### Agent Prompt Template

Use **Template 5: Crux Capability Implementation (Rust Side)** and **Template 6: Crux Capability Implementation (Swift Side)** from AGENT-PROMPT-TEMPLATES.md.

---

### Task 3.2: File Storage Capability

**Estimated Time**: 1 hour  
**Complexity**: Medium  
**Priority**: High (for current workout persistence)

#### Objective
Create capability for saving/loading current workout to/from file system.

#### Sub-Tasks

##### Sub-Task 3.2.1: Define Storage Capability (Rust Side)

**File**: `/applications/thiccc/app/shared/src/capabilities/storage.rs` (new file)

**Implementation Details**:
```rust
use crux_core::capability::{CapabilityContext, Operation};
use serde::{Deserialize, Serialize};
use crate::models::Workout;

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
pub enum StorageOperation {
    /// Save current workout to file
    SaveCurrentWorkout(Workout),
    
    /// Load current workout from file
    LoadCurrentWorkout,
    
    /// Delete current workout file
    DeleteCurrentWorkout,
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
pub enum StorageResponse {
    CurrentWorkoutSaved,
    CurrentWorkoutLoaded(Option<Workout>),
    CurrentWorkoutDeleted,
    Error(String),
}

pub struct Storage<Ev> {
    context: CapabilityContext<StorageOperation, Ev>,
}

impl<Ev> Storage<Ev>
where
    Ev: 'static,
{
    pub fn new(context: CapabilityContext<StorageOperation, Ev>) -> Self {
        Self { context }
    }

    pub fn save_current_workout(&self, workout: Workout, make_event: impl Fn(StorageResponse) -> Ev + Send + 'static) {
        // Implementation similar to Database capability
    }

    pub fn load_current_workout(&self, make_event: impl Fn(StorageResponse) -> Ev + Send + 'static) {
        // Implementation similar to Database capability
    }

    pub fn delete_current_workout(&self, make_event: impl Fn(StorageResponse) -> Ev + Send + 'static) {
        // Implementation similar to Database capability
    }
}

impl Operation for StorageOperation {
    type Output = StorageResponse;
}
```

##### Sub-Task 3.2.2: Implement Storage Capability (Swift Side)

**File**: `/applications/thiccc/app/ios/Thiccc/Capabilities/StorageCapability.swift` (new file)

```swift
import Foundation
import SharedTypes

class StorageCapability {
    private let fileURL: URL
    
    init() {
        self.fileURL = URL.documentsDirectory.appending(component: "current-workout.json")
    }
    
    func handle(_ operation: StorageOperation, core: Core) async {
        switch operation {
        case .saveCurrentWorkout(let workout):
            await handleSave(workout, core: core)
            
        case .loadCurrentWorkout:
            await handleLoad(core: core)
            
        case .deleteCurrentWorkout:
            await handleDelete(core: core)
        }
    }
    
    private func handleSave(_ workout: Workout, core: Core) async {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(workout)
            try data.write(to: fileURL, options: .atomic)
            
            let response = StorageResponse.currentWorkoutSaved
            core.handleStorageResponse(response)
        } catch {
            let response = StorageResponse.error(error.localizedDescription)
            core.handleStorageResponse(response)
        }
    }
    
    private func handleLoad(core: Core) async {
        do {
            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                let response = StorageResponse.currentWorkoutLoaded(nil)
                core.handleStorageResponse(response)
                return
            }
            
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let workout = try decoder.decode(Workout.self, from: data)
            
            let response = StorageResponse.currentWorkoutLoaded(workout)
            core.handleStorageResponse(response)
        } catch {
            let response = StorageResponse.error(error.localizedDescription)
            core.handleStorageResponse(response)
        }
    }
    
    private func handleDelete(core: Core) async {
        do {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
            }
            
            let response = StorageResponse.currentWorkoutDeleted
            core.handleStorageResponse(response)
        } catch {
            let response = StorageResponse.error(error.localizedDescription)
            core.handleStorageResponse(response)
        }
    }
}
```

**Success Criteria**:
- [ ] Can save workout to file
- [ ] Can load workout from file
- [ ] Can delete workout file
- [ ] Proper error handling
- [ ] Uses JSON encoding with proper date strategy

---

### Task 3.3: Timer Capability

**Estimated Time**: 1-2 hours  
**Complexity**: Medium  
**Priority**: High (for workout duration tracking)

#### Objective
Create capability for workout timer that sends tick events every second.

#### Sub-Tasks

##### Sub-Task 3.3.1: Define Timer Capability (Rust Side)

**File**: `/applications/thiccc/app/shared/src/capabilities/timer.rs` (new file)

```rust
use crux_core::capability::{CapabilityContext, Operation};
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
pub enum TimerOperation {
    /// Start the timer (sends tick events every second)
    Start,
    
    /// Stop the timer
    Stop,
    
    /// Pause the timer
    Pause,
    
    /// Resume the timer
    Resume,
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
pub enum TimerResponse {
    /// Timer tick (sent every second)
    Tick,
    
    /// Timer started
    Started,
    
    /// Timer stopped
    Stopped,
}

pub struct Timer<Ev> {
    context: CapabilityContext<TimerOperation, Ev>,
}

impl<Ev> Timer<Ev>
where
    Ev: 'static,
{
    pub fn new(context: CapabilityContext<TimerOperation, Ev>) -> Self {
        Self { context }
    }

    pub fn start(&self, make_event: impl Fn(TimerResponse) -> Ev + Send + 'static) {
        // Implementation
    }

    pub fn stop(&self, make_event: impl Fn(TimerResponse) -> Ev + Send + 'static) {
        // Implementation
    }
}

impl Operation for TimerOperation {
    type Output = TimerResponse;
}
```

##### Sub-Task 3.3.2: Implement Timer Capability (Swift Side)

**File**: `/applications/thiccc/app/ios/Thiccc/Capabilities/TimerCapability.swift` (new file)

```swift
import Foundation
import SharedTypes

class TimerCapability {
    private var timer: Timer?
    private weak var core: Core?
    
    func handle(_ operation: TimerOperation, core: Core) {
        self.core = core
        
        switch operation {
        case .start:
            startTimer()
            
        case .stop:
            stopTimer()
            
        case .pause:
            stopTimer()
            
        case .resume:
            startTimer()
        }
    }
    
    private func startTimer() {
        stopTimer() // Stop any existing timer
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let core = self.core else { return }
            
            // Send tick event to core
            let response = TimerResponse.tick
            core.handleTimerResponse(response)
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
```

**Success Criteria**:
- [ ] Timer sends tick events every second
- [ ] Can start/stop timer
- [ ] Timer properly invalidated
- [ ] No memory leaks

---

## Phase 3 Completion Checklist

Before moving to Phase 4, verify:

- [ ] Database capability implemented (Rust + Swift)
- [ ] Storage capability implemented (Rust + Swift)
- [ ] Timer capability implemented (Rust + Swift)
- [ ] All capabilities integrated into Effect enum
- [ ] Code compiles without errors (both Rust and Swift)
- [ ] No clippy warnings
- [ ] Capabilities can be called from update function
- [ ] Swift shell can send responses back to core

## Testing Phase 3

### Manual Testing Checklist

Test each capability independently:

**Database Capability:**
- [ ] Save a workout → verify it's in database
- [ ] Load workouts → verify they're returned
- [ ] Error cases → verify error responses

**Storage Capability:**
- [ ] Save current workout → verify file exists
- [ ] Load current workout → verify workout loaded
- [ ] Delete → verify file removed

**Timer Capability:**
- [ ] Start timer → verify tick events received
- [ ] Stop timer → verify ticks stop
- [ ] Multiple start/stop cycles work correctly

## Common Issues & Solutions

### Issue: Capability requests not reaching Swift shell
**Solution**: Verify effect handling is wired up correctly in Core bridge

### Issue: Responses not reaching Rust core
**Solution**: Check that response events are properly dispatched

### Issue: Timer not invalidating properly
**Solution**: Ensure weak references and proper cleanup

### Issue: Database queries slow
**Solution**: Add indices, use transactions, batch operations

## Next Steps

After completing Phase 3, proceed to:
- **[Phase 4: Core Business Logic](./04-PHASE-4-BUSINESS-LOGIC.md)** - Implement update and view functions

---

**Phase Status**: 📋 Ready for Implementation  
**Last Updated**: November 26, 2025
