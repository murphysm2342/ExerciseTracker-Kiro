import SwiftUI
import SwiftData

/// Create or edit a WorkoutFlow with an ordered machine list.
/// Requirements: 7.1, 7.2, 7.3, 7.7
struct WorkoutFlowBuilderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(UserViewModel.self) private var userViewModel

    /// Pass an existing flow to edit; nil to create a new one.
    var flow: WorkoutFlow?

    @State private var name: String = ""
    /// Ordered list of machines selected for this flow.
    @State private var orderedMachines: [Machine] = []
    @State private var showMachinePicker = false
    @State private var validationError: String?

    private var isEditing: Bool { flow != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Flow Name") {
                    TextField("e.g. Push Day", text: $name)
                }

                Section {
                    if orderedMachines.isEmpty {
                        Text("No machines added yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(orderedMachines) { machine in
                            HStack {
                                Image(systemName: "line.3.horizontal")
                                    .foregroundStyle(.secondary)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(machine.name)
                                    if let cat = machine.category, !cat.isEmpty {
                                        Text(cat)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                        .onMove { indices, newOffset in
                            orderedMachines.move(fromOffsets: indices, toOffset: newOffset)
                        }
                        .onDelete { indices in
                            orderedMachines.remove(atOffsets: indices)
                        }
                    }

                    Button {
                        showMachinePicker = true
                    } label: {
                        Label("Add Machine", systemImage: "plus")
                    }
                } header: {
                    HStack {
                        Text("Machines (in order)")
                        Spacer()
                        if !orderedMachines.isEmpty {
                            EditButton()
                                .font(.caption)
                        }
                    }
                }

                if let error = validationError {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Flow" : "New Flow")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
            .sheet(isPresented: $showMachinePicker) {
                MachinePickerView(
                    alreadySelected: orderedMachines,
                    onSelect: { machine in
                        if !orderedMachines.contains(where: { $0.id == machine.id }) {
                            orderedMachines.append(machine)
                        }
                    }
                )
            }
            .onAppear { loadExistingFlow() }
        }
    }

    // MARK: - Helpers

    private func loadExistingFlow() {
        guard let flow else { return }
        name = flow.name
        orderedMachines = WorkoutFlowService.orderedMachines(for: flow)
    }

    private func save() {
        guard let user = userViewModel.activeUser else { return }
        validationError = nil
        let service = WorkoutFlowService(modelContext: modelContext)

        do {
            if let flow {
                try service.updateFlow(flow, name: name, machines: orderedMachines)
            } else {
                _ = try service.createFlow(name: name, machines: orderedMachines, for: user)
            }
            dismiss()
        } catch WorkoutFlowServiceError.invalidName {
            validationError = "Flow name cannot be empty."
        } catch {
            validationError = "Failed to save flow. Please try again."
        }
    }
}

// MARK: - Machine Picker Sheet

/// Lets the user pick a machine to add to the flow.
private struct MachinePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(UserViewModel.self) private var userViewModel

    let alreadySelected: [Machine]
    let onSelect: (Machine) -> Void

    @State private var machines: [Machine] = []

    var body: some View {
        NavigationStack {
            Group {
                if machines.isEmpty {
                    ContentUnavailableView(
                        "No Machines",
                        systemImage: "dumbbell",
                        description: Text("Add machines in the Machines settings first.")
                    )
                } else {
                    List(machines) { machine in
                        Button {
                            onSelect(machine)
                            dismiss()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(machine.name)
                                        .foregroundStyle(.primary)
                                    if let cat = machine.category, !cat.isEmpty {
                                        Text(cat)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                if alreadySelected.contains(where: { $0.id == machine.id }) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Machine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear { fetchMachines() }
        }
    }

    private func fetchMachines() {
        guard let user = userViewModel.activeUser else { return }
        let userId = user.id
        let descriptor = FetchDescriptor<Machine>(
            sortBy: [SortDescriptor(\.name)]
        )
        let all = (try? modelContext.fetch(descriptor)) ?? []
        machines = all.filter { $0.user.id == userId }
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
    let m1 = Machine(name: "Bench Press", category: "Chest", user: user)
    let m2 = Machine(name: "Squat Rack", category: "Legs", user: user)
    ctx.insert(m1); ctx.insert(m2)
    let vm = UserViewModel(modelContext: ctx)
    vm.selectUser(user)
    return WorkoutFlowBuilderView()
        .environment(vm)
        .modelContainer(container)
}
