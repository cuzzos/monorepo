import SwiftUI

struct RestTimerModal: View {
    @Binding var isPresented: Bool
    var duration: Int // in seconds
    var onComplete: (() -> Void)? = nil

    @State private var remaining: Int
    @State private var timer: Timer? = nil

    init(isPresented: Binding<Bool>, duration: Int, onComplete: (() -> Void)? = nil) {
        self._isPresented = isPresented
        self.duration = duration
        self.onComplete = onComplete
        self._remaining = State(initialValue: duration)
    }

    var body: some View {
        VStack(spacing: 24) {
            Text("Rest Timer")
                .font(.title)
                .padding(.top)
            Text(String(format: "%d:%02d", remaining / 60, remaining % 60))
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundColor(remaining == 0 ? .green : .primary)
            HStack(spacing: 32) {
                Button(action: start) {
                    Image(systemName: "play.fill")
                        .font(.largeTitle)
                        .foregroundColor(.green)
                }
                Button(action: pause) {
                    Image(systemName: "pause.fill")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                }
                Button(action: reset) {
                    Image(systemName: "gobackward")
                        .font(.largeTitle)
                        .foregroundColor(.blue)
                }
            }
            Spacer()
            Button("Close") {
                isPresented = false
                stop()
            }
            .padding()
        }
        .padding()
        .onAppear(perform: start)
        .onDisappear(perform: stop)
        .onChange(of: remaining) { newValue in
            if newValue == 0 {
                stop()
                onComplete?()
            }
        }
    }

    private func start() {
        if timer == nil && remaining > 0 {
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                if remaining > 0 {
                    remaining -= 1
                }
            }
        }
    }

    private func pause() {
        stop()
    }

    private func reset() {
        stop()
        remaining = duration
    }

    private func stop() {
        timer?.invalidate()
        timer = nil
    }
}
