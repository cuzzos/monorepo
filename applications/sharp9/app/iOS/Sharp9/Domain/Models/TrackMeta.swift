import Foundation

/// Metadata for an imported audio track
struct TrackMeta: Sendable, Equatable {
    let name: String
    let durationSec: Double
    
    init(name: String, durationSec: Double) {
        self.name = name
        self.durationSec = durationSec
    }
}

