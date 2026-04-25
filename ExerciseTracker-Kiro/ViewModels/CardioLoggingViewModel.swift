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

/// Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 5.1–5.7
@Observable final class CardioLoggingViewModel {

    // MARK: - Manual entry fields

    var durationMinutes: Double = 0
    var distanceMiles: Double?
    var incline: Double?
    var avgHeartRate: Double?

    // MARK: - HealthKit state (Req 5.2, 5.6, 5.7)

    var healthKitWorkouts: [HKWorkout] = []
    var isLoadingHealthKit: Bool = false
    var healthKitError: Error?
    /// true when a fetch failed and a retry is possible (Req 5.6)
    var canRetry: Bool = false

    // MARK: - Dependencies

    private let modelContext: ModelContext
    private let user: User
    private let healthKitService: HealthKitServiceProtocol

    // MARK: - Init

    init(
        modelContext: ModelContext,
        user: User,
        healthKitService: HealthKitServiceProtocol = HealthKitService()
    ) {
        self.modelContext = modelContext
        self.user = user
        self.healthKitService = healthKitService
    }

    // MARK: - Manual Save (Req 4.2, 4.3)

    /// Validates duration > 0, then persists a CardioSession under a new WorkoutSession.
    /// Throws `.invalidDuration` if duration ≤ 0 (Req 4.2, 4.4).
    /// nil optional fields are saved as nil (Req 4.3).
    func saveManualSession() throws {
        guard durationMinutes > 0 else {
            throw CardioLoggingError.invalidDuration
        }

        let session = WorkoutSession(type: .cardio, user: user)
        modelContext.insert(session)

        let cardio = CardioSession(
            durationMinutes: durationMinutes,
            distanceMiles: distanceMiles,
            incline: incline,
            avgHeartRate: avgHeartRate,
            session: session
        )
        modelContext.insert(cardio)
        session.cardioSession = cardio

        try modelContext.save()
    }

    // MARK: - HealthKit: Fetch (Req 5.1, 5.2, 5.5, 5.6, 5.7)

    /// Requests permissions then fetches recent workouts.
    /// Sets isLoadingHealthKit during the operation (Req 5.7).
    /// On permission denial sets healthKitError (Req 5.5).
    /// On fetch failure sets healthKitError and canRetry = true (Req 5.6).
    func fetchHealthKitWorkouts() async {
        isLoadingHealthKit = true
        healthKitError = nil
        canRetry = false

        defer { isLoadingHealthKit = false }

        do {
            // Req 5.1 — request permissions before accessing data
            try await healthKitService.requestPermissions()
            // Req 5.2 — fetch recent workouts
            healthKitWorkouts = try await healthKitService.fetchRecentWorkouts(limit: 20)
        } catch let error as HealthKitError {
            healthKitError = error
            switch error {
            case .permissionDenied:
                // Req 5.5 — permission denied routes to manual entry (handled in view)
                canRetry = false
            case .fetchFailed:
                // Req 5.6 — fetch failure exposes retry option
                canRetry = true
            }
        } catch {
            healthKitError = HealthKitError.fetchFailed(underlying: error)
            canRetry = true
        }
    }

    // MARK: - HealthKit: Import (Req 5.3, 5.4)

    /// Maps an HKWorkout to a CardioSession and persists it.
    /// Silently skips if the workout has already been imported (Req 5.4).
    func importHealthKitWorkout(_ workout: HKWorkout) async throws {
        // Req 5.4 — duplicate detection: check existing CardioSessions for this user
        let workoutUUID = workout.uuid
        let existingSessions = user.workoutSessions
        let alreadyImported = existingSessions.compactMap(\.cardioSession).contains {
            $0.healthKitWorkoutId == workoutUUID
        }
        guard !alreadyImported else { return }

        // Req 5.3 — create a new WorkoutSession and map the HKWorkout
        let session = WorkoutSession(date: workout.startDate, type: .cardio, user: user)
        modelContext.insert(session)

        let cardio = await healthKitService.mapToCardioSession(workout, session: session)
        modelContext.insert(cardio)
        session.cardioSession = cardio

        try modelContext.save()
    }
}
