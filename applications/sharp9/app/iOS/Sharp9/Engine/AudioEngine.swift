import Foundation

/// Protocol for audio playback engine (replaceable with Rust/Crux later)
/// 
/// The engine is STATELESS - it does not track playhead position or playing state.
/// All state lives in the Model (AppState.transport). The engine is a pure executor
/// of commands.
protocol AudioEngine: AnyObject, Sendable {
    /// Callback for time updates during playback (called ~30fps while playing)
    var onTimeUpdate: (@Sendable (Double) -> Void)? { get set }
    
    /// Callback when playback reaches end of file/buffer
    var onPlaybackFinished: (@Sendable () -> Void)? { get set }
    
    /// Load an audio file and return its metadata
    func load(url: URL) async throws -> TrackMeta
    
    /// Start playback from the specified time (engine is stateless)
    func play(from timeSec: Double)
    
    /// Pause playback
    func pause()
    
    /// Set playback rate (0.25 to 2.0)
    func setRate(_ rate: Double)
    
    /// Set pitch shift in semitones (-12 to +12)
    func setPitchSemitones(_ semitones: Double)
    
    /// Configure A/B loop points
    func setLoop(aSec: Double?, bSec: Double?, enabled: Bool)
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

