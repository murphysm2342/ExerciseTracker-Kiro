import Foundation
import SwiftData

@Observable class StatsViewModel {
    var maxWeightByMachine: [MachineMaxWeight] = []
    var weightTrend: [WeightTrendPoint] = []
    var cardioTrend: [CardioTrendPoint] = []
    var cardioByType: [CardioTypeStat] = []
    var machines: [Machine] = []
    var selectedMachine: Machine?
    var selectedTrendPeriod: TrendPeriod = .month

    private var modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Data Types

    struct MachineMaxWeight: Identifiable {
        let id: UUID
        let machineName: String
        let category: String?
        let maxWeight: Double
        let totalSets: Int
    }

    struct WeightTrendPoint: Identifiable {
        let id = UUID()
        let date: Date
        let maxWeight: Double
        let totalVolume: Double
    }

    struct CardioTrendPoint: Identifiable {
        let id = UUID()
        let date: Date
        let durationMinutes: Double
        let distanceMiles: Double?
        let avgHeartRate: Double?
    }

    struct CardioTypeStat: Identifiable {
        let id = UUID()
        let machineType: CardioMachineType
        let sessionCount: Int
        let totalMinutes: Double
        let totalDistance: Double?
        let avgHeartRate: Double?
    }

    enum TrendPeriod: String, CaseIterable {
        case week = "7D"
        case month = "30D"
        case threeMonths = "90D"
        case all = "All"

        var days: Int? {
            switch self {
            case .week: return 7
            case .month: return 30
            case .threeMonths: return 90
            case .all: return nil
            }
        }
    }

    // MARK: - Refresh

    func refresh(for user: User) {
        fetchMachines(for: user)
        computeMaxWeightByMachine(for: user)
        computeCardioTrend(for: user)
        computeCardioByType(for: user)
        if let machine = selectedMachine {
            computeWeightTrend(for: machine, user: user)
        } else if let first = maxWeightByMachine.first,
                  let match = machines.first(where: { $0.name == first.machineName }) {
            selectedMachine = match
            computeWeightTrend(for: match, user: user)
        }
    }

    func selectMachine(_ machine: Machine, user: User) {
        selectedMachine = machine
        computeWeightTrend(for: machine, user: user)
    }

    func changePeriod(_ period: TrendPeriod, user: User) {
        selectedTrendPeriod = period
        if let machine = selectedMachine {
            computeWeightTrend(for: machine, user: user)
        }
        computeCardioTrend(for: user)
        computeCardioByType(for: user)
    }

    // MARK: - Queries

    private func fetchMachines(for user: User) {
        let userId = user.id
        let descriptor = FetchDescriptor<Machine>(
            predicate: #Predicate { $0.user.id == userId },
            sortBy: [SortDescriptor(\.name)]
        )
        machines = (try? modelContext.fetch(descriptor)) ?? []
    }

    private func computeMaxWeightByMachine(for user: User) {
        let userId = user.id
        let descriptor = FetchDescriptor<StrengthSet>(
            predicate: #Predicate { $0.session.user.id == userId }
        )
        let allSets = (try? modelContext.fetch(descriptor)) ?? []

        var grouped: [UUID: (name: String, category: String?, maxWeight: Double, count: Int)] = [:]
        for set in allSets {
            let machineId = set.machine.id
            if var entry = grouped[machineId] {
                entry.maxWeight = max(entry.maxWeight, set.weight)
                entry.count += 1
                grouped[machineId] = entry
            } else {
                grouped[machineId] = (
                    name: set.machine.name,
                    category: set.machine.category,
                    maxWeight: set.weight,
                    count: 1
                )
            }
        }

        maxWeightByMachine = grouped.map { key, value in
            MachineMaxWeight(
                id: key,
                machineName: value.name,
                category: value.category,
                maxWeight: value.maxWeight,
                totalSets: value.count
            )
        }
        .filter { $0.maxWeight > 0 }
        .sorted { $0.maxWeight > $1.maxWeight }
    }

    private func computeWeightTrend(for machine: Machine, user: User) {
        let userId = user.id
        let machineId = machine.id
        let descriptor = FetchDescriptor<StrengthSet>(
            predicate: #Predicate {
                $0.session.user.id == userId && $0.machine.id == machineId
            }
        )
        let allSets = (try? modelContext.fetch(descriptor)) ?? []

        let cutoff = periodCutoff()
        let filtered = cutoff == nil ? allSets : allSets.filter { $0.session.date >= cutoff! }

        let calendar = Calendar.current
        var byDay: [DateComponents: (maxWeight: Double, volume: Double)] = [:]
        for set in filtered {
            let day = calendar.dateComponents([.year, .month, .day], from: set.session.date)
            let volume = set.weight * Double(set.reps)
            if var entry = byDay[day] {
                entry.maxWeight = max(entry.maxWeight, set.weight)
                entry.volume += volume
                byDay[day] = entry
            } else {
                byDay[day] = (maxWeight: set.weight, volume: volume)
            }
        }

        weightTrend = byDay.compactMap { day, data in
            guard let date = calendar.date(from: day) else { return nil }
            return WeightTrendPoint(date: date, maxWeight: data.maxWeight, totalVolume: data.volume)
        }
        .sorted { $0.date < $1.date }
    }

    private func computeCardioTrend(for user: User) {
        let userId = user.id
        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.user.id == userId },
            sortBy: [SortDescriptor(\.date)]
        )
        let allSessions = (try? modelContext.fetch(descriptor)) ?? []
        let sessions = allSessions.filter { $0.type == .cardio }

        let cutoff = periodCutoff()
        let filtered = cutoff == nil ? sessions : sessions.filter { $0.date >= cutoff! }

        cardioTrend = filtered.compactMap { session in
            guard let cardio = session.cardioSession else { return nil }
            return CardioTrendPoint(
                date: session.date,
                durationMinutes: cardio.durationMinutes,
                distanceMiles: cardio.distanceMiles,
                avgHeartRate: cardio.avgHeartRate
            )
        }
    }

    private func computeCardioByType(for user: User) {
        let userId = user.id
        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.user.id == userId },
            sortBy: [SortDescriptor(\.date)]
        )
        let allSessions = (try? modelContext.fetch(descriptor)) ?? []
        let sessions = allSessions.filter { $0.type == .cardio }

        let cutoff = periodCutoff()
        let filtered = cutoff == nil ? sessions : sessions.filter { $0.date >= cutoff! }

        var grouped: [CardioMachineType: (count: Int, minutes: Double, distance: Double, heartRateSum: Double, heartRateCount: Int)] = [:]

        for session in filtered {
            guard let cardio = session.cardioSession, let type = cardio.machineType else { continue }
            var entry = grouped[type] ?? (count: 0, minutes: 0, distance: 0, heartRateSum: 0, heartRateCount: 0)
            entry.count += 1
            entry.minutes += cardio.durationMinutes
            entry.distance += cardio.distanceMiles ?? 0
            if let hr = cardio.avgHeartRate {
                entry.heartRateSum += hr
                entry.heartRateCount += 1
            }
            grouped[type] = entry
        }

        cardioByType = grouped.map { type, data in
            CardioTypeStat(
                machineType: type,
                sessionCount: data.count,
                totalMinutes: data.minutes,
                totalDistance: data.distance > 0 ? data.distance : nil,
                avgHeartRate: data.heartRateCount > 0 ? data.heartRateSum / Double(data.heartRateCount) : nil
            )
        }
        .sorted { $0.totalMinutes > $1.totalMinutes }
    }

    private func periodCutoff() -> Date? {
        guard let days = selectedTrendPeriod.days else { return nil }
        return Calendar.current.date(byAdding: .day, value: -days, to: Date())
    }

    // MARK: - Computed Stats

    var totalWorkouts: Int {
        maxWeightByMachine.reduce(0) { $0 + $1.totalSets }
    }

    var totalCardioMinutes: Double {
        cardioTrend.reduce(0) { $0 + $1.durationMinutes }
    }

    var totalCardioDistance: Double {
        cardioTrend.compactMap(\.distanceMiles).reduce(0, +)
    }
}
