import Foundation

/// A user-placed marker at a specific time in the track
struct Marker: Sendable, Equatable, Identifiable {
    let id: UUID
    let timeSec: Double
    
    init(id: UUID = UUID(), timeSec: Double) {
        self.id = id
        self.timeSec = timeSec
    }
}

