import Foundation

/// A temporary toast message to display
struct ToastState: Sendable, Equatable {
    let message: String
    let expiresAt: Date
    
    init(message: String, expiresAt: Date) {
        self.message = message
        self.expiresAt = expiresAt
    }
    
    init(message: String, duration: TimeInterval = 1.5, now: Date = Date()) {
        self.message = message
        self.expiresAt = now.addingTimeInterval(duration)
    }
}

