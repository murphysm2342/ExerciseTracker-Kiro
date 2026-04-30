import Foundation
import SwiftData

@Model final class Machine {
    @Attribute(.unique) var id: UUID
    var name: String
    var category: String?
    var isFavorite: Bool
    var lastUsedWeight: Double?
    var lastUsedReps: Int?
    var nfcTagId: String?
    @Relationship var user: User

    init(
        id: UUID = UUID(),
        name: String,
        category: String? = nil,
        isFavorite: Bool = false,
        lastUsedWeight: Double? = nil,
        lastUsedReps: Int? = nil,
        nfcTagId: String? = nil,
        user: User
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.isFavorite = isFavorite
        self.lastUsedWeight = lastUsedWeight
        self.lastUsedReps = lastUsedReps
        self.nfcTagId = nfcTagId
        self.user = user
    }
}
