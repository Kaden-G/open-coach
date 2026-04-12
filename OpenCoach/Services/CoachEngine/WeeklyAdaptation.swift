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

        let repCompletionRate = calculateRepCompletionRate(sessions: weekSessions)

        // Determine volume adjustment
        let adjustment = volumeAdjustment(completionRate: completionRate, averageRPE: averageRPE, repCompletionRate: repCompletionRate)

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

    private func calculateRepCompletionRate(sessions: [WorkoutSession]) -> Double {
        var totalPlanned = 0
        var totalActual = 0

        for session in sessions {
            for exercise in session.completedExercises {
                if exercise.setRecords.isEmpty {
                    totalPlanned += exercise.completedSets * exercise.completedReps
                    totalActual += exercise.completedSets * exercise.completedReps
                } else {
                    for record in exercise.setRecords {
                        totalPlanned += record.plannedReps
                        totalActual += record.actualReps
                    }
                }
            }
        }

        guard totalPlanned > 0 else { return 1.0 }
        return Double(totalActual) / Double(totalPlanned)
    }

    // MARK: - Volume Adjustment Logic

    private func volumeAdjustment(completionRate: Double, averageRPE: Double, repCompletionRate: Double) -> Double {
        // Rep completion < 80% is a strong signal to reduce regardless of RPE
        if repCompletionRate < 0.8 && completionRate >= 0.7 {
            return -0.05
        }

        if completionRate < 0.5 {
            return -0.15
        } else if completionRate < 0.7 || averageRPE > 8.5 {
            return -0.05
        } else if averageRPE > 7.5 {
            return 0.0
        } else if completionRate >= 0.9 && averageRPE < 6.0 && repCompletionRate >= 0.95 {
            return 0.10
        } else if completionRate >= 0.8 {
            return 0.05
        } else {
            return 0.0
        }
    }
}
