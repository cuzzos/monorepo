import Foundation

/// Precomputed waveform peak data for visualization
struct WaveformPeaks: Sendable, Equatable {
    /// Minimum amplitude values per bucket
    let min: [Float]
    /// Maximum amplitude values per bucket
    let max: [Float]
    /// Number of buckets
    let buckets: Int
    /// Duration of the audio in seconds
    let durationSec: Double
    
    init(min: [Float], max: [Float], buckets: Int, durationSec: Double) {
        self.min = min
        self.max = max
        self.buckets = buckets
        self.durationSec = durationSec
    }
    
    /// Empty peaks for placeholder
    static var empty: WaveformPeaks {
        WaveformPeaks(min: [], max: [], buckets: 0, durationSec: 0)
    }
}

