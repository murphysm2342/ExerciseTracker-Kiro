import SwiftUI

struct WatchHomeView: View {
    @Environment(WatchConnectivityService.self) private var connectivity

    var body: some View {
        NavigationStack {
            List {
                NavigationLink {
                    WatchStrengthPickerView()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "dumbbell.fill")
                            .font(.title3)
                            .foregroundStyle(.orange)
                            .frame(width: 28)
                        Text("Strength")
                            .font(.headline)
                    }
                }

                NavigationLink {
                    WatchCardioPickerView()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "figure.run")
                            .font(.title3)
                            .foregroundStyle(.green)
                            .frame(width: 28)
                        Text("Cardio")
                            .font(.headline)
                    }
                }

                Section {
                    HStack {
                        Image(systemName: connectivity.isReachable ? "iphone.radiowaves.left.and.right" : "iphone.slash")
                            .font(.caption2)
                            .foregroundStyle(connectivity.isReachable ? .green : .secondary)
                        Text(connectivity.isReachable ? "iPhone connected" : "iPhone not connected")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    if !connectivity.machines.isEmpty {
                        Text("\(connectivity.machines.count) machines synced")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Workout")
        }
    }
}
