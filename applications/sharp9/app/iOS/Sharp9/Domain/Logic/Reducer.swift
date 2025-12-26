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
            state.loop = LoopPoints()
            state.markers = []
            return [.enginePause, .engineLoad(url: url)]
            
        case .importSucceeded(let track):
            state.track = track
            state.isLoading = false
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
            switch state.mode {
            case .setA:
                return reduce(state: &state, action: .setA(timeSec: timeSec), now: now)
            case .setB:
                return reduce(state: &state, action: .setB(timeSec: timeSec), now: now)
            case .marker:
                return reduce(state: &state, action: .addMarker(timeSec: timeSec), now: now)
            case .loop:
                state.transport.currentTimeSec = timeSec
                return [.engineSeek(timeSec: timeSec)]
            }
            
        case .dragScrub(let timeSec):
            let clampedTime = clampTime(timeSec, state: state)
            state.transport.currentTimeSec = clampedTime
            return [.engineSeek(timeSec: clampedTime)]
            
        case .togglePlay:
            if state.transport.isPlaying {
                state.transport.isPlaying = false
                return [.enginePause]
            } else {
                state.transport.isPlaying = true
                return [.enginePlay]
            }
            
        case .tick(let currentTimeSec):
            state.transport.currentTimeSec = currentTimeSec
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

