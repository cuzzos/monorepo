import Foundation

/// Protocol for audio playback engine (replaceable with Rust/Crux later)
protocol AudioEngine: AnyObject, Sendable {
    /// Callback for time updates during playback
    var onTimeUpdate: (@Sendable (Double) -> Void)? { get set }
    
    /// Load an audio file and return its metadata
    func load(url: URL) async throws -> TrackMeta
    
    /// Start playback
    func play()
    
    /// Pause playback
    func pause()
    
    /// Seek to a specific time
    func seek(to timeSec: Double)
    
    /// Set playback rate (0.25 to 2.0)
    func setRate(_ rate: Double)
    
    /// Set pitch shift in semitones (-12 to +12)
    func setPitchSemitones(_ semitones: Double)
    
    /// Configure A/B loop points
    func setLoop(aSec: Double?, bSec: Double?, enabled: Bool)
    
    /// Get current playback time
    func currentTimeSec() -> Double
}

/// Errors that can occur during audio operations
enum AudioEngineError: Error, LocalizedError {
    case fileNotFound
    case invalidFormat
    case loadFailed(String)

    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "Audio file not found"
        case .invalidFormat:
            return "Audio format not supported. Please use WAV, AIFF, CAF, MP3, M4A, or AAC files."
        case .loadFailed(let message):
            return "Failed to load audio: \(message)"
        }
    }
}

