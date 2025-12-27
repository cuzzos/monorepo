import Foundation

/// Playback transport state
struct Transport: Sendable, Equatable {
    var isPlaying: Bool
    var currentTimeSec: Double
    var speed: Double
    var pitchSemitones: Double
    
    init(
        isPlaying: Bool = false,
        currentTimeSec: Double = 0,
        speed: Double = 1.0,
        pitchSemitones: Double = 0
    ) {
        self.isPlaying = isPlaying
        self.currentTimeSec = currentTimeSec
        self.speed = speed
        self.pitchSemitones = pitchSemitones
    }
    
    static let minSpeed: Double = 0.25
    static let maxSpeed: Double = 2.0
    static let minPitch: Double = -12.0
    static let maxPitch: Double = 12.0
}

