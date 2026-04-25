import Foundation

// MARK: - MachineDefaultsServiceProtocol

protocol MachineDefaultsServiceProtocol {
    /// Returns the last-used weight and reps for the given machine, or nil if none have been recorded.
    func lastUsedDefaults(for machine: Machine) -> (weight: Double, reps: Int)?

    /// Persists the supplied weight and reps as the last-used values on the machine model.
    func updateDefaults(for machine: Machine, weight: Double, reps: Int)
}

// MARK: - MachineDefaultsService

/// Concrete implementation that reads/writes `lastUsedWeight` and `lastUsedReps`
/// directly on the SwiftData `Machine` model.
///
/// Requirements 3.6, 3.9
final class MachineDefaultsService: MachineDefaultsServiceProtocol {

    // MARK: MachineDefaultsServiceProtocol

    /// Returns the stored last-used defaults for `machine`, or `nil` if either
    /// `lastUsedWeight` or `lastUsedReps` has never been set.
    func lastUsedDefaults(for machine: Machine) -> (weight: Double, reps: Int)? {
        guard let weight = machine.lastUsedWeight,
              let reps = machine.lastUsedReps else {
            return nil
        }
        return (weight: weight, reps: reps)
    }

    /// Writes `weight` and `reps` back onto the machine model.
    /// SwiftData will pick up the mutation automatically on the next context save.
    func updateDefaults(for machine: Machine, weight: Double, reps: Int) {
        machine.lastUsedWeight = weight
        machine.lastUsedReps = reps
    }
}
