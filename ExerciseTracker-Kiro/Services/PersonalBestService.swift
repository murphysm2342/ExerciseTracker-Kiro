import Foundation

struct PBAchievement: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let detail: String
}

enum PersonalBestService {

    /// Returns a PB if any set for `machine` in `session` beats the user's prior all-time max weight
    /// across all OTHER sessions. Only fires if the user has lifted this exercise before.
    static func checkStrengthPB(machine: Machine, session: WorkoutSession, user: User) -> PBAchievement? {
        let priorSets = user.workoutSessions
            .filter { $0.id != session.id }
            .flatMap(\.strengthSets)
            .filter { $0.machine.id == machine.id }

        guard !priorSets.isEmpty else { return nil }

        let priorMax = priorSets.map(\.weight).max() ?? 0

        let currentMax = session.strengthSets
            .filter { $0.machine.id == machine.id }
            .map(\.weight)
            .max() ?? 0

        guard currentMax > priorMax, currentMax > 0 else { return nil }

        let weightText = currentMax.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(currentMax))"
            : String(format: "%.1f", currentMax)

        return PBAchievement(
            title: "New Personal Best!",
            detail: "\(weightText) lb · \(machine.name)"
        )
    }

    /// Returns a PB if the cardio session in `session` beats the user's prior all-time max
    /// duration OR distance for that activity type. Only fires if the user has done this activity before.
    static func checkCardioPB(session: WorkoutSession, user: User) -> PBAchievement? {
        guard let cardio = session.cardioSession,
              let type = cardio.machineType else { return nil }

        let priorSessions = user.workoutSessions
            .filter { $0.id != session.id && $0.type == .cardio }
            .compactMap(\.cardioSession)
            .filter { $0.machineType == type }

        guard !priorSessions.isEmpty else { return nil }

        let priorMaxDuration = priorSessions.map(\.durationMinutes).max() ?? 0
        let priorMaxDistance = priorSessions.compactMap(\.distanceMiles).max() ?? 0

        var parts: [String] = []

        if cardio.durationMinutes > priorMaxDuration {
            parts.append(String(format: "%.0f min", cardio.durationMinutes))
        }

        if let distance = cardio.distanceMiles, distance > priorMaxDistance, priorMaxDistance > 0 {
            parts.append(String(format: "%.2f mi", distance))
        }

        guard !parts.isEmpty else { return nil }

        return PBAchievement(
            title: "New Personal Best!",
            detail: "\(parts.joined(separator: " · ")) · \(type.displayName)"
        )
    }
}
