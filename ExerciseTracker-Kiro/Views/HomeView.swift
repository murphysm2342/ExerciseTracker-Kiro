import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(UserViewModel.self) private var userViewModel
    @Environment(\.modelContext) private var modelContext

    @State private var showProfileSelector = false
    @State private var showActiveWorkout = false
    @State private var showCardio = false
    @State private var historyViewModel: HistoryViewModel?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignTokens.sectionSpacing) {
                    activeUserHeader
                    quickStatsRow
                    recentSessionSection
                    workoutButtons
                }
                .padding()
            }
            .background(Color.surfaceLight)
            .navigationTitle("Home")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(.secondary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showProfileSelector = true
                    } label: {
                        Image(systemName: "person.crop.circle")
                            .foregroundStyle(Color.brand)
                    }
                }
            }
            .sheet(isPresented: $showProfileSelector) {
                ProfileSelectorView()
            }
            .sheet(isPresented: $showActiveWorkout) {
                if let user = userViewModel.activeUser {
                    historyViewModel?.refresh(for: user)
                }
            } content: {
                if let user = userViewModel.activeUser {
                    ActiveWorkoutView(user: user, modelContext: modelContext)
                }
            }
            .sheet(isPresented: $showCardio) {
                if let user = userViewModel.activeUser {
                    historyViewModel?.refresh(for: user)
                }
            } content: {
                if let user = userViewModel.activeUser {
                    NavigationStack {
                        CardioLoggingView(user: user)
                    }
                }
            }
            .onAppear {
                historyViewModel = HistoryViewModel(modelContext: modelContext)
                if let user = userViewModel.activeUser {
                    historyViewModel?.refresh(for: user)
                }
            }
            .onChange(of: userViewModel.activeUser) { _, newUser in
                if let user = newUser {
                    historyViewModel?.refresh(for: user)
                }
            }
        }
    }

    // MARK: - Active User Header

    private var activeUserHeader: some View {
        HStack(spacing: 14) {
            if let user = userViewModel.activeUser {
                ZStack {
                    Circle()
                        .fill(color(for: user.colorTag).gradient)
                        .frame(width: 44, height: 44)
                    Text(String(user.name.prefix(1)).uppercased())
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Welcome back,")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(user.name)
                        .font(.title2)
                        .fontWeight(.bold)
                }
            } else {
                Text("No profile selected")
                    .foregroundStyle(.secondary)
            }
            Spacer()
            AppLogoSmall()
        }
    }

    // MARK: - Quick Stats

    private var quickStatsRow: some View {
        HStack(spacing: DesignTokens.itemSpacing) {
            if let hvm = historyViewModel {
                let strengthCount = hvm.sessions.filter { $0.type == .strength }.count
                let cardioCount = hvm.sessions.filter { $0.type == .cardio }.count

                miniStatCard(value: "\(strengthCount)", label: "Strength", icon: "dumbbell.fill", color: .strengthAccent)
                miniStatCard(value: "\(cardioCount)", label: "Cardio", icon: "heart.fill", color: .cardioAccent)
                miniStatCard(value: "\(strengthCount + cardioCount)", label: "Total", icon: "flame.fill", color: .brand)
            }
        }
    }

    private func miniStatCard(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .cardStyle()
    }

    // MARK: - Recent Session

    private var recentSessionSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.itemSpacing) {
            SectionHeader("Last Workout")

            if let hvm = historyViewModel,
               let recent = hvm.mostRecentSession {
                NavigationLink(destination: WorkoutDetailView(session: recent)) {
                    HStack(spacing: 14) {
                        IconBadge(
                            systemName: recent.type == .strength ? "dumbbell.fill" : "figure.run",
                            color: recent.type == .strength ? .strengthAccent : .cardioAccent,
                            size: 44
                        )
                        VStack(alignment: .leading, spacing: 3) {
                            Text(recent.type == .strength ? "Strength Workout" : "Cardio Workout")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                            Text(recent.date, style: .date)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if recent.type == .strength {
                                Text("\(recent.strengthSets.count) sets")
                                    .font(.caption2)
                                    .foregroundStyle(Color.subtleText)
                            }
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .cardStyle()
                }
                .buttonStyle(.plain)
            } else {
                HStack(spacing: 12) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.title2)
                        .foregroundStyle(.tertiary)
                    Text("No workouts logged yet. Start one below!")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardStyle()
            }
        }
    }

    // MARK: - Workout Buttons

    private var workoutButtons: some View {
        VStack(spacing: DesignTokens.itemSpacing) {
            SectionHeader("Start Workout")

            Button {
                showActiveWorkout = true
            } label: {
                HStack(spacing: 14) {
                    IconBadge(systemName: "dumbbell.fill", color: .white, size: 40)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Strength Workout")
                            .font(.headline)
                        Text("Log sets for your exercises")
                            .font(.caption)
                            .opacity(0.85)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.subheadline)
                        .opacity(0.7)
                }
                .foregroundStyle(.white)
                .padding(DesignTokens.cardPadding)
                .background(LinearGradient.strengthGradient)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cornerRadius))
                .shadow(color: .strengthAccent.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .disabled(userViewModel.activeUser == nil)

            Button {
                showCardio = true
            } label: {
                HStack(spacing: 14) {
                    IconBadge(systemName: "figure.run", color: .white, size: 40)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Cardio Workout")
                            .font(.headline)
                        Text("Track duration, distance & heart rate")
                            .font(.caption)
                            .opacity(0.85)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.subheadline)
                        .opacity(0.7)
                }
                .foregroundStyle(.white)
                .padding(DesignTokens.cardPadding)
                .background(LinearGradient.cardioGradient)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cornerRadius))
                .shadow(color: .cardioAccent.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .disabled(userViewModel.activeUser == nil)
        }
    }

    // MARK: - Helpers

    private func color(for tag: String?) -> Color {
        switch tag?.lowercased() {
        case "red":    return .red
        case "blue":   return .blue
        case "green":  return .green
        case "orange": return .orange
        case "purple": return .purple
        case "yellow": return .yellow
        case "pink":   return .pink
        default:       return .gray
        }
    }
}

// MARK: - Preview

#Preview {
    let container = try! ModelContainer(
        for: User.self, Machine.self, WorkoutSession.self,
             StrengthSet.self, CardioSession.self, WorkoutFlow.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let vm = UserViewModel(modelContext: container.mainContext)
    return HomeView()
        .environment(vm)
        .modelContainer(container)
}
