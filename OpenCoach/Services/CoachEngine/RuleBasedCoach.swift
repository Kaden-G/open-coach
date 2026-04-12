import Foundation
import SwiftData

// AI-001: Training Plan Generation (Rule-Based, Offline)
// AI-002: Weekly Adaptation Loop

struct RuleBasedCoach {

    func generatePlan(profile: UserProfile, exercises: [Exercise]) -> TrainingPlan {
        let totalWeeks = planDuration(for: profile)
        let plan = TrainingPlan(
            startDate: nextMonday(),
            totalWeeks: totalWeeks,
            goal: profile.primaryGoal,
            fitnessLevel: profile.fitnessLevel
        )

        let safeExercises = exercises.filter { exercise in
            !profile.hasInjuries || !exercise.contraindicatedInjuries.contains(where: { profile.injuries.contains($0) })
        }

        for weekNum in 1...totalWeeks {
            let week = TrainingWeek(weekNumber: weekNum)
            let volumeMultiplier = progressionMultiplier(week: weekNum, totalWeeks: totalWeeks, level: profile.fitnessLevel)
            week.volumeMultiplier = volumeMultiplier

            let days = distributeTrainingDays(
                count: profile.trainingDaysPerWeek,
                weekNumber: weekNum,
                goal: profile.primaryGoal,
                level: profile.fitnessLevel,
                exercises: safeExercises,
                volumeMultiplier: volumeMultiplier
            )
            week.days = days
            for day in days { day.week = week }

            plan.weeks.append(week)
            week.plan = plan
        }

        return plan
    }

    // MARK: - Plan Duration

    private func planDuration(for profile: UserProfile) -> Int {
        switch profile.fitnessLevel {
        case .beginner: 8
        case .intermediate: 10
        case .athlete: 12
        }
    }

    // MARK: - Progression

    private func progressionMultiplier(week: Int, totalWeeks: Int, level: FitnessLevel) -> Double {
        // Linear progression capped at 10% increase per week
        let baseMultiplier: Double = switch level {
        case .beginner: 0.7
        case .intermediate: 0.85
        case .athlete: 1.0
        }
        let weeklyIncrease = min(0.10, 0.05 * Double(week - 1) / Double(max(totalWeeks - 1, 1)))
        return min(baseMultiplier + weeklyIncrease * Double(week - 1), 1.5)
    }

    // MARK: - Day Distribution

    private func distributeTrainingDays(
        count: Int,
        weekNumber: Int,
        goal: TrainingGoal,
        level: FitnessLevel,
        exercises: [Exercise],
        volumeMultiplier: Double
    ) -> [TrainingDay] {
        // Map training days to weekdays (Mon=2, Tue=3, ..., Sat=7, Sun=1)
        let trainingWeekdays = selectTrainingWeekdays(count: count)
        var days: [TrainingDay] = []

        for weekday in 1...7 {
            let isTraining = trainingWeekdays.contains(weekday)
            let day = TrainingDay(dayOfWeek: weekday, isRestDay: !isTraining)

            if isTraining {
                let dayExercises = selectExercisesForDay(
                    dayIndex: trainingWeekdays.firstIndex(of: weekday) ?? 0,
                    totalDays: count,
                    goal: goal,
                    level: level,
                    exercises: exercises,
                    volumeMultiplier: volumeMultiplier
                )
                day.plannedExercises = dayExercises
                for ex in dayExercises { ex.day = day }
            }

            days.append(day)
        }

        return days
    }

    private func selectTrainingWeekdays(count: Int) -> [Int] {
        // Spread training days evenly through the week (Mon-Sat, avoid consecutive)
        switch count {
        case 2: return [2, 5] // Mon, Thu
        case 3: return [2, 4, 6] // Mon, Wed, Fri
        case 4: return [2, 3, 5, 6] // Mon, Tue, Thu, Fri
        case 5: return [2, 3, 4, 5, 6] // Mon-Fri
        case 6: return [2, 3, 4, 5, 6, 7] // Mon-Sat
        default: return [2, 4, 6]
        }
    }

    // MARK: - Exercise Selection

    private func selectExercisesForDay(
        dayIndex: Int,
        totalDays: Int,
        goal: TrainingGoal,
        level: FitnessLevel,
        exercises: [Exercise],
        volumeMultiplier: Double
    ) -> [PlannedExercise] {
        let split = determineSplit(dayIndex: dayIndex, totalDays: totalDays, goal: goal)
        let filteredExercises = exercises.filter { split.contains($0.category) }
            .filter { $0.difficulty.rawValue <= maxDifficulty(for: level) }

        let selectedCount = exercisesPerSession(goal: goal, level: level)
        let selected = Array(filteredExercises.shuffled().prefix(selectedCount))

        return selected.enumerated().map { index, exercise in
            let sets = baseSets(level: level, goal: goal, volumeMultiplier: volumeMultiplier)
            let reps = exercise.exerciseType == .reps
                ? Int(Double(exercise.defaultReps) * volumeMultiplier)
                : 0
            let duration = exercise.exerciseType == .timed
                ? Int(Double(exercise.defaultDurationSeconds) * volumeMultiplier)
                : 0

            return PlannedExercise(
                exerciseId: exercise.id,
                exerciseName: exercise.name,
                sets: sets,
                reps: reps,
                durationSeconds: duration,
                restSeconds: restDuration(goal: goal),
                orderIndex: index
            )
        }
    }

    private func determineSplit(dayIndex: Int, totalDays: Int, goal: TrainingGoal) -> [ExerciseCategory] {
        if totalDays <= 3 {
            // Full body each day
            return [.push, .pull, .legs, .core, .cardio]
        }

        // Upper/lower or push/pull/legs split
        switch dayIndex % 3 {
        case 0: return [.push, .core]
        case 1: return [.pull, .core]
        case 2: return [.legs, .cardio]
        default: return [.push, .pull, .legs]
        }
    }

    private func maxDifficulty(for level: FitnessLevel) -> Int {
        switch level {
        case .beginner: Difficulty.beginner.rawValue
        case .intermediate: Difficulty.intermediate.rawValue
        case .athlete: Difficulty.advanced.rawValue
        }
    }

    private func exercisesPerSession(goal: TrainingGoal, level: FitnessLevel) -> Int {
        let base = switch level {
        case .beginner: 4
        case .intermediate: 5
        case .athlete: 6
        }
        return goal == .endurance ? base + 1 : base
    }

    private func baseSets(level: FitnessLevel, goal: TrainingGoal, volumeMultiplier: Double) -> Int {
        let base = switch level {
        case .beginner: 2
        case .intermediate: 3
        case .athlete: 4
        }
        let goalModifier = goal == .strength ? 1 : 0
        return max(2, Int(Double(base + goalModifier) * min(volumeMultiplier, 1.2)))
    }

    private func restDuration(goal: TrainingGoal) -> Int {
        switch goal {
        case .strength: 90
        case .fatLoss: 30
        case .endurance: 45
        }
    }

    // MARK: - Helpers

    private func nextMonday() -> Date {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        let daysUntilMonday = (9 - weekday) % 7
        return calendar.date(byAdding: .day, value: daysUntilMonday == 0 ? 7 : daysUntilMonday, to: today) ?? today
    }
}
