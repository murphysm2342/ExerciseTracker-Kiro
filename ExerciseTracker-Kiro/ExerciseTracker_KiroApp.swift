//
//  ExerciseTracker_KiroApp.swift
//  ExerciseTracker-Kiro
//
//  Created by Sean Murphy on 3/20/26.
//

import SwiftUI
import SwiftData

@main
struct ExerciseTracker_KiroApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
