import Foundation
import SwiftData

@Model final class User {
    @Attribute(.unique) var id: UUID
    var name: String
    var colorTag: String?
    var createdAt: Date
    var usesHealthKit: Bool
    var preferredCardioSource: CardioSource
    @Relationship(deleteRule: .cascade) var machines: [Machine]
    @Relationship(deleteRule: .cascade) var workoutSessions: [WorkoutSession]
    @Relationship(deleteRule: .cascade) var workoutFlows: [WorkoutFlow]

    init(
        id: UUID = UUID(),
        name: String,
        colorTag: String? = nil,
        createdAt: Date = Date(),
        usesHealthKit: Bool = false,
        preferredCardioSource: CardioSource = .manual
    ) {
        self.id = id
        self.name = name
        self.colorTag = colorTag
        self.createdAt = createdAt
        self.usesHealthKit = usesHealthKit
        self.preferredCardioSource = preferredCardioSource
        self.machines = []
        self.workoutSessions = []
        self.workoutFlows = []
    }
}
