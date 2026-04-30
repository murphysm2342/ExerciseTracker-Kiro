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
    case treadmill
    case elliptical
    case stairStepper
    case stationaryBike
    case rowingMachine

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .treadmill:      return "Treadmill"
        case .elliptical:     return "Elliptical"
        case .stairStepper:   return "Stair Stepper"
        case .stationaryBike: return "Stationary Bike"
        case .rowingMachine:  return "Rowing Machine"
        }
    }

    var iconName: String {
        switch self {
        case .treadmill:      return "figure.run"
        case .elliptical:     return "figure.elliptical"
        case .stairStepper:   return "figure.stair.stepper"
        case .stationaryBike: return "figure.indoor.cycle"
        case .rowingMachine:  return "figure.rower"
        }
    }

    var accentColor: String {
        switch self {
        case .treadmill:      return "green"
        case .elliptical:     return "blue"
        case .stairStepper:   return "orange"
        case .stationaryBike: return "purple"
        case .rowingMachine:  return "teal"
        }
    }
}
