//
//  CoreUniffi.swift
//  Thiccc
//
//  Swift bridge to Rust/Crux core using UniFFI
//

import Foundation
import Combine

// MARK: - NOTE: Import the UniFFI-generated module
// After running build-ios.sh, you'll need to:
// 1. Add the Generated folder to your Xcode project
// 2. Uncomment the following import:
// import SharedCore

/// Bridge to Rust/Crux core using UniFFI
/// This is a simplified version that uses UniFFI-generated bindings
class RustCoreUniffi: ObservableObject {
    @Published var viewModel: ViewModel
    
    // Database manager for persistence
    private let databaseManager = DatabaseManager()
    
    init() {
        // Get initial view model from Rust core
        do {
            let viewData = try view()
            self.viewModel = try JSONDecoder().decode(ViewModel.self, from: Data(viewData))
        } catch {
            print("Error initializing view: \(error)")
            self.viewModel = Self.defaultViewModel()
        }
    }
    
    private static func defaultViewModel() -> ViewModel {
        ViewModel(
            workout: nil,
            isTimerRunning: false,
            formattedTime: "0:00",
            totalVolume: 0,
            totalSets: 0,
            workouts: [],
            selectedTab: .workout,
            navigationPath: [],
            plateCalculation: nil
        )
    }
    
    /// Dispatch an event to the core
    func dispatch(_ event: Event) {
        do {
            // Encode event to JSON bytes
            let eventJson = try JSONEncoder().encode(event)
            let eventBytes = [UInt8](eventJson)
            
            // Call UniFFI-generated processEvent function
            // NOTE: Uncomment this line after adding the Generated folder to Xcode:
            // let viewBytes = try processEvent(msg: eventBytes)
            
            // For now, as a placeholder until UniFFI bindings are generated:
            let viewBytes = try self.processEventFallback(eventBytes)
            
            // Decode view model
            let viewData = Data(viewBytes)
            self.viewModel = try JSONDecoder().decode(ViewModel.self, from: viewData)
            
            // Handle side effects
            handleSideEffects(event)
        } catch {
            print("Error dispatching event: \(error)")
        }
    }
    
    /// Fallback implementation until UniFFI bindings are ready
    /// This will be replaced by the actual UniFFI-generated function
    private func processEventFallback(_ eventBytes: [UInt8]) throws -> [UInt8] {
        // This is a temporary fallback that just returns the current view
        // In production, this will be replaced by calling the UniFFI processEvent()
        return try [UInt8](JSONEncoder().encode(viewModel))
    }
    
    /// Handle side effects that need to happen on the Swift side
    private func handleSideEffects(_ event: Event) {
        switch event {
        case .finishWorkout:
            // Save workout to database
            if let workoutViewModel = viewModel.workout {
                Task {
                    await saveWorkout(workoutViewModel)
                }
            }
        case .loadHistory:
            // Load workouts from database
            Task {
                await loadHistory()
            }
        case .loadWorkoutDetail(let workoutId):
            // Load workout detail from database
            Task {
                await loadWorkoutDetail(workoutId)
            }
        default:
            break
        }
    }
    
    // MARK: - Database Operations
    
    private func saveWorkout(_ workoutViewModel: WorkoutViewModel) async {
        // Convert ViewModel to full Workout model and save
        // This is handled by the database manager
        print("Saving workout: \(workoutViewModel.name)")
        // await databaseManager.saveWorkout(workout)
    }
    
    private func loadHistory() async {
        // Load all workouts from database
        print("Loading workout history")
        // let workouts = await databaseManager.loadAllWorkouts()
        // dispatch(.historyLoaded(workouts: workouts))
    }
    
    private func loadWorkoutDetail(_ workoutId: UUID) async {
        // Load specific workout from database
        print("Loading workout detail: \(workoutId)")
        // let workout = await databaseManager.loadWorkout(id: workoutId)
        // dispatch(.workoutLoaded(workout: workout))
    }
}

// MARK: - Migration Guide
/*
 To complete the UniFFI migration:
 
 1. Build the Rust library with UniFFI:
    cd app/shared
    ./build-ios.sh
 
 2. Add the Generated folder to Xcode:
    - In Xcode, right-click on the Thiccc folder
    - Select "Add Files to Thiccc"
    - Navigate to app/ios/thiccc/Thiccc/Generated
    - Check "Copy items if needed"
    - Add the folder
 
 3. Update the import at the top of this file:
    Uncomment: import SharedCore
 
 4. Update the dispatch() method:
    Replace: let viewBytes = try self.processEventFallback(eventBytes)
    With:    let viewBytes = try processEvent(msg: eventBytes)
 
 5. Update your app to use RustCoreUniffi instead of RustCore:
    In your app initialization, replace:
    @StateObject private var core = RustCore()
    With:
    @StateObject private var core = RustCoreUniffi()
 
 6. Remove the old Core.swift file (keep this CoreUniffi.swift)
 
 7. Delete obsolete files:
    - app/shared/shared.h
    - app/ios/thiccc/Thiccc/shared-Bridging-Header.h
*/

