import Foundation
import WatchConnectivity
import SwiftData

@Observable
final class PhoneConnectivityService: NSObject {
    var isPaired = false
    var isReachable = false

    private var wcSession: WCSession?
    private var modelContext: ModelContext?
    private var userProvider: (() -> User?)?

    func configure(modelContext: ModelContext, userProvider: @escaping () -> User?) {
        self.modelContext = modelContext
        self.userProvider = userProvider

        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
        wcSession = session
    }

    func syncMachines(for user: User) {
        guard let session = wcSession, session.activationState == .activated else { return }

        let watchMachines = user.machines.map { machine in
            WatchMachineTransfer(
                id: machine.id,
                name: machine.name,
                category: machine.category,
                lastUsedWeight: machine.lastUsedWeight,
                lastUsedReps: machine.lastUsedReps
            )
        }

        guard let data = try? JSONEncoder().encode(watchMachines) else { return }

        if session.isReachable {
            session.sendMessage(["machines": data], replyHandler: nil)
        }
        try? session.updateApplicationContext(["machines": data])
    }
}

extension PhoneConnectivityService: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            isPaired = session.isPaired
            isReachable = session.isReachable
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            isReachable = session.isReachable
            if session.isReachable, let user = userProvider?() {
                syncMachines(for: user)
            }
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        if message["request"] as? String == "machines" {
            Task { @MainActor in
                if let user = userProvider?() {
                    syncMachines(for: user)
                }
            }
        }
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        guard let data = userInfo["workout"] as? Data,
              let workout = try? JSONDecoder().decode(WatchWorkoutTransfer.self, from: data)
        else { return }

        Task { @MainActor in
            importWorkout(workout)
        }
    }

    @MainActor
    private func importWorkout(_ transfer: WatchWorkoutTransfer) {
        guard let ctx = modelContext, let user = userProvider?() else { return }

        let type: WorkoutType = transfer.type == "strength" ? .strength : .cardio
        let session = WorkoutSession(date: transfer.date, type: type, user: user)
        ctx.insert(session)

        if type == .strength {
            for setData in transfer.strengthSets {
                if let machine = user.machines.first(where: { $0.id == setData.machineId }) {
                    let strengthSet = StrengthSet(
                        setNumber: setData.setNumber,
                        weight: setData.weight,
                        reps: setData.reps,
                        isCompleted: true,
                        machine: machine,
                        session: session
                    )
                    ctx.insert(strengthSet)
                }
            }
        } else if let cardioData = transfer.cardio {
            let machineType = CardioMachineType(rawValue: cardioData.machineType)
            let cardio = CardioSession(
                durationMinutes: cardioData.durationMinutes,
                distanceMiles: cardioData.distanceMiles,
                avgHeartRate: cardioData.avgHeartRate,
                machineType: machineType,
                resistance: cardioData.resistance,
                floors: cardioData.floors,
                speed: cardioData.speed,
                session: session
            )
            ctx.insert(cardio)
        }

        try? ctx.save()
    }
}

// MARK: - Transfer Codable types (iPhone side)

struct WatchMachineTransfer: Codable {
    let id: UUID
    let name: String
    let category: String?
    let lastUsedWeight: Double?
    let lastUsedReps: Int?
}

struct WatchWorkoutTransfer: Codable {
    let id: UUID
    let date: Date
    let type: String
    let strengthSets: [WatchSetTransfer]
    let cardio: WatchCardioTransfer?
}

struct WatchSetTransfer: Codable {
    let setNumber: Int
    let weight: Double
    let reps: Int
    let machineId: UUID
    let machineName: String
}

struct WatchCardioTransfer: Codable {
    let machineType: String
    let durationMinutes: Double
    let distanceMiles: Double?
    let avgHeartRate: Double?
    let resistance: Double?
    let floors: Int?
    let speed: Double?
}
