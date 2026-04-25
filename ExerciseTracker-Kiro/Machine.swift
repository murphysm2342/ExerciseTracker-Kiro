import Foundation
import SwiftData

@Model final class Machine {
    @Attribute(.unique) var id: UUID
    var name: String
    var category: String?
    var isFavorite: Bool
    var lastUsedWeight: Double?
    var lastUsedReps: Int?
    @Relationship var user: User

    init(
        id: UUID = UUID(),
        name: String,
        category: String? = nil,
        isFavorite: Bool = false,
        lastUsedWeight: Double? = nil,
        lastUsedReps: Int? = nil,
        user: User
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.isFavorite = isFavorite
        self.lastUsedWeight = lastUsedWeight
        self.lastUsedReps = lastUsedReps
        self.user = user
    }
}
