import SwiftUI

/// Mode selection bar with 4 segments: marker, A, loop, B
/// A and B are momentary buttons that set loop points at current playhead position
struct ModeBar: View {
    let currentMode: Mode
    let loopEnabled: Bool
    let hasManualA: Bool
    let hasManualB: Bool
    let onModeSelected: (Mode) -> Void
    let onLoopToggle: (Bool) -> Void
    let onATapped: () -> Void
    let onBTapped: () -> Void
    
    private let loopColor = Color(hex: 0x2F6DFF)
    
    var body: some View {
        HStack(spacing: 0) {
            // Marker segment (selectable mode)
            modeButton(
                mode: .marker,
                icon: "mappin",
                label: nil
            )
            
            // A segment (momentary action button)
            setPointButton(label: "A", isSet: hasManualA) {
                onATapped()
            }
            
            // Loop segment (toggleable)
            loopButton()
            
            // B segment (momentary action button)
            setPointButton(label: "B", isSet: hasManualB) {
                onBTapped()
            }
        }
        .background(Color(hex: 0x111317))
        .clipShape(.rect(cornerRadius: 12))
    }
    
    @ViewBuilder
    private func modeButton(mode: Mode, icon: String?, label: String?) -> some View {
        let isSelected = currentMode == mode
        
        Button {
            onModeSelected(mode)
        } label: {
            Group {
                if let icon = icon {
                    Image(systemName: icon)
                } else if let label = label {
                    Text(label)
                        .font(.headline)
                        .bold()
                }
            }
            .foregroundStyle(isSelected ? .white : .white.opacity(0.6))
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(isSelected ? loopColor : Color.clear)
        }
        .buttonStyle(.plain)
    }
    
    /// Momentary button for setting A or B loop points
    @ViewBuilder
    private func setPointButton(label: String, isSet: Bool, action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            HStack(spacing: 4) {
                Text(label)
                    .font(.headline)
                    .bold()
                
                // Visual indicator when point is manually set
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
        Button {
            // Always toggle loop on/off
            onLoopToggle(!loopEnabled)
        } label: {
            Image(systemName: "repeat")
                .foregroundStyle(loopEnabled ? .white : .white.opacity(0.6))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(loopEnabled ? loopColor : Color.clear)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 16) {
        // No points set
        ModeBar(
            currentMode: .loop,
            loopEnabled: false,
            hasManualA: false,
            hasManualB: false,
            onModeSelected: { _ in },
            onLoopToggle: { _ in },
            onATapped: {},
            onBTapped: {}
        )
        
        // A is set
        ModeBar(
            currentMode: .loop,
            loopEnabled: false,
            hasManualA: true,
            hasManualB: false,
            onModeSelected: { _ in },
            onLoopToggle: { _ in },
            onATapped: {},
            onBTapped: {}
        )
        
        // Both set, loop enabled
        ModeBar(
            currentMode: .loop,
            loopEnabled: true,
            hasManualA: true,
            hasManualB: true,
            onModeSelected: { _ in },
            onLoopToggle: { _ in },
            onATapped: {},
            onBTapped: {}
        )
    }
    .padding()
    .background(Color(hex: 0x0B0C0E))
}
