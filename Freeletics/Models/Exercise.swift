import Foundation
import SwiftData

enum MuscleGroup: String, Codable, CaseIterable {
    case chest
    case back
    case shoulders
    case biceps
    case triceps
    case core
    case quads
    case hamstrings
    case glutes
    case calves
    case fullBody
    case cardio

    var displayName: String {
        switch self {
        case .chest: "Chest"
        case .back: "Back"
        case .shoulders: "Shoulders"
        case .biceps: "Biceps"
        case .triceps: "Triceps"
        case .core: "Core"
        case .quads: "Quads"
        case .hamstrings: "Hamstrings"
        case .glutes: "Glutes"
        case .calves: "Calves"
        case .fullBody: "Full Body"
        case .cardio: "Cardio"
        }
    }
}

enum ExerciseCategory: String, Codable, CaseIterable {
    case push
    case pull
    case legs
    case core
    case cardio
    case flexibility

    var displayName: String {
        switch self {
        case .push: "Push"
        case .pull: "Pull"
        case .legs: "Legs"
        case .core: "Core"
        case .cardio: "Cardio"
        case .flexibility: "Flexibility"
        }
    }
}

enum Difficulty: Int, Codable, CaseIterable, Comparable {
    case beginner = 1
    case intermediate = 2
    case advanced = 3

    static func < (lhs: Difficulty, rhs: Difficulty) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var displayName: String {
        switch self {
        case .beginner: "Beginner"
        case .intermediate: "Intermediate"
        case .advanced: "Advanced"
        }
    }
}

enum ExerciseType: String, Codable {
    case reps
    case timed

    var displayName: String {
        switch self {
        case .reps: "Reps"
        case .timed: "Timed"
        }
    }
}

@Model
final class Exercise {
    @Attribute(.unique) var id: String
    var name: String
    var exerciseDescription: String
    var instructions: [String]
    var primaryMuscles: [MuscleGroup]
    var secondaryMuscles: [MuscleGroup]
    var category: ExerciseCategory
    var difficulty: Difficulty
    var isBodyweight: Bool
    var exerciseType: ExerciseType
    var defaultReps: Int
    var defaultDurationSeconds: Int
    var restDurationSeconds: Int
    // Injury contraindications
    var contraindicatedInjuries: [InjuryFlag]

    init(
        id: String,
        name: String,
        description: String,
        instructions: [String],
        primaryMuscles: [MuscleGroup],
        secondaryMuscles: [MuscleGroup] = [],
        category: ExerciseCategory,
        difficulty: Difficulty,
        isBodyweight: Bool = true,
        exerciseType: ExerciseType = .reps,
        defaultReps: Int = 10,
        defaultDurationSeconds: Int = 30,
        restDurationSeconds: Int = 60,
        contraindicatedInjuries: [InjuryFlag] = []
    ) {
        self.id = id
        self.name = name
        self.exerciseDescription = description
        self.instructions = instructions
        self.primaryMuscles = primaryMuscles
        self.secondaryMuscles = secondaryMuscles
        self.category = category
        self.difficulty = difficulty
        self.isBodyweight = isBodyweight
        self.exerciseType = exerciseType
        self.defaultReps = defaultReps
        self.defaultDurationSeconds = defaultDurationSeconds
        self.restDurationSeconds = restDurationSeconds
        self.contraindicatedInjuries = contraindicatedInjuries
    }
}
