import Foundation
import SwiftData

@Model final class WorkoutFlow {
    @Attribute(.unique) var id: UUID
    var name: String
    var createdAt: Date
    var machineOrder: [UUID]
    @Relationship var user: User
    @Relationship var machines: [Machine]

    init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = Date(),
        machineOrder: [UUID] = [],
        user: User,
        machines: [Machine] = []
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.machineOrder = machineOrder
        self.user = user
        self.machines = machines
    }
}
