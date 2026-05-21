import SwiftUI
import SwiftData

struct StrengthLoggingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(UserViewModel.self) private var userViewModel
    @Environment(PBCelebrationManager.self) private var celebrationManager
    @Environment(\.modelContext) private var modelContext

    let machineName: String
    let initialMachine: Machine
    let initialUser: User
    let initialSession: WorkoutSession
    let passedModelContext: ModelContext

    @State private var viewModel: StrengthLoggingViewModel
    @State private var selectedUserId: UUID

    init(machine: Machine, user: User, session: WorkoutSession, modelContext: ModelContext) {
        self.machineName = machine.name
        self.initialMachine = machine
        self.initialUser = user
        self.initialSession = session
        self.passedModelContext = modelContext
        _viewModel = State(
            wrappedValue: StrengthLoggingViewModel(
                modelContext: modelContext,
                machine: machine,
                user: user,
                session: session
            )
        )
        _selectedUserId = State(initialValue: user.id)
    }

    var body: some View {
        VStack(spacing: 0) {
            if userViewModel.allUsers.count > 1 {
                profileSwitcher
            }

            Button {
                viewModel.addSet()
            } label: {
                Label("Add Set", systemImage: "plus.circle.fill")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.brand.opacity(0.1))
                    .foregroundStyle(Color.brand)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.smallRadius))
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 4)

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.sets.reversed()) { set in
                        SetEditorView(
                            set: set,
                            activeFieldTarget: $viewModel.activeFieldTarget,
                            fieldBuffers: viewModel.fieldBuffers,
                            onActivate: { target in viewModel.activateField(target) },
                            onRepsAdjust: { amount in viewModel.adjustReps(for: set.id, by: amount) },
                            onDelete: { viewModel.deleteSet(set) }
                        )
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical, 8)
            }

            Divider()

            NumberPadView { action in
                viewModel.handleNumberPadAction(action)
            }

            Button {
                trySave()
            } label: {
                Text("Done")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(LinearGradient.brandGradient)
                    .foregroundStyle(.white)
                    .fontWeight(.semibold)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.buttonRadius))
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
            .padding(.top, 8)
        }
        .navigationTitle(machineName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var profileSwitcher: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(userViewModel.allUsers, id: \.id) { user in
                    let isSelected = user.id == selectedUserId
                    Button {
                        switchToUser(user)
                    } label: {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(profileColor(for: user.colorTag).gradient)
                                .frame(width: 20, height: 20)
                                .overlay(
                                    Text(String(user.name.prefix(1)).uppercased())
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.white)
                                )
                            Text(user.name)
                                .font(.caption)
                                .fontWeight(isSelected ? .bold : .regular)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(isSelected ? Color.brand.opacity(0.15) : Color.cardBackground)
                        .foregroundStyle(isSelected ? Color.brand : .primary)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .strokeBorder(isSelected ? Color.brand : Color.clear, lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
        }
    }

    private func switchToUser(_ user: User) {
        guard user.id != selectedUserId else { return }

        try? viewModel.saveSession()

        guard let machine = user.machines.first(where: { $0.name == machineName }) else { return }

        let calendar = Calendar.current
        let session = user.workoutSessions.first(where: {
            $0.type == .strength && calendar.isDateInToday($0.date)
        }) ?? {
            let s = WorkoutSession(type: .strength, user: user)
            passedModelContext.insert(s)
            try? passedModelContext.save()
            return s
        }()

        selectedUserId = user.id
        viewModel = StrengthLoggingViewModel(
            modelContext: passedModelContext,
            machine: machine,
            user: user,
            session: session
        )
    }

    private func trySave() {
        do {
            try viewModel.saveSession()
            let pb = computePB()
            dismiss()
            if let pb {
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(500))
                    celebrationManager.celebrate(pb)
                }
            }
        } catch {
            print("Save error: \(error)")
        }
    }

    private func computePB() -> PBAchievement? {
        guard let user = userViewModel.activeUser, user.celebrationsEnabled else { return nil }
        return PersonalBestService.checkStrengthPB(
            machine: initialMachine,
            session: initialSession,
            user: user
        )
    }

    private func profileColor(for tag: String?) -> Color {
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
