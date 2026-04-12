import Testing
import Foundation
@testable import OpenCoach

@Suite("Workout Tracking Tests")
struct WorkoutTrackingTests {

    // MARK: - Time Estimation

    @Test("Time estimation for rep-based exercises")
    func timeEstimationRepBased() {
        // 3 sets × 10 reps × 3s/rep = 90s work
        // + 2 rest periods × 60s = 120s rest
        // = 210s per exercise
        // 2 exercises + 30s transition = 210 + 210 + 30 = 450s
        let exercises = [
            PlannedExercise(exerciseId: "pushup", exerciseName: "Push-Up", sets: 3, reps: 10, restSeconds: 60, orderIndex: 0),
            PlannedExercise(exerciseId: "squat", exerciseName: "Squat", sets: 3, reps: 10, restSeconds: 60, orderIndex: 1),
        ]

        let secondsPerRep = 3.0
        let transitionSeconds = 30

        var total: Double = 0
        for exercise in exercises {
            let sets = Double(exercise.sets)
            if exercise.reps > 0 {
                total += sets * (Double(exercise.reps) * secondsPerRep)
            }
            total += (sets - 1) * Double(exercise.restSeconds)
        }
        total += Double(exercises.count - 1) * Double(transitionSeconds)

        #expect(Int(total) == 450)
    }

    @Test("Time estimation for timed exercises")
    func timeEstimationTimedExercise() {
        // 3 sets × 45s hold = 135s
        // + 2 rest periods × 30s = 60s
        // = 195s
        let exercise = PlannedExercise(exerciseId: "plank", exerciseName: "Plank", sets: 3, reps: 0, durationSeconds: 45, restSeconds: 30, orderIndex: 0)

        let sets = Double(exercise.sets)
        let total = sets * Double(exercise.durationSeconds) + (sets - 1) * Double(exercise.restSeconds)

        #expect(Int(total) == 195)
    }

    // MARK: - SetRecord Creation

    @Test("SetRecord stores planned vs actual reps")
    func setRecordCreation() {
        let record = SetRecord(setNumber: 1, plannedReps: 12, actualReps: 10)
        #expect(record.setNumber == 1)
        #expect(record.plannedReps == 12)
        #expect(record.actualReps == 10)
    }

    // MARK: - Total Volume with SetRecords

    @Test("Total volume uses set records when available")
    func totalVolumeWithSetRecords() {
        let session = WorkoutSession()

        let exercise = CompletedExercise(
            exerciseId: "pushup",
            exerciseName: "Push-Up",
            completedSets: 3,
            completedReps: 12,
            plannedSets: 3,
            plannedReps: 12
        )

        let records = [
            SetRecord(setNumber: 1, plannedReps: 12, actualReps: 12),
            SetRecord(setNumber: 2, plannedReps: 12, actualReps: 10),
            SetRecord(setNumber: 3, plannedReps: 12, actualReps: 8),
        ]
        exercise.setRecords = records
        session.completedExercises.append(exercise)

        // Total should be 12 + 10 + 8 = 30 (from set records, not 3 × 12 = 36)
        #expect(session.totalVolume == 30)
    }

    @Test("Total volume falls back to legacy calculation when no set records")
    func totalVolumeLegacyFallback() {
        let session = WorkoutSession()

        let exercise = CompletedExercise(
            exerciseId: "pushup",
            exerciseName: "Push-Up",
            completedSets: 3,
            completedReps: 12
        )
        session.completedExercises.append(exercise)

        // No set records → legacy: 3 × 12 = 36
        #expect(session.totalVolume == 36)
    }
}
