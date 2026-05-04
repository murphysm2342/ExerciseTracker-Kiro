import SwiftUI

struct WatchSetLoggerView: View {
    let machine: WatchMachine
    @Binding var sets: [WatchStrengthSet]

    @State private var weight: Double
    @State private var reps: Int
    @State private var editingWeight = true

    init(machine: WatchMachine, sets: Binding<[WatchStrengthSet]>) {
        self.machine = machine
        self._sets = sets
        self._weight = State(initialValue: machine.lastUsedWeight ?? 50)
        self._reps = State(initialValue: machine.lastUsedReps ?? 10)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text(machine.name)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 16) {
                    valueColumn(
                        label: "LBS",
                        value: formatWeight(weight),
                        isActive: editingWeight
                    )
                    .onTapGesture { editingWeight = true }

                    valueColumn(
                        label: "REPS",
                        value: "\(reps)",
                        isActive: !editingWeight
                    )
                    .onTapGesture { editingWeight = false }
                }
                .focusable()
                .digitalCrownRotation(
                    editingWeight
                        ? Binding(get: { weight }, set: { weight = max(0, $0) })
                        : Binding(get: { Double(reps) }, set: { reps = max(1, Int($0)) }),
                    from: 0,
                    through: editingWeight ? 500 : 100,
                    by: editingWeight ? 5 : 1,
                    sensitivity: .medium
                )

                Button {
                    addSet()
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Set")
                    }
                    .frame(maxWidth: .infinity)
                }
                .tint(.orange)

                if !sets.isEmpty {
                    Divider()
                    ForEach(Array(sets.enumerated()), id: \.offset) { index, set in
                        HStack {
                            Text("Set \(set.setNumber)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(formatWeight(set.weight)) lb")
                                .font(.caption)
                                .fontWeight(.medium)
                            Text("×")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text("\(set.reps)")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func valueColumn(label: String, value: String, isActive: Bool) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(isActive ? .orange : .primary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(isActive ? Color.orange.opacity(0.15) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func addSet() {
        let set = WatchStrengthSet(
            setNumber: sets.count + 1,
            weight: weight,
            reps: reps,
            machineId: machine.id,
            machineName: machine.name
        )
        sets.append(set)
    }

    private func formatWeight(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", value)
            : String(format: "%.1f", value)
    }
}
