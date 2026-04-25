import SwiftUI
import SwiftData

@main
struct ExerciseTrackerApp: App {
    let modelContainer: ModelContainer
    let userViewModel: UserViewModel

    init() {
        do {
            let container = try ModelContainer(
                for: User.self,
                     Machine.self,
                     WorkoutSession.self,
                     StrengthSet.self,
                     CardioSession.self,
                     WorkoutFlow.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: false)
            )
            modelContainer = container
            userViewModel = UserViewModel(modelContext: container.mainContext)
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
