import Foundation

/// Derived state selectors
enum Selectors {
    /// Returns the normalized selection range (a, b) where a < b, or nil if incomplete
    static func selectionRange(_ state: AppState) -> (a: Double, b: Double)? {
        state.loop.normalizedRange
    }
    
    /// Whether looping can be enabled (both A and B are set)
    static func canLoop(_ state: AppState) -> Bool {
        state.loop.aSec != nil && state.loop.bSec != nil
    }
    
    /// Whether the loop selection overlay should be visible
    /// Only show when loop is enabled AND both A and B are set
    static func shouldShowLoopOverlay(_ state: AppState) -> Bool {
        state.loop.enabled && state.loop.normalizedRange != nil
    }
    
    /// Whether the track is loaded and ready
    static func hasTrack(_ state: AppState) -> Bool {
        state.track != nil
    }
    
    /// Current playback progress (0.0 to 1.0)
    static func playbackProgress(_ state: AppState) -> Double {
        guard let track = state.track, track.durationSec > 0 else { return 0 }
        return state.transport.currentTimeSec / track.durationSec
    }
    
    /// Convert a normalized position (0-1) to time in seconds
    static func positionToTime(_ position: Double, state: AppState) -> Double {
        guard let track = state.track else { return 0 }
        return position * track.durationSec
    }
    
    /// Convert a viewport-relative position (0-1) to time in seconds
    static func viewportPositionToTime(_ position: Double, state: AppState) -> Double {
        let viewport = state.viewport
        return viewport.startSec + position * viewport.durationSec
    }
}

