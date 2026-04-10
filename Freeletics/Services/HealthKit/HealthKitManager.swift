import Foundation
import HealthKit

// HEALTH-001: Write Completed Workouts
// HEALTH-002: Read Recovery Signals

final class HealthKitManager {
    static let shared = HealthKitManager()

    private let healthStore = HKHealthStore()

    private init() {}

    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    var isAuthorized: Bool {
        guard isAvailable else { return false }
        let workoutType = HKObjectType.workoutType()
        return healthStore.authorizationStatus(for: workoutType) == .sharingAuthorized
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        guard isAvailable else { return false }

        let readTypes: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
        ]

        let writeTypes: Set<HKSampleType> = [
            HKObjectType.workoutType(),
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
        ]

        do {
            try await healthStore.requestAuthorization(toShare: writeTypes, read: readTypes)
            return true
        } catch {
            print("HealthKit authorization failed: \(error)")
            return false
        }
    }

    // MARK: - HEALTH-001: Write Workout

    func saveWorkout(
        duration: TimeInterval,
        activeEnergy: Double,
        startDate: Date,
        endDate: Date
    ) async throws {
        let workout = HKWorkout(
            activityType: .functionalStrengthTraining,
            start: startDate,
            end: endDate,
            duration: duration,
            totalEnergyBurned: HKQuantity(unit: .kilocalorie(), doubleValue: activeEnergy),
            totalDistance: nil,
            metadata: [HKMetadataKeyWorkoutBrandName: "Freeletics"]
        )

        try await healthStore.save(workout)
    }

    // MARK: - HEALTH-002: Read Recovery Signals

    func fetchRestingHeartRate(for date: Date = Date()) async -> Double? {
        await fetchLatestQuantity(
            identifier: .restingHeartRate,
            unit: HKUnit.count().unitDivided(by: .minute()),
            date: date
        )
    }

    func fetchHRV(for date: Date = Date()) async -> Double? {
        await fetchLatestQuantity(
            identifier: .heartRateVariabilitySDNN,
            unit: .secondUnit(with: .milli),
            date: date
        )
    }

    func fetchSleepDuration(for date: Date = Date()) async -> TimeInterval? {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return nil }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay)
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.categorySample(type: sleepType, predicate: predicate)],
            sortDescriptors: [SortDescriptor(\.startDate, order: .reverse)]
        )

        do {
            let samples = try await descriptor.result(for: healthStore)
            // Sum asleep intervals
            let asleepSamples = samples.filter {
                $0.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                $0.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                $0.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue
            }
            let total = asleepSamples.reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
            return total > 0 ? total : nil
        } catch {
            return nil
        }
    }

    // MARK: - Helpers

    private func fetchLatestQuantity(
        identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        date: Date
    ) async -> Double? {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else { return nil }

        let predicate = HKQuery.predicateForSamples(
            withStart: Calendar.current.date(byAdding: .day, value: -1, to: date),
            end: date
        )
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: quantityType, predicate: predicate)],
            sortDescriptors: [SortDescriptor(\.startDate, order: .reverse)],
            limit: 1
        )

        do {
            let samples = try await descriptor.result(for: healthStore)
            return samples.first?.quantity.doubleValue(for: unit)
        } catch {
            return nil
        }
    }
}
