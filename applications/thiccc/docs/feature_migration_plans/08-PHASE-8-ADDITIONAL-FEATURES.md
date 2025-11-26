# Phase 8: Additional Features UI

## Overview

**Goal**: Implement supporting features (timers, plate calculator, exercise library, import).

**Phase Duration**: Estimated 3-4 hours  
**Complexity**: Medium  
**Dependencies**: Phase 5 (Navigation)  
**Blocks**: None

## Why This Phase Matters

These features enhance the user experience:
- Exercise library makes adding exercises easy
- Plate calculator helps with barbell loading
- Timers help with rest periods and workout tracking
- Import enables data migration

## Task Breakdown

### Task 8.1: Implement Add Exercise View

**Estimated Time**: 1.5 hours  
**Complexity**: Medium  
**Priority**: High

#### Objective
Create searchable exercise library with multi-select capability.

#### Reference Files
- `legacy/Goonlytics/Goonlytics/Sources/Workout/AddExerciseView.swift`

#### Implementation

**File**: `/applications/thiccc/app/ios/Thiccc/AddExerciseView.swift` (new file)

```swift
import SwiftUI

struct AddExerciseView: View {
    @ObservedObject var core: Core
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @State private var selectedExercises: Set<UUID> = []
    
    var filteredExercises: [GlobalExercise] {
        core.view.exerciseLibrary.filter { exercise in
            searchText.isEmpty || 
            exercise.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                searchBar
                
                // Exercise list
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        Text("All Exercises")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                            .padding(.top, 8)
                        
                        ForEach(filteredExercises, id: \.id) { exercise in
                            ExerciseRow(
                                exercise: exercise,
                                isSelected: selectedExercises.contains(exercise.id),
                                onTap: { toggleSelection(exercise.id) }
                            )
                        }
                    }
                }
                
                // Add button (if exercises selected)
                if !selectedExercises.isEmpty {
                    addButton
                        .transition(.move(edge: .bottom))
                }
            }
            .navigationBarTitle("Add Exercise", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Create Exercise") {
                    // Future: custom exercise creation
                    dismiss()
                }
            )
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("Search exercise", text: $searchText)
                .autocapitalization(.none)
                .disableAutocorrection(true)
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding([.horizontal, .top])
    }
    
    private var addButton: some View {
        Button {
            // Get selected exercises and add them
            let exercises = filteredExercises.filter { selectedExercises.contains($0.id) }
            for exercise in exercises {
                core.update(.addExercise(exercise: exercise))
            }
            dismiss()
        } label: {
            Text("Add \(selectedExercises.count) exercise\(selectedExercises.count > 1 ? "s" : "")")
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
                .padding([.horizontal, .bottom])
        }
    }
    
    private func toggleSelection(_ id: UUID) {
        if selectedExercises.contains(id) {
            selectedExercises.remove(id)
        } else {
            selectedExercises.insert(id)
        }
    }
}

struct ExerciseRow: View {
    let exercise: GlobalExercise
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Exercise icon/image
                Circle()
                    .fill(isSelected ? Color.blue : Color(.systemGray4))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(String(exercise.name.prefix(1)))
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.name)
                        .foregroundColor(.primary)
                        .fontWeight(.medium)
                    Text(exercise.muscleGroup)
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .imageScale(.large)
                } else {
                    Image(systemName: "info.circle")
                        .foregroundColor(.gray)
                        .imageScale(.large)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        }
        .buttonStyle(.plain)
    }
}
```

**Success Criteria**:
- [ ] Exercise list displays
- [ ] Search works
- [ ] Can select multiple exercises
- [ ] Add button shows count
- [ ] Adds exercises to workout
- [ ] Dismisses after adding

---

### Task 8.2: Implement Timer Modals

**Estimated Time**: 1 hour  
**Complexity**: Low-Medium  
**Priority**: Medium

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

### Task 8.3: Implement Plate Calculator View

**Estimated Time**: 1 hour  
**Complexity**: Medium  
**Priority**: Low

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

### Task 8.4: Implement Import Workout View

**Estimated Time**: 30 minutes  
**Complexity**: Low  
**Priority**: Low

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

Before moving to other phases, verify:

- [ ] Add Exercise view implemented
- [ ] Exercise search works
- [ ] Multi-select works
- [ ] Stopwatch modal works
- [ ] Rest timer modal works
- [ ] Plate calculator view implemented
- [ ] Calculator computes correctly
- [ ] Import view implemented
- [ ] All modals dismiss properly
- [ ] Code compiles without errors
- [ ] App runs in simulator

## Testing Phase 8

### Manual Testing

- [ ] Open Add Exercise → search for exercise
- [ ] Select multiple exercises → add to workout
- [ ] Open stopwatch → start/stop/reset
- [ ] Open rest timer → countdown works
- [ ] Open plate calculator → calculate plates
- [ ] Open import → paste JSON → import

## Next Steps

After completing Phase 8:
- **[Phase 9: Database Implementation](./09-PHASE-9-DATABASE.md)** - Full persistence
- **[Phase 10: Additional Business Logic](./10-PHASE-10-ADDITIONAL-LOGIC.md)** - Stats, calculator logic

---

**Phase Status**: 📋 Ready for Implementation  
**Last Updated**: November 26, 2025

