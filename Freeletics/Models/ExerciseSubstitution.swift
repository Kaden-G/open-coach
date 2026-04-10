import Foundation
import SwiftData

@Model
final class ExerciseSubstitution {
    var originalExerciseId: String
    var substituteExerciseId: String
    var reason: String
    var date: Date

    init(
        originalExerciseId: String,
        substituteExerciseId: String,
        reason: String = "User requested substitution"
    ) {
        self.originalExerciseId = originalExerciseId
        self.substituteExerciseId = substituteExerciseId
        self.reason = reason
        self.date = Date()
    }
}
