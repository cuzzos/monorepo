import SwiftUI
import SharedTypes
import GRDB

/// Debug view for testing capabilities.
///
/// This view provides buttons to manually trigger each capability operation
/// and displays console logs for verification.
///
/// **Usage**: Add this view to your app during development to test capabilities.
/// **Note**: Remove or disable in production builds.
struct DebugCapabilitiesView: View {
    @Bindable var core: Core
    @State private var testResult: String = "Tap a button to test"
    @State private var timerSeconds: Int = 0
    
    var body: some View {
        NavigationStack {
            List {
                // MARK: - Current State
                Section("Current State") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Has Active Workout: \(core.view.workout_view.has_active_workout ? "Yes" : "No")")
                        Text("Timer Running: \(core.view.workout_view.timer_running ? "Yes" : "No")")
                        Text("Duration: \(core.view.workout_view.formatted_duration)")
                        Text("Exercises: \(core.view.workout_view.exercises.count)")
                        Text("History Items: \(core.view.history_view.workouts.count)")
                    }
                    .font(.system(.body, design: .monospaced))
                }
                
                // MARK: - Workout Actions
                Section("Workout Actions") {
                    Button("Start Workout") {
                        print("🔍 DEBUG: DebugCapabilitiesView - Start Workout button tapped")
                        Task {
                            await core.update(.startWorkout)
                            print("🔍 DEBUG: DebugCapabilitiesView - Start Workout event sent")
                            testResult = "Started workout"
                        }
                    }
                    
                    Button("Finish Workout") {
                        Task {
                            await core.update(.finishWorkout)
                            testResult = "Finished workout"
                        }
                    }
                    
                    Button("Discard Workout") {
                        Task {
                            await core.update(.discardWorkout)
                            testResult = "Discarded workout"
                        }
                    }
                    
                    Button("Add Exercise (Bench Press)") {
                        print("🔍 DEBUG: DebugCapabilitiesView - Adding exercise: Bench Press")
                        Task {
                            await core.update(.addExercise(
                                name: "Bench Press",
                                exercise_type: "barbell",
                                muscle_group: "chest"
                            ))
                            print("🔍 DEBUG: DebugCapabilitiesView - Event sent for: Bench Press")
                            testResult = "Added exercise"
                        }
                    }
                }
                
                // MARK: - Timer Actions
                Section("Timer Actions") {
                    Button("Start Timer") {
                        Task {
                            await core.update(.startTimer)
                            testResult = "Timer started"
                        }
                    }
                    
                    Button("Stop Timer") {
                        Task {
                            await core.update(.stopTimer)
                            testResult = "Timer stopped"
                        }
                    }
                    
                    Button("Toggle Timer") {
                        Task {
                            await core.update(.toggleTimer)
                            testResult = "Timer toggled"
                        }
                    }
                }
                
                // MARK: - Storage Actions
                Section("Storage Actions") {
                    Button("Initialize (Load from Storage)") {
                        Task {
                            await core.update(.initialize)
                            testResult = "Initialized from storage"
                        }
                    }
                    
                    Button("Show File Path") {
                        let fileURL = URL.documentsDirectory.appending(component: "current-workout.json")
                        print("📂 File location: \(fileURL.path)")
                        print("📂 File exists: \(FileManager.default.fileExists(atPath: fileURL.path))")
                        testResult = "Check console for file path"
                    }
                    
                    Button("Read Storage File") {
                        let fileURL = URL.documentsDirectory.appending(component: "current-workout.json")
                        if FileManager.default.fileExists(atPath: fileURL.path) {
                            do {
                                let content = try String(contentsOf: fileURL, encoding: .utf8)
                                print("📄 File content:\n\(content)")
                                testResult = "File content logged to console (\(content.count) bytes)"
                            } catch {
                                testResult = "Failed to read file: \(error)"
                            }
                        } else {
                            testResult = "No file exists"
                        }
                    }
                }
                
                // MARK: - Database
                Section("Database") {
                    NavigationLink {
                        DatabaseInspectorView()
                    } label: {
                        Label("Database Inspector", systemImage: "externaldrive.fill")
                    }
                }
                
                // MARK: - Test Result
                Section("Test Result") {
                    Text(testResult)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                
                // MARK: - Console Logs (Last 10)
                Section("Recent Console Logs") {
                    ForEach(ConsoleLogger.shared.logs.suffix(10).reversed(), id: \.timestamp) { log in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(log.emoji)
                                Text(log.message)
                                    .font(.system(.caption, design: .monospaced))
                                Spacer()
                            }
                            Text(log.timestamp, style: .time)
                                .font(.system(.caption2))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                    
                    if ConsoleLogger.shared.logs.isEmpty {
                        Text("No logs yet")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Button("Clear Logs") {
                        ConsoleLogger.shared.clear()
                        testResult = "Logs cleared"
                    }
                }
            }
            .navigationTitle("Debug Capabilities")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Console Logger

@Observable
@MainActor
final class ConsoleLogger {
    static let shared = ConsoleLogger()
    
    struct LogEntry {
        let timestamp: Date
        let message: String
        let emoji: String
    }
    
    var logs: [LogEntry] = []
    
    private init() {}
    
    func log(_ message: String, emoji: String = "📝") {
        let entry = LogEntry(timestamp: Date(), message: message, emoji: emoji)
        logs.append(entry)
        
        // Keep only last 50 logs
        if logs.count > 50 {
            logs.removeFirst(logs.count - 50)
        }
    }
    
    func clear() {
        logs.removeAll()
    }
}

