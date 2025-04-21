import SwiftUI

struct StopwatchModal: View {
    @Binding var isPresented: Bool
    @State private var elapsedTime: Int = 0
    @State private var timer: Timer? = nil

    var body: some View {
        VStack(spacing: 24) {
            Text("Stopwatch")
                .font(.title)
                .padding(.top)
            Text(String(format: "%d:%02d", elapsedTime / 60, elapsedTime % 60))
                .font(.system(size: 48, weight: .bold, design: .monospaced))
            HStack(spacing: 32) {
                Button(action: start) {
                    Image(systemName: "play.fill")
                        .font(.largeTitle)
                        .foregroundColor(.green)
                }
                Button(action: stop) {
                    Image(systemName: "stop.fill")
                        .font(.largeTitle)
                        .foregroundColor(.red)
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
            }
            .padding()
        }
        .padding()
        .onAppear(perform: start)
        .onDisappear(perform: stop)
    }

    private func start() {
        if timer == nil {
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                elapsedTime += 1
            }
        }
    }

    private func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func reset() {
        elapsedTime = 0
    }
}
