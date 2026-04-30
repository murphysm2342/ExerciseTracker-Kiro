import SwiftUI
import SwiftData
import CoreNFC

struct HomeView: View {
    @Environment(UserViewModel.self) private var userViewModel
    @Environment(\.modelContext) private var modelContext

    @State private var showProfileSelector = false
    @State private var showActiveWorkout = false
    @State private var showCardio = false
    @State private var historyViewModel: HistoryViewModel?

    @State private var nfcService = NFCService()
    @State private var showNFCAssociation = false
    @State private var pendingNFCTagId: String?
    @State private var nfcCardioType: CardioMachineType?
    @State private var showNFCCardio = false
    @State private var showNFCStrength = false
    @State private var nfcStrengthMachine: Machine?
    @State private var nfcError: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignTokens.sectionSpacing) {
                    activeUserHeader
                    quickStatsRow
                    if nfcService.isAvailable {
                        nfcScanButton
                    }
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
            .sheet(isPresented: $showNFCCardio) {
                if let user = userViewModel.activeUser {
                    historyViewModel?.refresh(for: user)
                }
            } content: {
                if let user = userViewModel.activeUser, let type = nfcCardioType {
                    NavigationStack {
                        CardioLoggingView(user: user, preselectedMachineType: type)
                    }
                }
            }
            .sheet(isPresented: $showNFCStrength) {
                if let user = userViewModel.activeUser {
                    historyViewModel?.refresh(for: user)
                }
            } content: {
                if let user = userViewModel.activeUser, let machine = nfcStrengthMachine {
                    NavigationStack {
                        StrengthLoggingView(
                            machine: machine,
                            user: user,
                            session: getOrCreateSession(for: user),
                            modelContext: modelContext
                        )
                    }
                }
            }
            .sheet(isPresented: $showNFCAssociation) {
                if let tagId = pendingNFCTagId {
                    NFCAssociationView(tagId: tagId) { mapping in
                        NFCTagStore.save(tagId: tagId, mapping: mapping)
                        showNFCAssociation = false
                        handleMapping(mapping)
                    }
                }
            }
            .alert("NFC Error", isPresented: Binding(
                get: { nfcError != nil },
                set: { if !$0 { nfcError = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(nfcError ?? "")
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

    // MARK: - NFC Scan Button

    private var nfcScanButton: some View {
        Button {
            Task { await performNFCScan() }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "wave.3.right")
                    .font(.title3)
                    .symbolEffect(.variableColor.iterative, isActive: nfcService.isScanning)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Scan Machine")
                        .font(.headline)
                    Text("Tap your phone on a gym machine's NFC tag")
                        .font(.caption)
                        .opacity(0.85)
                }
                Spacer()
                Image(systemName: "iphone.radiowaves.left.and.right")
                    .font(.subheadline)
                    .opacity(0.7)
            }
            .foregroundStyle(.white)
            .padding(DesignTokens.cardPadding)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.3, green: 0.3, blue: 0.35), Color(red: 0.45, green: 0.45, blue: 0.5)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cornerRadius))
            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        }
        .disabled(userViewModel.activeUser == nil || nfcService.isScanning)
    }

    private func performNFCScan() async {
        do {
            let tagId = try await nfcService.scan()
            if let mapping = NFCTagStore.mapping(for: tagId) {
                handleMapping(mapping)
            } else {
                pendingNFCTagId = tagId
                showNFCAssociation = true
            }
        } catch let error as NFCScanError {
            if case .cancelled = error { return }
            nfcError = error.localizedDescription
        } catch {
            nfcError = error.localizedDescription
        }
    }

    private func handleMapping(_ mapping: NFCTagMapping) {
        switch mapping.kind {
        case .cardio:
            if let type = mapping.cardioMachineType {
                nfcCardioType = type
                showNFCCardio = true
            }
        case .strength:
            if let machineId = mapping.strengthMachineId,
               let user = userViewModel.activeUser {
                nfcStrengthMachine = user.machines.first { $0.id == machineId }
                if nfcStrengthMachine != nil {
                    showNFCStrength = true
                }
            }
        }
    }

    private func getOrCreateSession(for user: User) -> WorkoutSession {
        let calendar = Calendar.current
        if let existing = user.workoutSessions.first(where: {
            $0.type == .strength && calendar.isDateInToday($0.date)
        }) {
            return existing
        }
        let session = WorkoutSession(type: .strength, user: user)
        modelContext.insert(session)
        try? modelContext.save()
        return session
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
                        Text("Log sets for your machines")
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

// MARK: - NFC Association View

struct NFCAssociationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(UserViewModel.self) private var userViewModel

    let tagId: String
    let onAssociate: (NFCTagMapping) -> Void

    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: DesignTokens.sectionSpacing) {
                VStack(spacing: 6) {
                    Image(systemName: "wave.3.right.circle.fill")
                        .font(.largeTitle)
                        .foregroundStyle(Color.brand)
                    Text("New Machine Detected")
                        .font(.headline)
                    Text("What type of machine is this?")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top)

                Picker("Type", selection: $selectedTab) {
                    Text("Cardio").tag(0)
                    Text("Strength").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                if selectedTab == 0 {
                    cardioOptions
                } else {
                    strengthOptions
                }

                Spacer()
            }
            .navigationTitle("Assign Machine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var cardioOptions: some View {
        VStack(spacing: 10) {
            ForEach(CardioMachineType.allCases) { type in
                Button {
                    onAssociate(NFCTagMapping(
                        kind: .cardio,
                        strengthMachineId: nil,
                        cardioMachineType: type
                    ))
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: type.iconName)
                            .font(.title3)
                            .frame(width: 32)
                        Text(type.displayName)
                            .font(.body)
                            .fontWeight(.medium)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .foregroundStyle(.primary)
                    .cardStyle()
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
    }

    private var strengthOptions: some View {
        ScrollView {
            VStack(spacing: 8) {
                if let user = userViewModel.activeUser {
                    ForEach(user.machines.sorted(by: { $0.name < $1.name })) { machine in
                        Button {
                            onAssociate(NFCTagMapping(
                                kind: .strength,
                                strengthMachineId: machine.id,
                                cardioMachineType: nil
                            ))
                        } label: {
                            HStack(spacing: 14) {
                                IconBadge(
                                    systemName: MachineIconProvider.icon(for: machine.name, category: machine.category),
                                    color: MachineIconProvider.categoryColor(for: machine.category ?? ""),
                                    size: 32
                                )
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(machine.name)
                                        .font(.body)
                                        .fontWeight(.medium)
                                    if let cat = machine.category {
                                        Text(cat)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            .foregroundStyle(.primary)
                            .cardStyle()
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal)
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
