import SwiftUI
import SwiftData
import HealthKit

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(UserViewModel.self) private var userViewModel

    @State private var viewModel: SettingsViewModel?

    @State private var name: String = ""
    @State private var colorTag: String = ""
    @State private var usesHealthKit: Bool = false
    @State private var syncToHealthKit: Bool = false
    @State private var cardioSource: CardioSource = .manual
    @State private var celebrationsEnabled: Bool = true

    @State private var validationError: String?
    @State private var saveError: String?
    @State private var isRequestingHK: Bool = false
    @State private var showSaveSuccess: Bool = false

    private let colorOptions = ["red", "blue", "green", "orange", "purple", "yellow", "pink", "gray"]

    var body: some View {
        Form {
            Section {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(color(for: colorTag).gradient)
                            .frame(width: 48, height: 48)
                        Text(String(name.prefix(1)).uppercased())
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Profile")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("Name", text: $name)
                            .font(.body)
                            .fontWeight(.medium)
                    }
                }
                .listRowBackground(Color.cardBackground)

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
                .listRowBackground(Color.cardBackground)
            }

            Section("Cardio Preferences") {
                if HKHealthStore.isHealthDataAvailable() {
                    Toggle("Use HealthKit", isOn: $usesHealthKit)
                        .tint(.brand)
                        .onChange(of: usesHealthKit) { oldValue, newValue in
                            if newValue && !oldValue {
                                Task { await requestHealthKitIfNeeded() }
                            }
                        }
                } else {
                    HStack {
                        Text("Use HealthKit")
                        Spacer()
                        Text("Not Available")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Picker("Cardio Source", selection: $cardioSource) {
                    Text("Manual Entry").tag(CardioSource.manual)
                    if HKHealthStore.isHealthDataAvailable() {
                        Text("HealthKit").tag(CardioSource.healthKit)
                    }
                }
                .pickerStyle(.segmented)
            }
            .listRowBackground(Color.cardBackground)

            Section("HealthKit Export") {
                if HKHealthStore.isHealthDataAvailable() {
                    Toggle("Sync Workouts to Health", isOn: $syncToHealthKit)
                        .tint(.brand)
                        .onChange(of: syncToHealthKit) { oldValue, newValue in
                            if newValue && !oldValue {
                                Task { await requestHealthKitIfNeeded() }
                            }
                        }
                } else {
                    HStack {
                        Text("Sync Workouts to Health")
                        Spacer()
                        Text("Not Available")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Text(HKHealthStore.isHealthDataAvailable()
                     ? "Automatically export your workouts to the Health app."
                     : "HealthKit is not available on this device.")
                    .font(.caption)
                    .foregroundStyle(Color.subtleText)
            }
            .listRowBackground(Color.cardBackground)

            Section("Celebrations") {
                Toggle("Celebrate Personal Bests", isOn: $celebrationsEnabled)
                    .tint(.brand)
                Text("Show confetti when you hit a new PB on an exercise or cardio activity.")
                    .font(.caption)
                    .foregroundStyle(Color.subtleText)
            }
            .listRowBackground(Color.cardBackground)

            Section("Manage") {
                NavigationLink {
                    MachineListView()
                } label: {
                    HStack(spacing: 12) {
                        IconBadge(systemName: "dumbbell.fill", color: .strengthAccent, size: 32)
                        Text("Exercises")
                    }
                }

                NavigationLink {
                    WorkoutFlowListView()
                } label: {
                    HStack(spacing: 12) {
                        IconBadge(systemName: "list.bullet.rectangle", color: .brand, size: 32)
                        Text("Workout Flows")
                    }
                }

                NavigationLink {
                    DataBackupView()
                } label: {
                    HStack(spacing: 12) {
                        IconBadge(systemName: "externaldrive.fill", color: .orange, size: 32)
                        Text("Backup & Restore")
                    }
                }
            }
            .listRowBackground(Color.cardBackground)

            if let error = validationError ?? saveError {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }

            Section {
                Button {
                    save()
                } label: {
                    HStack(spacing: 8) {
                        if showSaveSuccess {
                            Image(systemName: "checkmark")
                                .fontWeight(.bold)
                                .transition(.scale.combined(with: .opacity))
                        }
                        Text(showSaveSuccess ? "Saved!" : "Save")
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                    .animation(.easeInOut(duration: 0.2), value: showSaveSuccess)
                }
                .listRowBackground(showSaveSuccess ? Color.green : Color.brand)
                .disabled(isRequestingHK || showSaveSuccess)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.surfaceLight)
        .navigationTitle("Settings")
        .onAppear {
            viewModel = SettingsViewModel(modelContext: modelContext)
            loadFromActiveUser()
        }
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
        syncToHealthKit = user.syncToHealthKit
        cardioSource = user.preferredCardioSource
        celebrationsEnabled = user.celebrationsEnabled
        validationError = nil
        saveError = nil
    }

    private func save() {
        guard let user = userViewModel.activeUser, let vm = viewModel else { return }
        validationError = nil
        saveError = nil
        let tagValue: String? = colorTag.isEmpty ? nil : colorTag
        do {
            try vm.saveUserPreferences(
                for: user,
                name: name,
                colorTag: tagValue,
                usesHealthKit: usesHealthKit,
                syncToHealthKit: syncToHealthKit,
                cardioSource: cardioSource,
                celebrationsEnabled: celebrationsEnabled
            )
            withAnimation {
                showSaveSuccess = true
            }
            Task {
                try? await Task.sleep(for: .seconds(1.5))
                withAnimation {
                    showSaveSuccess = false
                }
            }
        } catch SettingsViewModelError.invalidName {
            validationError = "Name cannot be empty."
        } catch {
            saveError = "Save failed. Please try again."
        }
    }

    private func requestHealthKitIfNeeded() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            usesHealthKit = false
            syncToHealthKit = false
            saveError = "HealthKit is not available on this device."
            return
        }
        guard let vm = viewModel else { return }
        isRequestingHK = true
        defer { isRequestingHK = false }
        do {
            try await vm.requestHealthKitPermissions()
        } catch {
            usesHealthKit = false
            syncToHealthKit = false
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
