import SwiftUI

@main
struct ExerciseTracker_Watch_Watch_AppApp: App {
    @State private var connectivity = WatchConnectivityService()

    var body: some Scene {
        WindowGroup {
            WatchHomeView()
                .environment(connectivity)
        }
    }
}
