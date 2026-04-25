import Foundation
import SwiftData

// MARK: - Error

enum WorkoutFlowServiceError: Error {
    case invalidName
}

// MARK: - Protocol

/// Requirements: 7.1, 7.2, 7.3, 7.4, 7.5
protocol WorkoutFlowServiceProtocol {
    func createFlow(name: String, machines: [Machine], for user: User) throws -> WorkoutFlow
    func updateFlow(_ flow: WorkoutFlow, name: String, machines: [Machine]) throws
    func deleteFlow(_ flow: WorkoutFlow) throws
    func removeMachine(_ machine: Machine, fromAllFlowsOf user: User)
}

// MARK: - Concrete Implementation

/// Manages WorkoutFlow persistence and machine ordering.
///
/// `machineOrder: [UUID]` is written on every create/update so that
/// `machines` can be sorted back into the correct sequence on read,
/// since SwiftData does not guarantee relationship array ordering.
final class WorkoutFlowService: WorkoutFlowServiceProtocol {

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Create (Req 7.1, 7.2)

    func createFlow(name: String, machines: [Machine], for user: User) throws -> WorkoutFlow {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { throw WorkoutFlowServiceError.invalidName }

        let flow = WorkoutFlow(
            name: trimmed,
            machineOrder: machines.map(\.id),
            user: user,
            machines: machines
        )
        modelContext.insert(flow)
        try modelContext.save()
        return flow
    }

    // MARK: - Update (Req 7.3)

    func updateFlow(_ flow: WorkoutFlow, name: String, machines: [Machine]) throws {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { throw WorkoutFlowServiceError.invalidName }

        flow.name = trimmed
        flow.machines = machines
        flow.machineOrder = machines.map(\.id)
        try modelContext.save()
    }

    // MARK: - Delete (Req 7.4)

    /// Removes the flow from persistence. Does NOT delete the machines it referenced.
    func deleteFlow(_ flow: WorkoutFlow) throws {
        modelContext.delete(flow)
        try modelContext.save()
    }

    // MARK: - Remove Machine from All Flows (Req 7.5)

    /// Removes `machine` from every WorkoutFlow belonging to `user`.
    func removeMachine(_ machine: Machine, fromAllFlowsOf user: User) {
        let userId = user.id
        let descriptor = FetchDescriptor<WorkoutFlow>()
        let allFlows = (try? modelContext.fetch(descriptor)) ?? []
        let userFlows = allFlows.filter { $0.user.id == userId }

        for flow in userFlows {
            flow.machines.removeAll { $0.id == machine.id }
            flow.machineOrder.removeAll { $0 == machine.id }
        }
        try? modelContext.save()
    }

    // MARK: - Read Helper (Req 7.6)

    /// Returns the machines of `flow` sorted by `flow.machineOrder`.
    static func orderedMachines(for flow: WorkoutFlow) -> [Machine] {
        let lookup = Dictionary(uniqueKeysWithValues: flow.machines.map { ($0.id, $0) })
        return flow.machineOrder.compactMap { lookup[$0] }
    }
}
