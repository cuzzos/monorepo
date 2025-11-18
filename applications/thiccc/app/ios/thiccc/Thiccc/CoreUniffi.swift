//
//  CoreUniffi.swift
//  Thiccc
//
//  Swift bridge to Rust/Crux core using UniFFI.
//  This file bridges Swift UI to Rust business logic using UniFFI-generated bindings.
//
//  For detailed architecture documentation, see: ../../../../docs/ARCHITECTURE.md
//
//  Quick summary:
//    • All business logic is in Rust (app/shared/src/lib.rs)
//    • This file calls Rust via UniFFI auto-generated functions
//    • SwiftUI views observe @Published viewModel and update automatically
//
//  Key files:
//    • CoreUniffi.swift (this file) - Swift side of the bridge
//    • app/shared/src/lib.rs - Rust business logic
//    • app/shared/src/shared.udl - FFI interface definition


import Foundation
import Combine
// SharedCore types are compiled into the same module (Thiccc), no import needed

/// Bridge to Rust/Crux core using UniFFI
/// This is a simplified version that uses UniFFI-generated bindings
class RustCore: ObservableObject {
    @Published var viewModel: ViewModel
    
    // Database manager for persistence
    private let databaseManager = DatabaseManager()
    
    init() {
        // Get initial view model from Rust core
        do {
            let viewData = try view()
            self.viewModel = try JSONDecoder().decode(ViewModel.self, from: viewData)
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
            // Encode event to JSON data
            let eventData = try JSONEncoder().encode(event)
            
            // Call UniFFI-generated processEvent function (from Rust)
            let viewData = try processEvent(eventData)
            
            // Decode view model
            self.viewModel = try JSONDecoder().decode(ViewModel.self, from: viewData)
            
            // Handle side effects
            handleSideEffects(event)
        } catch {
            print("Error dispatching event: \(error)")
        }
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
