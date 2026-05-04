import SwiftUI

struct WatchStrengthPickerView: View {
    @Environment(WatchConnectivityService.self) private var connectivity
    @State private var selectedSets: [UUID: [WatchStrengthSet]] = [:]
    @State private var workoutStarted = false

    var body: some View {
        Group {
            if connectivity.machines.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "iphone.and.arrow.forward")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("No machines synced")
                        .font(.headline)
                    Text("Open the iPhone app to sync your machines.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Retry Sync") {
                        connectivity.requestMachineSync()
                    }
                    .font(.caption)
                }
            } else {
                List {
                    ForEach(connectivity.machines) { machine in
                        NavigationLink {
                            WatchSetLoggerView(
                                machine: machine,
                                sets: Binding(
                                    get: { selectedSets[machine.id] ?? [] },
                                    set: { selectedSets[machine.id] = $0 }
                                )
                            )
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(machine.name)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    if let cat = machine.category {
                                        Text(cat)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                if let sets = selectedSets[machine.id], !sets.isEmpty {
                                    Text("\(sets.count)")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.white)
                                        .frame(width: 22, height: 22)
                                        .background(Color.orange)
                                        .clipShape(Circle())
                                }
                            }
                        }
                    }

                    if !selectedSets.isEmpty && selectedSets.values.contains(where: { !$0.isEmpty }) {
                        Section {
                            Button {
                                finishWorkout()
                            } label: {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Finish Workout")
                                }
                                .foregroundStyle(.green)
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Machines")
    }

    private func finishWorkout() {
        let allSets = selectedSets.values.flatMap { $0 }
        guard !allSets.isEmpty else { return }

        let workout = WatchWorkout(
            id: UUID(),
            date: Date(),
            type: "strength",
            strengthSets: allSets,
            cardio: nil
        )
        connectivity.sendWorkout(workout)
        selectedSets = [:]
    }
}
