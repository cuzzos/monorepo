import SwiftUI
import Dependencies

struct RestTimerModal: View {
    @Binding var isPresented: Bool
    var onComplete: (() -> Void)? = nil

    @State private var endDate: Date = .now
    @State private var timeRemaining: Int = 0
    @Dependency(\.date) var date

    init(isPresented: Binding<Bool>, duration: Int, onComplete: (() -> Void)? = nil) {
        self._isPresented = isPresented
        self.onComplete = onComplete
        self.endDate = date.now + TimeInterval(duration)
        self.timeRemaining = duration
    }

    var body: some View {
        VStack(spacing: 24) {
            Text("Rest Timer")
                .font(.title)
                .padding(.top)

            TimelineView(.periodic(from: Date(), by: 1.0)) { context in
                let currentDate = context.date
                let remainingTime = endDate.timeIntervalSince(currentDate)
                let minutes = Int(remainingTime) / 60
                let seconds = Int(remainingTime) % 60

                Text(String(format: "%02d:%02d", minutes, seconds))
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .onChange(of: context.date) { _, _ in
                        if timeRemaining > 0 {
                            timeRemaining -= 1
                        } else {
                            onComplete?()
                        }
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
}
