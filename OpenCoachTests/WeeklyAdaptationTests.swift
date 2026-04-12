import Testing
import Foundation
@testable import OpenCoach

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

    @Test("Low rep completion rate triggers volume reduction even with moderate RPE")
    func lowRepCompletionReduction() {
        let adaptation = WeeklyAdaptation()
        let plan = makeTestPlan()

        // Sessions with moderate RPE but consistently falling short on reps
        let session = makeSession(rpe: 6, completed: true, weekNumber: 1)
        let exercise = CompletedExercise(
            exerciseId: "pushup",
            exerciseName: "Push-Up",
            completedSets: 3,
            completedReps: 15,
            plannedSets: 3,
            plannedReps: 15
        )
        exercise.setRecords = [
            SetRecord(setNumber: 1, plannedReps: 15, actualReps: 10),
            SetRecord(setNumber: 2, plannedReps: 15, actualReps: 8),
            SetRecord(setNumber: 3, plannedReps: 15, actualReps: 7),
        ]
        session.completedExercises.append(exercise)

        // Add enough sessions to meet completion rate threshold
        let session2 = makeSession(rpe: 6, completed: true, weekNumber: 1)
        session2.completedExercises.append(CompletedExercise(
            exerciseId: "squat", exerciseName: "Squat",
            completedSets: 3, completedReps: 15, plannedSets: 3, plannedReps: 15
        ))
        let session3 = makeSession(rpe: 6, completed: true, weekNumber: 1)
        session3.completedExercises.append(CompletedExercise(
            exerciseId: "plank", exerciseName: "Plank",
            completedSets: 3, completedReps: 15, plannedSets: 3, plannedReps: 15
        ))

        let before = plan.weeks[1].volumeMultiplier
        adaptation.adaptNextWeek(plan: plan, completedSessions: [session, session2, session3], exercises: [])
        let after = plan.weeks[1].volumeMultiplier

        #expect(after <= before, "Volume should decrease when rep completion rate is low")
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
