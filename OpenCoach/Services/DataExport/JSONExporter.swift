import Foundation
import SwiftData

// OSS-003: One-tap JSON export of all workout history, plan data, and settings.
// Exported file is human-readable and schema-documented.

enum JSONExporter {
    struct ExportData: Codable {
        let exportVersion: String
        let exportDate: String
        let profile: ProfileExport?
        let workoutSessions: [SessionExport]
        let trainingPlans: [PlanExport]
    }

    struct ProfileExport: Codable {
        let fitnessLevel: String
        let primaryGoal: String
        let trainingDaysPerWeek: Int
        let injuries: [String]
        let createdAt: String
    }

    struct SessionExport: Codable {
        let date: String
        let durationSeconds: Int
        let rpe: Int?
        let notes: String?
        let completed: Bool
        let isCustomWorkout: Bool
        let customWorkoutName: String?
        let exercises: [ExerciseExport]
    }

    struct ExerciseExport: Codable {
        let exerciseId: String
        let exerciseName: String
        let completedSets: Int
        let completedReps: Int
        let plannedSets: Int
        let plannedReps: Int
        let durationSeconds: Int
        let wasSubstituted: Bool
        let setRecords: [SetRecordExport]
    }

    struct SetRecordExport: Codable {
        let setNumber: Int
        let plannedReps: Int
        let actualReps: Int
    }

    struct PlanExport: Codable {
        let startDate: String
        let totalWeeks: Int
        let goal: String
        let status: String
        let completionPercentage: Double
    }

    static func export(context: ModelContext) throws -> URL {
        let dateFormatter = ISO8601DateFormatter()

        // Fetch all data
        let profiles = (try? context.fetch(FetchDescriptor<UserProfile>())) ?? []
        let sessions = (try? context.fetch(FetchDescriptor<WorkoutSession>())) ?? []
        let plans = (try? context.fetch(FetchDescriptor<TrainingPlan>())) ?? []

        let profileExport = profiles.first.map { profile in
            ProfileExport(
                fitnessLevel: profile.fitnessLevel.rawValue,
                primaryGoal: profile.primaryGoal.rawValue,
                trainingDaysPerWeek: profile.trainingDaysPerWeek,
                injuries: profile.injuries.map(\.rawValue),
                createdAt: dateFormatter.string(from: profile.createdAt)
            )
        }

        let sessionExports = sessions.map { session in
            SessionExport(
                date: dateFormatter.string(from: session.date),
                durationSeconds: session.durationSeconds,
                rpe: session.rpe,
                notes: session.notes,
                completed: session.completed,
                isCustomWorkout: session.isCustomWorkout,
                customWorkoutName: session.customWorkoutName,
                exercises: session.completedExercises.map { ex in
                    ExerciseExport(
                        exerciseId: ex.exerciseId,
                        exerciseName: ex.exerciseName,
                        completedSets: ex.completedSets,
                        completedReps: ex.completedReps,
                        plannedSets: ex.plannedSets,
                        plannedReps: ex.plannedReps,
                        durationSeconds: ex.durationSeconds,
                        wasSubstituted: ex.wasSubstituted,
                        setRecords: ex.setRecords.sorted(by: { $0.setNumber < $1.setNumber }).map { record in
                            SetRecordExport(
                                setNumber: record.setNumber,
                                plannedReps: record.plannedReps,
                                actualReps: record.actualReps
                            )
                        }
                    )
                }
            )
        }

        let planExports = plans.map { plan in
            PlanExport(
                startDate: dateFormatter.string(from: plan.startDate),
                totalWeeks: plan.totalWeeks,
                goal: plan.goal.rawValue,
                status: plan.status.rawValue,
                completionPercentage: plan.completionPercentage
            )
        }

        let exportData = ExportData(
            exportVersion: "1.1.0",
            exportDate: dateFormatter.string(from: Date()),
            profile: profileExport,
            workoutSessions: sessionExports,
            trainingPlans: planExports
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(exportData)

        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("open-coach-export-\(dateFormatter.string(from: Date())).json")
        try data.write(to: fileURL)

        return fileURL
    }
}
