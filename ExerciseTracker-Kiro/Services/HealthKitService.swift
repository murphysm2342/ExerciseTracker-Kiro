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
    case saveFailed(underlying: Error)
    case notAvailable

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "HealthKit access was denied. Please enable it in Settings > Privacy > Health."
        case .fetchFailed(let underlying):
            return "Failed to fetch workouts: \(underlying.localizedDescription)"
        case .saveFailed(let underlying):
            return "Failed to save workout to Health: \(underlying.localizedDescription)"
        case .notAvailable:
            return "HealthKit is not available on this device."
        }
    }
}

// MARK: - HealthKitServiceProtocol

protocol HealthKitServiceProtocol {
    // Import functionality
    func requestPermissions() async throws
    func fetchRecentWorkouts(limit: Int) async throws -> [HKWorkout]
    
    @MainActor
    func mapToCardioSession(_ workout: HKWorkout, session: WorkoutSession) async -> CardioSession
    
    // Export functionality (Task 7)
    func exportCardioWorkout(
        startDate: Date,
        durationMinutes: Double,
        distanceMiles: Double?,
        avgHeartRate: Double?
    ) async throws
    
    @MainActor
    func exportStrengthWorkout(
        startDate: Date,
        sets: [StrengthSet]
    ) async throws
}

// MARK: - HealthKitService

/// Concrete implementation of HealthKitServiceProtocol.
/// Requirements: 5.1, 5.2, 5.3, 7 (export)
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
    
    private var writeTypes: Set<HKSampleType> {
        var types: Set<HKSampleType> = [HKObjectType.workoutType()]
        if let heartRate = HKObjectType.quantityType(forIdentifier: .heartRate) {
            types.insert(heartRate)
        }
        if let distance = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning) {
            types.insert(distance)
        }
        if let cyclingDistance = HKObjectType.quantityType(forIdentifier: .distanceCycling) {
            types.insert(cyclingDistance)
        }
        if let activeEnergy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) {
            types.insert(activeEnergy)
        }
        return types
    }

    // MARK: - Req 5.1: Request permissions

    func requestPermissions() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        do {
            try await store.requestAuthorization(toShare: writeTypes, read: readTypes)
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

    @MainActor
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
    
    // MARK: - Task 7: Export to HealthKit
    
    func exportCardioWorkout(
        startDate: Date,
        durationMinutes: Double,
        distanceMiles: Double?,
        avgHeartRate: Double?
    ) async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }
        
        let endDate = startDate.addingTimeInterval(durationMinutes * 60)
        
        // Build the workout with metadata using HKWorkoutBuilder
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .other  // Using .other for general cardio
        configuration.locationType = .indoor  // Assume gym workouts are indoor
        
        let builder = HKWorkoutBuilder(healthStore: store, configuration: configuration, device: .local())
        
        // Start building the workout
        try await builder.beginCollection(at: startDate)
        
        // Add heart rate sample if available
        if let hr = avgHeartRate {
            let hrType = HKQuantityType(.heartRate)
            let hrQuantity = HKQuantity(unit: .count().unitDivided(by: .minute()), doubleValue: hr)
            let hrSample = HKQuantitySample(
                type: hrType,
                quantity: hrQuantity,
                start: startDate,
                end: endDate
            )
            try await builder.addSamples([hrSample])
        }
        
        // Add distance if available
        if let distance = distanceMiles {
            let distanceType = HKQuantityType(.distanceWalkingRunning)
            let distanceQuantity = HKQuantity(unit: .mile(), doubleValue: distance)
            let distanceSample = HKQuantitySample(
                type: distanceType,
                quantity: distanceQuantity,
                start: startDate,
                end: endDate
            )
            try await builder.addSamples([distanceSample])
        }
        
        // End collection and finish workout
        try await builder.endCollection(at: endDate)
        try await builder.finishWorkout()
    }
    
    @MainActor
    func exportStrengthWorkout(
        startDate: Date,
        sets: [StrengthSet]
    ) async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }
        
        // Estimate duration based on sets (assume ~2 minutes per set)
        let estimatedDuration = TimeInterval(sets.count * 120)
        let endDate = startDate.addingTimeInterval(estimatedDuration)
        
        // Create workout using HKWorkoutBuilder
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .traditionalStrengthTraining
        configuration.locationType = .indoor
        
        let builder = HKWorkoutBuilder(healthStore: store, configuration: configuration, device: .local())
        
        // Start building the workout
        try await builder.beginCollection(at: startDate)
        
        // End collection and finish workout
        try await builder.endCollection(at: endDate)
        try await builder.finishWorkout()
    }
}
