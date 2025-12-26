import Foundation

/// Pure reducer function for state updates
enum Reducer {
    /// Process an action and return effects to execute
    static func reduce(state: inout AppState, action: Action, now: @Sendable () -> Date = { Date() }) -> [Effect] {
        switch action {
        case .onAppear:
            return []
            
        case .importPicked(let url):
            state.isLoading = true
            state.transport.isPlaying = false
            state.transport.currentTimeSec = 0
            state.isScrubbing = false  // Reset scrubbing state on new file import
            state.loop = LoopPoints()
            state.markers = []
            return [.enginePause, .engineLoad(url: url)]
            
        case .importSucceeded(let track):
            state.track = track
            state.isLoading = false
            state.isScrubbing = false  // Ensure scrubbing state is reset
            state.markers = []
            state.loop = LoopPoints()
            state.transport.currentTimeSec = 0
            state.viewport = Viewport(startSec: 0, endSec: track.durationSec)
            return [.computePeaks]
            
        case .importFailed(let message):
            state.isLoading = false
            state.toast = ToastState(message: message.isEmpty ? "Unable to open file" : message, now: now())
            return []
            
        case .setMode(let mode):
            state.mode = mode
            return []
            
        case .tapWaveform(let timeSec):
            // Reset scrubbing state on any tap (tap is a point-in-time action, not a drag)
            state.isScrubbing = false
            
            switch state.mode {
            case .setA:
                return reduce(state: &state, action: .setA(timeSec: timeSec), now: now)
            case .setB:
                return reduce(state: &state, action: .setB(timeSec: timeSec), now: now)
            case .marker:
                return reduce(state: &state, action: .addMarker(timeSec: timeSec), now: now)
            case .loop:
                state.transport.currentTimeSec = timeSec
                // Engine is stateless - if playing, restart from new position
                if state.transport.isPlaying {
                    return [.enginePlay(fromTimeSec: timeSec)]
                }
                return []
            }
            
        case .dragScrub(let timeSec):
            // Deprecated: redirect to new transportScrubChanged action
            return reduce(state: &state, action: .transportScrubChanged(timeSec: timeSec), now: now)
            
        case .transportScrubChanged(let timeSec):
            let clampedTime = clampTime(timeSec, state: state)
            let wasPlaying = state.transport.isPlaying
            
            // Mark that we're actively scrubbing (prevents tick events from overwriting position)
            state.isScrubbing = true
            state.transport.currentTimeSec = clampedTime
            
            // CRITICAL: Do NOT mutate isPlaying during scrub
            // Strategy:
            // - Visual position updates immediately to follow the drag
            // - Audio continues playing uninterrupted (if it was playing)
            // - Ticks are ignored via isScrubbing flag
            // - On drag end, audio will jump to final position
            if !wasPlaying {
                // If paused: seek immediately for visual/audio feedback
                return [.engineSeek(timeSec: clampedTime)]
            } else {
                // If playing: let audio continue, just update visual position
                // No effect - audio keeps playing, user sees drag position
                return []
            }
            
        case .transportScrubEnded(let timeSec):
            let clampedTime = clampTime(timeSec, state: state)
            let wasPlaying = state.transport.isPlaying
            
            // End scrubbing state
            state.isScrubbing = false
            state.transport.currentTimeSec = clampedTime
            
            // CRITICAL: Do NOT mutate isPlaying at end of scrub
            // Commit final position:
            // - If was playing: restart from new position
            // - If was paused: just seek
            if wasPlaying {
                return [.enginePlay(fromTimeSec: clampedTime)]
            } else {
                return [.engineSeek(timeSec: clampedTime)]
            }
            
        case .togglePlay:
            if state.transport.isPlaying {
                state.transport.isPlaying = false
                return [.enginePause]
            } else {
                state.transport.isPlaying = true
                // Engine is stateless - always pass the current playhead position
                return [.enginePlay(fromTimeSec: state.transport.currentTimeSec)]
            }
            
        case .tick(let currentTimeSec):
            // Ignore tick events while user is actively scrubbing
            // (prevents engine position from overwriting user's drag position)
            guard !state.isScrubbing else { return [] }
            
            state.transport.currentTimeSec = currentTimeSec
            
            // Loop boundary check: if enabled and past loop end, jump to loop start
            // This is business logic that belongs in the domain, not the engine
            if state.loop.enabled,
               let a = state.loop.aSec,
               let b = state.loop.bSec,
               currentTimeSec >= b {
                state.transport.currentTimeSec = a
                return [.enginePlay(fromTimeSec: a)]
            }
            
            return []
            
        case .playbackFinished:
            // Engine finished playing - update Model state
            state.transport.isPlaying = false
            // Keep currentTimeSec at end (or wherever it stopped)
            return []
            
        case .speedDelta(let delta):
            let newSpeed = (state.transport.speed + delta)
                .clamped(to: Transport.minSpeed...Transport.maxSpeed)
            state.transport.speed = newSpeed
            state.toast = ToastState(message: Formatting.speedToastMessage(newSpeed), now: now())
            return [.engineSetRate(newSpeed)]
            
        case .pitchDelta(let delta):
            let newPitch = (state.transport.pitchSemitones + delta)
                .clamped(to: Transport.minPitch...Transport.maxPitch)
            state.transport.pitchSemitones = newPitch
            state.toast = ToastState(message: Formatting.pitchToastMessage(newPitch), now: now())
            return [.engineSetPitchSemitones(newPitch)]
            
        case .addMarker(let timeSec):
            let marker = Marker(timeSec: timeSec)
            state.markers.append(marker)
            return []
            
        case .deleteMarker(let id):
            state.markers.removeAll { $0.id == id }
            return []
            
        case .toggleLoopEnabled(let enabled):
            if enabled {
                guard Selectors.canLoop(state) else {
                    state.toast = ToastState(message: "Set A and B", now: now())
                    return []
                }
                state.loop.enabled = true
            } else {
                state.loop.enabled = false
            }
            return [.engineSetLoop(
                aSec: state.loop.aSec,
                bSec: state.loop.bSec,
                enabled: state.loop.enabled
            )]
            
        case .setA(let timeSec):
            state.loop.aSec = timeSec
            normalizeLoopPoints(&state.loop)
            return [.engineSetLoop(
                aSec: state.loop.aSec,
                bSec: state.loop.bSec,
                enabled: state.loop.enabled
            )]
            
        case .setB(let timeSec):
            state.loop.bSec = timeSec
            normalizeLoopPoints(&state.loop)
            return [.engineSetLoop(
                aSec: state.loop.aSec,
                bSec: state.loop.bSec,
                enabled: state.loop.enabled
            )]
            
        case .clearToastIfExpired(let now):
            if let toast = state.toast, now >= toast.expiresAt {
                state.toast = nil
            }
            return []
        }
    }
    
    // MARK: - Private Helpers
    
    private static func clampTime(_ time: Double, state: AppState) -> Double {
        guard let track = state.track else { return 0 }
        return time.clamped(to: 0...track.durationSec)
    }
    
    private static func normalizeLoopPoints(_ loop: inout LoopPoints) {
        guard let a = loop.aSec, let b = loop.bSec, a > b else { return }
        loop.aSec = b
        loop.bSec = a
    }
}

// MARK: - Comparable Extension

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}


