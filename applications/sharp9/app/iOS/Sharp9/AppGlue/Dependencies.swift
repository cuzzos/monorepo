import Foundation

/// Container for all dependencies
struct Dependencies: Sendable {
    let engine: AudioEngine
    let peakComputer: WaveformPeakComputer
    let now: @Sendable () -> Date
    
    init(
        engine: AudioEngine,
        peakComputer: WaveformPeakComputer,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.engine = engine
        self.peakComputer = peakComputer
        self.now = now
    }
    
    /// Default live dependencies
    static var live: Dependencies {
        Dependencies(
            engine: DefaultAudioEngine(),
            peakComputer: WaveformPeakComputer()
        )
    }
}

