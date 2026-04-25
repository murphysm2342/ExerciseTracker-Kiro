import Foundation
import SwiftData

enum SettingsViewModelError: Error, LocalizedError {
    case invalidName
    case saveFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .invalidName:
            return "Name cannot be empty."
        case .saveFailed(let underlying):
            return "Save failed: \(underlying.localizedDescription)"
        }
    }
}

/// Manages settings persistence for the active user.
/// Requirements: 6.1, 6.2, 12.1, 12.2, 12.3, 12.5
@Observable class SettingsViewModel {
    private let modelContext: ModelContext
    private let healthKitService: HealthKitServiceProtocol

    init(modelContext: ModelContext, healthKitService: HealthKitServiceProtocol = HealthKitService()) {
        self.modelContext = modelContext
        self.healthKitService = healthKitService
    }

    /// Persists name, colorTag, usesHealthKit, and cardioSource for the given user.
    /// Req 12.2, 12.3, 12.5
    func saveUserPreferences(
        for user: User,
        name: String,
        colorTag: String?,
        usesHealthKit: Bool,
        cardioSource: CardioSource
    ) throws {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            throw SettingsViewModelError.invalidName
        }
        user.name = trimmed
        user.colorTag = colorTag
        user.usesHealthKit = usesHealthKit
        user.preferredCardioSource = cardioSource
        do {
            try modelContext.save()
        } catch {
            throw SettingsViewModelError.saveFailed(underlying: error)
        }
    }

    /// Requests HealthKit permissions. Called when the user enables the HealthKit toggle.
    /// Req 6.2
    func requestHealthKitPermissions() async throws {
        try await healthKitService.requestPermissions()
    }
}
