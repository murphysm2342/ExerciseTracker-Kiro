import Foundation
import SwiftData

// MARK: - Export Codable Types

struct BackupContainer: Codable {
    let version: Int
    let exportDate: Date
    let users: [BackupUser]
}

struct BackupUser: Codable {
    let id: UUID
    let name: String
    let colorTag: String?
    let createdAt: Date
    let preferredCardioSource: String
    let usesHealthKit: Bool
    let syncToHealthKit: Bool
    let machines: [BackupMachine]
    let workoutSessions: [BackupWorkoutSession]
    let workoutFlows: [BackupWorkoutFlow]
}

struct BackupMachine: Codable {
    let id: UUID
    let name: String
    let category: String?
    let isFavorite: Bool
    let lastUsedWeight: Double?
    let lastUsedReps: Int?
    let nfcTagId: String?
}

struct BackupWorkoutSession: Codable {
    let id: UUID
    let date: Date
    let type: String
    let strengthSets: [BackupStrengthSet]
    let cardioSession: BackupCardioSession?
}

struct BackupStrengthSet: Codable {
    let id: UUID
    let setNumber: Int
    let weight: Double
    let reps: Int
    let isCompleted: Bool
    let machineId: UUID
}

struct BackupCardioSession: Codable {
    let id: UUID
    let durationMinutes: Double
    let distanceMiles: Double?
    let incline: Double?
    let avgHeartRate: Double?
    let healthKitWorkoutId: UUID?
    let machineType: String?
    let resistance: Double?
    let floors: Int?
    let strides: Int?
    let strokeCount: Int?
    let speed: Double?
    let rpm: Double?
}

struct BackupWorkoutFlow: Codable {
    let id: UUID
    let name: String
    let createdAt: Date
    let machineOrder: [UUID]
    let machineIds: [UUID]
}

// MARK: - DataBackupService

struct DataBackupService {

    func exportAllData(modelContext: ModelContext) throws -> Data {
        let users = try modelContext.fetch(FetchDescriptor<User>())
        let allFlows = try modelContext.fetch(FetchDescriptor<WorkoutFlow>())

        let backupUsers = users.map { user in
            let userFlows = allFlows.filter { $0.user.id == user.id }

            return BackupUser(
                id: user.id,
                name: user.name,
                colorTag: user.colorTag,
                createdAt: user.createdAt,
                preferredCardioSource: user.preferredCardioSource.rawValue,
                usesHealthKit: user.usesHealthKit,
                syncToHealthKit: user.syncToHealthKit,
                machines: user.machines.map { machine in
                    BackupMachine(
                        id: machine.id,
                        name: machine.name,
                        category: machine.category,
                        isFavorite: machine.isFavorite,
                        lastUsedWeight: machine.lastUsedWeight,
                        lastUsedReps: machine.lastUsedReps,
                        nfcTagId: machine.nfcTagId
                    )
                },
                workoutSessions: user.workoutSessions.map { session in
                    BackupWorkoutSession(
                        id: session.id,
                        date: session.date,
                        type: session.type.rawValue,
                        strengthSets: session.strengthSets.map { set in
                            BackupStrengthSet(
                                id: set.id,
                                setNumber: set.setNumber,
                                weight: set.weight,
                                reps: set.reps,
                                isCompleted: set.isCompleted,
                                machineId: set.machine.id
                            )
                        },
                        cardioSession: session.cardioSession.map { cardio in
                            BackupCardioSession(
                                id: cardio.id,
                                durationMinutes: cardio.durationMinutes,
                                distanceMiles: cardio.distanceMiles,
                                incline: cardio.incline,
                                avgHeartRate: cardio.avgHeartRate,
                                healthKitWorkoutId: cardio.healthKitWorkoutId,
                                machineType: cardio.machineType?.rawValue,
                                resistance: cardio.resistance,
                                floors: cardio.floors,
                                strides: cardio.strides,
                                strokeCount: cardio.strokeCount,
                                speed: cardio.speed,
                                rpm: cardio.rpm
                            )
                        }
                    )
                },
                workoutFlows: userFlows.map { flow in
                    BackupWorkoutFlow(
                        id: flow.id,
                        name: flow.name,
                        createdAt: flow.createdAt,
                        machineOrder: flow.machineOrder,
                        machineIds: flow.machines.map(\.id)
                    )
                }
            )
        }

        let container = BackupContainer(
            version: 1,
            exportDate: Date(),
            users: backupUsers
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(container)
    }

    func importAllData(from data: Data, modelContext: ModelContext) throws -> Int {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let backup = try decoder.decode(BackupContainer.self, from: data)

        let existingUsers = try modelContext.fetch(FetchDescriptor<User>())
        let existingUserIds = Set(existingUsers.map(\.id))

        var importedCount = 0

        for backupUser in backup.users {
            if existingUserIds.contains(backupUser.id) {
                continue
            }

            let user = User(
                id: backupUser.id,
                name: backupUser.name,
                colorTag: backupUser.colorTag,
                createdAt: backupUser.createdAt,
                preferredCardioSource: CardioSource(rawValue: backupUser.preferredCardioSource) ?? .manual,
                usesHealthKit: backupUser.usesHealthKit,
                syncToHealthKit: backupUser.syncToHealthKit
            )
            modelContext.insert(user)

            var machineMap: [UUID: Machine] = [:]
            for bm in backupUser.machines {
                let machine = Machine(
                    id: bm.id,
                    name: bm.name,
                    category: bm.category,
                    isFavorite: bm.isFavorite,
                    lastUsedWeight: bm.lastUsedWeight,
                    lastUsedReps: bm.lastUsedReps,
                    nfcTagId: bm.nfcTagId,
                    user: user
                )
                modelContext.insert(machine)
                machineMap[bm.id] = machine
            }

            for bs in backupUser.workoutSessions {
                let workoutType = WorkoutType(rawValue: bs.type) ?? .strength
                let session = WorkoutSession(
                    id: bs.id,
                    date: bs.date,
                    type: workoutType,
                    user: user
                )
                modelContext.insert(session)

                for bSet in bs.strengthSets {
                    if let machine = machineMap[bSet.machineId] {
                        let strengthSet = StrengthSet(
                            id: bSet.id,
                            setNumber: bSet.setNumber,
                            weight: bSet.weight,
                            reps: bSet.reps,
                            isCompleted: bSet.isCompleted,
                            machine: machine,
                            session: session
                        )
                        modelContext.insert(strengthSet)
                    }
                }

                if let bc = bs.cardioSession {
                    let machineType = bc.machineType.flatMap { CardioMachineType(rawValue: $0) }
                    let cardio = CardioSession(
                        id: bc.id,
                        durationMinutes: bc.durationMinutes,
                        distanceMiles: bc.distanceMiles,
                        incline: bc.incline,
                        avgHeartRate: bc.avgHeartRate,
                        healthKitWorkoutId: bc.healthKitWorkoutId,
                        machineType: machineType,
                        resistance: bc.resistance,
                        floors: bc.floors,
                        strides: bc.strides,
                        strokeCount: bc.strokeCount,
                        speed: bc.speed,
                        rpm: bc.rpm,
                        session: session
                    )
                    modelContext.insert(cardio)
                    session.cardioSession = cardio
                }
            }

            for bf in backupUser.workoutFlows {
                let flowMachines = bf.machineIds.compactMap { machineMap[$0] }
                let flow = WorkoutFlow(
                    id: bf.id,
                    name: bf.name,
                    createdAt: bf.createdAt,
                    machineOrder: bf.machineOrder,
                    user: user,
                    machines: flowMachines
                )
                modelContext.insert(flow)
            }

            importedCount += 1
        }

        try modelContext.save()
        return importedCount
    }
}
