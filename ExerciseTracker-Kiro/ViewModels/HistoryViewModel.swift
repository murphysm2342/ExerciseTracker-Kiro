import Foundation
import SwiftData

@Observable class HistoryViewModel {
    var sessions: [WorkoutSession] = []
    var selectedDate: Date?
    var sessionsOnSelectedDate: [WorkoutSession] = []
    var mostRecentSession: WorkoutSession?
    var workoutDayComponents: Set<DateComponents> = []

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
        let all = (try? modelContext.fetch(descriptor)) ?? []

        // #10: Deduplicate — keep only one strength session per day (the most recent).
        // Multiple strength sessions on the same day are merged into the latest one.
        sessions = deduplicatedSessions(all)
        mostRecentSession = sessions.first

        let calendar = Calendar.current
        workoutDayComponents = Set(sessions.map {
            calendar.dateComponents([.year, .month, .day], from: $0.date)
        })

        if selectedDate == nil {
            selectedDate = Date()
        }
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

    // MARK: - Deduplication (#10)

    /// For each day, keep only one strength session (the most recent) and all cardio sessions.
    /// This prevents the "empty + real" duplicate that appeared when each machine created its own session.
    private func deduplicatedSessions(_ all: [WorkoutSession]) -> [WorkoutSession] {
        let calendar = Calendar.current
        var result: [WorkoutSession] = []
        var strengthByDay: [DateComponents: WorkoutSession] = [:]

        for session in all {
            switch session.type {
            case .cardio:
                result.append(session)
            case .strength:
                let day = calendar.dateComponents([.year, .month, .day], from: session.date)
                // Keep the one with the most sets (most complete), falling back to most recent
                if let existing = strengthByDay[day] {
                    let existingSets = existing.strengthSets.count
                    let newSets = session.strengthSets.count
                    if newSets > existingSets {
                        strengthByDay[day] = session
                    }
                } else {
                    strengthByDay[day] = session
                }
            }
        }

        result.append(contentsOf: strengthByDay.values)
        return result.sorted { $0.date > $1.date }
    }

    // MARK: - Recent session

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
