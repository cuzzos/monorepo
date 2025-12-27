import SwiftUI

/// Toast overlay for displaying temporary messages
struct ToastOverlay: View {
    let toast: ToastState?
    
    var body: some View {
        if let toast = toast {
            Text(toast.message)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.black.opacity(0.8))
                .clipShape(.rect(cornerRadius: 8))
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
                .animation(.easeOut(duration: 0.2), value: toast.message)
        }
    }
}

#Preview {
    VStack {
        ToastOverlay(toast: ToastState(message: "Speed 1.25"))
        ToastOverlay(toast: ToastState(message: "Pitch -2.00"))
        ToastOverlay(toast: ToastState(message: "Set A and B"))
        ToastOverlay(toast: nil)
    }
    .padding()
    .background(Color(hex: 0x0B0C0E))
}

