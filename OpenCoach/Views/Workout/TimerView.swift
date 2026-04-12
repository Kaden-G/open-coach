import SwiftUI

// WRK-002: Standalone timer view component for timed exercises

struct TimerView: View {
    @State private var timer = WorkoutTimer()
    let durationSeconds: Int
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text(timer.formattedTime)
                .font(.system(size: 64, weight: .black, design: .monospaced))
                .foregroundStyle(timer.isRunning ? .orange : .secondary)

            ProgressView(value: timer.progress)
                .tint(.orange)
                .padding(.horizontal, 40)

            HStack(spacing: 20) {
                if timer.isRunning {
                    Button("Pause") {
                        timer.pause()
                    }
                    .buttonStyle(.bordered)
                } else if timer.remainingSeconds > 0 {
                    Button("Resume") {
                        timer.resume()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                }
            }
        }
        .onAppear {
            timer.start(durationSeconds: durationSeconds)
        }
        .onChange(of: timer.isComplete) { _, isComplete in
            if isComplete {
                AudioCueManager.shared.playTimerComplete()
                onComplete()
            }
        }
    }
}
