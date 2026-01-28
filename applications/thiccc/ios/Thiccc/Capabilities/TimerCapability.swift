import Foundation
import SharedTypes

/// Handles workout timer operations.
///
/// The timer sends tick events every second while a workout is in progress.
/// This is used to track workout duration.
///
/// Implementation notes:
/// - Uses Foundation Timer for 1-second intervals
/// - Timer runs on the main thread for UI updates
/// - Automatically stops when the workout ends
@MainActor
class TimerCapability {
    private weak var core: Core?
    private var timer: Timer?
    private var isRunning: Bool = false
    
    init(core: Core) {
        self.core = core
        print("⏱️ [TimerCapability] Initialized")
    }
    
    /// Handle a timer operation from the Rust core.
    func handle(_ operation: SharedTypes.TimerOperation, requestId: UInt32) async {
        switch operation {
        case .start:
            await handleStart(requestId: requestId)
            
        case .stop:
            await handleStop(requestId: requestId)
        }
    }
    
    /// Start the workout timer.
    ///
    /// Begins sending tick events every second. If the timer is already
    /// running, this has no effect.
    private func handleStart(requestId: UInt32) async {
        print("▶️ [TimerCapability] Start requested")
        
        if isRunning {
            print("ℹ️ [TimerCapability] Timer already running")
            // Still send started response
            let output = SharedTypes.TimerOutput.started
            await core?.sendTimerResponse(requestId: requestId, output: output)
            return
        }
        
        isRunning = true
        
        // Create a timer that fires every second
        // Note: We capture a weak reference to self to avoid retain cycles
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.sendTick()
            }
        }
        
        // Make sure the timer runs even during scrolling
        // Note: We're on MainActor so this is safe
        if let timer = timer {
            RunLoop.main.add(timer, forMode: .common)
        }
        
        print("✅ [TimerCapability] Timer started")
        
        // Send started response
        let output = SharedTypes.TimerOutput.started
        await core?.sendTimerResponse(requestId: requestId, output: output)
    }
    
    /// Stop the workout timer.
    ///
    /// Stops sending tick events. If the timer is not running,
    /// this has no effect.
    private func handleStop(requestId: UInt32) async {
        print("⏹️ [TimerCapability] Stop requested")
        
        stopTimerInternal()
        
        print("✅ [TimerCapability] Timer stopped")
        
        // Send stopped response
        let output = SharedTypes.TimerOutput.stopped
        await core?.sendTimerResponse(requestId: requestId, output: output)
    }
    
    /// Send a tick event to the Rust core.
    ///
    /// Called every second by the timer.
    private func sendTick() async {
        guard isRunning, let core = core else { return }
        
        // Create a TimerTick event and send it to the core
        let event = SharedTypes.Event.timerTick
        await core.update(event)
    }
    
    /// Internal method to stop the timer.
    private func stopTimerInternal() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }
}

