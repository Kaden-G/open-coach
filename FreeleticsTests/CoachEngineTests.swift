import Testing
import Foundation
@testable import Freeletics

@Suite("RuleBasedCoach Tests")
struct CoachEngineTests {

    func makeProfile(
        level: FitnessLevel = .beginner,
        goal: TrainingGoal = .strength,
        days: Int = 3,
        injuries: [InjuryFlag] = [.none]
    ) -> UserProfile {
        UserProfile(
            fitnessLevel: level,
            primaryGoal: goal,
            trainingDaysPerWeek: days,
            injuries: injuries,
            onboardingComplete: true
        )
    }

    @Test("Generates plan with correct week count for each fitness level")
    func planDuration() {
        let coach = RuleBasedCoach()
        let exercises = ExerciseSeedData.allExercises

        let beginnerPlan = coach.generatePlan(profile: makeProfile(level: .beginner), exercises: exercises)
        #expect(beginnerPlan.totalWeeks == 8)

        let intermediatePlan = coach.generatePlan(profile: makeProfile(level: .intermediate), exercises: exercises)
        #expect(intermediatePlan.totalWeeks == 10)

        let athletePlan = coach.generatePlan(profile: makeProfile(level: .athlete), exercises: exercises)
        #expect(athletePlan.totalWeeks == 12)
    }

    @Test("Plan has correct number of training days per week")
    func trainingDayCount() {
        let coach = RuleBasedCoach()
        let exercises = ExerciseSeedData.allExercises

        for dayCount in 2...6 {
            let plan = coach.generatePlan(
                profile: makeProfile(days: dayCount),
                exercises: exercises
            )
            for week in plan.weeks {
                let trainingDays = week.days.filter { !$0.isRestDay }
                #expect(trainingDays.count == dayCount, "Week \(week.weekNumber) should have \(dayCount) training days")
            }
        }
    }

    @Test("Plan respects injury contraindications")
    func injuryFiltering() {
        let coach = RuleBasedCoach()
        let exercises = ExerciseSeedData.allExercises

        let plan = coach.generatePlan(
            profile: makeProfile(injuries: [.knees]),
            exercises: exercises
        )

        let kneeExercises = ExerciseSeedData.allExercises
            .filter { $0.contraindicatedInjuries.contains(.knees) }
            .map(\.id)

        for week in plan.weeks {
            for day in week.days {
                for exercise in day.plannedExercises {
                    #expect(!kneeExercises.contains(exercise.exerciseId),
                            "\(exercise.exerciseName) should be excluded for knee injury")
                }
            }
        }
    }

    @Test("All weeks contain 7 days")
    func weekStructure() {
        let coach = RuleBasedCoach()
        let exercises = ExerciseSeedData.allExercises
        let plan = coach.generatePlan(profile: makeProfile(), exercises: exercises)

        for week in plan.weeks {
            #expect(week.days.count == 7, "Week \(week.weekNumber) should have 7 days")
        }
    }

    @Test("Each training day has planned exercises")
    func exercisesPresent() {
        let coach = RuleBasedCoach()
        let exercises = ExerciseSeedData.allExercises
        let plan = coach.generatePlan(profile: makeProfile(), exercises: exercises)

        for week in plan.weeks {
            for day in week.days where !day.isRestDay {
                #expect(!day.plannedExercises.isEmpty,
                        "Training day \(day.dayOfWeek) in week \(week.weekNumber) should have exercises")
            }
        }
    }
}
