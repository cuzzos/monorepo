import Foundation

/// Executes effects by calling into dependencies
@MainActor
final class EffectRunner {
    
    private let deps: Dependencies
    private weak var core: Core?
    
    /// Cached waveform peaks (not stored in domain state to avoid large arrays)
    private(set) var peaks: WaveformPeaks = .empty
    
    /// Current audio file URL for peak computation
    private var currentURL: URL?
    
    init(deps: Dependencies) {
        self.deps = deps
        setupTimeUpdateCallback()
    }
    
    func setCore(_ core: Core) {
        self.core = core
    }
    
    func run(_ effect: Effect) {
        switch effect {
        case .engineLoad(let url):
            currentURL = url
            Task {
                await loadAudio(url: url)
            }
            
        case .enginePlay(let fromTimeSec):
            deps.engine.play(from: fromTimeSec)
            
        case .enginePause:
            deps.engine.pause()
            
        case .engineSetRate(let rate):
            deps.engine.setRate(rate)
            
        case .engineSetPitchSemitones(let semitones):
            deps.engine.setPitchSemitones(semitones)
            
        case .engineSetLoop(let aSec, let bSec, let enabled):
            deps.engine.setLoop(aSec: aSec, bSec: bSec, enabled: enabled)
            
        case .computePeaks:
            Task {
                await computePeaks()
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func setupTimeUpdateCallback() {
        deps.engine.onTimeUpdate = { [weak self] time in
            Task { @MainActor in
                self?.core?.send(.tick(currentTimeSec: time))
            }
        }
        
        deps.engine.onPlaybackFinished = { [weak self] in
            Task { @MainActor in
                // Playback reached end - pause and reset to start (or loop point A)
                self?.core?.send(.playbackFinished)
            }
        }
    }
    
    private func loadAudio(url: URL) async {
        do {
            let track = try await deps.engine.load(url: url)
            core?.send(.importSucceeded(track: track))
        } catch {
            core?.send(.importFailed(message: error.localizedDescription))
        }
    }
    
    private func computePeaks() async {
        guard let url = currentURL else { return }
        
        do {
            // Access security-scoped resource
            let didStartAccess = url.startAccessingSecurityScopedResource()
            defer {
                if didStartAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            
            // Compute peaks with reasonable bucket count
            let targetBuckets = 1000
            peaks = try await deps.peakComputer.computePeaks(url: url, targetBuckets: targetBuckets)
        } catch {
            // Silently fail - waveform just won't show
            peaks = .empty
        }
    }
}

