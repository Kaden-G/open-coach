import Foundation
import SwiftData

// PROFILE-001: Fitness Assessment Flow

enum FitnessLevel: String, Codable, CaseIterable {
    case beginner
    case intermediate
    case athlete

    var displayName: String {
        switch self {
        case .beginner: "Beginner"
        case .intermediate: "Intermediate"
        case .athlete: "Athlete"
        }
    }
}

enum TrainingGoal: String, Codable, CaseIterable {
    case fatLoss
    case strength
    case endurance

    var displayName: String {
        switch self {
        case .fatLoss: "Fat Loss"
        case .strength: "Strength"
        case .endurance: "Endurance"
        }
    }

    var icon: String {
        switch self {
        case .fatLoss: "flame.fill"
        case .strength: "figure.strengthtraining.traditional"
        case .endurance: "figure.run"
        }
    }
}

enum InjuryFlag: String, Codable, CaseIterable {
    case lowerBack
    case knees
    case shoulders
    case wrists
    case ankles
    case neck
    case none

    var displayName: String {
        switch self {
        case .lowerBack: "Lower Back"
        case .knees: "Knees"
        case .shoulders: "Shoulders"
        case .wrists: "Wrists"
        case .ankles: "Ankles"
        case .neck: "Neck"
        case .none: "None"
        }
    }
}

@Model
final class UserProfile {
    var fitnessLevel: FitnessLevel
    var primaryGoal: TrainingGoal
    var trainingDaysPerWeek: Int
    var injuries: [InjuryFlag]
    var onboardingComplete: Bool
    var createdAt: Date
    var updatedAt: Date

    // Weekly adaptation preferences
    var adaptationDay: Int // 1=Sunday, 2=Monday, etc.

    // HealthKit signal toggles
    var useHeartRateRecovery: Bool
    var useHRV: Bool
    var useSleepData: Bool

    init(
        fitnessLevel: FitnessLevel = .beginner,
        primaryGoal: TrainingGoal = .strength,
        trainingDaysPerWeek: Int = 3,
        injuries: [InjuryFlag] = [.none],
        onboardingComplete: Bool = false
    ) {
        self.fitnessLevel = fitnessLevel
        self.primaryGoal = primaryGoal
        self.trainingDaysPerWeek = trainingDaysPerWeek
        self.injuries = injuries
        self.onboardingComplete = onboardingComplete
        self.createdAt = Date()
        self.updatedAt = Date()
        self.adaptationDay = 1
        self.useHeartRateRecovery = false
        self.useHRV = false
        self.useSleepData = false
    }

    var hasInjuries: Bool {
        !injuries.contains(.none) && !injuries.isEmpty
    }
}
