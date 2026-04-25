import Foundation
import HealthKit
import SwiftData

// MARK: - DEVELOPER NOTE
// Before using HealthKit, you must:
// 1. Add the HealthKit capability in Xcode (target → Signing & Capabilities → + HealthKit)
// 2. Add NSHealthShareUsageDescription to Info.plist with a user-facing explanation string

// MARK: - HealthKitError

enum HealthKitError: Error, LocalizedError {
    case permissionDenied
    case fetchFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "HealthKit access was denied. Please enable it in Settings > Privacy > Health."
        case .fetchFailed(let underlying):
            return "Failed to fetch workouts: \(underlying.localizedDescription)"
        }
    }
}

// MARK: - HealthKitServiceProtocol

protocol HealthKitServiceProtocol {
    func requestPermissions() async throws
    func fetchRecentWorkouts(limit: Int) async throws -> [HKWorkout]
    func mapToCardioSession(_ workout: HKWorkout, session: WorkoutSession) async -> CardioSession
}

// MARK: - HealthKitService

/// Concrete implementation of HealthKitServiceProtocol.
/// Requirements: 5.1, 5.2, 5.3
final class HealthKitService: HealthKitServiceProtocol {

    private let store = HKHealthStore()

    private var readTypes: Set<HKObjectType> {
        var types: Set<HKObjectType> = [HKObjectType.workoutType()]
        if let heartRate = HKObjectType.quantityType(forIdentifier: .heartRate) {
            types.insert(heartRate)
        }
        if let distance = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning) {
            types.insert(distance)
        }
        if let cyclingDistance = HKObjectType.quantityType(forIdentifier: .distanceCycling) {
            types.insert(cyclingDistance)
        }
        return types
    }

    // MARK: - Req 5.1: Request permissions

    func requestPermissions() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.permissionDenied
        }

        do {
            try await store.requestAuthorization(toShare: [], read: readTypes)
        } catch {
            throw HealthKitError.permissionDenied
        }

        // Verify at least workout type is authorized
        let status = store.authorizationStatus(for: HKObjectType.workoutType())
        if status == .sharingDenied {
            throw HealthKitError.permissionDenied
        }
    }

    // MARK: - Req 5.2: Fetch recent workouts

    func fetchRecentWorkouts(limit: Int) async throws -> [HKWorkout] {
        let predicate = HKQuery.predicateForWorkouts(with: .greaterThanOrEqualTo, duration: 0)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: HKObjectType.workoutType(),
                predicate: predicate,
                limit: limit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: HealthKitError.fetchFailed(underlying: error))
                    return
                }
                let workouts = (samples as? [HKWorkout]) ?? []
                continuation.resume(returning: workouts)
            }
            store.execute(query)
        }
    }

    // MARK: - Req 5.3: Map HKWorkout → CardioSession

    func mapToCardioSession(_ workout: HKWorkout, session: WorkoutSession) async -> CardioSession {
        let durationMinutes = workout.duration / 60.0

        // Distance: prefer running/walking, fall back to cycling
        var distanceMiles: Double? = nil
        if let distanceStat = workout.statistics(for: HKQuantityType(.distanceWalkingRunning)) {
            distanceMiles = distanceStat.sumQuantity()?.doubleValue(for: .mile())
        } else if let cyclingStat = workout.statistics(for: HKQuantityType(.distanceCycling)) {
            distanceMiles = cyclingStat.sumQuantity()?.doubleValue(for: .mile())
        }

        // Average heart rate
        var avgHeartRate: Double? = nil
        if let hrStat = workout.statistics(for: HKQuantityType(.heartRate)) {
            let beatsPerMinute = HKUnit.count().unitDivided(by: .minute())
            avgHeartRate = hrStat.averageQuantity()?.doubleValue(for: beatsPerMinute)
        }

        return CardioSession(
            durationMinutes: durationMinutes,
            distanceMiles: distanceMiles,
            incline: nil,
            avgHeartRate: avgHeartRate,
            healthKitWorkoutId: workout.uuid,
            session: session
        )
    }
}
