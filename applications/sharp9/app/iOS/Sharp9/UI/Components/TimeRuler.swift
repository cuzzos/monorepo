import SwiftUI

/// Time ruler showing fixed 1-second tick marks
struct TimeRuler: View {
    let pixelsPerSecond: CGFloat
    let trackDurationSec: Double
    let scrollOffset: CGFloat
    let viewportWidth: CGFloat
    
    private let majorTickColor = Color.white.opacity(0.6)
    private let minorTickColor = Color.white.opacity(0.3)
    private let labelColor = Color.white.opacity(0.8)
    
    var body: some View {
        Canvas { context, size in
            drawRuler(context: context, size: size)
        }
        .frame(height: 24)
    }
    
    private func drawRuler(context: GraphicsContext, size: CGSize) {
        guard trackDurationSec > 0 else { return }
        
        // Calculate visible time range
        let startTime = max(0, -scrollOffset / pixelsPerSecond)
        let endTime = min(trackDurationSec, startTime + (viewportWidth / pixelsPerSecond))
        
        let firstTick = ceil(startTime)
        let lastTick = floor(endTime)
        
        // Draw major ticks (every 1 second)
        for tickTime in stride(from: firstTick, through: lastTick, by: 1.0) {
            let canvasX = tickTime * pixelsPerSecond
            let screenX = canvasX + scrollOffset
            
            // Skip if outside viewport
            guard screenX >= 0 && screenX <= viewportWidth else { continue }
            
            // Major tick line (longer)
            var tickPath = Path()
            tickPath.move(to: CGPoint(x: screenX, y: size.height - 10))
            tickPath.addLine(to: CGPoint(x: screenX, y: size.height))
            context.stroke(tickPath, with: .color(majorTickColor), lineWidth: 1)
            
            // Label every 5 seconds
            if Int(tickTime) % 5 == 0 {
                let label = formatTime(tickTime)
                let text = Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .monospacedDigit()
                    .foregroundStyle(labelColor)
                
                context.draw(text, at: CGPoint(x: screenX, y: 6), anchor: .center)
            }
        }
        
        // Draw minor ticks (every 0.2s) if zoomed in enough
        if pixelsPerSecond >= 30 {
            let minorTickInterval = 0.2
            let firstMinor = ceil(startTime / minorTickInterval) * minorTickInterval
            
            for tickTime in stride(from: firstMinor, through: endTime, by: minorTickInterval) {
                // Skip major ticks
                if tickTime.truncatingRemainder(dividingBy: 1.0) < 0.01 { continue }
                
                let canvasX = tickTime * pixelsPerSecond
                let screenX = canvasX + scrollOffset
                
                guard screenX >= 0 && screenX <= viewportWidth else { continue }
                
                // Minor tick line (shorter)
                var minorPath = Path()
                minorPath.move(to: CGPoint(x: screenX, y: size.height - 5))
                minorPath.addLine(to: CGPoint(x: screenX, y: size.height))
                context.stroke(minorPath, with: .color(minorTickColor), lineWidth: 0.5)
            }
        }
    }
    
    private func formatTime(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

#Preview {
    TimeRuler(
        pixelsPerSecond: 40,
        trackDurationSec: 76.13,
        scrollOffset: -1000,
        viewportWidth: 400
    )
    .background(Color(hex: 0x0B0C0E))
}

