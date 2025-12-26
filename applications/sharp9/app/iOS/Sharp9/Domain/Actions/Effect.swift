import Foundation

/// Commands for the audio engine, executed by EffectRunner
enum Effect: Sendable, Equatable {
    case engineLoad(url: URL)
    case enginePlay
    case enginePause
    case engineSeek(timeSec: Double)
    case engineSetRate(Double)
    case engineSetPitchSemitones(Double)
    case engineSetLoop(aSec: Double?, bSec: Double?, enabled: Bool)
    case computePeaks
}

