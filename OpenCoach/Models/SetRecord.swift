import Foundation
import SwiftData

@Model
final class SetRecord {
    var setNumber: Int
    var plannedReps: Int
    var actualReps: Int
    var completedExercise: CompletedExercise?

    init(setNumber: Int, plannedReps: Int, actualReps: Int) {
        self.setNumber = setNumber
        self.plannedReps = plannedReps
        self.actualReps = actualReps
    }
}
