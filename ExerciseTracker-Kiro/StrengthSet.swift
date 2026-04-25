import Foundation
import SwiftData

@Model final class StrengthSet {
    @Attribute(.unique) var id: UUID
    var setNumber: Int
    var weight: Double
    var reps: Int
    var isCompleted: Bool
    @Relationship var machine: Machine
    @Relationship var session: WorkoutSession

    init(
        id: UUID = UUID(),
        setNumber: Int,
        weight: Double = 0,
        reps: Int = 0,
        isCompleted: Bool = false,
        machine: Machine,
        session: WorkoutSession
    ) {
        self.id = id
        self.setNumber = setNumber
        self.weight = weight
        self.reps = reps
        self.isCompleted = isCompleted
        self.machine = machine
        self.session = session
    }
}
