import SwiftUI

enum MachineIconProvider {

    static func icon(for machineName: String, category: String? = nil) -> String {
        if let specific = machineIcons[machineName] {
            return specific
        }
        if let cat = category {
            return categoryIcon(for: cat)
        }
        return "dumbbell.fill"
    }

    static func categoryIcon(for category: String) -> String {
        switch category.lowercased() {
        case "core":  return "figure.core.training"
        case "back":  return "figure.strengthtraining.traditional"
        case "arms":  return "dumbbell.fill"
        case "chest": return "figure.strengthtraining.functional"
        case "legs":  return "figure.walk"
        default:      return "dumbbell.fill"
        }
    }

    static func categoryColor(for category: String) -> Color {
        switch category.lowercased() {
        case "core":  return .orange
        case "back":  return .blue
        case "arms":  return .purple
        case "chest": return .red
        case "legs":  return .green
        default:      return .brand
        }
    }

    private static let machineIcons: [String: String] = [
        "Abdominal Crunch":      "figure.core.training",
        "Abdominal (Strap)":     "figure.core.training",
        "Back Extension":        "figure.strengthtraining.traditional",
        "Biceps Curl":           "dumbbell.fill",
        "Calf Extension":        "figure.walk",
        "Chest Press":           "figure.strengthtraining.functional",
        "Cross Body Pull":       "figure.strengthtraining.traditional",
        "Lat Pulldown (Cable)":  "figure.strengthtraining.traditional",
        "Lat Pulldown (Machine)":"figure.strengthtraining.traditional",
        "Leg Extension":         "figure.step.training",
        "Leg Press (Platform)":  "figure.strengthtraining.traditional",
        "Leg Press (Sled)":      "figure.strengthtraining.traditional",
        "Pec Fly":               "figure.arms.open",
        "Rotary Torso (L)":      "figure.core.training",
        "Rotary Torso (R)":      "figure.core.training",
        "Triceps Press":         "dumbbell.fill",
    ]
}
