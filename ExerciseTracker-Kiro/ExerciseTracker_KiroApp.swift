import SwiftUI
import SwiftData

@main
struct ExerciseTrackerApp: App {
    let modelContainer: ModelContainer
    let userViewModel: UserViewModel

    init() {
        do {
            // Use a custom URL without spaces to avoid CoreData path issues
            let url = URL.documentsDirectory.appending(path: "ExerciseTracker.store")
            let config = ModelConfiguration(url: url)
            
            let container = try ModelContainer(
                for: User.self,
                     Machine.self,
                     WorkoutSession.self,
                     StrengthSet.self,
                     CardioSession.self,
                     WorkoutFlow.self,
                configurations: config
            )
            modelContainer = container
            userViewModel = UserViewModel(modelContext: container.mainContext)
            print("📦 ModelContainer initialized at: \(url.path())")
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(userViewModel)
        }
        .modelContainer(modelContainer)
    }
}
