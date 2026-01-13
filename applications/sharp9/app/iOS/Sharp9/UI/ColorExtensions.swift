import SwiftUI

extension Color {
    /// Initialize a Color from a hex value
    /// - Parameter hex: A hex color value (e.g., 0xFF3B30)
    init(hex: UInt32) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        
        self.init(red: red, green: green, blue: blue)
    }
}

/// Design system colors for Sharp9
enum DesignColors {
    static let bg = Color(hex: 0x0B0C0E)
    static let panel = Color(hex: 0x111317)
    static let waveformFill = Color(hex: 0xC9CED6)
    static let gridLine = Color(hex: 0x2A2E36)
    static let playheadRed = Color(hex: 0xFF3B30)
    static let loopBlue = Color(hex: 0x2F6DFF)
    static let loopBlueFill = Color(hex: 0x2F6DFF).opacity(0.30)
    static let markerPurple = Color(hex: 0xA855F7)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.70)
    static let textTertiary = Color.white.opacity(0.45)
}

