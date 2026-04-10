import Testing
import Foundation
@testable import Freeletics

@Suite("WeeklyAdaptation Tests")
struct WeeklyAdaptationTests {

    @Test("Volume increase capped at 10% per week")
    func volumeCap() {
        let adaptation = WeeklyAdaptation()
        let plan = makeTestPlan()

        // Simulate perfect week with low RPE
        let sessions = [makeSession(rpe: 3, completed: true, weekNumber: 1)]

        let currentMultiplier = plan.weeks[0].volumeMultiplier
        adaptation.adaptNextWeek(plan: plan, completedSessions: sessions, exercises: [])

        let nextMultiplier = plan.weeks[1].volumeMultiplier
        let increase = (nextMultiplier - currentMultiplier) / currentMultiplier

        #expect(increase <= 0.10 + 0.001, "Volume increase should be capped at 10%, got \(increase * 100)%")
    }

    @Test("Volume decreases when RPE is high")
    func highRPEReduction() {
        let adaptation = WeeklyAdaptation()
        let plan = makeTestPlan()

        let sessions = [
            makeSession(rpe: 9, completed: true, weekNumber: 1),
            makeSession(rpe: 10, completed: true, weekNumber: 1),
        ]

        let before = plan.weeks[1].volumeMultiplier
        adaptation.adaptNextWeek(plan: plan, completedSessions: sessions, exercises: [])
        let after = plan.weeks[1].volumeMultiplier

        #expect(after <= before, "Volume should decrease or stay same with high RPE")
    }

    @Test("Volume decreases when completion rate is low")
    func lowCompletionReduction() {
        let adaptation = WeeklyAdaptation()
        let plan = makeTestPlan()

        // Only 1 of 3 training days completed
        let sessions = [makeSession(rpe: 5, completed: true, weekNumber: 1)]

        let before = plan.weeks[1].volumeMultiplier
        adaptation.adaptNextWeek(plan: plan, completedSessions: sessions, exercises: [])
        let after = plan.weeks[1].volumeMultiplier

        #expect(after <= before, "Volume should decrease with low completion rate")
    }

    // MARK: - Helpers

    private func makeTestPlan() -> TrainingPlan {
        let plan = TrainingPlan(
            startDate: Date(),
            totalWeeks: 4,
            goal: .strength,
            fitnessLevel: .intermediate
        )

        for i in 1...4 {
            let week = TrainingWeek(weekNumber: i)
            week.volumeMultiplier = 1.0
            week.plan = plan

            for day in 1...7 {
                let isTraining = [2, 4, 6].contains(day)
                let trainingDay = TrainingDay(dayOfWeek: day, isRestDay: !isTraining)
                if isTraining {
                    let exercise = PlannedExercise(
                        exerciseId: "pushup",
                        exerciseName: "Push-Up",
                        sets: 3,
                        reps: 15,
                        restSeconds: 60
                    )
                    trainingDay.plannedExercises = [exercise]
                    exercise.day = trainingDay
                }
                week.days.append(trainingDay)
                trainingDay.week = week
            }

            plan.weeks.append(week)
        }
        return plan
    }

    private func makeSession(rpe: Int, completed: Bool, weekNumber: Int) -> WorkoutSession {
        let session = WorkoutSession(planWeekNumber: weekNumber)
        session.rpe = rpe
        session.completed = completed
        return session
    }
}
