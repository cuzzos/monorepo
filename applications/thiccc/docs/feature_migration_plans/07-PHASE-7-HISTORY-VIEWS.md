# Phase 7: History Views UI

## Overview

**Goal**: Implement history list and detail views for completed workouts.

**Phase Duration**: Estimated 2-3 hours (Swift UI implementation only)
**Complexity**: Medium
**Dependencies**: Phase 9 (Database) ✅ Complete
**Blocks**: Phase 8 (Exercise Library)
**Status**: 🚨 ACTIVE - Core logic complete, Swift UI implementation needed

## Current Implementation Status

### ✅ What's Already Implemented

**Rust Core (Complete):**
- ✅ `HistoryViewModel`, `HistoryItemViewModel`, `HistoryDetailViewModel` - ViewModels defined
- ✅ `LoadHistory`, `ViewHistoryItem` events - Event handling ready
- ✅ Database operations: `LoadAllWorkouts`, `LoadWorkoutById`, `DeleteWorkout`
- ✅ DatabaseCapability implements all history operations
- ✅ Core business logic populates `workout_history` from database
- ✅ View function builds HistoryViewModel from workout data

**Swift Bridge:**
- ✅ ViewModels accessible via `core.view.history_view`
- ✅ Events can be sent to core for navigation and data loading

### ❌ What's Missing (Needs Implementation)

**Swift UI Views:**
- ❌ `HistoryView.swift` - List view showing workout history (currently placeholder)
- ❌ `HistoryDetailView.swift` - Detail view for individual workouts (currently placeholder)
- ❌ Navigation integration in `ContentView.swift`
- ❌ Proper loading/empty states in Swift UI

## Why This Phase Matters

History lets users:
- Review past performance
- Track progress over time
- View workout details
- Analyze training patterns

## Task Breakdown

### Task 7.1: Implement History List View (Swift UI)

**Estimated Time**: 1 hour
**Complexity**: Medium
**Priority**: High
**Status**: ❌ NOT IMPLEMENTED

#### Objective
Replace placeholder HistoryPlaceholderView with functional HistoryView showing list of completed workouts.

#### Current State
- ❌ Only `HistoryPlaceholderView` exists (shows "History view will be implemented in Phase 7")
- ✅ ViewModels ready: `core.view.history_view.workouts` contains workout data
- ✅ Events ready: `LoadHistory` loads data on appear

#### Reference Files
- `legacy/Goonlytics/Goonlytics/Sources/History/HistoryView.swift`

#### Implementation

**File**: `/applications/thiccc/app/ios/Thiccc/HistoryView.swift`

```swift
import SwiftUI

struct HistoryView: View {
    @ObservedObject var core: Core
    
    var body: some View {
        Group {
            if core.view.historyView.isLoading {
                loadingView
            } else if core.view.historyView.workouts.isEmpty {
                emptyStateView
            } else {
                workoutsList
            }
        }
        .navigationTitle("History")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    core.update(.showImportView)
                } label: {
                    Image(systemName: "square.and.arrow.down")
                        .foregroundColor(.accentColor)
                }
            }
        }
        .onAppear {
            core.update(.loadHistory)
        }
    }
    
    private var loadingView: some View {
        VStack {
            ProgressView()
            Text("Loading workouts...")
                .foregroundColor(.secondary)
                .padding(.top)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Workout History")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Complete your first workout to see it here")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    private var workoutsList: some View {
        List {
            ForEach(core.view.historyView.workouts, id: \.id) { workout in
                Button {
                    core.update(.viewHistoryItem(workoutId: workout.id))
                } label: {
                    HistoryItemRow(workout: workout)
                }
                .buttonStyle(.plain)
            }
        }
        .listStyle(.plain)
    }
}

struct HistoryItemRow: View {
    let workout: HistoryItemViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(workout.name)
                .font(.headline)
            
            HStack {
                Text(workout.date)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Label("\(workout.exerciseCount) exercises", systemImage: "figure.run")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Label("\(workout.setCount) sets", systemImage: "square.stack.3d.up")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
```

**Success Criteria**:
- [ ] List displays workouts
- [ ] Empty state displays when no workouts
- [ ] Loading state displays while fetching
- [ ] Can tap workout to view details
- [ ] Import button in toolbar
- [ ] Loads data on appear

---

### Task 7.2: Implement History Detail View (Swift UI)

**Estimated Time**: 1.5-2 hours
**Complexity**: Medium
**Priority**: High
**Status**: ❌ NOT IMPLEMENTED

#### Objective
Replace placeholder HistoryDetailView with functional detail view showing complete workout data.

#### Current State
- ❌ Only placeholder exists (shows "To be implemented in Phase 7")
- ✅ ViewModel ready: `HistoryDetailViewModel` exists but not populated in core
- ✅ Events ready: `ViewHistoryItem(workoutId)` loads specific workout
- ❌ **ISSUE**: Core doesn't currently provide detail view for specific workouts

#### Reference Files
- `legacy/Goonlytics/Goonlytics/Sources/History/HistoryDetailView.swift`

#### Implementation

**File**: `/applications/thiccc/app/ios/Thiccc/HistoryDetailView.swift`

```swift
import SwiftUI

struct HistoryDetailView: View {
    @ObservedObject var core: Core
    let workoutId: UUID
    
    @State private var showingNotes = false
    
    var detailView: HistoryDetailViewModel? {
        // Get from core.view based on workoutId
        // This assumes core provides detail view for specific workout
        core.view.historyDetailView
    }
    
    var body: some View {
        ScrollView {
            if let detail = detailView {
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    headerSection(detail: detail)
                    
                    Divider()
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    
                    // Exercises
                    exercisesSection(detail: detail)
                    
                    // Notes
                    if let notes = detail.notes, !notes.isEmpty {
                        notesSection(notes: notes)
                    }
                }
                .padding(.bottom, 32)
            } else {
                ProgressView()
            }
        }
        .navigationTitle(detailView?.workoutName ?? "Workout")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            core.update(.viewHistoryItem(workoutId: workoutId))
        }
    }
    
    private func headerSection(detail: HistoryDetailViewModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(detail.workoutName)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
                .padding(.horizontal)
            
            Text(detail.formattedDate)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            if let duration = detail.duration {
                HStack {
                    Label(duration, systemImage: "clock")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
            }
        }
        .padding(.top, 16)
    }
    
    private func exercisesSection(detail: HistoryDetailViewModel) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            ForEach(Array(detail.exercises.enumerated()), id: \.offset) { _, exercise in
                exerciseCard(exercise: exercise)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    private func exerciseCard(exercise: ExerciseDetailViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Exercise name
            Text(exercise.name)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            // Sets
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(exercise.sets.enumerated()), id: \.offset) { _, set in
                    HStack(alignment: .center) {
                        Text("Set \(set.setNumber):")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(width: 60, alignment: .leading)
                        
                        Spacer()
                            .frame(width: 8)
                        
                        Text(set.displayText)
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding(.leading, 4)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    private func notesSection(notes: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                showingNotes.toggle()
            } label: {
                HStack {
                    Text("Workout Notes")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: showingNotes ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.top, 16)
            
            if showingNotes {
                Text(notes)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.primary)
                    .padding(.horizontal)
                    .padding(.top, 4)
            }
        }
    }
}
```

**Success Criteria**:
- [ ] Detail view displays
- [ ] Shows workout name and date
- [ ] Shows all exercises and sets
- [ ] Set data formatted correctly (weight × reps @ RPE)
- [ ] Notes section collapsible
- [ ] Duration displays if available

#### Agent Prompt Template

```
I need you to implement the Swift UI for the history views in the Thiccc iOS app.

**Current State:**
- ✅ ALL Rust core logic is complete (ViewModels, events, database operations)
- ✅ Database persistence working (Phase 9 complete)
- ❌ Swift UI views are placeholders only

**Reference Files:**
- @legacy/Goonlytics/Goonlytics/Sources/History/HistoryView.swift
- @legacy/Goonlytics/Goonlytics/Sources/History/HistoryDetailView.swift

**Task: Implement History List and Detail Views (Swift UI Only)**

1. **HistoryView.swift** - Replace HistoryPlaceholderView:
   - Use `core.view.history_view.workouts` (already populated)
   - Loading state: `core.view.history_view.is_loading`
   - Empty state when workouts.isEmpty
   - List of workout cards with HistoryItemRow
   - Tap workout → send `ViewHistoryItem(workoutId: workout.id)`
   - Import button → send `ShowImportView`
   - Send `LoadHistory` on appear

2. **HistoryDetailView.swift** - Replace placeholder:
   - Use `core.view.history_detail_view` (needs implementation in Rust core)
   - Show workout name, date, duration, exercises, sets, notes
   - Send `ViewHistoryItem(workoutId: workoutId)` on appear
   - Format sets as "weight lb × reps @ RPE"

3. **Update ContentView.swift** - Replace HistoryPlaceholderView with HistoryView

**Requirements:**
1. ViewModels already exist: HistoryViewModel, HistoryItemViewModel, HistoryDetailViewModel
2. Events already exist: LoadHistory, ViewHistoryItem, ShowImportView
3. Database operations already work
4. Match Goonlytics appearance
5. iOS 18+ APIs (@Bindable, etc.)

**Success Criteria:**
- [ ] HistoryView shows list of saved workouts
- [ ] HistoryDetailView shows complete workout data
- [ ] Navigation from list to detail works
- [ ] Loading/empty states display correctly
- [ ] Data loads from database on appear
```

---

## Phase 7 Completion Checklist

Before moving to Phase 8, verify:

- [ ] HistoryView.swift implemented (replaces HistoryPlaceholderView)
- [ ] HistoryDetailView.swift implemented (shows complete workout data)
- [ ] ContentView.swift updated to use HistoryView instead of placeholder
- [ ] Empty states display correctly when no workouts
- [ ] Loading states display while fetching data
- [ ] Can navigate from list to detail view
- [ ] Back button navigation works
- [ ] Workout data displays correctly (name, date, exercises, sets)
- [ ] Set data formatted correctly (weight × reps @ RPE)
- [ ] Notes section works (if present)
- [ ] Code compiles without errors
- [ ] App runs in simulator
- [ ] Workouts load from database on tab switch

## Testing Phase 7

### Manual Testing Checklist

- [ ] Open History tab → see list (or empty state)
- [ ] Tap workout → see detail view
- [ ] Back button → return to list
- [ ] Scroll through long workout (10+ exercises)
- [ ] Expand/collapse notes section
- [ ] Import button opens import view

### Test Data Setup

Create test workouts in database to verify:
- [ ] Single exercise workout
- [ ] Multi-exercise workout (5+ exercises)
- [ ] Workout with notes
- [ ] Workout without notes
- [ ] Very long workout (15+ exercises)

## Common Issues & Solutions

### Issue: Workouts not loading
**Solution**: Verify LoadHistory event is sent, check database capability

### Issue: Detail view not showing data
**Solution**: Check ViewModel is populated in core's view function

### Issue: Set formatting wrong
**Solution**: Verify format_set logic in Rust core

### Issue: Navigation not working
**Solution**: Check NavigationDestination is correct, path is observable

## Next Steps

After completing Phase 7:
- **[Phase 8: Exercise Library + Custom CRUD](./08-PHASE-8-ADDITIONAL-FEATURES.md)** - Database-backed exercise library with custom exercises
- **[Phase 10: Additional Business Logic](./10-PHASE-10-ADDITIONAL-LOGIC.md)** - Stats, calculator logic

**MVP Complete After Phase 8:** Users can track workouts, save to database, view history, and create custom exercises.

---

**Phase Status**: 🚨 ACTIVE - Implementation In Progress
**Last Updated**: January 16, 2026

