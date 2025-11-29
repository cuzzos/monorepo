import Foundation
import SharedTypes

/// Handles file-based storage of the current in-progress workout.
///
/// The current workout is persisted to a JSON file so it can be restored
/// if the app is terminated. This is separate from the database which
/// stores completed workouts.
///
/// File location: `Documents/current-workout.json`
@MainActor
class StorageCapability {
    private weak var core: Core?
    private let fileURL: URL
    
    init(core: Core) {
        self.core = core
        self.fileURL = URL.documentsDirectory.appending(component: "current-workout.json")
        
        print("📂 [StorageCapability] Initialized")
        print("📂 [StorageCapability] File path: \(fileURL.path)")
    }
    
    /// Handle a storage operation from the Rust core.
    func handle(_ operation: SharedTypes.StorageOperation, requestId: UInt32) async {
        switch operation {
        case .saveCurrentWorkout(let workoutJson):
            await handleSave(workoutJson: workoutJson, requestId: requestId)
            
        case .loadCurrentWorkout:
            await handleLoad(requestId: requestId)
            
        case .deleteCurrentWorkout:
            await handleDelete(requestId: requestId)
        }
    }
    
    /// Save the current workout to file storage.
    ///
    /// The workout is already JSON-encoded by the Rust core.
    private func handleSave(workoutJson: String, requestId: UInt32) async {
        print("💾 [StorageCapability] Saving current workout...")
        
        do {
            // Write the JSON string directly to the file
            try workoutJson.write(to: fileURL, atomically: true, encoding: .utf8)
            
            print("✅ [StorageCapability] Workout saved successfully")
            print("📄 [StorageCapability] File size: \(workoutJson.count) bytes")
            
            // Send success response
            let result = SharedTypes.StorageResult.currentWorkoutSaved
            await core?.sendStorageResponse(requestId: requestId, result: result)
            
        } catch {
            print("❌ [StorageCapability] Save failed: \(error)")
            
            // Send error response with error details
            let result = SharedTypes.StorageResult.error(message: error.localizedDescription)
            await core?.sendStorageResponse(requestId: requestId, result: result)
        }
    }
    
    /// Load the current workout from file storage.
    ///
    /// Returns the JSON string directly - the Rust core handles deserialization.
    private func handleLoad(requestId: UInt32) async {
        print("📖 [StorageCapability] Loading current workout...")
        
        // Check if file exists
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("ℹ️ [StorageCapability] No saved workout found")
            
            let result = SharedTypes.StorageResult.currentWorkoutLoaded(workout_json: nil)
            await core?.sendStorageResponse(requestId: requestId, result: result)
            return
        }
        
        do {
            // Read the JSON string from file
            let jsonString = try String(contentsOf: fileURL, encoding: .utf8)
            
            print("📄 [StorageCapability] Loaded JSON (\(jsonString.count) bytes)")
            print("✅ [StorageCapability] Returning JSON to Rust core for deserialization")
            
            // Return JSON string - Rust core will deserialize it
            let result = SharedTypes.StorageResult.currentWorkoutLoaded(workout_json: jsonString)
            await core?.sendStorageResponse(requestId: requestId, result: result)
            
        } catch {
            print("❌ [StorageCapability] Load failed: \(error)")
            
            // Return nil on error
            let result = SharedTypes.StorageResult.currentWorkoutLoaded(workout_json: nil)
            await core?.sendStorageResponse(requestId: requestId, result: result)
        }
    }
    
    /// Delete the current workout file from storage.
    private func handleDelete(requestId: UInt32) async {
        print("🗑️ [StorageCapability] Deleting current workout...")
        
        do {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
                print("✅ [StorageCapability] Workout file deleted")
            } else {
                print("ℹ️ [StorageCapability] No file to delete")
            }
            
            let result = SharedTypes.StorageResult.currentWorkoutDeleted
            await core?.sendStorageResponse(requestId: requestId, result: result)
            
        } catch {
            print("❌ [StorageCapability] Delete failed: \(error)")
            
            // Send success anyway - file might not exist
            let result = SharedTypes.StorageResult.currentWorkoutDeleted
            await core?.sendStorageResponse(requestId: requestId, result: result)
        }
    }
}

