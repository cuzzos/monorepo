import Foundation

/// The visible time range of the waveform
struct Viewport: Sendable, Equatable {
    var startSec: Double
    var endSec: Double
    
    init(startSec: Double = 0, endSec: Double = 60) {
        self.startSec = startSec
        self.endSec = endSec
    }
    
    var durationSec: Double {
        endSec - startSec
    }
}

