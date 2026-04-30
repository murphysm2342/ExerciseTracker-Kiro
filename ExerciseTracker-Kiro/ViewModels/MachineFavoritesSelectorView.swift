import SwiftUI
import SwiftData

/// Allows a new user to select their favorite machines from the default catalog.
/// Requirements: 2.2 (favorite selection for new profiles)
struct MachineFavoritesSelectorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let user: User
    var onComplete: () -> Void
    
    @State private var selectedMachines: Set<UUID> = []
    
    private var machines: [Machine] {
        user.machines.sorted { $0.name < $1.name }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                headerView
                machineListView
            }
            .navigationTitle("Select Favorites")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") {
                        dismiss()
                        onComplete()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        saveFavorites()
                        dismiss()
                        onComplete()
                    }
                    .disabled(selectedMachines.isEmpty)
                }
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 8) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.yellow)
            
            Text("Select Your Favorite Machines")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Choose the machines you use most often. You can change this later.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    private var machineListView: some View {
        List {
            ForEach(machines, id: \.id) { machine in
                machineRowView(for: machine)
            }
        }
    }
    
    private func machineRowView(for machine: Machine) -> some View {
        Button {
            toggleSelection(machine.id)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(machine.name)
                        .foregroundStyle(.primary)
                    if let category = machine.category {
                        Text(category)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if selectedMachines.contains(machine.id) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.tint)
                } else {
                    Image(systemName: "circle")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    private func toggleSelection(_ machineID: UUID) {
        if selectedMachines.contains(machineID) {
            selectedMachines.remove(machineID)
        } else {
            selectedMachines.insert(machineID)
        }
    }
    
    private func saveFavorites() {
        for machine in machines where selectedMachines.contains(machine.id) {
            machine.isFavorite = true
        }
        
        do {
            try modelContext.save()
            print("✅ Saved \(selectedMachines.count) favorite machines for \(user.name)")
        } catch {
            print("❌ Failed to save favorites: \(error)")
        }
    }
}
