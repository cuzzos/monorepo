import SwiftUI

struct StopwatchModal: View {
    @Binding var isPresented: Bool
    @State private var startTime: Date? = nil
    @State private var isRunning: Bool = false

    var body: some View {
        VStack(spacing: 24) {
            Text("Stopwatch")
                .font(.title)
                .padding(.top)

            TimelineView(.periodic(from: .now, by: 1)) { context in
                let elapsedSeconds = startTime.map { Calendar.current.dateComponents([.second], from: $0, to: context.date).second ?? 0 } ?? 0
                Text(String(format: "%d:%02d", elapsedSeconds / 60, elapsedSeconds % 60))
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
            }

            HStack(spacing: 32) {
                Button(action: start) {
                    Image(systemName: isRunning ? "pause.fill" : "play.fill")
                        .font(.largeTitle)
                        .foregroundColor(isRunning ? .orange : .green)
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
    }

    private func start() {
        if !isRunning {
            startTime = Date()
            isRunning = true
        }
    }

    private func stop() {
        if isRunning {
            isRunning = false
            startTime = nil
        }
    }

    private func reset() {
        isRunning = false
        startTime = nil
    }
}
