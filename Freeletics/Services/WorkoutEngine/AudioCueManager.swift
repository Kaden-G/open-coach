import AVFoundation

// WRK-002: Audio cue fires on timer completion even when screen is off.
// Uses AVAudioSession with background audio mode.

final class AudioCueManager {
    static let shared = AudioCueManager()

    private var audioSession: AVAudioSession { AVAudioSession.sharedInstance() }
    private var player: AVAudioPlayer?

    private init() {}

    func configureForWorkout() {
        do {
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try audioSession.setActive(true)
        } catch {
            print("AudioCueManager: Failed to configure audio session: \(error)")
        }
    }

    func playTimerComplete() {
        playSystemSound(.timerComplete)
    }

    func playSetComplete() {
        playSystemSound(.setComplete)
    }

    func playWorkoutComplete() {
        playSystemSound(.workoutComplete)
    }

    func deactivate() {
        player?.stop()
        try? audioSession.setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func playSystemSound(_ sound: SoundType) {
        // Use system sound IDs for reliability without bundled audio files
        AudioServicesPlaySystemSound(sound.systemSoundID)
    }
}

private enum SoundType {
    case timerComplete
    case setComplete
    case workoutComplete

    var systemSoundID: SystemSoundID {
        switch self {
        case .timerComplete: 1007  // Tock
        case .setComplete: 1057    // SMS received
        case .workoutComplete: 1025 // Fanfare
        }
    }
}
