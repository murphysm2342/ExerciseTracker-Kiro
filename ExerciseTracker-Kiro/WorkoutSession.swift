import Foundation
import SwiftData

@Model final class WorkoutSession {
    @Attribute(.unique) var id: UUID
    var date: Date
    var type: WorkoutType
    @Relationship var user: User
    @Relationship(deleteRule: .cascade) var strengthSets: [StrengthSet]
    @Relationship(deleteRule: .cascade) var cardioSession: CardioSession?

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        type: WorkoutType,
        user: User
    ) {
        self.id = id
        self.date = date
        self.type = type
        self.user = user
        self.strengthSets = []
        self.cardioSession = nil
    }
}
