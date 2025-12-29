import SwiftUI

/// Track row showing add button, track name, and action icons
struct TrackRow: View {
    let trackName: String?
    let onImportTapped: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(trackName ?? "Import File", systemImage: "plus") {
                onImportTapped()
            }
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundStyle(.white)
            .buttonStyle(.plain)

            Spacer()
            
            // Right side icons (placeholder for v1)
            HStack(spacing: 16) {
                Button("Export", systemImage: "square.and.arrow.down") {}
                    .labelStyle(.iconOnly)
                    .foregroundStyle(.white.opacity(0.7))
                
                Button("Settings", systemImage: "slider.horizontal.3") {}
                    .labelStyle(.iconOnly)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .font(.title3)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    VStack {
        TrackRow(trackName: nil, onImportTapped: {})
        TrackRow(trackName: "Stevie Wonder Superstition (Extended Mix)", onImportTapped: {})
    }
    .background(Color(hex: 0x0B0C0E))
}

