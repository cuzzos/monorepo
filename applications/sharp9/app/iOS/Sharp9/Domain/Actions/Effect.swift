import Foundation

/// Commands for the audio engine, executed by EffectRunner
/// 
/// The engine is STATELESS. All playback state (isPlaying, currentTimeSec) lives in
/// the Model (AppState.transport). Commands describe side effects to execute.
enum Effect: Sendable, Equatable {
    case engineLoad(url: URL)
    /// Start playback from the specified time (engine is stateless, always needs start position)
    case enginePlay(fromTimeSec: Double)
    case enginePause
    /// Seek to a specific time without changing play/pause state
    case engineSeek(timeSec: Double)
    case engineSetRate(Double)
    case engineSetPitchSemitones(Double)
    case engineSetLoop(aSec: Double?, bSec: Double?, enabled: Bool)
    case computePeaks
}

