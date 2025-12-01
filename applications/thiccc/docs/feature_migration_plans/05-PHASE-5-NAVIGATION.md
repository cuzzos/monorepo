# Phase 5: Main Navigation UI

## Overview

**Goal**: Implement the SwiftUI navigation structure (tabs, navigation stack, modal presentation).

**Phase Duration**: Estimated 2-3 hours  
**Complexity**: Medium  
**Dependencies**: Phase 4 (Business Logic) ✅  
**Blocks**: Phase 6 (Workout View), Phase 7 (History Views), Phase 8 (Additional Features)

## iOS 18+ / Swift 6 Requirements

> **CRITICAL**: All code in this phase MUST use iOS 18+ APIs and Swift 6 patterns.

### Observation Framework Migration

The `Core` class currently uses the deprecated Combine-based pattern (`ObservableObject` + `@Published`). 
Before implementing Phase 5, the Core class should be migrated to use the Observation framework:

**Current (Deprecated):**
```swift
@MainActor
class Core: ObservableObject {
    @Published var view: SharedTypes.ViewModel
}
```

**Required (iOS 17+/Swift 5.9+ Observation Framework):**
```swift
import Observation

@Observable
@MainActor
final class Core {
    var view: SharedTypes.ViewModel  // Automatically observable
}
```

### View Pattern Updates

| Old Pattern | New Pattern (Required) |
|-------------|------------------------|
| `@ObservedObject var core: Core` | `@Bindable var core: Core` |
| `@StateObject` | `@State` (for @Observable objects) |
| `NavigationView` | `NavigationStack` |

---

## Current Implementation Status

**Status**: 🟡 Partially Implemented (~30%)

### What's Already Done
- ✅ Basic TabView structure exists in `ContentView.swift`
- ✅ Placeholder views (WorkoutPlaceholderView, HistoryPlaceholderView)
- ✅ Tab items with SF Symbols icons
- ✅ Core integration (needs migration to @Observable)
- ✅ Debug tab for capability testing (temporary)

### What Still Needs Work
- ❌ Core class uses deprecated `ObservableObject` (needs `@Observable`)
- ❌ Views use `@ObservedObject` (needs `@Bindable`)
- ❌ Tab selection uses local `@State` instead of syncing with core
- ❌ No `Event.changeTab` sent when switching tabs
- ❌ Local Swift `Tab` enum duplicates `SharedTypes.Tab`
- ❌ App still named `SimpleCounterApp` (not `ThicccApp`)
- ❌ No NavigationStack on tabs
- ❌ No navigation destinations (detail views)
- ❌ No modal/sheet presentation

### Current File Structure
```
app/iOS/Thiccc/
├── SimpleCounterApp.swift  ← Should be renamed to ThicccApp.swift
├── ContentView.swift       ← Has tab structure but needs core sync + @Bindable
├── core.swift              ← Needs migration to @Observable
├── Capabilities/           ← ✅ Complete
│   ├── DatabaseCapability.swift
│   ├── StorageCapability.swift
│   └── TimerCapability.swift
└── DebugCapabilitiesView.swift ← Temporary, can be removed
```

---

## Pre-Phase Task: Migrate Core to @Observable

**IMPORTANT**: Before starting Phase 5 tasks, migrate the Core class.

### File: `app/iOS/Thiccc/core.swift`

```swift
import Foundation
import Observation
import SharedTypes

@Observable
@MainActor
final class Core {
    var view: SharedTypes.ViewModel
    
    // Capability handlers
    private var databaseCapability: DatabaseCapability?
    private var storageCapability: StorageCapability?
    private var timerCapability: TimerCapability?
    
    init() {
        // Get initial view from Rust core via FFI
        let viewData = Thiccc.view()
        let viewBytes = Array(viewData)
        self.view = try! SharedTypes.ViewModel.bincodeDeserialize(input: viewBytes)
        
        // Initialize capabilities
        self.databaseCapability = DatabaseCapability(core: self)
        self.storageCapability = StorageCapability(core: self)
        self.timerCapability = TimerCapability(core: self)
        
        // Send Initialize event to load any saved workout
        Task {
            await update(.initialize)
        }
    }
    
    /// Send an event to the Rust core and process any resulting effects.
    func update(_ event: SharedTypes.Event) async {
        let eventBytes = try! event.bincodeSerialize()
        let eventData = Data(eventBytes)
        
        let effectsData = Thiccc.processEvent(eventData)
        let effectsBytes = Array(effectsData)
        
        await processEffects(effectsBytes)
        refreshView()
    }
    
    // ... rest of implementation unchanged ...
}
```

### Update App Entry Point

```swift
// SimpleCounterApp.swift → ThicccApp.swift
import SwiftUI

@main
struct ThicccApp: App {
    @State private var core = Core()
    
    var body: some Scene {
        WindowGroup {
            ContentView(core: core)
        }
    }
}
```

---

## Why This Phase Matters

Navigation is the skeleton of the app. All other views hang off this structure. Getting it right ensures:
- Clean navigation flow
- Proper state management with Observation framework
- Modal presentation works correctly
- Deep linking foundation (if needed later)

## Task Breakdown

### Task 5.1: Update Tab Navigation to Sync with Core

**Estimated Time**: 45 minutes  
**Complexity**: Medium  
**Priority**: Critical  
**Status**: 🟡 Partially Done

#### Objective
Fix the existing tab navigation to sync with the Rust core state using iOS 18+ patterns.

#### Current Issues in `ContentView.swift`

The current implementation has these problems:
1. Uses `@ObservedObject` instead of `@Bindable`
2. Uses local `@State private var selectedTab: Tab` instead of core state
3. Defines a local `Tab` enum that duplicates `SharedTypes.Tab`
4. Doesn't send `Event.changeTab` when tabs change
5. No NavigationStack wrappers

#### Sub-Tasks

##### Sub-Task 5.1.1: Update ContentView to Use @Bindable and Sync with Core

**File**: `app/iOS/Thiccc/ContentView.swift`

**Changes needed**:

```swift
import SharedTypes
import SwiftUI

struct ContentView: View {
    @Bindable var core: Core
    
    var body: some View {
        TabView(selection: Binding(
            get: { core.view.selected_tab },
            set: { newTab in
                Task {
                    await core.update(.changeTab(tab: newTab))
                }
            }
        )) {
            // Workout Tab
            NavigationStack {
                WorkoutPlaceholderView(core: core)
            }
            .tabItem {
                Label("Workout", systemImage: "figure.run")
            }
            .tag(SharedTypes.Tab.workout)
            
            // History Tab
            NavigationStack {
                HistoryPlaceholderView(core: core)
            }
            .tabItem {
                Label("History", systemImage: "clock.arrow.circlepath")
            }
            .tag(SharedTypes.Tab.history)
        }
    }
}

/// Placeholder for the Workout view (Phase 6)
struct WorkoutPlaceholderView: View {
    @Bindable var core: Core
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Workout")
                .font(.largeTitle.bold())
            Text("Implementation coming in Phase 6")
                .foregroundStyle(.secondary)
        }
        .navigationTitle("Workout")
    }
}

/// Placeholder for the History view (Phase 7)
struct HistoryPlaceholderView: View {
    @Bindable var core: Core
    
    var body: some View {
        VStack(spacing: 20) {
            Text("History")
                .font(.largeTitle.bold())
            Text("Implementation coming in Phase 7")
                .foregroundStyle(.secondary)
        }
        .navigationTitle("History")
    }
}

#Preview {
    @Previewable @State var core = Core()
    ContentView(core: core)
}
```

**Key Changes**:
1. Replace `@ObservedObject var core` with `@Bindable var core`
2. Remove local `Tab` enum - use `SharedTypes.Tab` instead
3. Remove `@State private var selectedTab` - use `core.view.selected_tab`
4. Add `Task { await core.update(.changeTab(tab: newTab)) }` in binding setter
5. Add `NavigationStack` wrapper to each tab
6. Remove Debug tab (or keep temporarily for testing)
7. Update placeholder views to use `@Bindable`
8. Use iOS 18+ preview with `@Previewable`

**Success Criteria**:
- [x] Tab structure exists
- [ ] Views use `@Bindable` (not `@ObservedObject`)
- [ ] Tab selection syncs with `core.view.selected_tab`
- [ ] `Event.changeTab` sent when switching tabs
- [ ] Uses `SharedTypes.Tab` (not local enum)
- [ ] Each tab has NavigationStack
- [ ] Navigation titles display

##### Sub-Task 5.1.2: Rename App Entry Point

**File**: `app/iOS/Thiccc/SimpleCounterApp.swift` → `ThicccApp.swift`

```swift
import SwiftUI

@main
struct ThicccApp: App {
    @State private var core = Core()
    
    var body: some Scene {
        WindowGroup {
            ContentView(core: core)
        }
    }
}
```

**Key Changes**:
1. Rename file to `ThicccApp.swift`
2. Rename struct to `ThicccApp`
3. Use `@State` for the `@Observable` Core object (not `@StateObject`)

**Success Criteria**:
- [ ] File renamed to ThicccApp.swift
- [ ] Struct renamed to ThicccApp
- [ ] Uses `@State` for Core (not `@StateObject`)
- [ ] App compiles and runs

#### Agent Prompt Template

```
I need you to fix the tab navigation in the Thiccc iOS app to sync with the Rust core 
using iOS 18+ / Swift 6 patterns.

**IMPORTANT**: Use @Observable and @Bindable (NOT ObservableObject/@ObservedObject)

**Current Files:**
- @ios/Thiccc/ContentView.swift (has basic tab structure but uses deprecated patterns)
- @ios/Thiccc/core.swift (needs migration to @Observable)

**Problem:**
The current implementation uses deprecated Combine patterns (@ObservableObject, @Published, 
@ObservedObject). It also uses local @State for tab selection instead of syncing with 
core.view.selected_tab.

**Task: Migrate to @Observable and Fix Tab Navigation**

1. Migrate Core class to @Observable (remove ObservableObject, @Published)
2. Update views to use @Bindable (not @ObservedObject)
3. Remove the local `Tab` enum - use `SharedTypes.Tab` instead
4. Use binding to `core.view.selected_tab` for TabView selection
5. Send `Event.changeTab(tab:)` when user switches tabs
6. Add NavigationStack wrapper to each tab
7. Use @Previewable for previews (iOS 18+)

**Required Patterns:**
```swift
// Core class
@Observable
@MainActor
final class Core {
    var view: SharedTypes.ViewModel
}

// View with @Bindable
struct ContentView: View {
    @Bindable var core: Core
    
    var body: some View {
        TabView(selection: Binding(
            get: { core.view.selected_tab },
            set: { newTab in
                Task { await core.update(.changeTab(tab: newTab)) }
            }
        )) {
            NavigationStack {
                WorkoutPlaceholderView(core: core)
            }
            .tabItem { Label("Workout", systemImage: "figure.run") }
            .tag(SharedTypes.Tab.workout)
        }
    }
}
```

**Success Criteria:**
- [ ] Core uses @Observable (not ObservableObject)
- [ ] Views use @Bindable (not @ObservedObject)
- [ ] Uses SharedTypes.Tab (not local enum)
- [ ] Tab selection reads from core.view.selected_tab
- [ ] Changing tab sends Event.changeTab
- [ ] Each tab has NavigationStack
- [ ] App compiles and runs
```

---

### Task 5.2: Implement Navigation Destinations

**Estimated Time**: 1-1.5 hours  
**Complexity**: Medium  
**Priority**: High  
**Status**: ❌ Not Started

#### Objective
Add navigation to detail views (workout detail, history detail).

#### Note on NavigationDestination

The Rust core already has `NavigationDestination` defined in `events.rs`:
```rust
pub enum NavigationDestination {
    WorkoutDetail { workout_id: String },
    HistoryDetail { workout_id: String },
}
```

And `Model` has:
```rust
pub navigation_stack: Vec<NavigationDestination>,
```

**However**, this type is NOT currently exposed in the ViewModel. For now, we can implement 
navigation on the Swift side without syncing the navigation stack with core, or we can 
add navigation paths to the ViewModel later.

#### Sub-Tasks

##### Sub-Task 5.2.1: Add NavigationStack with Destinations

**File**: Update `app/iOS/Thiccc/ContentView.swift`

For initial implementation, use SwiftUI's native navigation without syncing to core:

```swift
import SharedTypes
import SwiftUI

struct ContentView: View {
    @Bindable var core: Core
    @State private var workoutPath = NavigationPath()
    @State private var historyPath = NavigationPath()

    var body: some View {
        TabView(selection: Binding(
            get: { core.view.selected_tab },
            set: { newTab in
                Task { await core.update(.changeTab(tab: newTab)) }
            }
        )) {
            // Workout Tab
            NavigationStack(path: $workoutPath) {
                WorkoutPlaceholderView(core: core)
                    .navigationDestination(for: String.self) { workoutId in
                        WorkoutDetailView(core: core, workoutId: workoutId)
                    }
            }
            .tabItem { Label("Workout", systemImage: "figure.run") }
            .tag(SharedTypes.Tab.workout)
            
            // History Tab
            NavigationStack(path: $historyPath) {
                HistoryPlaceholderView(core: core)
                    .navigationDestination(for: String.self) { workoutId in
                        HistoryDetailView(core: core, workoutId: workoutId)
                    }
            }
            .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
            .tag(SharedTypes.Tab.history)
        }
    }
}
```

##### Sub-Task 5.2.2: Create Detail View Placeholders

**File**: `app/iOS/Thiccc/HistoryDetailView.swift` (new)

```swift
import SwiftUI

struct HistoryDetailView: View {
    @Bindable var core: Core
    let workoutId: String
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("History Detail View")
                    .font(.largeTitle.bold())
                Text("Workout ID: \(workoutId)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("To be implemented in Phase 7")
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationTitle("Workout Detail")
    }
}

#Preview {
    @Previewable @State var core = Core()
    NavigationStack {
        HistoryDetailView(core: core, workoutId: "preview-123")
    }
}
```

**File**: `app/iOS/Thiccc/WorkoutDetailView.swift` (new)

```swift
import SwiftUI

struct WorkoutDetailView: View {
    @Bindable var core: Core
    let workoutId: String
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Workout Detail")
                .font(.largeTitle.bold())
            Text("Workout ID: \(workoutId)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .navigationTitle("Workout")
    }
}

#Preview {
    @Previewable @State var core = Core()
    NavigationStack {
        WorkoutDetailView(core: core, workoutId: "preview-123")
    }
}
```

**Success Criteria**:
- [ ] NavigationStack added to each tab
- [ ] navigationDestination modifier configured
- [ ] Detail view placeholders created with `@Bindable`
- [ ] Previews use `@Previewable` (iOS 18+)
- [ ] Can navigate to detail views (when implemented)
- [ ] Back button works

#### Agent Prompt Template

```
I need you to add navigation destinations to the Thiccc iOS app using iOS 18+ patterns.

**Current Files:**
- @ios/Thiccc/ContentView.swift (needs NavigationStack paths)

**Task: Add Navigation Destinations**

1. Add @State properties for navigation paths (workoutPath, historyPath)
2. Wrap each tab content in NavigationStack(path:)
3. Add .navigationDestination(for: String.self) modifier
4. Create placeholder detail views with @Bindable:
   - HistoryDetailView.swift
   - WorkoutDetailView.swift
5. Add iOS 18+ previews with @Previewable

**Note:** We're using String for workout IDs to match the Rust core (which uses 
String IDs for TypeGen compatibility). Later we can sync navigation state with 
the core if needed.

**Required Patterns:**
```swift
// Use @Bindable in views
struct HistoryDetailView: View {
    @Bindable var core: Core
    let workoutId: String
}

// Use @Previewable for previews (iOS 18+)
#Preview {
    @Previewable @State var core = Core()
    NavigationStack {
        HistoryDetailView(core: core, workoutId: "preview-123")
    }
}
```

**Success Criteria:**
- [ ] NavigationStack with paths on each tab
- [ ] navigationDestination configured
- [ ] Detail view placeholders use @Bindable
- [ ] Previews use @Previewable
- [ ] Code compiles
```

---

### Task 5.3: Implement Modal Presentation

**Estimated Time**: 30 minutes  
**Complexity**: Low  
**Priority**: Medium  
**Status**: ❌ Not Started

#### Objective
Add sheet/modal presentation for add exercise, import, etc.

#### ViewModel Fields Available

The `WorkoutViewModel` already has these fields for modal state:
- `showing_add_exercise: bool`
- `showing_import: bool`  
- `showing_stopwatch: bool`
- `showing_rest_timer: Option<i32>`

#### Implementation

**File**: Update `app/iOS/Thiccc/ContentView.swift` (WorkoutPlaceholderView)

**Add sheet modifiers**:
```swift
struct WorkoutPlaceholderView: View {
    @Bindable var core: Core
    
    var body: some View {
        VStack {
            // Content...
        }
        .navigationTitle("Workout")
        .sheet(isPresented: Binding(
            get: { core.view.workout_view.showing_add_exercise },
            set: { if !$0 { Task { await core.update(.dismissAddExerciseView) } } }
        )) {
            AddExercisePlaceholderView(core: core)
        }
        .sheet(isPresented: Binding(
            get: { core.view.workout_view.showing_import },
            set: { if !$0 { Task { await core.update(.dismissImportView) } } }
        )) {
            ImportPlaceholderView(core: core)
        }
    }
}

struct AddExercisePlaceholderView: View {
    @Bindable var core: Core
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Text("Add Exercise")
                .navigationTitle("Add Exercise")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            Task { await core.update(.dismissAddExerciseView) }
                        }
                    }
                }
        }
    }
}

struct ImportPlaceholderView: View {
    @Bindable var core: Core
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Text("Import")
                .navigationTitle("Import")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            Task { await core.update(.dismissImportView) }
                        }
                    }
                }
        }
    }
}
```

**Success Criteria**:
- [ ] Sheet modifiers added
- [ ] Views use `@Bindable` (not `@ObservedObject`)
- [ ] Sheets present when core state is true
- [ ] Sheets dismiss and send events to core
- [ ] Placeholder sheet views created

---

## Phase 5 Completion Checklist

Before moving to Phase 6, verify:

### Pre-Phase: Core Migration (Critical)
- [ ] Core class migrated to `@Observable`
- [ ] Removed `ObservableObject` conformance
- [ ] Removed `@Published` property wrappers
- [ ] App entry point uses `@State` for Core

### Task 5.1: Tab Navigation (Critical)
- [x] Basic tab structure exists
- [ ] Views use `@Bindable` (not `@ObservedObject`)
- [ ] Tab selection syncs with `core.view.selected_tab`
- [ ] `Event.changeTab` sent when switching tabs  
- [ ] Uses `SharedTypes.Tab` (not local enum)
- [ ] Each tab has NavigationStack
- [ ] Navigation titles display

### Task 5.2: Navigation Destinations
- [ ] NavigationStack with paths configured
- [ ] navigationDestination modifiers added
- [ ] HistoryDetailView placeholder created with `@Bindable`
- [ ] WorkoutDetailView placeholder created with `@Bindable`
- [ ] Back button works correctly

### Task 5.3: Modal Presentation
- [ ] Sheet modifiers for add exercise
- [ ] Sheet modifiers for import
- [ ] Modal state syncs with core
- [ ] Placeholder modal views created with `@Bindable`

### General
- [ ] All views use `@Bindable` (not deprecated patterns)
- [ ] Previews use `@Previewable` (iOS 18+)
- [ ] Code compiles without errors
- [ ] App runs in simulator
- [ ] No SwiftUI warnings

## Testing Phase 5

### Manual Testing Checklist

Run in iOS Simulator:

- [ ] Launch app → see tab bar
- [ ] Tap Workout tab → see workout view with navigation title
- [ ] Tap History tab → see history view with navigation title
- [ ] Check console: `Event.changeTab` should be logged when switching tabs
- [ ] Navigation stack works per tab
- [ ] Modals can be presented and dismissed

### Verify Core Sync

In DebugCapabilitiesView or via logging:
1. Switch tabs multiple times
2. Check that `core.view.selected_tab` updates correctly
3. Verify events are being sent to Rust core

## Common Issues & Solutions

### Issue: "Type 'Core' does not conform to protocol 'Observable'"
**Solution**: Add `import Observation` and ensure Core is marked with `@Observable` macro (not `ObservableObject` protocol).

### Issue: "@ObservedObject requires ObservableObject"
**Solution**: Replace `@ObservedObject var core: Core` with `@Bindable var core: Core`. The Core class must use `@Observable`.

### Issue: Tab selection not syncing
**Solution**: Ensure the TabView selection binding:
- Gets from `core.view.selected_tab`
- Sets by calling `await core.update(.changeTab(tab: newTab))`
- Uses `SharedTypes.Tab` for the tag values

### Issue: "Cannot convert Tab to SharedTypes.Tab"
**Solution**: Remove the local `Tab` enum from ContentView.swift. Use `SharedTypes.Tab.workout` and `SharedTypes.Tab.history` directly.

### Issue: Async update in binding setter
**Solution**: Wrap in Task:
```swift
set: { newTab in
    Task {
        await core.update(.changeTab(tab: newTab))
    }
}
```

### Issue: Navigation path errors
**Solution**: Use `NavigationPath()` for type-erased navigation, or `[String]` for simple string-based navigation.

### Issue: Sheets not dismissing
**Solution**: Check bindings use the correct property path:
- `core.view.workout_view.showing_add_exercise` (note underscores)

### Issue: Back button not working
**Solution**: Verify NavigationStack wraps the correct content and path is @State.

### Issue: Preview crashes
**Solution**: Use `@Previewable` macro for state in previews (iOS 18+):
```swift
#Preview {
    @Previewable @State var core = Core()
    ContentView(core: core)
}
```

## Remaining Work Summary

| Task | Status | Effort |
|------|--------|--------|
| Pre-Phase: Migrate Core to @Observable | ❌ Not started | 15 min |
| 5.1 Fix tab sync with core | 🟡 Partial | 30 min |
| 5.2 Add navigation destinations | ❌ Not started | 1 hour |
| 5.3 Add modal presentation | ❌ Not started | 30 min |

**Total Remaining**: ~2.25 hours

## Next Steps

After completing Phase 5, you can work on these in parallel:
- **[Phase 6: Workout View UI](./06-PHASE-6-WORKOUT-VIEW.md)** - Main workout tracking interface
- **[Phase 7: History Views UI](./07-PHASE-7-HISTORY-VIEWS.md)** - History list and detail

---

**Phase Status**: 🟡 Partially Implemented (~30%)  
**Last Updated**: November 30, 2025  
**Swift Version**: Swift 6.0+ required  
**iOS Version**: iOS 18.0+ required
