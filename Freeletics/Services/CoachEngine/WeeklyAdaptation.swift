import Foundation
import SwiftData

// AI-002: Weekly Adaptation Loop
// Recalculates next week based on completed vs skipped workouts and RPE feedback.
// Volume increases capped at 10% per week.

struct WeeklyAdaptation {

    func adaptNextWeek(
        plan: TrainingPlan,
        completedSessions: [WorkoutSession],
        exercises: [Exercise]
    ) {
        guard let currentWeek = plan.currentWeek else { return }
        let nextWeekNumber = currentWeek.weekNumber + 1
        guard let nextWeek = plan.weeks.first(where: { $0.weekNumber == nextWeekNumber }) else { return }

        // Calculate current week metrics
        let weekSessions = completedSessions.filter { session in
            session.planWeekNumber == currentWeek.weekNumber
        }

        let completionRate = calculateCompletionRate(week: currentWeek, sessions: weekSessions)
        let averageRPE = calculateAverageRPE(sessions: weekSessions)

        currentWeek.completionRate = completionRate
        currentWeek.averageRPE = averageRPE

        // Determine volume adjustment
        let adjustment = volumeAdjustment(completionRate: completionRate, averageRPE: averageRPE)

        // Apply adjustment to next week (capped at 10% increase)
        let newMultiplier = currentWeek.volumeMultiplier * (1.0 + adjustment)
        let cappedMultiplier = min(newMultiplier, currentWeek.volumeMultiplier * 1.10)
        nextWeek.volumeMultiplier = max(cappedMultiplier, 0.6) // Floor at 60%

        // Update planned exercises in next week
        for day in nextWeek.days where !day.isRestDay {
            for exercise in day.plannedExercises {
                let volumeRatio = nextWeek.volumeMultiplier / currentWeek.volumeMultiplier
                exercise.reps = max(1, Int(Double(exercise.reps) * volumeRatio))
                exercise.sets = max(1, Int(Double(exercise.sets) * volumeRatio))
                if exercise.durationSeconds > 0 {
                    exercise.durationSeconds = max(10, Int(Double(exercise.durationSeconds) * volumeRatio))
                }
            }
        }
    }

    // MARK: - Metrics

    private func calculateCompletionRate(week: TrainingWeek, sessions: [WorkoutSession]) -> Double {
        let trainingDays = week.days.filter { !$0.isRestDay }
        guard !trainingDays.isEmpty else { return 1.0 }
        let completedCount = sessions.filter(\.completed).count
        return Double(completedCount) / Double(trainingDays.count)
    }

    private func calculateAverageRPE(sessions: [WorkoutSession]) -> Double {
        let rpeSessions = sessions.compactMap(\.rpe)
        guard !rpeSessions.isEmpty else { return 5.0 }
        return Double(rpeSessions.reduce(0, +)) / Double(rpeSessions.count)
    }

    // MARK: - Volume Adjustment Logic

    private func volumeAdjustment(completionRate: Double, averageRPE: Double) -> Double {
        // High RPE (>8) or low completion (<70%) → decrease volume
        // Moderate RPE and good completion → increase volume
        // Cap increases at 10%

        if completionRate < 0.5 {
            return -0.15 // Significant reduction
        } else if completionRate < 0.7 || averageRPE > 8.5 {
            return -0.05 // Mild reduction
        } else if averageRPE > 7.5 {
            return 0.0 // Maintain
        } else if completionRate >= 0.9 && averageRPE < 6.0 {
            return 0.10 // Maximum increase
        } else if completionRate >= 0.8 {
            return 0.05 // Moderate increase
        } else {
            return 0.0
        }
    }
}
