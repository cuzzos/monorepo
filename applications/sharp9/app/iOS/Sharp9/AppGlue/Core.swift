import Foundation
import Observation

/// The main observable state container
@Observable
@MainActor
final class Core {
    
    /// The current application state
    var state: AppState
    
    /// Access to waveform peaks (cached in runner, not in state)
    var peaks: WaveformPeaks {
        runner.peaks
    }
    
    private let runner: EffectRunner
    private let now: @Sendable () -> Date
    
    /// Timer task for clearing expired toasts
    /// Using nonisolated(unsafe) since Task cancellation is thread-safe
    nonisolated(unsafe) private var toastTimerTask: Task<Void, Never>?
    
    init(deps: Dependencies) {
        self.state = AppState()
        self.runner = EffectRunner(deps: deps)
        self.now = deps.now
        
        // Wire up the runner to this core
        runner.setCore(self)
        
        // Start toast expiry timer
        startToastTimer()
    }
    
    /// Send an action to update state and run effects
    func send(_ action: Action) {
        let effects = Reducer.reduce(state: &state, action: action, now: now)
        
        for effect in effects {
            runner.run(effect)
        }
    }
    
    // MARK: - Private Methods
    
    private func startToastTimer() {
        toastTimerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(100))
                
                guard let self = self else { break }
                
                if self.state.toast != nil {
                    self.send(.clearToastIfExpired(now: self.now()))
                }
            }
        }
    }
    
    deinit {
        toastTimerTask?.cancel()
    }
}

