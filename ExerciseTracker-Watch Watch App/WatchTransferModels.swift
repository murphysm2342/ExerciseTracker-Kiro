import Foundation

struct WatchMachine: Codable, Identifiable {
    let id: UUID
    let name: String
    let category: String?
    let lastUsedWeight: Double?
    let lastUsedReps: Int?
}

struct WatchStrengthSet: Codable {
    let setNumber: Int
    let weight: Double
    let reps: Int
    let machineId: UUID
    let machineName: String
}

struct WatchWorkout: Codable {
    let id: UUID
    let date: Date
    let type: String
    let strengthSets: [WatchStrengthSet]
    let cardio: WatchCardioData?
}

struct WatchCardioData: Codable {
    let machineType: String
    let durationMinutes: Double
    let distanceMiles: Double?
    let avgHeartRate: Double?
    let resistance: Double?
    let floors: Int?
    let speed: Double?
}

enum WatchCardioType: String, CaseIterable, Identifiable {
    case treadmill, elliptical, stairStepper, stationaryBike, rowingMachine
    case outdoorRun, outdoorCycling, hiking
    case swimming, jumpRope, hiit, boxing
    case yoga, pilates, stretching, dance

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .treadmill:      return "Treadmill"
        case .elliptical:     return "Elliptical"
        case .stairStepper:   return "Stair Stepper"
        case .stationaryBike: return "Bike"
        case .rowingMachine:  return "Rowing"
        case .outdoorRun:     return "Run"
        case .outdoorCycling: return "Cycling"
        case .hiking:         return "Hiking"
        case .swimming:       return "Swimming"
        case .jumpRope:       return "Jump Rope"
        case .hiit:           return "HIIT"
        case .boxing:         return "Boxing"
        case .yoga:           return "Yoga"
        case .pilates:        return "Pilates"
        case .stretching:     return "Stretching"
        case .dance:          return "Dance"
        }
    }

    var iconName: String {
        switch self {
        case .treadmill:      return "figure.run"
        case .elliptical:     return "figure.elliptical"
        case .stairStepper:   return "figure.stair.stepper"
        case .stationaryBike: return "figure.indoor.cycle"
        case .rowingMachine:  return "figure.rower"
        case .outdoorRun:     return "figure.run"
        case .outdoorCycling: return "figure.outdoor.cycle"
        case .hiking:         return "figure.hiking"
        case .swimming:       return "figure.pool.swim"
        case .jumpRope:       return "figure.jumprope"
        case .hiit:           return "figure.highintensity.intervaltraining"
        case .boxing:         return "figure.boxing"
        case .yoga:           return "figure.yoga"
        case .pilates:        return "figure.pilates"
        case .stretching:     return "figure.cooldown"
        case .dance:          return "figure.dance"
        }
    }
}
