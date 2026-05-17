import Foundation
import SwiftData

/// Provides the default list of gym machines (Matrix/Planet Fitness catalog).
/// On first launch for a user, these are seeded as their available machines.
/// Users can add more at any time.
struct MachineCatalogService {

    static let defaultMachines: [(name: String, category: String)] = [
        ("Abdominal Crunch",     "Core"),
        ("Abdominal (Strap)",    "Core"),
        ("Back Extension",       "Back"),
        ("Biceps Curl",          "Arms"),
        ("Calf Extension",       "Legs"),
        ("Chest Press",          "Chest"),
        ("Cross Body Pull",      "Back"),
        ("Lat Pulldown (Cable)", "Back"),
        ("Lat Pulldown (Machine)","Back"),
        ("Leg Extension",        "Legs"),
        ("Leg Press (Platform)", "Legs"),
        ("Leg Press (Sled)",     "Legs"),
        ("Pec Fly",              "Chest"),
        ("Rotary Torso (L)",     "Core"),
        ("Rotary Torso (R)",     "Core"),
        ("Triceps Press",        "Arms"),
    ]

    static let freeWeightExercises: [(name: String, category: String)] = [
        ("Smith Machine Bench Press",  "Chest"),
        ("Smith Machine Squat",        "Legs"),
        ("Dumbbell Bench Press",       "Chest"),
        ("Dumbbell Incline Press",     "Chest"),
        ("Dumbbell Shoulder Press",    "Shoulders"),
        ("Dumbbell Lateral Raise",     "Shoulders"),
        ("Dumbbell Curl",              "Arms"),
        ("Dumbbell Hammer Curl",       "Arms"),
        ("Dumbbell Triceps Extension", "Arms"),
        ("Dumbbell Row",               "Back"),
        ("Dumbbell Lunges",            "Legs"),
        ("Cable Fly",                  "Chest"),
        ("Cable Triceps Pushdown",     "Arms"),
        ("Cable Biceps Curl",          "Arms"),
        ("Cable Row",                  "Back"),
    ]

    /// Seeds the default machine catalog for `user` if they have no machines yet.
    /// Safe to call multiple times — skips if machines already exist.
    static func seedIfNeeded(for user: User, modelContext: ModelContext) {
        guard user.machines.isEmpty else { return }
        for entry in defaultMachines {
            let machine = Machine(
                name: entry.name,
                category: entry.category,
                isFavorite: false,
                user: user
            )
            modelContext.insert(machine)
        }
        do {
            try modelContext.save()
        } catch {
            print("Failed to seed machines: \(error)")
        }
    }

    /// Seeds free weight exercises for a user. Skips any that already exist by name.
    static func seedFreeWeights(for user: User, modelContext: ModelContext) {
        let existingNames = Set(user.machines.map(\.name))
        var added = 0
        for entry in freeWeightExercises where !existingNames.contains(entry.name) {
            let machine = Machine(
                name: entry.name,
                category: entry.category,
                isFavorite: false,
                user: user
            )
            modelContext.insert(machine)
            added += 1
        }
        if added > 0 {
            try? modelContext.save()
        }
    }
}
