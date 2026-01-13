import Foundation

/// Formatting utilities for display values
enum Formatting {
    /// Formats time as "MM:SS.xx" (e.g., "03:45.12")
    static func formatTime(_ seconds: Double) -> String {
        let totalSeconds = max(0, seconds)
        var minutes = Int(totalSeconds) / 60
        let secs = totalSeconds.truncatingRemainder(dividingBy: 60)

        // Manually format seconds with rounding to 2 decimal places
        var roundedSecs = (secs * 100).rounded() / 100
        if roundedSecs >= 60 {
            minutes += 1
            roundedSecs = 0
        }

        let minutesPart = minutes.formatted(.number.precision(.integerLength(2)))
        let integerSeconds = Int(roundedSecs)
        let fractionalSeconds = Int((roundedSecs - Double(integerSeconds)) * 100)
        let secondsPart = String(format: "%02d.%02d", integerSeconds, fractionalSeconds)

        return "\(minutesPart):\(secondsPart)"
    }
    
    /// Formats speed as "1.00 x"
    static func formatSpeed(_ speed: Double) -> String {
        let formatted = speed.formatted(.number.precision(.fractionLength(2)))
        return "\(formatted) x"
    }

    /// Formats pitch as "0.00 st" or "+0.00 st" for positive values
    static func formatPitch(_ semitones: Double) -> String {
        let formatted = semitones.formatted(.number.precision(.fractionLength(2)))
        return "\(formatted) st"
    }
    
    /// Toast message for speed change
    static func speedToastMessage(_ speed: Double) -> String {
        let formatted = speed.formatted(.number.precision(.fractionLength(2)))
        return "Speed \(formatted)"
    }

    /// Toast message for pitch change
    static func pitchToastMessage(_ semitones: Double) -> String {
        let formatted = semitones.formatted(.number.precision(.fractionLength(2)))
        return "Pitch \(formatted)"
    }
}
