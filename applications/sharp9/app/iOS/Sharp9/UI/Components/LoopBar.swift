import SwiftUI

/// Loop + marker controls:
/// - Marker: adds marker at current playhead
/// - A/B: set loop start/end at playhead
/// - Loop: toggle loop on/off
struct LoopBar: View {
    let state: AppState
    let send: (Action) -> Void

    private let loopColor = Color(hex: 0x2F6DFF)

    var body: some View {
        HStack(spacing: 0) {
            markerButton()
            setAButton()
            loopButton()
            setBButton()
        }
        .background(Color(hex: 0x111317))
        .clipShape(.rect(cornerRadius: 12))
    }

    @ViewBuilder
    private func markerButton() -> some View {
        Button {
            send(.addMarker(timeSec: state.transport.currentTimeSec))
        } label: {
            Image(systemName: "mappin")
                .foregroundStyle(.white.opacity(0.6))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func setAButton() -> some View {
        let isSet = Selectors.hasLoopStart(state)

        Button {
            send(.tappedAButton)
        } label: {
            HStack(spacing: 4) {
                Text("A")
                    .font(.headline)
                    .bold()

                if isSet {
                    Circle()
                        .fill(loopColor)
                        .frame(width: 6, height: 6)
                }
            }
            .foregroundStyle(isSet ? loopColor : .white.opacity(0.6))
            .frame(maxWidth: .infinity)
            .frame(height: 44)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func loopButton() -> some View {
        let isEnabled = Selectors.isLoopEnabled(state)

        Button {
            send(.toggleLoopEnabled(!isEnabled))
        } label: {
            Image(systemName: "repeat")
                .foregroundStyle(isEnabled ? .white : .white.opacity(0.6))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(isEnabled ? loopColor : Color.clear)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func setBButton() -> some View {
        let isSet = Selectors.hasLoopEnd(state)

        Button {
            send(.tappedBButton)
        } label: {
            HStack(spacing: 4) {
                Text("B")
                    .font(.headline)
                    .bold()

                if isSet {
                    Circle()
                        .fill(loopColor)
                        .frame(width: 6, height: 6)
                }
            }
            .foregroundStyle(isSet ? loopColor : .white.opacity(0.6))
            .frame(maxWidth: .infinity)
            .frame(height: 44)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 16) {
        let state1 = AppState(loop: LoopPoints(enabled: false))
        LoopBar(state: state1, send: { _ in })

        let state2 = AppState(loop: LoopPoints(aSec: 10, enabled: false))
        LoopBar(state: state2, send: { _ in })

        let state3 = AppState(loop: LoopPoints(aSec: 10, bSec: 20, enabled: true))
        LoopBar(state: state3, send: { _ in })
    }
    .padding()
    .background(Color(hex: 0x0B0C0E))
}
