import Foundation
import SwiftData

@Model final class User {
    @Attribute(.unique) var id: UUID
    var name: String
    var colorTag: String?
    var createdAt: Date
    var preferredCardioSource: CardioSource
    /// Whether to allow importing cardio workouts from HealthKit
    var usesHealthKit: Bool
    /// Task 7: Whether to automatically export/sync workouts TO HealthKit
    var syncToHealthKit: Bool
    var favoriteCardioTypes: [String] = []

    @Relationship(deleteRule: .cascade, inverse: \Machine.user) var machines: [Machine]
    @Relationship(deleteRule: .cascade, inverse: \WorkoutSession.user) var workoutSessions: [WorkoutSession]

    init(
        id: UUID = UUID(),
        name: String,
        colorTag: String? = nil,
        createdAt: Date = Date(),
        preferredCardioSource: CardioSource = .manual,
        usesHealthKit: Bool = false,
        syncToHealthKit: Bool = false,
        favoriteCardioTypes: [String] = []
    ) {
        self.id = id
        self.name = name
        self.colorTag = colorTag
        self.createdAt = createdAt
        self.preferredCardioSource = preferredCardioSource
        self.usesHealthKit = usesHealthKit
        self.syncToHealthKit = syncToHealthKit
        self.favoriteCardioTypes = favoriteCardioTypes
        self.machines = []
        self.workoutSessions = []
    }
}
