import SwiftUI

/// Transport control bar with speed, play/pause, and pitch controls
struct TransportBar: View {
    let state: AppState
    let onSpeedDelta: (Double) -> Void
    let onPitchDelta: (Double) -> Void
    let onTogglePlay: () -> Void
    let onSeekPrev: () -> Void
    let onSeekNext: () -> Void
    
    var body: some View {
        HStack {
            // Speed controls
            speedControls()
            
            Spacer()
            
            // Transport controls
            transportControls()
            
            Spacer()
            
            // Pitch controls
            pitchControls()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(hex: 0x111317))
        .clipShape(.rect(cornerRadius: 16))
    }
    
    @ViewBuilder
    private func speedControls() -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 12) {
                Button("Decrease Speed", systemImage: "minus") {
                    onSpeedDelta(-0.05)
                }
                .labelStyle(.iconOnly)
                .foregroundStyle(.white.opacity(0.7))
                
                Text(Formatting.formatSpeed(state.transport.speed))
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .frame(minWidth: 50)
                
                Button("Increase Speed", systemImage: "plus") {
                    onSpeedDelta(0.05)
                }
                .labelStyle(.iconOnly)
                .foregroundStyle(.white.opacity(0.7))
            }
            
            Text("SPEED")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.5))
        }
    }
    
    @ViewBuilder
    private func transportControls() -> some View {
        HStack(spacing: 24) {
            // Previous (seek to A or start)
            Button("Previous", systemImage: "backward.end.fill") {
                onSeekPrev()
            }
            .labelStyle(.iconOnly)
            .font(.title2)
            .foregroundStyle(.white.opacity(0.7))
            
            // Play/Pause
            Button(
                state.transport.isPlaying ? "Pause" : "Play",
                systemImage: state.transport.isPlaying ? "pause.fill" : "play.fill"
            ) {
                onTogglePlay()
            }
            .labelStyle(.iconOnly)
            .font(.largeTitle)
            .foregroundStyle(.white)
            
            // Next (seek to B or end)
            Button("Next", systemImage: "forward.end.fill") {
                onSeekNext()
            }
            .labelStyle(.iconOnly)
            .font(.title2)
            .foregroundStyle(.white.opacity(0.7))
        }
    }
    
    @ViewBuilder
    private func pitchControls() -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 12) {
                Button("Decrease Pitch", systemImage: "chevron.down") {
                    onPitchDelta(-1.0)
                }
                .labelStyle(.iconOnly)
                .foregroundStyle(.white.opacity(0.7))
                
                Text(Formatting.formatPitch(state.transport.pitchSemitones))
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .frame(minWidth: 55)
                
                Button("Increase Pitch", systemImage: "chevron.up") {
                    onPitchDelta(1.0)
                }
                .labelStyle(.iconOnly)
                .foregroundStyle(.white.opacity(0.7))
            }
            
            Text("PITCH")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.5))
        }
    }
}

#Preview {
    TransportBar(
        state: AppState(),
        onSpeedDelta: { _ in },
        onPitchDelta: { _ in },
        onTogglePlay: {},
        onSeekPrev: {},
        onSeekNext: {}
    )
    .padding()
    .background(Color(hex: 0x0B0C0E))
}

