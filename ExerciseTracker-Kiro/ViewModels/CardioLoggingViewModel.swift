import Foundation
import SwiftData
import HealthKit
import Observation

// MARK: - CardioLoggingError

enum CardioLoggingError: Error, LocalizedError {
    case invalidDuration

    var errorDescription: String? {
        switch self {
        case .invalidDuration:
            return "Duration must be greater than zero."
        }
    }
}

// MARK: - CardioLoggingViewModel

@Observable final class CardioLoggingViewModel {

    // MARK: - Entry fields

    var machineType: CardioMachineType = .treadmill
    var durationMinutes: Double = 0
    var distanceMiles: Double?
    var incline: Double?
    var avgHeartRate: Double?
    var resistance: Double?
    var floors: Int?
    var strides: Int?
    var strokeCount: Int?
    var speed: Double?
    var rpm: Double?

    // MARK: - HealthKit state

    var healthKitWorkouts: [HKWorkout] = []
    var isLoadingHealthKit: Bool = false
    var healthKitError: Error?
    var canRetry: Bool = false

    // MARK: - Dependencies

    private let modelContext: ModelContext
    private let user: User
    var workoutDate: Date
    private let healthKitService: HealthKitServiceProtocol

    // MARK: - Init

    init(
        modelContext: ModelContext,
        user: User,
        date: Date = Date(),
        machineType: CardioMachineType = .treadmill,
        healthKitService: HealthKitServiceProtocol = HealthKitService()
    ) {
        self.modelContext = modelContext
        self.user = user
        self.workoutDate = date
        self.machineType = machineType
        self.healthKitService = healthKitService
    }

    // MARK: - Manual Save

    func saveManualSession() throws {
        guard durationMinutes > 0 else {
            throw CardioLoggingError.invalidDuration
        }

        let session = WorkoutSession(date: workoutDate, type: .cardio, user: user)
        modelContext.insert(session)

        let cardio = CardioSession(
            durationMinutes: durationMinutes,
            distanceMiles: distanceMiles,
            incline: incline,
            avgHeartRate: avgHeartRate,
            machineType: machineType,
            resistance: resistance,
            floors: floors,
            strides: strides,
            strokeCount: strokeCount,
            speed: speed,
            rpm: rpm,
            session: session
        )
        modelContext.insert(cardio)
        session.cardioSession = cardio

        try modelContext.save()

        if user.syncToHealthKit {
            Task {
                do {
                    try await healthKitService.exportCardioWorkout(
                        startDate: session.date,
                        durationMinutes: durationMinutes,
                        distanceMiles: distanceMiles,
                        avgHeartRate: avgHeartRate
                    )
                } catch {
                    print("Failed to export to HealthKit: \(error)")
                }
            }
        }
    }

    // MARK: - HealthKit Fetch

    func fetchHealthKitWorkouts() async {
        isLoadingHealthKit = true
        healthKitError = nil
        canRetry = false
        defer { isLoadingHealthKit = false }

        do {
            try await healthKitService.requestPermissions()
            healthKitWorkouts = try await healthKitService.fetchRecentWorkouts(limit: 20)
        } catch let error as HealthKitError {
            healthKitError = error
            if case .fetchFailed = error {
                canRetry = true
            } else {
                canRetry = false
            }
        } catch {
            healthKitError = HealthKitError.fetchFailed(underlying: error)
            canRetry = true
        }
    }

    // MARK: - HealthKit Import

    func importHealthKitWorkout(_ workout: HKWorkout) async throws {
        let workoutUUID = workout.uuid
        let existingSessions = user.workoutSessions
        let alreadyImported = existingSessions.compactMap(\.cardioSession).contains {
            $0.healthKitWorkoutId == workoutUUID
        }
        guard !alreadyImported else { return }

        let session = WorkoutSession(date: workout.startDate, type: .cardio, user: user)
        modelContext.insert(session)

        let cardio = await healthKitService.mapToCardioSession(workout, session: session)
        modelContext.insert(cardio)
        session.cardioSession = cardio

        try modelContext.save()
    }
}
