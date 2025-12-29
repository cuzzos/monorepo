import SwiftUI

/// Main waveform visualization with selection, playhead, and markers
struct WaveformView: View {
    let peaks: WaveformPeaks
    let state: AppState
    let onTap: (Double) -> Void
    let onDrag: (Double) -> Void
    let onDragEnded: (Double) -> Void
    
    // FIXED ZOOM LEVEL: 1 second = 40 pixels (tune this for desired zoom)
    // Recommended: 40 px/s = fine editing, 30 px/s = moderate, 25 px/s = comfortable
    private let pixelsPerSecond: CGFloat = 40
    
    // Track drag start time for delta-based dragging
    // NOTE: Using @State instead of @GestureState because @GestureState resets to nil
    // BEFORE .onEnded is called, which would prevent onDragEnded from being called.
    @State private var dragStartTime: Double?
    
    // Design colors
    private let waveformColor = Color(hex: 0xC9CED6)
    private let playheadColor = Color(hex: 0xFF3B30)
    private let loopColor = Color(hex: 0x2F6DFF)
    private let markerColor = Color(hex: 0xA855F7)
    
    var body: some View {
        GeometryReader { geometry in
            let viewportWidth = geometry.size.width
            let viewportHeight = geometry.size.height
            let trackDuration = state.track?.durationSec ?? 0
            let currentTime = state.transport.currentTimeSec
            
            // Calculate canvas width and scroll offset
            let canvasWidth = trackDuration * pixelsPerSecond
            let scrollOffset = calculateScrollOffset(
                currentTime: currentTime,
                viewportWidth: viewportWidth
            )
            
            ZStack {
                // Waveform canvas layer (scrollable, wide canvas)
                Canvas { context, _ in
                    // Translate context so canvas x=0 is at scroll position
                    context.translateBy(x: scrollOffset, y: 0)
                    
                    // Draw waveform
                    drawWaveform(
                        context: context,
                        canvasWidth: canvasWidth,
                        height: viewportHeight
                    )
                    
                    // Draw selection overlay (only show when loop is enabled)
                    if Selectors.shouldShowLoopOverlay(state), let range = Selectors.selectionRange(state) {
                        drawSelectionOverlay(
                            context: context,
                            range: range,
                            height: viewportHeight
                        )
                    }
                    
                    // Draw markers
                    for marker in state.markers {
                        drawMarker(
                            context: context,
                            timeSec: marker.timeSec,
                            height: viewportHeight
                        )
                    }
                    
                    // Draw A/B loop point markers
                    let effectiveA = state.loop.effectiveA(trackDuration: trackDuration)
                    let effectiveB = state.loop.effectiveB(trackDuration: trackDuration)
                    drawLoopPointMarker(
                        context: context,
                        timeSec: effectiveA,
                        label: "A",
                        height: viewportHeight
                    )
                    drawLoopPointMarker(
                        context: context,
                        timeSec: effectiveB,
                        label: "B",
                        height: viewportHeight
                    )
                }
                .frame(width: viewportWidth, height: viewportHeight)
                
                // Fixed playhead at center (above waveform layer)
                playheadLine(height: viewportHeight)
                
                // Time ruler at top
                VStack(spacing: 0) {
                    TimeRuler(
                        pixelsPerSecond: pixelsPerSecond,
                        trackDurationSec: trackDuration,
                        scrollOffset: scrollOffset,
                        viewportWidth: viewportWidth
                    )
                    Spacer()
                }
                
                // Time display
                VStack {
                    Text(Formatting.formatTime(currentTime))
                        .font(.caption)
                        .monospacedDigit()
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.6))
                        .clipShape(.rect(cornerRadius: 4))
                    
                    Spacer()
                }
                .padding(.top, 32)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        // Capture start time on first drag event
                        if dragStartTime == nil {
                            dragStartTime = currentTime
                        }
                        
                        guard let startTime = dragStartTime else { return }
                        
                        // Delta-based: translation drives time change
                        let deltaTime = -value.translation.width / pixelsPerSecond
                        let newTime = (startTime + deltaTime).clamped(to: 0...trackDuration)
                        
                        onDrag(newTime)
                    }
                    .onEnded { value in
                        guard let startTime = dragStartTime else { return }
                        
                        // Calculate final time and commit
                        let deltaTime = -value.translation.width / pixelsPerSecond
                        let finalTime = (startTime + deltaTime).clamped(to: 0...trackDuration)
                        
                        // Reset drag state for next gesture
                        dragStartTime = nil
                        
                        onDragEnded(finalTime)
                    }
            )
            .onTapGesture { location in
                let time = screenXToTime(
                    x: location.x,
                    scrollOffset: scrollOffset,
                    trackDuration: trackDuration
                )
                onTap(time)
            }
        }
        .background(Color(hex: 0x0B0C0E))
    }
    
    // MARK: - Drawing
    
    private func drawWaveform(context: GraphicsContext, canvasWidth: CGFloat, height: CGFloat) {
        guard peaks.buckets > 0 else { return }
        
        let midY = height / 2
        let bucketWidth = canvasWidth / CGFloat(peaks.buckets)
        
        var path = Path()
        
        // Draw top half (max values)
        for (index, maxVal) in peaks.max.enumerated() {
            let x = CGFloat(index) * bucketWidth
            let amp = CGFloat(maxVal) * midY * 0.9
            let y = midY - amp
            
            if index == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        // Draw bottom half (min values, reversed)
        for (index, minVal) in peaks.min.enumerated().reversed() {
            let x = CGFloat(index) * bucketWidth
            let amp = CGFloat(abs(minVal)) * midY * 0.9
            let y = midY + amp
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.closeSubpath()
        
        context.fill(path, with: .color(waveformColor))
    }
    
    private func drawSelectionOverlay(context: GraphicsContext, range: (a: Double, b: Double), height: CGFloat) {
        let startX = timeToCanvasX(timeSec: range.a)
        let endX = timeToCanvasX(timeSec: range.b)
        let width = max(0, endX - startX)
        
        let rect = CGRect(x: startX, y: 0, width: width, height: height)
        context.fill(Path(rect), with: .color(loopColor.opacity(0.3)))
    }
    
    private func drawMarker(context: GraphicsContext, timeSec: Double, height: CGFloat) {
        let x = timeToCanvasX(timeSec: timeSec)
        
        // Draw marker circle at top
        let circlePath = Path(ellipseIn: CGRect(x: x - 4, y: 0, width: 8, height: 8))
        context.fill(circlePath, with: .color(markerColor))
        
        // Draw marker line
        var linePath = Path()
        linePath.move(to: CGPoint(x: x, y: 8))
        linePath.addLine(to: CGPoint(x: x, y: height))
        context.stroke(linePath, with: .color(markerColor), lineWidth: 2)
    }
    
    private func drawLoopPointMarker(context: GraphicsContext, timeSec: Double, label: String, height: CGFloat) {
        let x = timeToCanvasX(timeSec: timeSec)
        let squareSize: CGFloat = 16
        
        // Draw vertical line (same height as playhead)
        var linePath = Path()
        linePath.move(to: CGPoint(x: x, y: squareSize))
        linePath.addLine(to: CGPoint(x: x, y: height))
        context.stroke(linePath, with: .color(loopColor), lineWidth: 2)
        
        // Draw square at top (aligned right with the line)
        let squareRect = CGRect(x: x - squareSize, y: 0, width: squareSize, height: squareSize)
        context.fill(Path(squareRect), with: .color(loopColor))
        
        // Draw label text inside the square
        let text = Text(label)
            .font(.caption2)
            .bold()
            .foregroundColor(.white)
        context.draw(
            context.resolve(text),
            at: CGPoint(x: x - squareSize / 2, y: squareSize / 2),
            anchor: .center
        )
    }
    
    private func playheadLine(height: CGFloat) -> some View {
        // Playhead is always fixed at the center (x=0 in the ZStack)
        return Rectangle()
            .fill(playheadColor)
            .frame(width: 2, height: height)
    }
    
    // MARK: - Coordinate Conversion (Fixed-Scale System)
    
    /// Calculate scroll offset to keep current time centered under playhead
    /// Formula: offset = -(currentTime * pixelsPerSecond) + (viewportWidth / 2)
    private func calculateScrollOffset(currentTime: Double, viewportWidth: CGFloat) -> CGFloat {
        let timePosition = currentTime * pixelsPerSecond
        return -timePosition + (viewportWidth / 2)
    }
    
    /// Convert time to absolute x-position on the canvas
    /// Canvas uses fixed scale: 1 second = pixelsPerSecond pixels
    private func timeToCanvasX(timeSec: Double) -> CGFloat {
        return timeSec * pixelsPerSecond
    }
    
    /// Convert screen x-position to time (for tap gestures)
    private func screenXToTime(x: CGFloat, scrollOffset: CGFloat, trackDuration: Double) -> Double {
        // x is in screen coordinates, subtract offset to get canvas coordinate
        let canvasX = x - scrollOffset
        let time = canvasX / pixelsPerSecond
        return time.clamped(to: 0...trackDuration)
    }
}

// MARK: - Clamped Extension

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

#Preview {
    WaveformView(
        peaks: .empty,
        state: AppState(track: TrackMeta(name: "Test", durationSec: 180)),
        onTap: { _ in },
        onDrag: { _ in },
        onDragEnded: { _ in }
    )
}
