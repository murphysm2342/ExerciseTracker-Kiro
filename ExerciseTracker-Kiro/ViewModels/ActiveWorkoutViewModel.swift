import Foundation
import SwiftData
import Observation

/// Manages a single strength WorkoutSession for the current day.
/// Multiple machines can be added to the same session.
/// Requirements: 3.1, 6 (one session per day)
@Observable final class ActiveWorkoutViewModel {

    // MARK: - State

    /// The single WorkoutSession for today (created or resumed on init).
    private(set) var session: WorkoutSession

    /// All machines that have at least one set in this session, in order first added.
    var machinesInSession: [Machine] {
        let seen = NSMutableOrderedSet()
        for set in session.strengthSets.sorted(by: { $0.setNumber < $1.setNumber }) {
            seen.add(set.machine)
        }
        return seen.array as? [Machine] ?? []
    }

    // MARK: - Dependencies

    private let modelContext: ModelContext
    private let user: User

    // MARK: - Init

    init(modelContext: ModelContext, user: User, date: Date = Date()) {
        self.modelContext = modelContext
        self.user = user

        let userId = user.id
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate {
                $0.user.id == userId &&
                $0.date >= startOfDay &&
                $0.date < endOfDay
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        let todaysSessions = (try? modelContext.fetch(descriptor)) ?? []
        let existing = todaysSessions.first(where: { $0.type == .strength })

        if let existing {
            self.session = existing
        } else {
            let newSession = WorkoutSession(date: date, type: .strength, user: user)
            modelContext.insert(newSession)
            try? modelContext.save()
            self.session = newSession
        }
    }

    // MARK: - Helpers

    /// Returns all sets for a given machine in this session, sorted by setNumber.
    func sets(for machine: Machine) -> [StrengthSet] {
        session.strengthSets
            .filter { $0.machine.id == machine.id }
            .sorted { $0.setNumber < $1.setNumber }
    }

    /// Saves the current context state.
    func save() throws {
        try modelContext.save()
    }
}
