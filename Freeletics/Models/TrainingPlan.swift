import Foundation
import SwiftData

enum PlanStatus: String, Codable {
    case active
    case completed
    case paused
}

@Model
final class TrainingPlan {
    var startDate: Date
    var endDate: Date
    var goal: TrainingGoal
    var fitnessLevel: FitnessLevel
    var totalWeeks: Int
    var status: PlanStatus
    var createdAt: Date
    @Relationship(deleteRule: .cascade) var weeks: [TrainingWeek]

    init(
        startDate: Date,
        totalWeeks: Int,
        goal: TrainingGoal,
        fitnessLevel: FitnessLevel
    ) {
        self.startDate = startDate
        self.endDate = Calendar.current.date(byAdding: .weekOfYear, value: totalWeeks, to: startDate) ?? startDate
        self.goal = goal
        self.fitnessLevel = fitnessLevel
        self.totalWeeks = totalWeeks
        self.status = .active
        self.createdAt = Date()
        self.weeks = []
    }

    var currentWeekNumber: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.weekOfYear], from: startDate, to: Date())
        return min(max((components.weekOfYear ?? 0) + 1, 1), totalWeeks)
    }

    var currentWeek: TrainingWeek? {
        weeks.first { $0.weekNumber == currentWeekNumber }
    }

    var completionPercentage: Double {
        guard !weeks.isEmpty else { return 0 }
        let totalDays = weeks.flatMap(\.days)
        let completedDays = totalDays.filter(\.isCompleted)
        guard !totalDays.isEmpty else { return 0 }
        return Double(completedDays.count) / Double(totalDays.count)
    }
}

@Model
final class TrainingWeek {
    var weekNumber: Int
    @Relationship(deleteRule: .cascade) var days: [TrainingDay]
    var plan: TrainingPlan?

    // Weekly adaptation data
    var averageRPE: Double?
    var completionRate: Double?
    var volumeMultiplier: Double

    init(weekNumber: Int) {
        self.weekNumber = weekNumber
        self.days = []
        self.volumeMultiplier = 1.0
    }

    var isCurrentWeek: Bool {
        plan?.currentWeekNumber == weekNumber
    }
}

@Model
final class TrainingDay {
    var dayOfWeek: Int // 1=Sunday, 2=Monday, ..., 7=Saturday
    var isRestDay: Bool
    var isCompleted: Bool
    @Relationship(deleteRule: .cascade) var plannedExercises: [PlannedExercise]
    var week: TrainingWeek?

    init(dayOfWeek: Int, isRestDay: Bool = false) {
        self.dayOfWeek = dayOfWeek
        self.isRestDay = isRestDay
        self.isCompleted = false
        self.plannedExercises = []
    }

    var dayName: String {
        let formatter = DateFormatter()
        // dayOfWeek: 1=Sunday matches Calendar weekday symbols
        let index = dayOfWeek - 1
        guard index >= 0, index < formatter.weekdaySymbols.count else { return "Unknown" }
        return formatter.weekdaySymbols[index]
    }
}

@Model
final class PlannedExercise {
    var exerciseId: String
    var exerciseName: String
    var sets: Int
    var reps: Int
    var durationSeconds: Int
    var restSeconds: Int
    var orderIndex: Int
    var day: TrainingDay?

    init(
        exerciseId: String,
        exerciseName: String,
        sets: Int,
        reps: Int,
        durationSeconds: Int = 0,
        restSeconds: Int = 60,
        orderIndex: Int = 0
    ) {
        self.exerciseId = exerciseId
        self.exerciseName = exerciseName
        self.sets = sets
        self.reps = reps
        self.durationSeconds = durationSeconds
        self.restSeconds = restSeconds
        self.orderIndex = orderIndex
    }
}
