import SwiftUI
import SwiftData

/// Lists all WorkoutFlows for the active user and allows create/edit/delete.
/// Replaces the placeholder in SettingsView.
/// Requirements: 7.1, 7.2, 7.3, 7.4
struct WorkoutFlowListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(UserViewModel.self) private var userViewModel

    @State private var flows: [WorkoutFlow] = []
    @State private var showBuilder = false
    @State private var flowToEdit: WorkoutFlow?
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if flows.isEmpty {
                ContentUnavailableView(
                    "No Workout Flows",
                    systemImage: "list.bullet.rectangle",
                    description: Text("Tap + to create your first workout flow.")
                )
            } else {
                List {
                    ForEach(flows) { flow in
                        flowRow(flow)
                    }
                    .onDelete { indices in
                        deleteFlows(at: indices)
                    }
                }
            }
        }
        .navigationTitle("Workout Flows")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showBuilder = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showBuilder, onDismiss: fetchFlows) {
            WorkoutFlowBuilderView(flow: nil)
        }
        .sheet(item: $flowToEdit, onDismiss: fetchFlows) { flow in
            WorkoutFlowBuilderView(flow: flow)
        }
        .alert("Error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .onAppear { fetchFlows() }
        .onChange(of: userViewModel.activeUser) { _, _ in fetchFlows() }
    }

    // MARK: - Row

    private func flowRow(_ flow: WorkoutFlow) -> some View {
        let ordered = WorkoutFlowService.orderedMachines(for: flow)
        return VStack(alignment: .leading, spacing: 4) {
            Text(flow.name)
                .font(.headline)
            if ordered.isEmpty {
                Text("No exercises")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text(ordered.map(\.name).joined(separator: " → "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            flowToEdit = flow
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                deleteFlow(flow)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading) {
            Button {
                flowToEdit = flow
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.blue)
        }
    }

    // MARK: - Data

    private func fetchFlows() {
        guard let user = userViewModel.activeUser else {
            flows = []
            return
        }
        let userId = user.id
        let descriptor = FetchDescriptor<WorkoutFlow>(
            sortBy: [SortDescriptor(\.createdAt)]
        )
        let all = (try? modelContext.fetch(descriptor)) ?? []
        flows = all.filter { $0.user.id == userId }
    }

    private func deleteFlow(_ flow: WorkoutFlow) {
        let service = WorkoutFlowService(modelContext: modelContext)
        do {
            try service.deleteFlow(flow)
            fetchFlows()
        } catch {
            errorMessage = "Failed to delete flow."
        }
    }

    private func deleteFlows(at indices: IndexSet) {
        for index in indices {
            deleteFlow(flows[index])
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
    let m1 = Machine(name: "Bench Press", category: "Chest", user: user)
    let m2 = Machine(name: "Squat Rack", category: "Legs", user: user)
    ctx.insert(m1); ctx.insert(m2)
    let flow = WorkoutFlow(name: "Push Day", machineOrder: [m1.id, m2.id], user: user, machines: [m1, m2])
    ctx.insert(flow)
    let vm = UserViewModel(modelContext: ctx)
    vm.selectUser(user)
    return NavigationStack {
        WorkoutFlowListView()
    }
    .environment(vm)
    .modelContainer(container)
}
