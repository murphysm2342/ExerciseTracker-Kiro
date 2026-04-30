import Foundation
import SwiftData

@Model final class CardioSession {
    @Attribute(.unique) var id: UUID
    var durationMinutes: Double
    var distanceMiles: Double?
    var incline: Double?
    var avgHeartRate: Double?
    var healthKitWorkoutId: UUID?
    var machineType: CardioMachineType?
    var resistance: Double?
    var floors: Int?
    var strides: Int?
    var strokeCount: Int?
    var speed: Double?
    var rpm: Double?
    @Relationship var session: WorkoutSession

    init(
        id: UUID = UUID(),
        durationMinutes: Double,
        distanceMiles: Double? = nil,
        incline: Double? = nil,
        avgHeartRate: Double? = nil,
        healthKitWorkoutId: UUID? = nil,
        machineType: CardioMachineType? = nil,
        resistance: Double? = nil,
        floors: Int? = nil,
        strides: Int? = nil,
        strokeCount: Int? = nil,
        speed: Double? = nil,
        rpm: Double? = nil,
        session: WorkoutSession
    ) {
        self.id = id
        self.durationMinutes = durationMinutes
        self.distanceMiles = distanceMiles
        self.incline = incline
        self.avgHeartRate = avgHeartRate
        self.healthKitWorkoutId = healthKitWorkoutId
        self.machineType = machineType
        self.resistance = resistance
        self.floors = floors
        self.strides = strides
        self.strokeCount = strokeCount
        self.speed = speed
        self.rpm = rpm
        self.session = session
    }
}
