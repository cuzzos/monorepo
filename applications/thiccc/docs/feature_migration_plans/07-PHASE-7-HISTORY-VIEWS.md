# Phase 7: History Views UI

## Overview

**Goal**: Implement history list and detail views for completed workouts.

**Phase Duration**: Estimated 2-3 hours  
**Complexity**: Medium  
**Dependencies**: Phase 4 (Business Logic), Phase 5 (Navigation), Phase 9 (Database)  
**Blocks**: None

## Why This Phase Matters

History lets users:
- Review past performance
- Track progress over time
- View workout details
- Analyze training patterns

## Task Breakdown

### Task 7.1: Implement History List View

**Estimated Time**: 1 hour  
**Complexity**: Medium  
**Priority**: High

#### Objective
Show list of all completed workouts.

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

### Task 7.2: Implement History Detail View

**Estimated Time**: 1.5-2 hours  
**Complexity**: Medium  
**Priority**: High

#### Objective
Show detailed view of a completed workout.

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
I need you to implement the history views for the Thiccc iOS app.

**Reference Files:**
- @legacy/Goonlytics/Goonlytics/Sources/History/HistoryView.swift
- @legacy/Goonlytics/Goonlytics/Sources/History/HistoryDetailView.swift

**Task: Implement History List and Detail Views**

1. **HistoryView.swift** - List of completed workouts:
   - Loading state while fetching
   - Empty state when no workouts
   - List of workout cards
   - Tap to navigate to detail
   - Import button in toolbar
   - Load data on appear

2. **HistoryDetailView.swift** - Detailed workout view:
   - Workout name and date header
   - Duration (if available)
   - Exercise cards with sets
   - Set data formatted as "weight lb × reps @ RPE"
   - Collapsible notes section

**Events to Send:**
- LoadHistory (on HistoryView appear)
- ViewHistoryItem(workoutId) (on tap, on detail appear)
- ShowImportView (toolbar button)

**Requirements:**
1. Use ViewModels from core
2. Match Goonlytics appearance
3. Proper loading/empty states
4. iOS 18+ APIs

**Success Criteria:**
- [ ] List displays workouts
- [ ] Detail shows complete workout data
- [ ] Navigation works
- [ ] Empty states display
- [ ] Data formatted correctly
```

---

## Phase 7 Completion Checklist

Before moving to other phases, verify:

- [ ] History list view implemented
- [ ] History detail view implemented
- [ ] Empty states display correctly
- [ ] Loading states display correctly
- [ ] Can navigate from list to detail
- [ ] Back button works
- [ ] Data displays correctly
- [ ] Set formatting correct (weight × reps @ RPE)
- [ ] Notes section works
- [ ] Code compiles without errors
- [ ] App runs in simulator

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
- **[Phase 8: Additional Features](./08-PHASE-8-ADDITIONAL-FEATURES.md)** - Timers, calculator, import
- **[Phase 9: Database Implementation](./09-PHASE-9-DATABASE.md)** - Full persistence

---

**Phase Status**: 📋 Ready for Implementation  
**Last Updated**: November 26, 2025

