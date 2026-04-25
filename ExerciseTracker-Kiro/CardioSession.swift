import Foundation
import SwiftData

@Model final class CardioSession {
    @Attribute(.unique) var id: UUID
    var durationMinutes: Double
    var distanceMiles: Double?
    var incline: Double?
    var avgHeartRate: Double?
    var healthKitWorkoutId: UUID?
    @Relationship var session: WorkoutSession

    init(
        id: UUID = UUID(),
        durationMinutes: Double,
        distanceMiles: Double? = nil,
        incline: Double? = nil,
        avgHeartRate: Double? = nil,
        healthKitWorkoutId: UUID? = nil,
        session: WorkoutSession
    ) {
        self.id = id
        self.durationMinutes = durationMinutes
        self.distanceMiles = distanceMiles
        self.incline = incline
        self.avgHeartRate = avgHeartRate
        self.healthKitWorkoutId = healthKitWorkoutId
        self.session = session
    }
}
