# Phase 8: Additional Features UI + Custom Exercises

## Overview

**Goal**: Implement exercise library with custom exercise CRUD, plus supporting features (timers, plate calculator, import).

**Phase Duration**: Estimated 6-8 hours  
**Complexity**: Medium-High  
**Dependencies**: Phase 5 (Navigation), Phase 9 (Database)  
**Blocks**: None

## Why This Phase Matters

These features complete the MVP experience:
- **Exercise library (CRITICAL)**: Users can browse and add from 60+ built-in exercises
- **Custom exercises (CRITICAL FOR MVP)**: Users can create/delete custom exercises for their specific needs
- **Import (Medium Priority)**: Enables workout template migration
- **Timers (Post-MVP)**: Nice-to-have for rest periods
- **Plate calculator (Post-MVP)**: Nice-to-have for barbell loading

**MVP Justification for Custom Exercises:**
Thiccc aims to be a full digital replacement for pen & paper workout journals. Just as users can write any exercise name in a notebook, they must be able to create custom exercises in the app. Real-world users WILL encounter exercises not in the built-in library (gym-specific machines, exercise variations, personal preferences).

## Architecture Decision: Exercise Library Storage

### Single-Table Design (Recommended)

**Database Schema:**
```sql
CREATE TABLE exercises (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    muscle_group TEXT NOT NULL,
    type TEXT NOT NULL,
    source TEXT NOT NULL DEFAULT 'builtin',  -- 'builtin' | 'user' | 'community'
    is_custom BOOLEAN NOT NULL DEFAULT 0,
    usage_count INTEGER NOT NULL DEFAULT 0,  -- For future analytics
    created_at INTEGER NOT NULL,
    
    -- Future columns (add when needed, schema ready for expansion)
    -- image_url TEXT,
    -- description TEXT,
    -- server_id TEXT,  -- For cloud sync (Phase 12)
    -- last_synced_at INTEGER
);

CREATE INDEX idx_exercises_muscle_group ON exercises(muscle_group);
CREATE INDEX idx_exercises_source ON exercises(source);
```

**Migration Strategy:**
1. **Phase 8 (Now)**: Seed database with 60 built-in exercises on first app launch
2. **Phase 8 (Now)**: User-created exercises stored with `source = 'user'`, `is_custom = true`
3. **Phase 12 (Future)**: Server-synced exercises marked with `source = 'community'`

**Why Single Table:**
- ✅ No data duplication
- ✅ Simple queries (single SELECT for all exercises)
- ✅ Easy migration path (built-in → database → community)
- ✅ Future-proof schema for analytics and sync
- ✅ Natural filtering: `WHERE source = 'user'` for custom-only view

**Alternative Rejected**: Separate `custom_exercises` table would require:
- Duplicate schema definitions
- Complex UNION queries
- Migration logic to "promote" custom → global
- Confusing UX ("why can't I see my exercise in history?")

---

## Task Breakdown

### Task 8.1: Exercise Library Database Setup

**Estimated Time**: 1 hour  
**Complexity**: Medium  
**Priority**: CRITICAL (MVP Blocker)

#### Objective
Create `exercises` table and seed built-in exercises on first app launch.

#### Implementation

**File**: `/applications/thiccc/app/ios/Thiccc/Database/Schema.swift`

Add table creation:
```swift
static let createExercisesTable = """
    CREATE TABLE IF NOT EXISTS exercises (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        muscle_group TEXT NOT NULL,
        type TEXT NOT NULL,
        source TEXT NOT NULL DEFAULT 'builtin',
        is_custom INTEGER NOT NULL DEFAULT 0,
        usage_count INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL
    );
    
    CREATE INDEX IF NOT EXISTS idx_exercises_muscle_group 
        ON exercises(muscle_group);
    CREATE INDEX IF NOT EXISTS idx_exercises_source 
        ON exercises(source);
"""
```

**File**: `/applications/thiccc/app/ios/Thiccc/Database/DatabaseManager.swift`

Add seeding function:
```swift
func seedBuiltinExercises() async throws {
    // Check if already seeded
    let count = try await db.read { db in
        try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM exercises WHERE source = 'builtin'") ?? 0
    }
    
    if count > 0 { return }  // Already seeded
    
    // Get built-in exercises from ExerciseLibrary
    let builtins = ExerciseLibrary.defaults
    
    try await db.write { db in
        for exercise in builtins {
            try db.execute(sql: """
                INSERT INTO exercises (id, name, muscle_group, type, source, is_custom, created_at)
                VALUES (?, ?, ?, ?, 'builtin', 0, ?)
                """,
                arguments: [
                    UUID().uuidString,
                    exercise.name,
                    exercise.muscleGroup,
                    exercise.type,
                    Int(Date().timeIntervalSince1970)
                ]
            )
        }
    }
}
```

**File**: `/applications/thiccc/app/ios/Thiccc/AddExerciseView.swift`

Create `ExerciseLibrary` helper:
```swift
// Move hardcoded list to static property for seeding
struct ExerciseLibrary {
    static let defaults: [ExerciseLibraryItem] = [
        // Chest
        ExerciseLibraryItem(name: "Barbell Bench Press", type: "Compound", muscleGroup: "Chest"),
        ExerciseLibraryItem(name: "Dumbbell Bench Press", type: "Compound", muscleGroup: "Chest"),
        // ... (rest of 60 exercises)
    ]
}
```

**Success Criteria**:
- [ ] `exercises` table created on first launch
- [ ] 60+ built-in exercises seeded with `source = 'builtin'`
- [ ] Seeding only happens once (idempotent)
- [ ] Database queries work for all exercises

---

### Task 8.2: Implement Add Exercise View (with Database)

**Estimated Time**: 1.5 hours  
**Complexity**: Medium  
**Priority**: High

#### Objective
Create searchable exercise library that reads from database and shows all exercises (built-in + custom).

#### Reference Files
- `legacy/Goonlytics/Goonlytics/Sources/Workout/AddExerciseView.swift`

#### Implementation

**File**: `/applications/thiccc/app/ios/Thiccc/AddExerciseView.swift` (update existing)

Update to load from database:
```swift
import SwiftUI

struct AddExerciseView: View {
    @Bindable var core: Core
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @State private var selectedExercises: Set<String> = []
    @State private var showingCreateForm = false
    
    var exercises: [ExerciseLibraryItem] {
        core.view.exercises  // Loaded from database
    }
    
    var filteredExercises: [ExerciseLibraryItem] {
        if searchText.isEmpty {
            return exercises
        }
        return exercises.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.muscleGroup.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var filteredExercisesByMuscleGroup: [(key: String, value: [ExerciseLibraryItem])] {
        let grouped = Dictionary(grouping: filteredExercises, by: { $0.muscleGroup })
        return grouped.sorted { $0.key < $1.key }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar
                
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(filteredExercisesByMuscleGroup, id: \.key) { group in
                            muscleGroupSection(group: group.key, exercises: group.value)
                        }
                    }
                    .padding(.horizontal)
                }
                
                if !selectedExercises.isEmpty {
                    addButton
                        .transition(.move(edge: .bottom))
                }
            }
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingCreateForm = true
                    } label: {
                        Label("Create", systemImage: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showingCreateForm) {
                CreateExerciseView(core: core)
            }
            .task {
                // Load exercises from database when view appears
                await core.update(.loadExercises)
            }
        }
    }
    
    private func muscleGroupSection(group: String, exercises: [ExerciseLibraryItem]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(group)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 8)
            
            ForEach(exercises, id: \.id) { exercise in
                ExerciseRow(
                    exercise: exercise,
                    isSelected: selectedExercises.contains(exercise.id),
                    onTap: { toggleSelection(exercise.id) }
                )
            }
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search exercises", text: $searchText)
                .autocorrectionDisabled()
        }
        .padding(10)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding([.horizontal, .top])
    }
    
    private var addButton: some View {
        Button {
            let selected = exercises.filter { selectedExercises.contains($0.id) }
            for exercise in selected {
                Task { await core.update(.addExerciseToWorkout(exerciseId: exercise.id)) }
            }
            dismiss()
        } label: {
            Text("Add \(selectedExercises.count) exercise\(selectedExercises.count > 1 ? "s" : "")")
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding([.horizontal, .bottom])
        }
    }
    
    private func toggleSelection(_ id: String) {
        if selectedExercises.contains(id) {
            selectedExercises.remove(id)
        } else {
            selectedExercises.insert(id)
        }
    }
}

struct ExerciseRow: View {
    let exercise: ExerciseLibraryItem
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                Circle()
                    .fill(isSelected ? Color.blue : Color(.systemGray4))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(String(exercise.name.prefix(1)))
                            .foregroundStyle(.white)
                            .fontWeight(.medium)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(exercise.name)
                            .foregroundStyle(.primary)
                            .fontWeight(.medium)
                        
                        // Badge for custom exercises
                        if exercise.isCustom {
                            Image(systemName: "person.fill")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Text(exercise.muscleGroup)
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.blue)
                        .imageScale(.large)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        // Swipe to delete for custom exercises only
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if exercise.isCustom {
                Button(role: .destructive) {
                    // Delete handled by parent view
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }
}

struct ExerciseLibraryItem {
    let id: String
    let name: String
    let type: String
    let muscleGroup: String
    let isCustom: Bool
    let source: String
}
```

**Rust Core Changes:**

**File**: `app/shared/src/app.rs`

Add events and state:
```rust
pub enum Event {
    // ... existing events
    LoadExercises,
    ExercisesLoaded { exercises: Vec<Exercise> },
    AddExerciseToWorkout { exercise_id: String },
}

pub struct Model {
    // ... existing fields
    pub exercises: Vec<Exercise>,  // All exercises (built-in + custom)
}

pub struct ViewModel {
    // ... existing fields
    pub exercises: Vec<ExerciseViewModel>,
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
pub struct Exercise {
    pub id: String,
    pub name: String,
    pub muscle_group: String,
    pub exercise_type: String,
    pub source: String,  // "builtin" | "user" | "community"
    pub is_custom: bool,
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
pub struct ExerciseViewModel {
    pub id: String,
    pub name: String,
    pub muscle_group: String,
    pub exercise_type: String,
    pub is_custom: bool,
}

// In update()
Event::LoadExercises => {
    let effect = Effect::LoadExercises;
    model.update(effect);
}

Event::ExercisesLoaded { exercises } => {
    model.exercises = exercises;
    render()
}

// In view()
pub fn view(model: &Model) -> ViewModel {
    ViewModel {
        // ...
        exercises: model.exercises.iter().map(|e| ExerciseViewModel {
            id: e.id.clone(),
            name: e.name.clone(),
            muscle_group: e.muscle_group.clone(),
            exercise_type: e.exercise_type.clone(),
            is_custom: e.is_custom,
        }).collect(),
    }
}
```

**Success Criteria**:
- [ ] Exercise list loads from database
- [ ] Built-in and custom exercises show together
- [ ] Custom exercises have visual badge (person icon)
- [ ] Search works across all exercises
- [ ] Muscle group filtering works
- [ ] Multi-select works
- [ ] Add button sends correct event
- [ ] Swipe-to-delete only shows for custom exercises

---

### Task 8.3: Implement Custom Exercise Creation

**Estimated Time**: 2 hours  
**Complexity**: Medium  
**Priority**: CRITICAL (MVP Blocker)

#### Objective
Allow users to create custom exercises with name, muscle group, and type.

#### Implementation

**File**: `/applications/thiccc/app/ios/Thiccc/CreateExerciseView.swift` (new file)

```swift
import SwiftUI

struct CreateExerciseView: View {
    @Bindable var core: Core
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var selectedMuscleGroup = "Chest"
    @State private var selectedType = "Compound"
    @State private var showingError = false
    @State private var errorMessage = ""
    
    let muscleGroups = [
        "Chest", "Back", "Legs", "Shoulders", "Arms", "Core", "Full Body", "Cardio"
    ]
    
    let exerciseTypes = [
        "Compound", "Isolation", "Bodyweight", "Isometric", "Cardio"
    ]
    
    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Exercise Name", text: $name)
                        .autocorrectionDisabled()
                } header: {
                    Text("Name")
                } footer: {
                    Text("Enter a descriptive name for your exercise")
                }
                
                Section("Muscle Group") {
                    Picker("Muscle Group", selection: $selectedMuscleGroup) {
                        ForEach(muscleGroups, id: \.self) { group in
                            Text(group).tag(group)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section("Type") {
                    Picker("Exercise Type", selection: $selectedType) {
                        ForEach(exerciseTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            .navigationTitle("Create Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task {
                            await createExercise()
                        }
                    }
                    .disabled(!isValid)
                    .fontWeight(.semibold)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func createExercise() async {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        
        await core.update(.createCustomExercise(
            name: trimmedName,
            muscleGroup: selectedMuscleGroup,
            exerciseType: selectedType
        ))
        
        // Reload exercises to show the new one
        await core.update(.loadExercises)
        
        dismiss()
    }
}
```

**Rust Core Changes:**

**File**: `app/shared/src/app.rs`

Add events:
```rust
pub enum Event {
    // ... existing
    CreateCustomExercise { name: String, muscle_group: String, exercise_type: String },
    DeleteCustomExercise { exercise_id: String },
}

// In update()
Event::CreateCustomExercise { name, muscle_group, exercise_type } => {
    let exercise = Exercise {
        id: Uuid::new_v4().to_string(),
        name,
        muscle_group,
        exercise_type,
        source: "user".to_string(),
        is_custom: true,
    };
    
    let effect = Effect::SaveCustomExercise { exercise };
    model.update(effect);
}

Event::DeleteCustomExercise { exercise_id } => {
    let effect = Effect::DeleteCustomExercise { exercise_id };
    model.update(effect);
}
```

**Database Capability:**

**File**: `app/ios/Thiccc/Database/DatabaseManager.swift`

Add methods:
```swift
func saveCustomExercise(_ exercise: Exercise) async throws {
    try await db.write { db in
        try db.execute(sql: """
            INSERT INTO exercises (id, name, muscle_group, type, source, is_custom, created_at)
            VALUES (?, ?, ?, ?, 'user', 1, ?)
            """,
            arguments: [
                exercise.id,
                exercise.name,
                exercise.muscleGroup,
                exercise.type,
                Int(Date().timeIntervalSince1970)
            ]
        )
    }
}

func loadExercises() async throws -> [Exercise] {
    try await db.read { db in
        let rows = try Row.fetchAll(db, sql: """
            SELECT id, name, muscle_group, type, source, is_custom
            FROM exercises
            ORDER BY name ASC
            """)
        
        return rows.map { row in
            Exercise(
                id: row["id"],
                name: row["name"],
                muscleGroup: row["muscle_group"],
                type: row["type"],
                source: row["source"],
                isCustom: row["is_custom"] == 1
            )
        }
    }
}

func deleteCustomExercise(id: String) async throws {
    try await db.write { db in
        try db.execute(sql: "DELETE FROM exercises WHERE id = ? AND source = 'user'",
                      arguments: [id])
    }
}
```

**Success Criteria**:
- [ ] Create button opens form
- [ ] Form validates (name required)
- [ ] Can select muscle group from picker
- [ ] Can select exercise type from picker
- [ ] Create saves to database
- [ ] Exercise appears in library immediately
- [ ] Custom exercises marked with badge
- [ ] Swipe-to-delete works for custom exercises only
- [ ] Cannot delete built-in exercises

---

### Task 8.4: Implement Timer Modals (POST-MVP)

### Task 8.4: Implement Timer Modals (POST-MVP)

**Estimated Time**: 1 hour  
**Complexity**: Low-Medium  
**Priority**: Low (Post-MVP - Nice to Have)

#### Objective
Create stopwatch and rest timer modals.

#### Reference Files
- `legacy/Goonlytics/Goonlytics/Sources/Workout/StopwatchModal.swift`
- `legacy/Goonlytics/Goonlytics/Sources/Workout/RestTimerModal.swift`

#### Sub-Tasks

##### Sub-Task 8.2.1: Stopwatch Modal

**File**: `/applications/thiccc/app/ios/Thiccc/StopwatchModal.swift` (new file)

```swift
import SwiftUI

struct StopwatchModal: View {
    @ObservedObject var core: Core
    @Environment(\.dismiss) private var dismiss
    
    @State private var startTime: Date?
    @State private var isRunning = false
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Stopwatch")
                .font(.title)
                .padding(.top)
            
            TimelineView(.periodic(from: .now, by: 1)) { context in
                let elapsedSeconds = startTime.map {
                    Calendar.current.dateComponents([.second], from: $0, to: context.date).second ?? 0
                } ?? 0
                
                Text(formatTime(elapsedSeconds))
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
            }
            
            HStack(spacing: 32) {
                Button(action: toggleStartStop) {
                    Image(systemName: isRunning ? "pause.fill" : "play.fill")
                        .font(.largeTitle)
                        .foregroundColor(isRunning ? .orange : .green)
                }
                
                Button(action: stop) {
                    Image(systemName: "stop.fill")
                        .font(.largeTitle)
                        .foregroundColor(.red)
                }
                
                Button(action: reset) {
                    Image(systemName: "gobackward")
                        .font(.largeTitle)
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
            
            Button("Close") {
                dismiss()
            }
            .padding()
        }
        .padding()
    }
    
    private func toggleStartStop() {
        if isRunning {
            isRunning = false
        } else {
            if startTime == nil {
                startTime = Date()
            }
            isRunning = true
        }
    }
    
    private func stop() {
        isRunning = false
        startTime = nil
    }
    
    private func reset() {
        isRunning = false
        startTime = nil
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}
```

##### Sub-Task 8.2.2: Rest Timer Modal

**File**: `/applications/thiccc/app/ios/Thiccc/RestTimerModal.swift` (new file)

```swift
import SwiftUI

struct RestTimerModal: View {
    @ObservedObject var core: Core
    @Environment(\.dismiss) private var dismiss
    
    let duration: Int // seconds
    let onComplete: (() -> Void)?
    
    @State private var endDate: Date
    
    init(core: Core, duration: Int, onComplete: (() -> Void)? = nil) {
        self.core = core
        self.duration = duration
        self.onComplete = onComplete
        _endDate = State(initialValue: Date().addingTimeInterval(TimeInterval(duration)))
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Rest Timer")
                .font(.title)
                .padding(.top)
            
            TimelineView(.periodic(from: Date(), by: 1.0)) { context in
                let remainingTime = endDate.timeIntervalSince(context.date)
                let minutes = max(0, Int(remainingTime) / 60)
                let seconds = max(0, Int(remainingTime) % 60)
                
                Text(String(format: "%02d:%02d", minutes, seconds))
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .onChange(of: context.date) { _, _ in
                        if remainingTime <= 0 {
                            onComplete?()
                        }
                    }
            }
            
            Spacer()
            
            Button("Close") {
                dismiss()
            }
            .padding()
        }
        .padding()
    }
}
```

**Success Criteria**:
- [ ] Stopwatch displays and works
- [ ] Can start/stop/reset stopwatch
- [ ] Rest timer counts down
- [ ] Timer completes and calls callback
- [ ] Both modals dismiss properly

---

### Task 8.5: Implement Plate Calculator View (POST-MVP)

**Estimated Time**: 1 hour  
**Complexity**: Medium  
**Priority**: Low (Post-MVP - Nice to Have)

#### Objective
Create barbell plate calculator with visual representation.

#### Reference Files
- `legacy/Goonlytics/Goonlytics/Sources/Workout/PlateCalculatorView.swift`

#### Implementation

**File**: `/applications/thiccc/app/ios/Thiccc/PlateCalculatorView.swift` (new file)

```swift
import SwiftUI

struct PlateCalculatorView: View {
    @ObservedObject var core: Core
    
    @State private var targetWeight = ""
    @State private var percentage = ""
    @State private var selectedBarType: BarType = .olympic
    
    var calculation: PlateCalculationResult? {
        core.view.plateCalculatorView.calculation
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Plate Calculator")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // Bar type selector
            barTypeSelector
            
            // Weight and percentage inputs
            inputSection
            
            // Calculate button
            Button("Calculate Plates") {
                if let weight = Double(targetWeight) {
                    let pct = Double(percentage)
                    core.update(.calculatePlates(
                        targetWeight: weight,
                        barType: selectedBarType,
                        usePercentage: pct
                    ))
                }
            }
            .buttonStyle(.bordered)
            .padding(.top, 8)
            
            // Result display
            if let calc = calculation {
                resultView(calc)
            }
            
            Spacer()
        }
        .padding()
    }
    
    private var barTypeSelector: some View {
        HStack {
            Text("Bar Type:")
                .fontWeight(.medium)
            
            Picker("Select Bar", selection: $selectedBarType) {
                ForEach(BarType.allCases, id: \.self) { bar in
                    Text("\(bar.name) (\(Int(bar.weight))lb)")
                        .tag(bar)
                }
            }
            .pickerStyle(MenuPickerStyle())
        }
        .padding(.horizontal)
    }
    
    private var inputSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Target Weight:")
                    .fontWeight(.medium)
                
                Spacer()
                
                TextField("Enter weight", text: $targetWeight)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .multilineTextAlignment(.trailing)
                    .frame(width: 120)
                
                Text("lbs")
            }
            
            HStack {
                Text("Use Percentage:")
                    .fontWeight(.medium)
                
                Spacer()
                
                TextField("Enter %", text: $percentage)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .multilineTextAlignment(.trailing)
                    .frame(width: 60)
                
                Text("%")
            }
        }
        .padding(.horizontal)
    }
    
    private func resultView(_ calc: PlateCalculationResult) -> some View {
        VStack(spacing: 16) {
            Divider()
                .padding(.vertical, 8)
            
            Text("Results")
                .font(.headline)
            
            VStack(alignment: .leading) {
                HStack {
                    Text("Total Weight:")
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(Int(calc.totalWeight))lb")
                        .fontWeight(.bold)
                }
                
                HStack {
                    Text("Bar Weight:")
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(Int(calc.barWeight))lb")
                }
                
                HStack {
                    Text("Plates Per Side:")
                        .fontWeight(.medium)
                    Spacer()
                    Text(calc.platesPerSide)
                }
            }
            .padding(.horizontal)
            
            // Visual bar representation
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    // Left side plates (reversed)
                    ForEach(calc.plates.reversed()) { plate in
                        platePic(plate)
                    }
                    
                    // Bar
                    Rectangle()
                        .fill(Color.gray)
                        .frame(width: 120, height: 10)
                    
                    // Right side plates
                    ForEach(calc.plates) { plate in
                        platePic(plate)
                    }
                }
                .padding()
            }
        }
    }
    
    private func platePic(_ plate: PlateViewModel) -> some View {
        let width = max(min(plate.weight / 2, 10), 5)
        
        return Rectangle()
            .fill(plateColor(plate.color))
            .frame(width: width, height: 60)
    }
    
    private func plateColor(_ colorName: String) -> Color {
        switch colorName.lowercased() {
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "black": return .black
        case "gray": return .gray
        case "purple": return .purple
        default: return .orange
        }
    }
}
```

**Success Criteria**:
- [ ] Calculator displays
- [ ] Can select bar type
- [ ] Can enter target weight
- [ ] Can enter percentage
- [ ] Calculates correct plates
- [ ] Visual representation displays

---

### Task 8.6: Implement Import Workout View

**Estimated Time**: 30 minutes  
**Complexity**: Low  
**Priority**: Medium (Useful for Migration)

#### Objective
Create view for importing workout JSON.

#### Reference Files
- `legacy/Goonlytics/Goonlytics/Sources/Workout/ImportWorkoutView.swift`

#### Implementation

**File**: `/applications/thiccc/app/ios/Thiccc/ImportWorkoutView.swift` (new file)

```swift
import SwiftUI

struct ImportWorkoutView: View {
    @ObservedObject var core: Core
    @Environment(\.dismiss) private var dismiss
    
    @State private var workoutText = ""
    
    var body: some View {
        NavigationView {
            VStack {
                TextEditor(text: $workoutText)
                    .font(.body)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Import Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Import") {
                        core.update(.importWorkout(jsonData: workoutText))
                        dismiss()
                    }
                    .disabled(workoutText.isEmpty)
                }
            }
        }
    }
}
```

**Success Criteria**:
- [ ] Text editor displays
- [ ] Can paste JSON
- [ ] Import button enabled when text present
- [ ] Sends import event
- [ ] Dismisses after import

---

## Phase 8 Completion Checklist

### MVP-Critical (Must Complete)
- [ ] `exercises` table created and seeded
- [ ] Built-in exercises (60+) available
- [ ] Exercise library loads from database
- [ ] Search works across all exercises
- [ ] Muscle group filtering works
- [ ] Multi-select works
- [ ] Custom exercise creation form implemented
- [ ] Custom exercises save to database
- [ ] Custom exercises appear with badge
- [ ] Delete custom exercise works (swipe-to-delete)
- [ ] Cannot delete built-in exercises

### Post-MVP (Optional)
- [ ] Stopwatch modal implemented
- [ ] Rest timer modal implemented
- [ ] Plate calculator implemented
- [ ] Import workout implemented

### General
- [ ] All modals dismiss properly
- [ ] Code compiles without errors
- [ ] App runs in simulator
- [ ] No regressions to existing features

---

## Testing Phase 8

### Manual Testing - MVP Features

**Exercise Library:**
- [ ] Open Add Exercise → see 60+ exercises grouped by muscle
- [ ] Search for "bench" → filters correctly
- [ ] Select multiple exercises → add to workout
- [ ] Exercises appear in active workout

**Custom Exercises:**
- [ ] Tap "Create" button → form appears
- [ ] Fill out form (name, muscle group, type)
- [ ] Save → exercise appears in library with person badge
- [ ] Custom exercise searchable and addable
- [ ] Swipe custom exercise → delete appears
- [ ] Delete custom exercise → removed from list
- [ ] Try to swipe built-in exercise → no delete option

**Database Persistence:**
- [ ] Create custom exercise → close app → reopen
- [ ] Custom exercise still exists
- [ ] Built-in exercises present (no duplicates)

### Manual Testing - Post-MVP Features

- [ ] Open stopwatch → start/stop/reset works
- [ ] Open rest timer → countdown works
- [ ] Open plate calculator → calculate plates
- [ ] Open import → paste JSON → imports workout

---

## Architecture Notes

### Why This Approach?

**Single Table Design:**
- Simpler queries (no UNION needed)
- Easy migration path (hardcoded → DB → cloud)
- Natural filtering by `source` column
- Future-proof for analytics (`usage_count`, etc.)

**Seeding Strategy:**
- Hardcoded list becomes "golden source" for seeding
- Seeding is idempotent (checks if exists)
- Built-in exercises never change (stable IDs)
- Custom exercises user-owned (can delete)

**UX Decisions:**
- Person badge = clear indicator of custom
- Swipe-to-delete only for custom = prevents accidents
- "Create" in toolbar = discoverable but not intrusive
- Simple form = low friction for creation

---

## Future Enhancements (Phase 12)

See `12-PHASE-12-OPTIONAL.md` for detailed server sync architecture.

**Planned for Phase 12:**
1. **Server-Sync Architecture**
   - Backend API for exercise library
   - Community exercise submissions
   - Conflict resolution (manual → AI)
   - Usage analytics per exercise

2. **Exercise Images**
   - `image_url` column already planned in schema
   - CDN storage for images
   - Open-source exercise database integration

3. **Social Features ("Thiccc Wrapped")**
   - "Spotify Wrapped" for workouts
   - Exercise popularity rankings
   - Personal records vs. community
   - Year-end analytics dashboard

4. **Advanced Analytics**
   - Exercise usage heatmap
   - Progression tracking per exercise
   - Volume trends over time
   - Exercise recommendations based on history

**Schema Already Supports:**
- `usage_count` → track exercise popularity
- `source` → differentiate builtin/user/community
- Future columns commented in schema (image_url, server_id, etc.)

---

## Next Steps

After completing Phase 8 MVP features (Tasks 8.1-8.3):
- **[Phase 7: History Views](./07-PHASE-7-HISTORY-VIEWS.md)** - Complete MVP!
- **[Phase 10: Additional Business Logic](./10-PHASE-10-ADDITIONAL-LOGIC.md)** - Stats calculations
- **[Phase 12: Optional Enhancements](./12-PHASE-12-OPTIONAL.md)** - Server sync, analytics, images

**Recommended Order:**
1. Complete Phase 8 MVP (exercise library + custom CRUD) - 4-5 hours
2. Complete Phase 7 (History views) - 2-3 hours
3. **Ship MVP to testers** 🚀
4. Gather feedback
5. Prioritize Phase 8 post-MVP features (timers, calculator) or Phase 12 features based on user requests

---

**Phase Status**: 🚨 **MVP-Critical** (Custom Exercises Required)  
**Last Updated**: December 25, 2025



