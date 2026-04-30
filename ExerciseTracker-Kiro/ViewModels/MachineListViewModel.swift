import Foundation
import SwiftData

enum MachineListViewModelError: Error {
    case invalidName
}

@Observable class MachineListViewModel {
    /// Machines scoped to the active user: favorites first, then alphabetical (Req 2.1, 2.2)
    var machines: [Machine] = []

    private var modelContext: ModelContext
    private var user: User
    private let flowService: any WorkoutFlowServiceProtocol

    init(modelContext: ModelContext, user: User) {
        self.modelContext = modelContext
        self.user = user
        self.flowService = WorkoutFlowService(modelContext: modelContext)
        fetchMachines()
    }

    // MARK: - Fetch

    func fetchMachines() {
        let userId = user.id
        let descriptor = FetchDescriptor<Machine>()
        let all = (try? modelContext.fetch(descriptor)) ?? []
        // Scope to active user, then sort: favorites first, then alphabetical
        machines = all
            .filter { $0.user.id == userId }
            .sorted { lhs, rhs in
                if lhs.isFavorite != rhs.isFavorite {
                    return lhs.isFavorite && !rhs.isFavorite
                }
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
    }

    // MARK: - Add (Req 2.3)

    func addMachine(name: String, category: String?, isFavorite: Bool) throws {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            throw MachineListViewModelError.invalidName
        }
        let machine = Machine(name: trimmed, category: category, isFavorite: isFavorite, user: user)
        modelContext.insert(machine)
        try modelContext.save()
        fetchMachines()
    }

    // MARK: - Update (Req 2.4)

    func updateMachine(_ machine: Machine, name: String, category: String?, isFavorite: Bool) throws {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            throw MachineListViewModelError.invalidName
        }
        machine.name = trimmed
        machine.category = category
        machine.isFavorite = isFavorite
        try modelContext.save()
        fetchMachines()
    }

    // MARK: - Delete (Req 2.5, 7.5)

    func deleteMachine(_ machine: Machine) throws {
        // Remove this machine from all WorkoutFlows that reference it (Req 7.5)
        flowService.removeMachine(machine, fromAllFlowsOf: user)
        modelContext.delete(machine)
        try modelContext.save()
        fetchMachines()
    }

    // MARK: - Toggle Favorite (Req 2.6)

    func toggleFavorite(_ machine: Machine) {
        machine.isFavorite.toggle()
        do {
            try modelContext.save()
            print("✅ Toggled favorite for \(machine.name): \(machine.isFavorite)")
        } catch {
            print("❌ Failed to save favorite toggle: \(error)")
            // Revert on error
            machine.isFavorite.toggle()
        }
        fetchMachines()
    }
}
