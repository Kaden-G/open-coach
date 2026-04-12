import Foundation
import SwiftData

// GAP-1: LLM-enhanced plan generation with rule-based fallback.
// Sends plan generation prompt to configured LLM provider, parses JSON response,
// validates all fields against safe bounds, and falls back to RuleBasedCoach on any failure.

struct LLMCoach {

    enum Source: String {
        case llm = "LLM-Generated"
        case ruleBased = "Rule-Based"
    }

    struct GenerationResult {
        let plan: TrainingPlan
        let source: Source
    }

    func generatePlan(profile: UserProfile, exercises: [Exercise]) async -> GenerationResult {
        // Try LLM path if configured
        if let config = LLMConfiguration.current {
            do {
                let plan = try await generateWithLLM(config: config, profile: profile, exercises: exercises)
                return GenerationResult(plan: plan, source: .llm)
            } catch {
                // Fall through to rule-based
            }
        }

        // Fallback to rule-based
        let coach = RuleBasedCoach()
        let plan = coach.generatePlan(profile: profile, exercises: exercises)
        return GenerationResult(plan: plan, source: .ruleBased)
    }

    // MARK: - LLM Generation

    private func generateWithLLM(
        config: LLMConfiguration,
        profile: UserProfile,
        exercises: [Exercise]
    ) async throws -> TrainingPlan {
        let client = LLMClient(config: config)

        let exerciseNames = exercises.map(\.name)
        let prompt = PromptTemplates.planGenerationPrompt(
            fitnessLevel: profile.fitnessLevel.rawValue,
            goal: profile.primaryGoal.rawValue,
            trainingDays: profile.trainingDaysPerWeek,
            injuries: profile.injuries.filter { $0 != .none }.map(\.rawValue),
            exerciseNames: exerciseNames
        )

        let response = try await client.send(
            prompt: prompt,
            systemPrompt: PromptTemplates.coachSystemPrompt
        )

        let plan = try parsePlanResponse(
            response.content,
            profile: profile,
            validExerciseIds: Set(exercises.map(\.id)),
            exerciseLookup: Dictionary(uniqueKeysWithValues: exercises.map { ($0.id, $0) })
        )

        return plan
    }

    // MARK: - Response Parsing with Validation

    private func parsePlanResponse(
        _ jsonString: String,
        profile: UserProfile,
        validExerciseIds: Set<String>,
        exerciseLookup: [String: Exercise]
    ) throws -> TrainingPlan {
        guard let data = jsonString.data(using: .utf8) else {
            throw LLMClient.LLMError.invalidResponse
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let json else { throw LLMClient.LLMError.invalidResponse }

        // Validate totalWeeks (must be 4-16)
        guard let totalWeeks = json["totalWeeks"] as? Int,
              (4...16).contains(totalWeeks) else {
            throw LLMClient.LLMError.invalidResponse
        }

        guard let weeksJSON = json["weeks"] as? [[String: Any]],
              !weeksJSON.isEmpty else {
            throw LLMClient.LLMError.invalidResponse
        }

        let plan = TrainingPlan(
            startDate: nextMonday(),
            totalWeeks: totalWeeks,
            goal: profile.primaryGoal,
            fitnessLevel: profile.fitnessLevel
        )

        for weekData in weeksJSON {
            guard let weekNumber = weekData["weekNumber"] as? Int,
                  (1...totalWeeks).contains(weekNumber),
                  let daysData = weekData["days"] as? [[String: Any]] else {
                continue
            }

            let week = TrainingWeek(weekNumber: weekNumber)

            for dayData in daysData {
                guard let dayOfWeek = dayData["dayOfWeek"] as? Int,
                      (1...7).contains(dayOfWeek) else {
                    continue
                }

                let isRestDay = dayData["isRestDay"] as? Bool ?? false
                let day = TrainingDay(dayOfWeek: dayOfWeek, isRestDay: isRestDay)

                if !isRestDay, let exercisesData = dayData["exercises"] as? [[String: Any]] {
                    for (index, exData) in exercisesData.enumerated() {
                        guard let exerciseId = exData["exerciseId"] as? String,
                              validExerciseIds.contains(exerciseId),
                              let exercise = exerciseLookup[exerciseId] else {
                            // Skip exercises with unknown IDs (OWASP LLM01)
                            continue
                        }

                        let sets = clamp(exData["sets"] as? Int ?? 3, min: 1, max: 10)
                        let reps = clamp(exData["reps"] as? Int ?? exercise.defaultReps, min: 1, max: 100)
                        let duration = clamp(exData["durationSeconds"] as? Int ?? 0, min: 0, max: 300)
                        let rest = clamp(exData["restSeconds"] as? Int ?? 60, min: 10, max: 180)

                        let planned = PlannedExercise(
                            exerciseId: exerciseId,
                            exerciseName: exercise.name,
                            sets: sets,
                            reps: reps,
                            durationSeconds: duration,
                            restSeconds: rest,
                            orderIndex: index
                        )
                        planned.day = day
                        day.plannedExercises.append(planned)
                    }
                }

                day.week = week
                week.days.append(day)
            }

            week.plan = plan
            plan.weeks.append(week)
        }

        // Final validation: plan must have at least 1 week with training days
        let hasTrainingDays = plan.weeks.contains { week in
            week.days.contains { !$0.isRestDay && !$0.plannedExercises.isEmpty }
        }
        guard hasTrainingDays else {
            throw LLMClient.LLMError.invalidResponse
        }

        return plan
    }

    // MARK: - Helpers

    private func clamp(_ value: Int, min: Int, max: Int) -> Int {
        Swift.min(Swift.max(value, min), max)
    }

    private func nextMonday() -> Date {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        let daysUntilMonday = (9 - weekday) % 7
        return calendar.date(byAdding: .day, value: daysUntilMonday == 0 ? 7 : daysUntilMonday, to: today) ?? today
    }
}
