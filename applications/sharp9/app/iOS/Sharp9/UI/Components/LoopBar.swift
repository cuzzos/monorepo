import SwiftUI

enum LoopTool: Sendable, Equatable {
    case marker
    case loop
    case setA
    case setB
}

/// Loop + marker controls:
/// - Marker: selectable tool
/// - A/B: momentary actions to set loop start/end at playhead
/// - Loop: toggle loop on/off
struct LoopBar: View {
    let selectedTool: LoopTool

    let isLoopEnabled: Bool
    let hasLoopStart: Bool
    let hasLoopEnd: Bool

    let onToolSelected: (LoopTool) -> Void
    let onSetLoopEnabled: (Bool) -> Void
    let onSetLoopStart: () -> Void
    let onSetLoopEnd: () -> Void

    private let loopColor = Color(hex: 0x2F6DFF)

    var body: some View {
        HStack(spacing: 0) {
            toolButton(tool: .marker, icon: "mappin")

            setPointButton(label: "A", isSet: hasLoopStart) {
                onSetLoopStart()
            }

            setLoopEnabledButton()

            setPointButton(label: "B", isSet: hasLoopEnd) {
                onSetLoopEnd()
            }
        }
        .background(Color(hex: 0x111317))
        .clipShape(.rect(cornerRadius: 12))
    }

    @ViewBuilder
    private func toolButton(tool: LoopTool, icon: String) -> some View {
        let isSelected = selectedTool == tool

        Button {
            onToolSelected(tool)
        } label: {
            Image(systemName: icon)
                .foregroundStyle(isSelected ? .white : .white.opacity(0.6))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(isSelected ? loopColor : Color.clear)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func setPointButton(label: String, isSet: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(label)
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
    private func setLoopEnabledButton() -> some View {
        Button {
            onSetLoopEnabled(!isLoopEnabled)
        } label: {
            Image(systemName: "repeat")
                .foregroundStyle(isLoopEnabled ? .white : .white.opacity(0.6))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(isLoopEnabled ? loopColor : Color.clear)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 16) {
        LoopBar(
            selectedTool: .loop,
            isLoopEnabled: false,
            hasLoopStart: false,
            hasLoopEnd: false,
            onToolSelected: { _ in },
            onSetLoopEnabled: { _ in },
            onSetLoopStart: {},
            onSetLoopEnd: {}
        )

        LoopBar(
            selectedTool: .loop,
            isLoopEnabled: false,
            hasLoopStart: true,
            hasLoopEnd: false,
            onToolSelected: { _ in },
            onSetLoopEnabled: { _ in },
            onSetLoopStart: {},
            onSetLoopEnd: {}
        )

        LoopBar(
            selectedTool: .loop,
            isLoopEnabled: true,
            hasLoopStart: true,
            hasLoopEnd: true,
            onToolSelected: { _ in },
            onSetLoopEnabled: { _ in },
            onSetLoopStart: {},
            onSetLoopEnd: {}
        )
    }
    .padding()
    .background(Color(hex: 0x0B0C0E))
}
