import Foundation

enum WorkoutType: String, Codable {
    case strength
    case cardio
}

enum CardioSource: String, Codable {
    case healthKit
    case manual
}
