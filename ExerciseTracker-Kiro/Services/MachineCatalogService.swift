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
        // Force save and handle errors properly instead of silently failing
        do {
            try modelContext.save()
            print("✅ Seeded \(defaultMachines.count) machines for user \(user.name)")
        } catch {
            print("❌ Failed to seed machines: \(error)")
        }
    }
}
