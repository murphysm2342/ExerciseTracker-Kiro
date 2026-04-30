import SwiftUI
import SwiftData

/// The main strength workout session screen for today.
/// Shows machines already logged and lets the user add more.
struct ActiveWorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(UserViewModel.self) private var userViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: ActiveWorkoutViewModel
    @State private var showMachinePicker = false
    @State private var selectedMachine: Machine?
    @State private var navigateToMachine = false

    init(user: User, modelContext: ModelContext, date: Date = Date()) {
        _viewModel = State(
            wrappedValue: ActiveWorkoutViewModel(modelContext: modelContext, user: user, date: date)
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.machinesInSession.isEmpty {
                    emptyState
                } else {
                    machineList
                }

                Spacer()

                addMachineButton
                    .padding()
            }
            .navigationTitle("Today's Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            // Navigate to logging view after picking a machine from the picker sheet
            .navigationDestination(isPresented: $navigateToMachine) {
                if let machine = selectedMachine {
                    machineLoggingView(for: machine)
                }
            }
            // Navigate to logging view for machines already in the session (via NavigationLink value)
            .navigationDestination(for: Machine.self) { machine in
                machineLoggingView(for: machine)
            }
            .sheet(isPresented: $showMachinePicker) {
                WorkoutMachinePickerView(
                    session: viewModel.session,
                    onSelect: { machine in
                        selectedMachine = machine
                        navigateToMachine = true
                    }
                )
            }
        }
    }

    // MARK: - Subviews

    private var emptyState: some View {
        ContentUnavailableView(
            "No Machines Yet",
            systemImage: "dumbbell",
            description: Text("Tap \"Add Machine\" to start logging sets.")
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var machineList: some View {
        List {
            ForEach(viewModel.machinesInSession) { machine in
                NavigationLink(value: machine) {
                    MachineSessionRowView(
                        machine: machine,
                        sets: viewModel.sets(for: machine)
                    )
                }
            }
        }
        .listStyle(.plain)
    }

    private var addMachineButton: some View {
        Button {
            showMachinePicker = true
        } label: {
            Label("Add Machine", systemImage: "plus.circle.fill")
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .fontWeight(.semibold)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func machineLoggingView(for machine: Machine) -> some View {
        StrengthLoggingView(
            machine: machine,
            user: viewModel.session.user,
            session: viewModel.session,
            modelContext: modelContext
        )
    }
}

// MARK: - MachineSessionRowView

private struct MachineSessionRowView: View {
    let machine: Machine
    let sets: [StrengthSet]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(machine.name)
                    .font(.headline)
                if machine.isFavorite {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                }
            }
            if sets.isEmpty {
                Text("No sets yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                let completed = sets.filter(\.isCompleted).count
                Text("\(completed)/\(sets.count) sets completed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(sets.map { setLabel($0) }.joined(separator: "  ·  "))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }

    private func setLabel(_ set: StrengthSet) -> String {
        let w = StrengthLoggingViewModel.formatDouble(set.weight)
        return "\(w)lb × \(set.reps)"
    }
}

// MARK: - WorkoutMachinePickerView

struct WorkoutMachinePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(UserViewModel.self) private var userViewModel

    let session: WorkoutSession
    let onSelect: (Machine) -> Void

    @State private var machineListVM: MachineListViewModel?
    @State private var showAddMachine = false
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            Group {
                if let vm = machineListVM {
                    pickerContent(vm: vm)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Select Machine")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search machines")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddMachine = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddMachine) {
                if let vm = machineListVM {
                    MachineFormView(viewModel: vm, machine: nil)
                }
            }
            .onAppear {
                if let user = userViewModel.activeUser {
                    machineListVM = MachineListViewModel(modelContext: modelContext, user: user)
                }
            }
        }
    }

    @ViewBuilder
    private func pickerContent(vm: MachineListViewModel) -> some View {
        let filtered = searchText.isEmpty
            ? vm.machines
            : vm.machines.filter { $0.name.localizedCaseInsensitiveContains(searchText) }

        if filtered.isEmpty {
            ContentUnavailableView.search(text: searchText)
        } else {
            List(filtered) { machine in
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

                    Button {
                        vm.toggleFavorite(machine)
                    } label: {
                        Image(systemName: machine.isFavorite ? "star.fill" : "star")
                            .foregroundStyle(machine.isFavorite ? .yellow : .secondary)
                    }
                    .buttonStyle(.plain)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    onSelect(machine)
                    dismiss()
                }
            }
        }
    }
}
