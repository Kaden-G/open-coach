import Foundation
import Combine

// WRK-002: Timer Accuracy During Interruptions
// Uses Date-based elapsed time calculation, not cumulative Timer intervals.
// Survives app backgrounding and screen lock.

@Observable
final class WorkoutTimer {
    private(set) var remainingSeconds: Double = 0
    private(set) var isRunning = false
    private(set) var isComplete = false

    private var targetEndDate: Date?
    private var totalDuration: TimeInterval = 0
    private var timer: Timer?

    var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return 1.0 - (remainingSeconds / totalDuration)
    }

    var formattedTime: String {
        let total = Int(ceil(remainingSeconds))
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    func start(durationSeconds: Int) {
        totalDuration = TimeInterval(durationSeconds)
        remainingSeconds = totalDuration
        targetEndDate = Date().addingTimeInterval(totalDuration)
        isRunning = true
        isComplete = false
        startDisplayTimer()
    }

    func pause() {
        guard isRunning else { return }
        isRunning = false
        timer?.invalidate()
        timer = nil
        // Store remaining time
        if let end = targetEndDate {
            remainingSeconds = max(0, end.timeIntervalSinceNow)
        }
        targetEndDate = nil
    }

    func resume() {
        guard !isRunning, remainingSeconds > 0 else { return }
        targetEndDate = Date().addingTimeInterval(remainingSeconds)
        isRunning = true
        startDisplayTimer()
    }

    func stop() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        targetEndDate = nil
        remainingSeconds = 0
    }

    private func startDisplayTimer() {
        timer?.invalidate()
        // Update display at 10Hz for smooth countdown
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.tick()
        }
        // Ensure timer runs even during scroll
        if let timer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }

    private func tick() {
        guard let end = targetEndDate else { return }
        let remaining = end.timeIntervalSinceNow
        if remaining <= 0 {
            remainingSeconds = 0
            isRunning = false
            isComplete = true
            timer?.invalidate()
            timer = nil
            targetEndDate = nil
        } else {
            remainingSeconds = remaining
        }
    }

    deinit {
        timer?.invalidate()
    }
}
