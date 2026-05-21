import SwiftUI
import SwiftData

@main
struct ExerciseTrackerApp: App {
    let modelContainer: ModelContainer
    let userViewModel: UserViewModel
    let phoneConnectivity = PhoneConnectivityService()
    let celebrationManager = PBCelebrationManager()

    init() {
        do {
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
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(userViewModel)
                .environment(celebrationManager)
                .onAppear {
                    phoneConnectivity.configure(
                        modelContext: modelContainer.mainContext,
                        userProvider: { [userViewModel] in userViewModel.activeUser }
                    )
                    if let user = userViewModel.activeUser {
                        phoneConnectivity.syncMachines(for: user)
                    }
                }
                .onChange(of: userViewModel.activeUser) { _, newUser in
                    if let user = newUser {
                        phoneConnectivity.syncMachines(for: user)
                    }
                }
        }
        .modelContainer(modelContainer)
    }
}
