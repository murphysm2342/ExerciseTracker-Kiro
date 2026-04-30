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

/// Manages sets for a single machine within an existing WorkoutSession.
/// Requirements: 3.1–3.9, 10.3–10.6
@Observable final class StrengthLoggingViewModel {

    // MARK: - State

    var sets: [StrengthSet] = []
    var activeFieldTarget: FieldTarget?

    /// String buffers for the number pad. Key: set UUID.
    var fieldBuffers: [UUID: (weight: String, reps: String)] = [:]

    /// Tracks which fields have been "touched" so we can clear the 0 on first tap. (Fix #5)
    private var touchedFields: Set<String> = []

    // MARK: - Dependencies

    private let modelContext: ModelContext
    let machine: Machine
    private let user: User
    private let machineDefaultsService: MachineDefaultsServiceProtocol
    private let healthKitService: HealthKitServiceProtocol

    /// The existing WorkoutSession this machine's sets belong to.
    private let session: WorkoutSession

    // MARK: - Init

    init(
        modelContext: ModelContext,
        machine: Machine,
        user: User,
        session: WorkoutSession,
        machineDefaultsService: MachineDefaultsServiceProtocol = MachineDefaultsService(),
        healthKitService: HealthKitServiceProtocol = HealthKitService()
    ) {
        self.modelContext = modelContext
        self.machine = machine
        self.user = user
        self.session = session
        self.machineDefaultsService = machineDefaultsService
        self.healthKitService = healthKitService

        print("🏋️ Initializing StrengthLoggingViewModel for machine: \(machine.name)")
        print("🏋️ Session ID: \(session.id)")

        // Load existing sets for this machine in this session, or create the first one.
        let existing = session.strengthSets
            .filter { $0.machine.id == machine.id }
            .sorted { $0.setNumber < $1.setNumber }

        if existing.isEmpty {
            print("🏋️ No existing sets found, creating first set")
            // New machine in this session — pre-fill from defaults (Req 3.6)
            let defaults = machineDefaultsService.lastUsedDefaults(for: machine)
            let firstSet = StrengthSet(
                setNumber: 1,
                weight: defaults?.weight ?? 0,
                reps: defaults?.reps ?? 10,
                machine: machine,
                session: session
            )
            modelContext.insert(firstSet)
            print("🏋️ Created first set with weight: \(firstSet.weight), reps: \(firstSet.reps)")
            self.sets = [firstSet]
            self.fieldBuffers[firstSet.id] = (
                weight: Self.formatDouble(defaults?.weight ?? 0),
                reps: "\(defaults?.reps ?? 10)"
            )
            // Auto-focus weight field on first set
            self.activeFieldTarget = .weight(setID: firstSet.id)
        } else {
            print("🏋️ Found \(existing.count) existing sets")
            self.sets = existing
            for set in existing {
                self.fieldBuffers[set.id] = (
                    weight: Self.formatDouble(set.weight),
                    reps: "\(set.reps)"
                )
            }
            // Auto-focus weight field on last set
            if let lastSet = existing.last {
                self.activeFieldTarget = .weight(setID: lastSet.id)
            }
        }
    }

    // MARK: - Field Activation (Fix #5: clear on first tap)

    func activateField(_ target: FieldTarget) {
        let setID = targetSetID(target)
        let key = fieldKey(target, setID: setID)

        // If this field hasn't been touched yet, clear the buffer so typing replaces the 0
        if !touchedFields.contains(key) {
            touchedFields.insert(key)
            switch target {
            case .weight:
                fieldBuffers[setID, default: ("", "")].weight = ""
            case .reps:
                fieldBuffers[setID, default: ("", "")].reps = ""
            }
        }
        activeFieldTarget = target
    }

    private func fieldKey(_ target: FieldTarget, setID: UUID) -> String {
        switch target {
        case .weight: return "w-\(setID)"
        case .reps:   return "r-\(setID)"
        }
    }

    // MARK: - Session Actions

    /// Adds a new set, using the last set's current weight/reps (Fix #11).
    func addSet() {
        // Use the last set's current values, not machine defaults
        let lastWeight = sets.last?.weight ?? machineDefaultsService.lastUsedDefaults(for: machine)?.weight ?? 0
        let lastReps   = sets.last?.reps   ?? machineDefaultsService.lastUsedDefaults(for: machine)?.reps   ?? 10

        let nextNumber = (sets.last?.setNumber ?? 0) + 1
        let newSet = StrengthSet(
            setNumber: nextNumber,
            weight: lastWeight,
            reps: lastReps,
            machine: machine,
            session: session
        )
        modelContext.insert(newSet)
        sets.append(newSet)
        fieldBuffers[newSet.id] = (
            weight: Self.formatDouble(lastWeight),
            reps: "\(lastReps)"
        )
        // Auto-focus weight field of new set; mark as untouched so first digit clears it
        activeFieldTarget = .weight(setID: newSet.id)
        // #14: persist immediately so sets aren't lost if app is backgrounded
        try? modelContext.save()
    }

    func adjustReps(for setID: UUID, by amount: Int) {
        guard let index = sets.firstIndex(where: { $0.id == setID }) else { return }
        let newValue = max(0, sets[index].reps + amount)
        sets[index].reps = newValue
        fieldBuffers[setID, default: ("", "")].reps = "\(newValue)"
        try? modelContext.save()
    }

    func deleteSet(_ set: StrengthSet) {
        guard let idx = sets.firstIndex(where: { $0.id == set.id }) else { return }
        modelContext.delete(sets[idx])
        sets.remove(at: idx)
        fieldBuffers.removeValue(forKey: set.id)
        // Renumber remaining sets
        for i in sets.indices {
            sets[i].setNumber = i + 1
        }
        try? modelContext.save()  // #14
    }

    /// Saves sets to the session. All sets are automatically marked as completed.
    /// If user has HealthKit sync enabled, also exports to HealthKit (Task 7).
    func saveSession() throws {
        // Auto-complete all sets before saving
        for i in sets.indices {
            if !sets[i].isCompleted {
                sets[i].isCompleted = true
            }
        }
        try persistSession()
        
        // Task 7: Export to HealthKit if enabled
        if user.syncToHealthKit {
            // Get all strength sets for this session
            let allSets = session.strengthSets.sorted { $0.setNumber < $1.setNumber }
            Task {
                do {
                    try await healthKitService.exportStrengthWorkout(
                        startDate: session.date,
                        sets: allSets
                    )
                    print("✅ Exported strength workout to HealthKit")
                } catch {
                    print("⚠️ Failed to export to HealthKit: \(error)")
                    // Don't throw - the workout was still saved locally
                }
            }
        }
    }

    // MARK: - NumberPad Routing

    func handleNumberPadAction(_ action: NumberPadAction) {
        switch action {
        case .digit(let d):     appendDigit(d)
        case .delete:           deleteLastDigit()
        case .increment(let n): increment(by: n)
        }
    }

    func appendDigit(_ digit: Int) {
        guard let target = activeFieldTarget else { return }
        let setID = targetSetID(target)
        let key = fieldKey(target, setID: setID)

        if !touchedFields.contains(key) {
            touchedFields.insert(key)
            switch target {
            case .weight: fieldBuffers[setID, default: ("", "")].weight = ""
            case .reps:   fieldBuffers[setID, default: ("", "")].reps = ""
            }
        }

        var buf = fieldBuffers[setID] ?? ("", "")
        switch target {
        case .weight: buf.weight += "\(digit)"
        case .reps:   buf.reps   += "\(digit)"
        }
        fieldBuffers[setID] = buf
        applyBuffer(for: target, setID: setID, buffer: buf)
        try? modelContext.save()  // #14
    }

    func deleteLastDigit() {
        guard let target = activeFieldTarget else { return }
        let setID = targetSetID(target)
        touchedFields.insert(fieldKey(target, setID: setID))
        var buf = fieldBuffers[setID] ?? ("", "")
        switch target {
        case .weight: if !buf.weight.isEmpty { buf.weight.removeLast() }
        case .reps:   if !buf.reps.isEmpty   { buf.reps.removeLast()   }
        }
        fieldBuffers[setID] = buf
        applyBuffer(for: target, setID: setID, buffer: buf)
        try? modelContext.save()  // #14
    }

    func increment(by amount: Int) {
        guard let target = activeFieldTarget,
              let setIndex = sets.firstIndex(where: { $0.id == targetSetID(target) }) else { return }
        let setID = sets[setIndex].id
        touchedFields.insert(fieldKey(target, setID: setID))
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
        try? modelContext.save()  // #14
    }

    // MARK: - Private Helpers

    private func persistSession() throws {
        print("💾 Attempting to save workout session...")
        print("💾 Session has \(session.strengthSets.count) total sets")
        print("💾 This machine (\(machine.name)) has \(sets.count) sets")
        
        for (index, set) in sets.enumerated() {
            print("💾   Set \(index + 1): \(set.weight)lbs × \(set.reps) reps, completed: \(set.isCompleted)")
        }
        
        do {
            try modelContext.save()
            print("✅ Successfully saved workout session!")
            
            // Update machine defaults from the last set (Req 3.9)
            if let lastSet = sets.last {
                machineDefaultsService.updateDefaults(
                    for: machine,
                    weight: lastSet.weight,
                    reps: lastSet.reps
                )
                print("✅ Updated defaults for \(machine.name): \(lastSet.weight)lbs × \(lastSet.reps) reps")
            }
        } catch {
            print("❌ SAVE FAILED: \(error)")
            throw error
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
        case .weight: sets[setIndex].weight = Double(buffer.weight) ?? 0
        case .reps:   sets[setIndex].reps   = Int(buffer.reps)   ?? 0
        }
    }

    static func formatDouble(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(value))"
            : "\(value)"
    }
}
