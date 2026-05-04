import Foundation
import WatchConnectivity

@Observable
final class WatchConnectivityService: NSObject {
    var machines: [WatchMachine] = []
    var isReachable = false
    var lastSyncMessage: String?

    private var wcSession: WCSession?

    override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
        wcSession = session
    }

    func requestMachineSync() {
        guard let session = wcSession, session.isReachable else {
            lastSyncMessage = "iPhone not reachable"
            return
        }
        session.sendMessage(["request": "machines"], replyHandler: nil)
    }

    func sendWorkout(_ workout: WatchWorkout) {
        guard let session = wcSession else { return }
        guard let data = try? JSONEncoder().encode(workout) else { return }
        session.transferUserInfo(["workout": data])
        lastSyncMessage = "Workout sent to iPhone"
    }
}

extension WatchConnectivityService: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            isReachable = session.isReachable
            loadCachedMachines()
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            isReachable = session.isReachable
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        guard let data = applicationContext["machines"] as? Data else { return }
        decodeMachines(from: data)
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        if let data = message["machines"] as? Data {
            decodeMachines(from: data)
        }
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        if let data = userInfo["machines"] as? Data {
            decodeMachines(from: data)
        }
    }

    private func decodeMachines(from data: Data) {
        guard let decoded = try? JSONDecoder().decode([WatchMachine].self, from: data) else { return }
        UserDefaults.standard.set(data, forKey: "cached_machines")
        Task { @MainActor in
            machines = decoded
            lastSyncMessage = "Synced \(decoded.count) machines"
        }
    }

    private func loadCachedMachines() {
        guard let data = UserDefaults.standard.data(forKey: "cached_machines"),
              let cached = try? JSONDecoder().decode([WatchMachine].self, from: data)
        else { return }
        machines = cached
    }
}
