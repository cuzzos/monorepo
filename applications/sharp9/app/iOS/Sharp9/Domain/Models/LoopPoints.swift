import Foundation

/// A/B loop points for looping playback
struct LoopPoints: Sendable, Equatable {
    var aSec: Double?
    var bSec: Double?
    var enabled: Bool
    
    init(aSec: Double? = nil, bSec: Double? = nil, enabled: Bool = false) {
        self.aSec = aSec
        self.bSec = bSec
        self.enabled = enabled
    }
    
    /// Returns normalized (a, b) tuple where a < b, or nil if incomplete
    var normalizedRange: (a: Double, b: Double)? {
        guard let a = aSec, let b = bSec else { return nil }
        return a <= b ? (a, b) : (b, a)
    }
    
    /// Effective A position (returns 0 if not manually set)
    func effectiveA(trackDuration: Double) -> Double {
        aSec ?? 0
    }
    
    /// Effective B position (returns track duration if not manually set)
    func effectiveB(trackDuration: Double) -> Double {
        bSec ?? trackDuration
    }
    
    /// Whether the user has manually set A
    var hasManualA: Bool { aSec != nil }
    
    /// Whether the user has manually set B
    var hasManualB: Bool { bSec != nil }
}

