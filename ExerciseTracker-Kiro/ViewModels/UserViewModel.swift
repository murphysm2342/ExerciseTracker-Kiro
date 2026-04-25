import Foundation
import SwiftData

enum UserViewModelError: Error {
    case invalidName
}

@Observable class UserViewModel {
    var activeUser: User?
    var allUsers: [User] = []

    private var modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchUsers()
    }

    // MARK: - Fetch

    func fetchUsers() {
        let descriptor = FetchDescriptor<User>(sortBy: [SortDescriptor(\.createdAt)])
        allUsers = (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - Select

    func selectUser(_ user: User) {
        activeUser = user
    }

    // MARK: - Create

    func createUser(name: String, colorTag: String?) throws {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw UserViewModelError.invalidName
        }
        let user = User(name: name.trimmingCharacters(in: .whitespaces), colorTag: colorTag)
        modelContext.insert(user)
        try modelContext.save()
        fetchUsers()
    }

    // MARK: - Update

    func updateUser(_ user: User, name: String, colorTag: String?) throws {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw UserViewModelError.invalidName
        }
        user.name = name.trimmingCharacters(in: .whitespaces)
        user.colorTag = colorTag
        try modelContext.save()
        fetchUsers()
    }

    // MARK: - Delete

    func deleteUser(_ user: User) throws {
        if activeUser?.id == user.id {
            activeUser = nil
        }
        modelContext.delete(user)
        try modelContext.save()
        fetchUsers()
    }
}
