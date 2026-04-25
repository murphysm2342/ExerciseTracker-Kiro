import Foundation
import SwiftData
import Observation

// MARK: - FieldTarget

/// Identifies which field (weight or reps) on which set is currently active.
enum FieldTarget: Equatable {
    case weight(setID: UUID)
    case reps(setID: UUID)
}

// MARK: - StrengthLoggingViewModel

/// Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8, 3.9, 10.3, 10.4, 10.5, 10.6
@Observable final class StrengthLoggingViewModel {

    // MARK: - State

    var sets: [StrengthSet] = []
    var activeFieldTarget: FieldTarget?

    /// Exposed when saving with zero completed sets (Req 3.8)
    var requiresConfirmation: Bool = false

    /// Internal string buffers for the active field (used by number pad)
    /// Key: set UUID, Value: (weightString, repsString)
    var fieldBuffers: [UUID: (weight: String, reps: String)] = [:]

    // MARK: - Dependencies

    private let modelContext: ModelContext
    private let machine: Machine
    private let user: User
    private let machineDefaultsService: MachineDefaultsServiceProtocol

    /// The in-progress WorkoutSession created when the view model is initialized.
    private let session: WorkoutSession

    // MARK: - Init

    init(
        modelContext: ModelContext,
        machine: Machine,
        user: User,
        machineDefaultsService: MachineDefaultsServiceProtocol = MachineDefaultsService()
    ) {
        self.modelContext = modelContext
        self.machine = machine
        self.user = user
        self.machineDefaultsService = machineDefaultsService

        // Create the WorkoutSession immediately so sets can reference it
        let newSession = WorkoutSession(type: .strength, user: user)
        modelContext.insert(newSession)
        self.session = newSession

        // Start with one set pre-filled from defaults (Req 3.6)
        let defaults = machineDefaultsService.lastUsedDefaults(for: machine)
        let firstSet = StrengthSet(
            setNumber: 1,
            weight: defaults?.weight ?? 0,
            reps: defaults?.reps ?? 0,
            machine: machine,
            session: newSession
        )
        modelContext.insert(firstSet)
        self.sets = [firstSet]
        self.fieldBuffers[firstSet.id] = (
            weight: Self.formatDouble(defaults?.weight ?? 0),
            reps: "\(defaults?.reps ?? 0)"
        )
    }

    // MARK: - Session Actions

    /// Adds a new StrengthSet, auto-filling from MachineDefaultsService. (Req 3.6)
    func addSet() {
        let defaults = machineDefaultsService.lastUsedDefaults(for: machine)
        let nextNumber = (sets.last?.setNumber ?? 0) + 1
        let newSet = StrengthSet(
            setNumber: nextNumber,
            weight: defaults?.weight ?? 0,
            reps: defaults?.reps ?? 0,
            machine: machine,
            session: session
        )
        modelContext.insert(newSet)
        sets.append(newSet)
        fieldBuffers[newSet.id] = (
            weight: Self.formatDouble(defaults?.weight ?? 0),
            reps: "\(defaults?.reps ?? 0)"
        )
        // Auto-focus the weight field of the new set
        activeFieldTarget = .weight(setID: newSet.id)
    }

    /// Updates the weight value for a specific set.
    func updateWeight(_ set: StrengthSet, value: Double) {
        guard let idx = sets.firstIndex(where: { $0.id == set.id }) else { return }
        sets[idx].weight = value
        fieldBuffers[set.id, default: ("", "")].weight = Self.formatDouble(value)
    }

    /// Updates the reps value for a specific set.
    func updateReps(_ set: StrengthSet, value: Int) {
        guard let idx = sets.firstIndex(where: { $0.id == set.id }) else { return }
        sets[idx].reps = value
        fieldBuffers[set.id, default: ("", "")].reps = "\(value)"
    }

    /// Marks a set as completed (Req 3.5).
    func completeSet(_ set: StrengthSet) {
        guard let idx = sets.firstIndex(where: { $0.id == set.id }) else { return }
        sets[idx].isCompleted.toggle()
    }

    /// Saves the session and all sets. Sets requiresConfirmation if no sets are completed (Req 3.8).
    /// On save, updates MachineDefaultsService with the last set's values (Req 3.9).
    func saveSession() throws {
        let completedCount = sets.filter { $0.isCompleted }.count
        if completedCount == 0 {
            requiresConfirmation = true
            return
        }
        try persistSession()
    }

    /// Force-saves even with zero completed sets (called after user confirms).
    func confirmSave() throws {
        requiresConfirmation = false
        try persistSession()
    }

    // MARK: - NumberPad Routing

    func handleNumberPadAction(_ action: NumberPadAction) {
        switch action {
        case .digit(let d):     appendDigit(d)
        case .delete:           deleteLastDigit()
        case .increment(let n): increment(by: n)
        }
    }

    // MARK: - NumberPad Logic (Req 10.3, 10.4, 10.5, 10.6)

    func appendDigit(_ digit: Int) {
        guard let target = activeFieldTarget else { return }
        let setID = targetSetID(target)
        var buf = fieldBuffers[setID] ?? ("", "")
        switch target {
        case .weight:
            buf.weight += "\(digit)"
        case .reps:
            buf.reps += "\(digit)"
        }
        fieldBuffers[setID] = buf
        applyBuffer(for: target, setID: setID, buffer: buf)
    }

    func deleteLastDigit() {
        guard let target = activeFieldTarget else { return }
        let setID = targetSetID(target)
        var buf = fieldBuffers[setID] ?? ("", "")
        switch target {
        case .weight:
            if !buf.weight.isEmpty { buf.weight.removeLast() }
        case .reps:
            if !buf.reps.isEmpty { buf.reps.removeLast() }
        }
        fieldBuffers[setID] = buf
        applyBuffer(for: target, setID: setID, buffer: buf)
    }

    func increment(by amount: Int) {
        guard let target = activeFieldTarget,
              let setIndex = sets.firstIndex(where: { $0.id == targetSetID(target) }) else { return }
        let setID = sets[setIndex].id
        switch target {
        case .weight:
            let newValue = max(0, sets[setIndex].weight + Double(amount))
            sets[setIndex].weight = newValue
            fieldBuffers[setID, default: ("", "")].weight = Self.formatDouble(newValue)
        case .reps:
            let newValue = max(0, sets[setIndex].reps + amount)
            sets[setIndex].reps = newValue
            fieldBuffers[setID, default: ("", "")].reps = "\(newValue)"
        }
    }

    // MARK: - Private Helpers

    private func persistSession() throws {
        // Attach all sets to the session
        session.strengthSets = sets
        try modelContext.save()

        // Update machine defaults from the last set (Req 3.9)
        if let lastSet = sets.last {
            machineDefaultsService.updateDefaults(
                for: machine,
                weight: lastSet.weight,
                reps: lastSet.reps
            )
        }
    }

    private func targetSetID(_ target: FieldTarget) -> UUID {
        switch target {
        case .weight(let id): return id
        case .reps(let id):   return id
        }
    }

    private func applyBuffer(for target: FieldTarget, setID: UUID, buffer: (weight: String, reps: String)) {
        guard let setIndex = sets.firstIndex(where: { $0.id == setID }) else { return }
        switch target {
        case .weight:
            sets[setIndex].weight = Double(buffer.weight) ?? 0
        case .reps:
            sets[setIndex].reps = Int(buffer.reps) ?? 0
        }
    }

    static func formatDouble(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(value))"
            : "\(value)"
    }
}
