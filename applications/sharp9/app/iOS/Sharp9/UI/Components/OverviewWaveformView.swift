import SwiftUI

/// Mini overview waveform strip showing the full track
struct OverviewWaveformView: View {
    let peaks: WaveformPeaks
    let state: AppState
    let onTap: (Double) -> Void
    
    // Design colors
    private let waveformColor = Color(hex: 0xC9CED6).opacity(0.5)
    private let playheadColor = Color(hex: 0xFF3B30)
    private let loopColor = Color(hex: 0x2F6DFF)
    private let markerColor = Color(hex: 0xA855F7)
    
    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            
            ZStack {
                // Waveform canvas
                Canvas { context, canvasSize in
                    drawWaveform(context: context, size: canvasSize)
                }
                
                // Selection overlay
                if let range = Selectors.selectionRange(state) {
                    selectionOverlay(range: range, size: size)
                }
                
                // Marker ticks
                ForEach(state.markers) { marker in
                    markerTick(timeSec: marker.timeSec, size: size)
                }
                
                // Playhead
                playheadTick(size: size)
            }
            .contentShape(Rectangle())
            .onTapGesture { location in
                let time = xToTime(x: location.x, width: size.width)
                onTap(time)
            }
        }
        .frame(height: 20)
        .background(Color(hex: 0x111317))
        .clipShape(.rect(cornerRadius: 4))
    }
    
    // MARK: - Drawing
    
    private func drawWaveform(context: GraphicsContext, size: CGSize) {
        guard peaks.buckets > 0 else { return }
        
        let midY = size.height / 2
        let bucketWidth = size.width / CGFloat(peaks.buckets)
        
        var path = Path()
        
        for (index, maxVal) in peaks.max.enumerated() {
            let x = CGFloat(index) * bucketWidth
            let height = CGFloat(abs(maxVal)) * midY * 0.8
            
            path.move(to: CGPoint(x: x, y: midY - height))
            path.addLine(to: CGPoint(x: x, y: midY + height))
        }
        
        context.stroke(path, with: .color(waveformColor), lineWidth: 1)
    }
    
    private func selectionOverlay(range: (a: Double, b: Double), size: CGSize) -> some View {
        let startX = timeToX(timeSec: range.a, width: size.width)
        let endX = timeToX(timeSec: range.b, width: size.width)
        
        return Rectangle()
            .fill(loopColor.opacity(0.4))
            .frame(width: max(0, endX - startX))
            .offset(x: startX - size.width / 2 + (endX - startX) / 2)
    }
    
    private func markerTick(timeSec: Double, size: CGSize) -> some View {
        let x = timeToX(timeSec: timeSec, width: size.width)
        
        return Rectangle()
            .fill(markerColor)
            .frame(width: 2, height: size.height)
            .offset(x: x - size.width / 2)
    }
    
    private func playheadTick(size: CGSize) -> some View {
        let x = timeToX(timeSec: state.transport.currentTimeSec, width: size.width)
        
        return Rectangle()
            .fill(playheadColor)
            .frame(width: 2, height: size.height)
            .offset(x: x - size.width / 2)
    }
    
    // MARK: - Coordinate Conversion
    
    private func timeToX(timeSec: Double, width: CGFloat) -> CGFloat {
        guard let track = state.track, track.durationSec > 0 else { return 0 }
        let progress = timeSec / track.durationSec
        return CGFloat(progress) * width
    }
    
    private func xToTime(x: CGFloat, width: CGFloat) -> Double {
        guard let track = state.track, width > 0 else { return 0 }
        let progress = Double(x / width).clamped(to: 0...1)
        return progress * track.durationSec
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

#Preview {
    OverviewWaveformView(
        peaks: .empty,
        state: AppState(track: TrackMeta(name: "Test", durationSec: 180)),
        onTap: { _ in }
    )
    .padding()
    .background(Color(hex: 0x0B0C0E))
}
