import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(UserViewModel.self) private var userViewModel
    @Environment(\.modelContext) private var modelContext

    @State private var showProfileSelector = false
    @State private var showMachinePicker = false
    @State private var selectedMachine: Machine?
    @State private var historyViewModel: HistoryViewModel?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Active user header
                activeUserHeader

                Divider()

                // Recent session summary
                recentSessionSection

                Divider()

                // Workout start buttons
                workoutButtons

                Spacer()
            }
            .padding()
            .navigationTitle("Home")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Label("Settings", systemImage: "gearshape")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showProfileSelector = true
                    } label: {
                        Label("Switch Profile", systemImage: "person.2")
                    }
                }
            }
            .sheet(isPresented: $showProfileSelector) {
                ProfileSelectorView()
            }
            .onAppear {
                let hvm = HistoryViewModel(modelContext: modelContext)
                historyViewModel = hvm
            }
        }
    }

    // MARK: - Subviews

    private var activeUserHeader: some View {
        HStack(spacing: 12) {
            if let user = userViewModel.activeUser {
                Circle()
                    .fill(color(for: user.colorTag))
                    .frame(width: 16, height: 16)
                Text(user.name)
                    .font(.title2)
                    .fontWeight(.semibold)
            } else {
                Text("No profile selected")
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private var recentSessionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader("Last Workout")

            CardView {
                if let user = userViewModel.activeUser,
                   let hvm = historyViewModel,
                   let recent = hvm.recentSession(for: user) {
                    HStack {
                        Image(systemName: recent.type == .strength ? "dumbbell" : "figure.run")
                            .foregroundStyle(Color.accentColor)
                        Text(recent.type == .strength ? "Strength" : "Cardio")
                        Spacer()
                        Text(recent.date, style: .date)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("No workouts logged yet.")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var workoutButtons: some View {
        VStack(spacing: 16) {
            SectionHeader("Start Workout")

            // Strength: pick a machine first, then navigate to StrengthLoggingView
            PrimaryButton("Start Strength Workout", systemImage: "dumbbell") {
                showMachinePicker = true
            }
            .sheet(isPresented: $showMachinePicker) {
                HomeMachinePickerView(selectedMachine: $selectedMachine)
            }
            .background(
                NavigationLink(
                    destination: strengthLoggingDestination,
                    isActive: Binding(
                        get: { selectedMachine != nil },
                        set: { if !$0 { selectedMachine = nil } }
                    )
                ) { EmptyView() }
            )

            // Cardio: route to CardioLoggingView which picks manual vs HealthKit (Req 4.5)
            if let user = userViewModel.activeUser {
                NavigationLink(destination: CardioLoggingView(user: user)) {
                    SecondaryButton("Start Cardio Workout", systemImage: "figure.run") {}
                }
                .buttonStyle(.plain)
            } else {
                NavigationLink(destination: PlaceholderWorkoutView(title: "Cardio Workout")) {
                    SecondaryButton("Start Cardio Workout", systemImage: "figure.run") {}
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private var strengthLoggingDestination: some View {
        if let machine = selectedMachine, let user = userViewModel.activeUser {
            StrengthLoggingView(machine: machine, user: user, modelContext: modelContext)
        } else {
            PlaceholderWorkoutView(title: "Strength Workout")
        }
    }

    // MARK: - Helpers

    private func color(for tag: String?) -> Color {
        switch tag?.lowercased() {
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "yellow": return .yellow
        case "pink": return .pink
        default: return .gray
        }
    }
}

// Placeholder for workout screens (implemented in later tasks)
struct PlaceholderWorkoutView: View {
    let title: String
    var body: some View {
        Text(title)
            .navigationTitle(title)
    }
}

// MARK: - HomeMachinePickerView

/// Sheet that lets the user pick a machine before starting a strength session.
struct HomeMachinePickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(UserViewModel.self) private var userViewModel
    @Environment(\.dismiss) private var dismiss

    @Binding var selectedMachine: Machine?

    @State private var viewModel: MachineListViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    if vm.machines.isEmpty {
                        ContentUnavailableView(
                            "No Machines",
                            systemImage: "dumbbell",
                            description: Text("Add machines in the Machines tab first.")
                        )
                    } else {
                        List(vm.machines) { machine in
                            Button {
                                selectedMachine = machine
                                dismiss()
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(machine.name)
                                        .foregroundStyle(.primary)
                                    if let category = machine.category {
                                        Text(category)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Select Machine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                if let user = userViewModel.activeUser {
                    viewModel = MachineListViewModel(modelContext: modelContext, user: user)
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
    return HomeView()
        .environment(vm)
        .modelContainer(container)
}
