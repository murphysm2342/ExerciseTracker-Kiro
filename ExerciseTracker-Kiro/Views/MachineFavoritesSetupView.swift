import SwiftUI
import SwiftData

/// Shown after a new profile is created so the user can mark favorite machines
/// before their first workout. (#13)
struct MachineFavoritesSetupView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let user: User

    @State private var machineVM: MachineListViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let vm = machineVM {
                    if vm.machines.isEmpty {
                        // Debug view - should not normally appear if seeding worked
                        ContentUnavailableView(
                            "No Machines Available",
                            systemImage: "exclamationmark.triangle",
                            description: Text("Default machines failed to load. Please contact support.")
                        )
                    } else {
                        content(vm: vm)
                    }
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Pick Your Favorites")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                print("📱 MachineFavoritesSetupView appeared for user: \(user.name)")
                print("📱 User has \(user.machines.count) machines")
                machineVM = MachineListViewModel(modelContext: modelContext, user: user)
                if let vm = machineVM {
                    print("📱 ViewModel loaded \(vm.machines.count) machines")
                }
            }
        }
    }

    @ViewBuilder
    private func content(vm: MachineListViewModel) -> some View {
        VStack(spacing: 0) {
            Text("Star the machines you use most. They'll appear at the top when starting a workout.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.vertical, 12)

            List {
                // Group by category
                let grouped = groupedByCategory(vm.machines)
                ForEach(grouped, id: \.category) { group in
                    Section(group.category) {
                        ForEach(group.machines) { machine in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(machine.name)
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
                                        .font(.title3)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
    }

    private struct CategoryGroup {
        let category: String
        let machines: [Machine]
    }

    private func groupedByCategory(_ machines: [Machine]) -> [CategoryGroup] {
        var order: [String] = []
        var dict: [String: [Machine]] = [:]
        for machine in machines.sorted(by: { $0.name < $1.name }) {
            let cat = machine.category ?? "Other"
            if dict[cat] == nil {
                order.append(cat)
                dict[cat] = []
            }
            dict[cat]!.append(machine)
        }
        return order.sorted().map { CategoryGroup(category: $0, machines: dict[$0]!) }
    }
}
