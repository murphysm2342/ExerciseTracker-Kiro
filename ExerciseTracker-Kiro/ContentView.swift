import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(UserViewModel.self) private var userViewModel

    var body: some View {
        if userViewModel.allUsers.isEmpty {
            // Req 11.6: no users → prompt to create first profile
            EditProfileView()
        } else {
            TabView {
                HomeView()
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }

                HistoryView()
                    .tabItem {
                        Label("History", systemImage: "calendar")
                    }
            }
        }
    }
}

#Preview {
    let container = try! ModelContainer(
        for: User.self, Machine.self, WorkoutSession.self,
             StrengthSet.self, CardioSession.self, WorkoutFlow.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let vm = UserViewModel(modelContext: container.mainContext)
    return ContentView()
        .environment(vm)
        .modelContainer(container)
}
