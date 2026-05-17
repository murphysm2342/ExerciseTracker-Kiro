import Foundation

enum WorkoutType: String, Codable {
    case strength
    case cardio
}

enum CardioSource: String, Codable {
    case healthKit
    case manual
}

enum CardioMachineType: String, Codable, CaseIterable, Identifiable {
    // Gym machines
    case treadmill
    case elliptical
    case stairStepper
    case stationaryBike
    case rowingMachine
    // Outdoor
    case outdoorRun
    case outdoorCycling
    case hiking
    // Full body
    case swimming
    case jumpRope
    case hiit
    case boxing
    // Mind & body
    case yoga
    case pilates
    case stretching
    case dance

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .treadmill:      return "Treadmill"
        case .elliptical:     return "Elliptical"
        case .stairStepper:   return "Stair Stepper"
        case .stationaryBike: return "Stationary Bike"
        case .rowingMachine:  return "Rowing Machine"
        case .outdoorRun:     return "Outdoor Run"
        case .outdoorCycling: return "Outdoor Cycling"
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

    var accentColor: String {
        switch self {
        case .treadmill:      return "green"
        case .elliptical:     return "blue"
        case .stairStepper:   return "orange"
        case .stationaryBike: return "purple"
        case .rowingMachine:  return "teal"
        case .outdoorRun:     return "mint"
        case .outdoorCycling: return "cyan"
        case .hiking:         return "brown"
        case .swimming:       return "indigo"
        case .jumpRope:       return "pink"
        case .hiit:           return "red"
        case .boxing:         return "orange"
        case .yoga:           return "mint"
        case .pilates:        return "teal"
        case .stretching:     return "green"
        case .dance:          return "pink"
        }
    }
}
