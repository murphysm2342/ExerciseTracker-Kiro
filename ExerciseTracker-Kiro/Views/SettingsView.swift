import SwiftUI
import SwiftData

/// Settings screen scoped to the active user.
/// Requirements: 6.1, 6.2, 6.3, 6.4, 12.1, 12.2, 12.3, 12.4, 12.5
struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(UserViewModel.self) private var userViewModel

    @State private var viewModel: SettingsViewModel?

    // Form state
    @State private var name: String = ""
    @State private var colorTag: String = ""
    @State private var usesHealthKit: Bool = false
    @State private var cardioSource: CardioSource = .manual

    // UI state
    @State private var validationError: String?
    @State private var saveError: String?
    @State private var isRequestingHK: Bool = false

    private let colorOptions = ["red", "blue", "green", "orange", "purple", "yellow", "pink", "gray"]

    var body: some View {
        Form {
            // Req 12.2: name and color tag
            Section("Profile") {
                TextField("Name", text: $name)

                Picker("Color Tag", selection: $colorTag) {
                    Text("None").tag("")
                    ForEach(colorOptions, id: \.self) { option in
                        HStack {
                            Circle()
                                .fill(color(for: option))
                                .frame(width: 12, height: 12)
                            Text(option.capitalized)
                        }
                        .tag(option)
                    }
                }
            }

            // Req 12.3: HealthKit toggle and cardio source picker
            Section("Cardio Preferences") {
                Toggle("Use HealthKit", isOn: $usesHealthKit)
                    .onChange(of: usesHealthKit) { oldValue, newValue in
                        // Req 6.2: request permissions when first enabled
                        if newValue && !oldValue {
                            Task { await requestHealthKitIfNeeded() }
                        }
                    }

                Picker("Cardio Source", selection: $cardioSource) {
                    Text("Manual Entry").tag(CardioSource.manual)
                    Text("HealthKit").tag(CardioSource.healthKit)
                }
                .pickerStyle(.segmented)
            }

            // Req 12.4: navigation to machine management and workout flow management
            Section("Manage") {
                NavigationLink("Machines") {
                    MachineListView()
                }
                NavigationLink("Workout Flows") {
                    WorkoutFlowListView()
                }
            }

            // Validation / error display
            if let error = validationError ?? saveError {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }

            Section {
                Button("Save") {
                    save()
                }
                .frame(maxWidth: .infinity)
                .disabled(isRequestingHK)
            }
        }
        .navigationTitle("Settings")
        .onAppear {
            viewModel = SettingsViewModel(modelContext: modelContext)
            loadFromActiveUser()
        }
        // Req 6.5: apply new user's preferences immediately on active user switch
        .onChange(of: userViewModel.activeUser) { _, _ in
            loadFromActiveUser()
        }
    }

    // MARK: - Helpers

    private func loadFromActiveUser() {
        guard let user = userViewModel.activeUser else { return }
        name = user.name
        colorTag = user.colorTag ?? ""
        usesHealthKit = user.usesHealthKit
        cardioSource = user.preferredCardioSource
        validationError = nil
        saveError = nil
    }

    private func save() {
        guard let user = userViewModel.activeUser, let vm = viewModel else { return }
        validationError = nil
        saveError = nil
        let tagValue: String? = colorTag.isEmpty ? nil : colorTag
        do {
            // Req 12.5: persist immediately on save
            try vm.saveUserPreferences(
                for: user,
                name: name,
                colorTag: tagValue,
                usesHealthKit: usesHealthKit,
                cardioSource: cardioSource
            )
        } catch SettingsViewModelError.invalidName {
            validationError = "Name cannot be empty."
        } catch {
            saveError = "Save failed. Please try again."
        }
    }

    private func requestHealthKitIfNeeded() async {
        guard let vm = viewModel else { return }
        isRequestingHK = true
        defer { isRequestingHK = false }
        do {
            try await vm.requestHealthKitPermissions()
        } catch {
            // If permission denied, revert toggle and show error
            usesHealthKit = false
            saveError = "HealthKit access was denied. Please enable it in Settings > Privacy > Health."
        }
    }

    private func color(for tag: String) -> Color {
        switch tag.lowercased() {
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

#Preview {
    let container = try! ModelContainer(
        for: User.self, Machine.self, WorkoutSession.self,
             StrengthSet.self, CardioSession.self, WorkoutFlow.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let ctx = container.mainContext
    let user = User(name: "Preview User", colorTag: "blue")
    ctx.insert(user)
    let vm = UserViewModel(modelContext: ctx)
    vm.selectUser(user)
    return NavigationStack {
        SettingsView()
    }
    .environment(vm)
    .modelContainer(container)
}
