import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(UserViewModel.self) private var userViewModel
    @Environment(PBCelebrationManager.self) private var celebrationManager
    @State private var showingOnboarding = false
    @State private var newUser: User?
    @State private var hasCompletedOnboarding = false
    @State private var showSplash = true

    var body: some View {
        ZStack {
            mainContent
                .opacity(showSplash ? 0 : 1)

            if showSplash {
                SplashScreenView()
                    .transition(.opacity)
            }

            if let achievement = celebrationManager.active {
                CelebrationOverlay(achievement: achievement)
                    .zIndex(1000)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: celebrationManager.active)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                withAnimation(.easeOut(duration: 0.5)) {
                    showSplash = false
                }
            }
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        if userViewModel.allUsers.isEmpty || (newUser != nil && !hasCompletedOnboarding) {
            ZStack {
                EditProfileView(onCreated: { user in
                    newUser = user
                    showingOnboarding = true
                })

                if showingOnboarding {
                    Color.clear
                        .ignoresSafeArea()
                }
            }
            .sheet(isPresented: $showingOnboarding, onDismiss: {
                hasCompletedOnboarding = true
                newUser = nil
            }) {
                if let user = newUser {
                    OnboardingSetupView(user: user) {
                        showingOnboarding = false
                    }
                    .interactiveDismissDisabled()
                }
            }
        } else if userViewModel.activeUser == nil {
            if userViewModel.allUsers.count == 1 {
                Color.clear.onAppear {
                    userViewModel.selectUser(userViewModel.allUsers[0])
                }
            } else {
                ProfileSelectorView(canDismiss: false)
            }
        } else {
            TabView {
                HomeView()
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }

                StatsView()
                    .tabItem {
                        Label("Stats", systemImage: "chart.xyaxis.line")
                    }

                HistoryView()
                    .tabItem {
                        Label("History", systemImage: "calendar")
                    }
            }
            .tint(.brand)
        }
    }
}

// MARK: - Splash Screen

private struct SplashScreenView: View {
    @State private var logoScale: CGFloat = 0.6
    @State private var logoOpacity: Double = 0
    @State private var titleOffset: CGFloat = 20
    @State private var titleOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0

    var body: some View {
        ZStack {
            LinearGradient.brandGradient
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                ZStack {
                    RoundedRectangle(cornerRadius: 36)
                        .fill(.white.opacity(0.15))
                        .frame(width: 160, height: 160)
                        .blur(radius: 1)

                    AppLogoView(size: 140)
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

                VStack(spacing: 8) {
                    Text("ExerciseTracker")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)

                    Text("Track. Improve. Repeat.")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.white.opacity(0.8))
                        .opacity(subtitleOpacity)
                }
                .offset(y: titleOffset)
                .opacity(titleOpacity)

                Spacer()
                Spacer()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.1)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.5)) {
                titleOffset = 0
                titleOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.9)) {
                subtitleOpacity = 1.0
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
        .environment(PBCelebrationManager())
        .modelContainer(container)
}
