import Foundation
import SwiftData

// AI-003: In-Workout Exercise Substitution
// Selects an alternative targeting the same muscle group at equivalent difficulty.

struct ExerciseSubstitutor {

    func findSubstitute(
        for exercise: Exercise,
        in library: [Exercise],
        excluding excludedIds: Set<String>,
        userInjuries: [InjuryFlag]
    ) -> Exercise? {
        let candidates = library.filter { candidate in
            // Must not be the same exercise
            candidate.id != exercise.id
            // Must not be already excluded (e.g., already in workout)
            && !excludedIds.contains(candidate.id)
            // Must share at least one primary muscle group
            && !Set(candidate.primaryMuscles).intersection(Set(exercise.primaryMuscles)).isEmpty
            // Must not be contraindicated for user's injuries
            && !candidate.contraindicatedInjuries.contains(where: { userInjuries.contains($0) })
        }

        // Prefer same difficulty, then adjacent difficulty
        let sameDifficulty = candidates.filter { $0.difficulty == exercise.difficulty }
        if let match = sameDifficulty.randomElement() {
            return match
        }

        // Try one level easier
        let easier = candidates.filter { $0.difficulty.rawValue == exercise.difficulty.rawValue - 1 }
        if let match = easier.randomElement() {
            return match
        }

        // Try one level harder
        let harder = candidates.filter { $0.difficulty.rawValue == exercise.difficulty.rawValue + 1 }
        if let match = harder.randomElement() {
            return match
        }

        // Any candidate
        return candidates.randomElement()
    }
}
