import SwiftUI

/// Mode selection bar with 4 segments: marker, A, loop, B
struct ModeBar: View {
    let currentMode: Mode
    let loopEnabled: Bool
    let onModeSelected: (Mode) -> Void
    let onLoopToggle: (Bool) -> Void
    
    private let loopColor = Color(hex: 0x2F6DFF)
    
    var body: some View {
        HStack(spacing: 0) {
            // Marker segment
            modeButton(
                mode: .marker,
                icon: "mappin",
                label: nil
            )
            
            // A segment
            modeButton(
                mode: .setA,
                icon: nil,
                label: "A"
            )
            
            // Loop segment (toggleable)
            loopButton()
            
            // B segment
            modeButton(
                mode: .setB,
                icon: nil,
                label: "B"
            )
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
    
    @ViewBuilder
    private func loopButton() -> some View {
        let isActive = currentMode == .loop
        
        Button {
            if isActive {
                // Toggle loop on/off when already in loop mode
                onLoopToggle(!loopEnabled)
            } else {
                onModeSelected(.loop)
            }
        } label: {
            Image(systemName: loopEnabled ? "repeat" : "repeat")
                .foregroundStyle(isActive ? .white : (loopEnabled ? loopColor : .white.opacity(0.6)))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(isActive ? loopColor : Color.clear)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack {
        ModeBar(
            currentMode: .loop,
            loopEnabled: true,
            onModeSelected: { _ in },
            onLoopToggle: { _ in }
        )
        
        ModeBar(
            currentMode: .setA,
            loopEnabled: false,
            onModeSelected: { _ in },
            onLoopToggle: { _ in }
        )
    }
    .padding()
    .background(Color(hex: 0x0B0C0E))
}

