import Foundation

/// All user-triggered and system actions
enum Action: Sendable, Equatable {
    // Lifecycle
    case onAppear
    
    // Import
    case importPicked(url: URL)
    case importSucceeded(track: TrackMeta)
    case importFailed(message: String)
    
    // Mode
    case setMode(Mode)
    
    // Waveform interaction
    case tapWaveform(timeSec: Double)
    case dragScrub(timeSec: Double) // Deprecated: use transportScrubChanged/Ended instead
    
    // Transport scrubbing (Elm-style: separate changed/ended)
    case transportScrubChanged(timeSec: Double)
    case transportScrubEnded(timeSec: Double)
    
    // Transport
    case togglePlay
    case tick(currentTimeSec: Double)
    /// Engine finished playing (reached end of file/buffer)
    case playbackFinished
    
    // Speed/Pitch
    case speedDelta(Double)
    case pitchDelta(Double)
    
    // Markers
    case addMarker(timeSec: Double)
    case deleteMarker(id: UUID)
    
    // Loop
    case toggleLoopEnabled(Bool)
    case setA(timeSec: Double)
    case setB(timeSec: Double)
    
    // Toast
    case clearToastIfExpired(now: Date)
}

