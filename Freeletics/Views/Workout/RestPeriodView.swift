import SwiftUI

struct RestPeriodView: View {
    let timer: WorkoutTimer
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Text("Rest")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text(timer.formattedTime)
                .font(.system(size: 80, weight: .black, design: .monospaced))
                .foregroundStyle(.orange)

            // Circular progress
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: timer.progress)
                    .stroke(.orange, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.1), value: timer.progress)
            }
            .frame(width: 120, height: 120)

            Spacer()

            Button("Skip Rest") {
                timer.stop()
                onComplete()
            }
            .foregroundStyle(.secondary)
            .padding(.bottom, 32)
        }
        .onChange(of: timer.isComplete) { _, isComplete in
            if isComplete {
                AudioCueManager.shared.playTimerComplete()
                onComplete()
            }
        }
    }
}
