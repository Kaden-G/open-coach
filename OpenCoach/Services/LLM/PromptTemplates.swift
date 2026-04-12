import Foundation

enum PromptTemplates {
    static let coachSystemPrompt = """
    You are an expert fitness coach AI for the Open-Coach app. You create personalized \
    bodyweight training plans based on the user's fitness level, goals, and constraints.

    Your responses must be valid JSON matching the expected schema. Do not include markdown \
    formatting, explanations, or text outside the JSON structure.

    Training principles:
    - Progressive overload: gradually increase volume/intensity each week
    - Volume increases capped at 10% per week
    - Balance push/pull/legs across the training week
    - Include adequate rest days
    - Respect injury contraindications
    - Match exercise difficulty to fitness level
    """

    static func planGenerationPrompt(
        fitnessLevel: String,
        goal: String,
        trainingDays: Int,
        injuries: [String],
        exerciseNames: [String]
    ) -> String {
        """
        Generate a training plan with the following parameters:
        - Fitness Level: \(fitnessLevel)
        - Primary Goal: \(goal)
        - Training Days Per Week: \(trainingDays)
        - Injuries/Limitations: \(injuries.isEmpty ? "None" : injuries.joined(separator: ", "))
        - Available Exercises: \(exerciseNames.joined(separator: ", "))

        Return a JSON object with this structure:
        {
          "totalWeeks": <number>,
          "weeks": [
            {
              "weekNumber": <number>,
              "days": [
                {
                  "dayOfWeek": <1-7, 1=Sunday>,
                  "isRestDay": <boolean>,
                  "exercises": [
                    {
                      "exerciseId": "<id>",
                      "sets": <number>,
                      "reps": <number>,
                      "durationSeconds": <number or 0>,
                      "restSeconds": <number>
                    }
                  ]
                }
              ]
            }
          ]
        }
        """
    }

    static func weeklyAdaptationPrompt(
        completionRate: Double,
        averageRPE: Double,
        currentWeekPlan: String,
        exerciseNames: [String]
    ) -> String {
        """
        Adapt next week's training plan based on performance data:
        - Completion Rate: \(Int(completionRate * 100))%
        - Average RPE: \(String(format: "%.1f", averageRPE))/10
        - Current Week Plan: \(currentWeekPlan)
        - Available Exercises: \(exerciseNames.joined(separator: ", "))

        Rules:
        - Volume increase capped at 10% per week
        - If RPE > 8, reduce volume
        - If completion < 70%, simplify the plan
        - If RPE < 5 and completion > 90%, increase challenge

        Return the same JSON structure as the plan generation prompt, but for a single week.
        """
    }
}
