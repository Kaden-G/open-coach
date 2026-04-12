import Foundation
import SwiftData

@Model
final class WorkoutSession {
    var date: Date
    var durationSeconds: Int
    var rpe: Int? // 1-10 rate of perceived exertion
    var notes: String?
    var completed: Bool
    var planWeekNumber: Int?
    var planDayOfWeek: Int?
    var isCustomWorkout: Bool
    var customWorkoutName: String?
    @Relationship(deleteRule: .cascade) var completedExercises: [CompletedExercise]

    init(
        date: Date = Date(),
        isCustomWorkout: Bool = false,
        customWorkoutName: String? = nil,
        planWeekNumber: Int? = nil,
        planDayOfWeek: Int? = nil
    ) {
        self.date = date
        self.durationSeconds = 0
        self.completed = false
        self.isCustomWorkout = isCustomWorkout
        self.customWorkoutName = customWorkoutName
        self.planWeekNumber = planWeekNumber
        self.planDayOfWeek = planDayOfWeek
        self.completedExercises = []
    }

    var formattedDuration: String {
        let minutes = durationSeconds / 60
        let seconds = durationSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var totalVolume: Int {
        completedExercises.reduce(0) { $0 + ($1.completedSets * $1.completedReps) }
    }

    var displayName: String {
        if let name = customWorkoutName {
            return name
        }
        if let week = planWeekNumber, let day = planDayOfWeek {
            let formatter = DateFormatter()
            let dayIndex = day - 1
            let dayName = dayIndex >= 0 && dayIndex < formatter.weekdaySymbols.count
                ? formatter.weekdaySymbols[dayIndex]
                : "Day \(day)"
            return "Week \(week) — \(dayName)"
        }
        return "Workout"
    }
}

@Model
final class CompletedExercise {
    var exerciseId: String
    var exerciseName: String
    var completedSets: Int
    var completedReps: Int
    var durationSeconds: Int
    var orderIndex: Int
    var wasSubstituted: Bool
    var originalExerciseId: String?
    var session: WorkoutSession?

    init(
        exerciseId: String,
        exerciseName: String,
        completedSets: Int,
        completedReps: Int,
        durationSeconds: Int = 0,
        orderIndex: Int = 0,
        wasSubstituted: Bool = false,
        originalExerciseId: String? = nil
    ) {
        self.exerciseId = exerciseId
        self.exerciseName = exerciseName
        self.completedSets = completedSets
        self.completedReps = completedReps
        self.durationSeconds = durationSeconds
        self.orderIndex = orderIndex
        self.wasSubstituted = wasSubstituted
        self.originalExerciseId = originalExerciseId
    }
}
