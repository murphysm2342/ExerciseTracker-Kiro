import Foundation
import SwiftData

@Observable class HistoryViewModel {
    var sessions: [WorkoutSession] = []
    var selectedDate: Date?
    var sessionsOnSelectedDate: [WorkoutSession] = []

    private var modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Refresh

    func refresh(for user: User) {
        let userId = user.id
        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.user.id == userId },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        sessions = (try? modelContext.fetch(descriptor)) ?? []
        updateSessionsOnSelectedDate()
    }

    // MARK: - Date selection

    func selectDate(_ date: Date?) {
        selectedDate = date
        updateSessionsOnSelectedDate()
    }

    private func updateSessionsOnSelectedDate() {
        guard let date = selectedDate else {
            sessionsOnSelectedDate = []
            return
        }
        let calendar = Calendar.current
        sessionsOnSelectedDate = sessions.filter {
            calendar.isDate($0.date, inSameDayAs: date)
        }
    }

    // MARK: - Recent session

    /// Returns the most recent WorkoutSession for the given user, or nil if none exist.
    func recentSession(for user: User) -> WorkoutSession? {
        let userId = user.id
        var descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.user.id == userId },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return (try? modelContext.fetch(descriptor))?.first
    }
}
