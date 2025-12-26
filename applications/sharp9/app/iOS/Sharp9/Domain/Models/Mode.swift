import Foundation

/// The current interaction mode for waveform taps
enum Mode: Sendable, Equatable {
    case marker
    case setA
    case loop
    case setB
}

