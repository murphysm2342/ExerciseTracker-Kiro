import SwiftUI
import SwiftData

struct MachineListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(UserViewModel.self) private var userViewModel

    @State private var viewModel: MachineListViewModel?
    @State private var showAddSheet = false
    @State private var machineToEdit: Machine?
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if let vm = viewModel {
                machineList(vm: vm)
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Exercises")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(Color.brand)
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            if let vm = viewModel {
                MachineFormView(viewModel: vm, machine: nil)
            }
        }
        .sheet(item: $machineToEdit) { machine in
            if let vm = viewModel {
                MachineFormView(viewModel: vm, machine: machine)
            }
        }
        .alert("Error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .onAppear {
            if let user = userViewModel.activeUser {
                viewModel = MachineListViewModel(modelContext: modelContext, user: user)
            }
        }
        .onChange(of: userViewModel.activeUser) { _, newUser in
            if let user = newUser {
                viewModel = MachineListViewModel(modelContext: modelContext, user: user)
            } else {
                viewModel = nil
            }
        }
    }

    // MARK: - Machine List

    @ViewBuilder
    private func machineList(vm: MachineListViewModel) -> some View {
        if vm.machines.isEmpty {
            ContentUnavailableView(
                "No Exercises",
                systemImage: "dumbbell",
                description: Text("Tap + to add your first exercise.")
            )
        } else {
            List {
                let favorites = vm.machines.filter { $0.isFavorite }
                let others = vm.machines.filter { !$0.isFavorite }

                if !favorites.isEmpty {
                    Section("Favorites") {
                        ForEach(favorites) { machine in
                            machineRow(machine: machine, vm: vm)
                        }
                    }
                }

                if !others.isEmpty {
                    Section(favorites.isEmpty ? "" : "All Exercises") {
                        ForEach(others) { machine in
                            machineRow(machine: machine, vm: vm)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Machine Row

    private func machineRow(machine: Machine, vm: MachineListViewModel) -> some View {
        HStack(spacing: 12) {
            IconBadge(
                systemName: MachineIconProvider.icon(for: machine.name, category: machine.category),
                color: MachineIconProvider.categoryColor(for: machine.category ?? ""),
                size: 36
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(machine.name)
                    .font(.body)
                    .fontWeight(.medium)
                if let category = machine.category, !category.isEmpty {
                    Text(category)
                        .font(.caption)
                        .foregroundStyle(Color.subtleText)
                }
            }
            Spacer()
            Button {
                vm.toggleFavorite(machine)
            } label: {
                Image(systemName: machine.isFavorite ? "star.fill" : "star")
                    .foregroundStyle(machine.isFavorite ? .yellow : .secondary)
                    .font(.body)
            }
            .buttonStyle(.plain)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            machineToEdit = machine
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                do {
                    try vm.deleteMachine(machine)
                } catch {
                    errorMessage = "Failed to delete exercise."
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading) {
            Button {
                machineToEdit = machine
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.brand)
        }
    }
}

// MARK: - Machine Form Sheet

struct MachineFormView: View {
    @Environment(\.dismiss) private var dismiss

    let viewModel: MachineListViewModel
    let machine: Machine?

    @State private var name: String = ""
    @State private var category: String = ""
    @State private var isFavorite: Bool = false
    @State private var validationError: String?

    private var isEditing: Bool { machine != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Name", text: $name)
                    TextField("Category (optional)", text: $category)
                }
                Section {
                    Toggle("Favorite", isOn: $isFavorite)
                }
                if let error = validationError {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Exercise" : "Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.brand)
                }
            }
            .onAppear {
                if let machine {
                    name = machine.name
                    category = machine.category ?? ""
                    isFavorite = machine.isFavorite
                }
            }
        }
    }

    private func save() {
        let categoryValue: String? = category.trimmingCharacters(in: .whitespaces).isEmpty
            ? nil
            : category.trimmingCharacters(in: .whitespaces)

        do {
            if let machine {
                try viewModel.updateMachine(machine, name: name, category: categoryValue, isFavorite: isFavorite)
            } else {
                try viewModel.addMachine(name: name, category: categoryValue, isFavorite: isFavorite)
            }
            dismiss()
        } catch MachineListViewModelError.invalidName {
            validationError = "Name cannot be empty."
        } catch {
            validationError = "Failed to save exercise."
        }
    }
}

#Preview {
    @Previewable @State var vm: UserViewModel? = nil

    let container = try! ModelContainer(
        for: User.self, Machine.self, WorkoutSession.self,
             StrengthSet.self, CardioSession.self, WorkoutFlow.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let ctx = container.mainContext
    let user = User(name: "Preview User", colorTag: "blue")
    ctx.insert(user)

    let viewModel = UserViewModel(modelContext: ctx)
    viewModel.selectUser(user)
    vm = viewModel

    return NavigationStack {
        MachineListView()
    }
    .environment(vm!)
    .modelContainer(container)
}
