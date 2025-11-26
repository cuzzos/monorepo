# Phase 5: Main Navigation UI

## Overview

**Goal**: Implement the SwiftUI navigation structure (tabs, navigation stack, modal presentation).

**Phase Duration**: Estimated 2-3 hours  
**Complexity**: Medium  
**Dependencies**: Phase 4 (Business Logic)  
**Blocks**: Phase 6 (Workout View), Phase 7 (History Views), Phase 8 (Additional Features)

## Why This Phase Matters

Navigation is the skeleton of the app. All other views hang off this structure. Getting it right ensures:
- Clean navigation flow
- Proper state management
- Modal presentation works correctly
- Deep linking foundation (if needed later)

## Task Breakdown

### Task 5.1: Create Main App Structure with Tab Navigation

**Estimated Time**: 1 hour  
**Complexity**: Medium  
**Priority**: Critical

#### Objective
Replace the simple counter app with tab-based navigation matching Goonlytics.

#### Reference Files
- `legacy/Goonlytics/Goonlytics/Sources/GoonlyticsApp.swift`
- Current: `applications/thiccc/app/ios/Thiccc/SimpleCounterApp.swift`

#### Sub-Tasks

##### Sub-Task 5.1.1: Update Main App Entry Point

**File**: `/applications/thiccc/app/ios/Thiccc/SimpleCounterApp.swift`

**Rename to**: `ThicccApp.swift`

**Implementation**:
```swift
import SwiftUI

@main
struct ThicccApp: App {
    let core: Core
    
    init() {
        // Initialize core with database and capabilities
        self.core = Core()
    }
    
    var body: some Scene {
        WindowGroup {
            AppView(core: core)
        }
    }
}

struct AppView: View {
    @ObservedObject var core: Core
    
    var body: some View {
        TabView(selection: Binding(
            get: { core.view.selectedTab },
            set: { core.update(.changeTab(tab: $0)) }
        )) {
            // Workout Tab
            NavigationStack {
                WorkoutView(core: core)
            }
            .tag(Tab.workout)
            .tabItem {
                Label("Workout", systemImage: "figure.run")
            }
            
            // History Tab
            NavigationStack {
                HistoryView(core: core)
            }
            .tag(Tab.history)
            .tabItem {
                Label("History", systemImage: "clock")
            }
        }
    }
}

#Preview {
    AppView(core: Core())
}
```

**Success Criteria**:
- [ ] App compiles
- [ ] Tab bar displays with two tabs
- [ ] Can switch between tabs
- [ ] Each tab has NavigationStack
- [ ] Tab selection syncs with core

##### Sub-Task 5.1.2: Create Placeholder Views

**File**: `/applications/thiccc/app/ios/Thiccc/WorkoutView.swift` (new file)

**Temporary implementation**:
```swift
import SwiftUI

struct WorkoutView: View {
    @ObservedObject var core: Core
    
    var body: some View {
        VStack {
            Text("Workout View")
                .font(.largeTitle)
            Text("To be implemented in Phase 6")
                .foregroundColor(.secondary)
        }
        .navigationTitle("Workout")
    }
}
```

**File**: `/applications/thiccc/app/ios/Thiccc/HistoryView.swift` (new file)

**Temporary implementation**:
```swift
import SwiftUI

struct HistoryView: View {
    @ObservedObject var core: Core
    
    var body: some View {
        VStack {
            Text("History View")
                .font(.largeTitle)
            Text("To be implemented in Phase 7")
                .foregroundColor(.secondary)
        }
        .navigationTitle("History")
    }
}
```

**Success Criteria**:
- [ ] Placeholder views compile
- [ ] Can navigate to each tab
- [ ] Navigation titles display
- [ ] Views receive Core instance

#### Agent Prompt Template

```
I need you to implement the main navigation structure for the Thiccc iOS app.

**Reference Files:**
- @legacy/Goonlytics/Goonlytics/Sources/GoonlyticsApp.swift
- @ios/Thiccc/SimpleCounterApp.swift (current implementation)

**Task: Create Tab-Based Navigation**

1. Rename `SimpleCounterApp.swift` to `ThicccApp.swift`

2. Replace the simple counter view with tab-based navigation:
   - Create TabView with two tabs: Workout and History
   - Each tab should have its own NavigationStack
   - Tab selection should sync with core state (core.view.selectedTab)
   - Send ChangeTab event when user switches tabs

3. Create placeholder views:
   - WorkoutView.swift - temporary placeholder
   - HistoryView.swift - temporary placeholder

**Requirements:**
1. Match Goonlytics tab structure
2. Use iOS 18+ SwiftUI APIs
3. Proper Core integration (@ObservedObject var core: Core)
4. Tab items with SF Symbols icons
5. Navigation titles for each view

**Success Criteria:**
- [ ] App compiles and runs
- [ ] Two tabs visible and functional
- [ ] Can switch between tabs
- [ ] Tab selection syncs with core
- [ ] Navigation structure in place

Please implement following SwiftUI best practices and iOS 18 standards.
```

---

### Task 5.2: Implement Navigation Destinations

**Estimated Time**: 1-1.5 hours  
**Complexity**: Medium  
**Priority**: High

#### Objective
Add navigation to detail views (workout detail, history detail).

#### Reference Files
- `legacy/Goonlytics/Goonlytics/Sources/GoonlyticsApp.swift` (lines 26-79)

#### Sub-Tasks

##### Sub-Task 5.2.1: Define Navigation Destinations in Swift

**File**: `/applications/thiccc/app/ios/Thiccc/Navigation.swift` (new file)

**Implementation**:
```swift
import Foundation

/// Navigation destinations matching Rust core
enum NavigationDestination: Hashable {
    case workoutDetail(workoutId: UUID)
    case historyDetail(workoutId: UUID)
}

/// Map Rust NavigationDestination to Swift
extension NavigationDestination {
    init?(from rustDestination: SharedTypes.NavigationDestination) {
        switch rustDestination {
        case .workoutDetail(let id):
            self = .workoutDetail(workoutId: id)
        case .historyDetail(let id):
            self = .historyDetail(workoutId: id)
        }
    }
}
```

**Success Criteria**:
- [ ] Navigation destinations defined
- [ ] Matches Rust types
- [ ] Hashable for NavigationStack

##### Sub-Task 5.2.2: Add Navigation to AppView

**File**: Update `/applications/thiccc/app/ios/Thiccc/ThicccApp.swift`

**Add navigation handling**:
```swift
struct AppView: View {
    @ObservedObject var core: Core
    
    var body: some View {
        TabView(selection: Binding(
            get: { core.view.selectedTab },
            set: { core.update(.changeTab(tab: $0)) }
        )) {
            // Workout Tab
            NavigationStack(path: Binding(
                get: { core.view.workoutNavigationPath ?? [] },
                set: { _ in /* Navigation handled by core */ }
            )) {
                WorkoutView(core: core)
                    .navigationDestination(for: NavigationDestination.self) { destination in
                        destinationView(for: destination)
                    }
            }
            .tag(Tab.workout)
            .tabItem {
                Label("Workout", systemImage: "figure.run")
            }
            
            // History Tab
            NavigationStack(path: Binding(
                get: { core.view.historyNavigationPath ?? [] },
                set: { _ in /* Navigation handled by core */ }
            )) {
                HistoryView(core: core)
                    .navigationDestination(for: NavigationDestination.self) { destination in
                        destinationView(for: destination)
                    }
            }
            .tag(Tab.history)
            .tabItem {
                Label("History", systemImage: "clock")
            }
        }
    }
    
    @ViewBuilder
    private func destinationView(for destination: NavigationDestination) -> some View {
        switch destination {
        case .workoutDetail(let workoutId):
            WorkoutDetailView(core: core, workoutId: workoutId)
            
        case .historyDetail(let workoutId):
            HistoryDetailView(core: core, workoutId: workoutId)
        }
    }
}
```

##### Sub-Task 5.2.3: Create Detail View Placeholders

**Files**: 
- `/applications/thiccc/app/ios/Thiccc/WorkoutDetailView.swift` (new)
- `/applications/thiccc/app/ios/Thiccc/HistoryDetailView.swift` (new)

**Placeholder implementation**:
```swift
import SwiftUI

struct WorkoutDetailView: View {
    @ObservedObject var core: Core
    let workoutId: UUID
    
    var body: some View {
        VStack {
            Text("Workout Detail")
            Text("Workout ID: \(workoutId.uuidString)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .navigationTitle("Workout")
    }
}

struct HistoryDetailView: View {
    @ObservedObject var core: Core
    let workoutId: UUID
    
    var body: some View {
        ScrollView {
            Text("History Detail View")
            Text("To be implemented in Phase 7")
                .foregroundColor(.secondary)
        }
        .navigationTitle("Workout Detail")
    }
}
```

**Success Criteria**:
- [ ] Navigation destinations compile
- [ ] Can navigate to detail views
- [ ] Back button works
- [ ] Detail views receive workout ID

#### Agent Prompt Template

```
I need you to implement navigation to detail views in the Thiccc iOS app.

**Reference Files:**
- @legacy/Goonlytics/Goonlytics/Sources/GoonlyticsApp.swift (lines 26-79)
- @ios/Thiccc/ThicccApp.swift (current implementation)

**Task: Add Navigation Destinations**

1. Create `Navigation.swift`:
   - Define NavigationDestination enum
   - Match Rust NavigationDestination type
   - Make Hashable for SwiftUI

2. Update AppView with NavigationStack paths:
   - Add navigation handling to each tab
   - Use .navigationDestination modifier
   - Create destinationView helper method

3. Create detail view placeholders:
   - WorkoutDetailView
   - HistoryDetailView

**Requirements:**
1. Navigation state managed by Core
2. Use iOS 18 NavigationStack APIs
3. Proper typing (UUID for workout IDs)
4. Back button should work automatically
5. Tab-specific navigation stacks

**Success Criteria:**
- [ ] Can navigate to detail views
- [ ] Back navigation works
- [ ] Navigation state syncs with core
- [ ] Compiles without errors

Please implement following iOS 18 navigation patterns.
```

---

### Task 5.3: Implement Modal Presentation

**Estimated Time**: 30 minutes  
**Complexity**: Low  
**Priority**: Medium

#### Objective
Add sheet/modal presentation for add exercise, import, etc.

#### Implementation

**File**: Update `/applications/thiccc/app/ios/Thiccc/WorkoutView.swift`

**Add sheet modifiers**:
```swift
struct WorkoutView: View {
    @ObservedObject var core: Core
    
    var body: some View {
        VStack {
            // Content...
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
        // More sheets...
    }
}
```

**Success Criteria**:
- [ ] Sheets can be presented
- [ ] Sheets can be dismissed
- [ ] Modal state syncs with core
- [ ] Multiple modals supported

---

## Phase 5 Completion Checklist

Before moving to Phase 6, verify:

- [ ] Tab navigation works
- [ ] Can switch between Workout and History tabs
- [ ] Navigation to detail views works
- [ ] Back button works correctly
- [ ] Modal presentation foundation in place
- [ ] Code compiles without errors
- [ ] App runs in simulator
- [ ] Navigation state syncs with Core
- [ ] Placeholder views display correctly

## Testing Phase 5

### Manual Testing Checklist

Run in iOS Simulator:

- [ ] Launch app → see tab bar
- [ ] Tap Workout tab → see workout view
- [ ] Tap History tab → see history view
- [ ] Tab selection persists
- [ ] Navigation stack works per tab
- [ ] Modals can be presented and dismissed

## Common Issues & Solutions

### Issue: Tab selection not syncing
**Solution**: Check binding to core.view.selectedTab, ensure ChangeTab event is sent

### Issue: Navigation path errors
**Solution**: Verify NavigationDestination type matches between Rust and Swift

### Issue: Sheets not dismissing
**Solution**: Check bindings, ensure dismiss events are sent to core

### Issue: Back button not working
**Solution**: Verify NavigationStack is properly configured, path is observable

## Next Steps

After completing Phase 5, you can work on these in parallel:
- **[Phase 6: Workout View UI](./06-PHASE-6-WORKOUT-VIEW.md)** - Main workout tracking interface
- **[Phase 7: History Views UI](./07-PHASE-7-HISTORY-VIEWS.md)** - History list and detail

---

**Phase Status**: 📋 Ready for Implementation  
**Last Updated**: November 26, 2025
