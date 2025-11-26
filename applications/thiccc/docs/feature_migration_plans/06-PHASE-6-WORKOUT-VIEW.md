# Phase 6: Workout View UI (Primary Feature)

## Overview

**Goal**: Implement the main workout tracking interface - the core feature of the app.

**Phase Duration**: Estimated 4-6 hours  
**Complexity**: High  
**Dependencies**: Phase 4 (Business Logic), Phase 5 (Navigation)  
**Blocks**: None (but needed for end-to-end testing)

## Why This Phase Matters

This is the most-used view in the app. Users will spend 90% of their time here. Quality is critical:
- Smooth text input
- Responsive UI
- Proper keyboard handling
- Intuitive interactions

## Task Breakdown

### Task 6.1: Implement Main Workout View Structure

**Estimated Time**: 2 hours  
**Complexity**: High  
**Priority**: Critical

#### Objective
Build the main workout view with stats header, exercise list, and action buttons.

#### Reference Files
- `legacy/Goonlytics/Goonlytics/Sources/Workout/WorkoutView.swift`

#### Sub-Tasks

##### Sub-Task 6.1.1: Create WorkoutView Layout

**File**: `/applications/thiccc/app/ios/Thiccc/WorkoutView.swift`

**Implementation**:
```swift
import SwiftUI

struct WorkoutView: View {
    @ObservedObject var core: Core
    
    var body: some View {
        ZStack {
            if core.view.workoutView.hasActiveWorkout {
                activeWorkoutView
            } else {
                emptyStateView
            }
        }
        .sheet(isPresented: Binding(
            get: { core.view.workoutView.showingAddExercise },
            set: { if !$0 { core.update(.dismissAddExerciseView) } }
        )) {
            AddExerciseView(core: core)
        }
        .sheet(isPresented: Binding(
            get: { core.view.workoutView.showingImport },
            set: { if !$0 { core.update(.dismissImportView) } }
        )) {
            ImportWorkoutView(core: core)
        }
    }
    
    private var activeWorkoutView: some View {
        VStack(spacing: 0) {
            // Custom Top Bar
            topBar
            
            // Workout Stats
            statsBar
            
            // Workout Name
            workoutNameField
            
            // Exercise List
            exerciseList
        }
        .safeAreaInset(edge: .bottom) {
            bottomActionBar
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "figure.run")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Active Workout")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Start a new workout to begin tracking")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Start Workout") {
                core.update(.startWorkout)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
```

**Success Criteria**:
- [ ] Layout compiles and renders
- [ ] Shows empty state when no workout
- [ ] Shows active workout UI when workout exists
- [ ] Proper spacing and structure

##### Sub-Task 6.1.2: Implement Top Bar

**Add to WorkoutView**:
```swift
private var topBar: some View {
    HStack {
        Image(systemName: "chevron.down")
            .font(.title2)
            .foregroundColor(.white)
        
        Spacer()
        
        Text("Log Workout")
            .font(.headline)
            .foregroundColor(.white)
        
        Spacer()
        
        Button {
            core.update(.showStopwatch)
        } label: {
            Image(systemName: "clock")
                .font(.title2)
                .foregroundColor(.white)
        }
        
        Button {
            core.update(.finishWorkout)
        } label: {
            Text("Finish")
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.blue)
                .cornerRadius(8)
        }
    }
    .padding(.horizontal)
    .padding(.top, 8)
    .background(Color.black)
}
```

##### Sub-Task 6.1.3: Implement Stats Bar

```swift
private var statsBar: some View {
    HStack(spacing: 24) {
        StatView(
            title: "Duration",
            value: core.view.workoutView.formattedDuration
        )
        
        StatView(
            title: "Volume",
            value: "\(core.view.workoutView.totalVolume) lbs"
        )
        
        StatView(
            title: "Sets",
            value: "\(core.view.workoutView.totalSets)"
        )
        
        Spacer()
    }
    .padding(.horizontal)
    .padding(.vertical, 8)
    .background(Color.black)
}

struct StatView: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            Text(value)
                .font(.subheadline)
                .foregroundColor(.white)
        }
    }
}
```

##### Sub-Task 6.1.4: Implement Workout Name Field

```swift
private var workoutNameField: some View {
    TextField("Workout Name", text: Binding(
        get: { core.view.workoutView.workoutName },
        set: { core.update(.updateWorkoutName(name: $0)) }
    ))
    .font(.title)
    .padding(.horizontal)
    .padding(.vertical, 8)
}
```

##### Sub-Task 6.1.5: Implement Exercise List

```swift
private var exerciseList: some View {
    List {
        ForEach(core.view.workoutView.exercises, id: \.id) { exercise in
            ExerciseSection(exercise: exercise, core: core)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
        }
        .onMove { from, to in
            if let fromIndex = from.first {
                core.update(.moveExercise(fromIndex: fromIndex, toIndex: to))
            }
        }
    }
    .listStyle(.plain)
    .scrollContentBackground(.hidden)
}
```

##### Sub-Task 6.1.6: Implement Bottom Action Bar

```swift
private var bottomActionBar: some View {
    HStack(spacing: 0) {
        Button {
            core.update(.showImportView)
        } label: {
            Text("Settings")
                .frame(maxWidth: .infinity)
                .padding()
        }
        .buttonStyle(.bordered)
        
        Button {
            core.update(.showAddExerciseView)
        } label: {
            Text("+ Add Exercise")
                .frame(maxWidth: .infinity)
                .padding()
        }
        .buttonStyle(.bordered)
        
        Button {
            core.update(.discardWorkout)
        } label: {
            Text("Discard Workout")
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding()
        }
        .buttonStyle(.bordered)
    }
    .background(.ultraThinMaterial)
}
```

#### Agent Prompt Template

Use **Template 7: SwiftUI View Implementation** from AGENT-PROMPT-TEMPLATES.md with these specifics:

```
**Reference Files:**
- @legacy/Goonlytics/Goonlytics/Sources/Workout/WorkoutView.swift

**Task: Create Main Workout View**

Implement the main workout tracking view in `/applications/thiccc/app/ios/Thiccc/WorkoutView.swift`.

**View Structure:**
1. Empty state (when no workout)
2. Active workout view (when workout exists):
   - Top bar (title, clock, finish button)
   - Stats bar (duration, volume, sets)
   - Workout name field
   - Exercise list
   - Bottom action bar

**User Interactions:**
- Start workout → Event::StartWorkout
- Finish workout → Event::FinishWorkout
- Discard workout → Event::DiscardWorkout
- Update name → Event::UpdateWorkoutName
- Show stopwatch → Event::ShowStopwatch
- Show add exercise → Event::ShowAddExerciseView

**Requirements:**
1. Match Goonlytics UI exactly
2. Use ViewModel from core (core.view.workoutView)
3. All interactions send events to core
4. Proper keyboard handling
5. iOS 18+ APIs

**Success Criteria:**
- [ ] Empty state displays
- [ ] Active workout UI displays
- [ ] All buttons work
- [ ] Stats update in real-time
- [ ] Name field editable
```

---

### Task 6.2: Implement Exercise Section Component

**Estimated Time**: 1.5 hours  
**Complexity**: Medium  
**Priority**: Critical

#### Objective
Create the exercise card component with header and set rows.

#### Reference Files
- `legacy/Goonlytics/Goonlytics/Sources/Workout/WorkoutView.swift` (lines 149-214)

#### Implementation

**File**: `/applications/thiccc/app/ios/Thiccc/ExerciseSection.swift` (new file)

```swift
import SwiftUI

struct ExerciseSection: View {
    let exercise: ExerciseViewModel
    @ObservedObject var core: Core
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Exercise Header
            exerciseHeader
            
            // Column Headers
            columnHeaders
            
            // Sets
            setsList
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(8)
        .shadow(radius: 1)
    }
    
    private var exerciseHeader: some View {
        HStack {
            Text(exercise.name)
                .font(.headline)
            
            Spacer()
            
            Button {
                core.update(.deleteExercise(exerciseId: exercise.id))
            } label: {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            
            Button {
                core.update(.addSet(exerciseId: exercise.id))
            } label: {
                Text("Add Set")
                    .font(.caption)
                    .foregroundStyle(.white)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .cornerRadius(12)
                    .shadow(radius: 1)
            }
        }
    }
    
    private var columnHeaders: some View {
        HStack {
            Text("SET")
                .font(.caption)
                .foregroundColor(.gray)
                .frame(width: 30, alignment: .leading)
            
            Text("PREVIOUS")
                .font(.caption)
                .foregroundColor(.gray)
                .frame(width: 100, alignment: .leading)
            
            Text("WEIGHT")
                .font(.caption)
                .foregroundColor(.gray)
                .frame(width: 50, alignment: .leading)
            
            Text("REPS")
                .font(.caption)
                .foregroundColor(.gray)
                .frame(width: 50, alignment: .leading)
            
            Text("RPE")
                .font(.caption)
                .foregroundColor(.gray)
                .frame(width: 50, alignment: .leading)
        }
    }
    
    private var setsList: some View {
        ForEach(exercise.sets, id: \.id) { set in
            SetRow(set: set, core: core)
        }
        .onDelete { indexSet in
            if let index = indexSet.first {
                core.update(.deleteSet(
                    exerciseId: exercise.id,
                    setIndex: index
                ))
            }
        }
    }
}
```

**Success Criteria**:
- [ ] Exercise card displays
- [ ] Header shows exercise name
- [ ] Can delete exercise
- [ ] Can add set
- [ ] Column headers display
- [ ] Sets list displays

---

### Task 6.3: Implement Set Row Component

**Estimated Time**: 1.5-2 hours  
**Complexity**: High (text input handling)  
**Priority**: Critical

#### Objective
Create the individual set row with text fields for weight, reps, RPE.

#### Reference Files
- `legacy/Goonlytics/Goonlytics/Sources/Workout/SetRow.swift`

#### Implementation

**File**: `/applications/thiccc/app/ios/Thiccc/SetRow.swift` (new file)

```swift
import SwiftUI

struct SetRow: View {
    let set: SetViewModel
    @ObservedObject var core: Core
    
    @FocusState private var focusedField: Field?
    @State private var weightText: String
    @State private var repsText: String
    @State private var rpeText: String
    
    enum Field {
        case weight, reps, rpe
    }
    
    init(set: SetViewModel, core: Core) {
        self.set = set
        self.core = core
        _weightText = State(initialValue: set.weight)
        _repsText = State(initialValue: set.reps)
        _rpeText = State(initialValue: set.rpe)
    }
    
    var body: some View {
        HStack {
            // Set Number
            Text("\(set.setNumber)")
                .font(.subheadline)
                .frame(width: 30, alignment: .leading)
            
            // Previous
            Text(set.previousDisplay)
                .font(.caption)
                .frame(width: 100, alignment: .leading)
                .foregroundColor(.secondary)
            
            // Weight
            TextField("0", text: $weightText, onCommit: updateActual)
                .keyboardType(.decimalPad)
                .focused($focusedField, equals: .weight)
                .frame(width: 50)
                .onChange(of: focusedField) { _, newFocus in
                    if newFocus == .weight && !weightText.isEmpty {
                        // Select all on focus
                    }
                }
            
            // Reps
            TextField("0", text: $repsText, onCommit: updateActual)
                .keyboardType(.numberPad)
                .focused($focusedField, equals: .reps)
                .frame(width: 50)
            
            // RPE
            TextField("0", text: $rpeText, onCommit: updateActual)
                .keyboardType(.decimalPad)
                .focused($focusedField, equals: .rpe)
                .frame(width: 50)
            
            // Completion Checkmark
            Button {
                core.update(.toggleSetCompleted(setId: set.id))
            } label: {
                Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(set.isCompleted ? .green : .gray)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func updateActual() {
        // Parse values and send update event
        let weight = Double(weightText)
        let reps = Int(repsText)
        let rpe = Double(rpeText)
        
        let actual = SetActual(
            weight: weight,
            reps: reps,
            rpe: rpe,
            duration: nil,
            actualRestTime: nil
        )
        
        core.update(.updateSetActual(setId: set.id, actual: actual))
    }
}
```

**Success Criteria**:
- [ ] Set row displays
- [ ] Text fields work
- [ ] Keyboard types correct (number pad, decimal pad)
- [ ] Can toggle completion
- [ ] Updates sent to core on blur/commit
- [ ] Previous data displays

#### Agent Prompt Template

```
I need you to implement the SetRow component for the Thiccc iOS app.

**Reference Files:**
- @legacy/Goonlytics/Goonlytics/Sources/Workout/SetRow.swift

**Task: Create Set Input Row**

Implement `/applications/thiccc/app/ios/Thiccc/SetRow.swift` with:

**Display Fields:**
- Set number (read-only)
- Previous data (read-only, shows last workout)
- Weight (editable TextField)
- Reps (editable TextField)
- RPE (editable TextField)
- Completion checkbox (toggle button)

**Text Input Requirements:**
1. Weight: decimal keyboard (.decimalPad)
2. Reps: number keyboard (.numberPad)
3. RPE: decimal keyboard (.decimalPad)
4. Use @FocusState for keyboard management
5. Send UpdateSetActual event on commit/blur
6. Select all text on focus (UX improvement)

**Success Criteria:**
- [ ] All fields display correctly
- [ ] Text input works smoothly
- [ ] Keyboard types correct
- [ ] Data updates sent to core
- [ ] Completion toggle works
- [ ] Matches Goonlytics behavior

This is a critical component - users will interact with it constantly. Prioritize smooth UX.
```

---

## Phase 6 Completion Checklist

Before moving to other phases, verify:

- [ ] Main WorkoutView implemented
- [ ] Empty state displays
- [ ] Active workout UI displays
- [ ] Exercise sections display
- [ ] Set rows display and work
- [ ] All text fields functional
- [ ] All buttons send correct events
- [ ] Stats update in real-time
- [ ] Can add/delete exercises
- [ ] Can add/delete sets
- [ ] Can reorder exercises
- [ ] Code compiles without errors
- [ ] App runs smoothly in simulator
- [ ] Keyboard handling works well

## Testing Phase 6

### Manual Testing Checklist

Complete user flow:

- [ ] Start new workout
- [ ] Add exercise from library
- [ ] Add sets to exercise
- [ ] Enter weight, reps, RPE
- [ ] Toggle set completion
- [ ] Add another exercise
- [ ] Reorder exercises (drag)
- [ ] Delete a set
- [ ] Delete an exercise
- [ ] Update workout name
- [ ] Check stats update (duration, volume, sets)
- [ ] Finish workout
- [ ] Verify workout saved

### Performance Testing

- [ ] Smooth scrolling with 10+ exercises
- [ ] No lag when typing in text fields
- [ ] Stats update without frame drops
- [ ] Timer updates smoothly

## Common Issues & Solutions

### Issue: Text fields losing focus
**Solution**: Use @FocusState properly, ensure state management is correct

### Issue: Keyboard covering input
**Solution**: Use .scrollDismissesKeyboard() modifier

### Issue: Lag when typing
**Solution**: Debounce updates to core, don't send event on every keystroke

### Issue: Stats not updating
**Solution**: Verify ViewModel is being recalculated in core's view function

## Next Steps

After completing Phase 6:
- **[Phase 7: History Views](./07-PHASE-7-HISTORY-VIEWS.md)** - View completed workouts
- **[Phase 8: Additional Features](./08-PHASE-8-ADDITIONAL-FEATURES.md)** - Timers, plate calculator, etc.

---

**Phase Status**: 📋 Ready for Implementation  
**Last Updated**: November 26, 2025
