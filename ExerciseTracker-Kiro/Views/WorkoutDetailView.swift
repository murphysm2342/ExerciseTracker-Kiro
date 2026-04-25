import SwiftUI
import SwiftData

/// Detail view for a single WorkoutSession.
/// - Strength: groups StrengthSets by machine (Req 8.3)
/// - Cardio: shows duration, distance, incline, heart rate (Req 8.3)
struct WorkoutDetailView: View {
    let session: WorkoutSession

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                sessionHeader

                Divider()

                // Content by type
                switch session.type {
                case .strength:
                    strengthContent
                case .cardio:
                    cardioContent
                }
            }
            .padding()
        }
        .navigationTitle(session.type == .strength ? "Strength Workout" : "Cardio Workout")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header

    private var sessionHeader: some View {
        HStack(spacing: 12) {
            Image(systemName: session.type == .strength ? "dumbbell.fill" : "figure.run")
                .font(.title2)
                .foregroundStyle(session.type == .strength ? Color.blue : Color.green)

            VStack(alignment: .leading, spacing: 2) {
                Text(session.type == .strength ? "Strength" : "Cardio")
                    .font(.title3)
                    .fontWeight(.semibold)
                Text(session.date.formatted(date: .long, time: .shortened))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Strength content

    /// Groups sets by machine and renders each group (Req 8.3)
    private var strengthContent: some View {
        let grouped = groupedByMachine(session.strengthSets)

        return VStack(alignment: .leading, spacing: 20) {
            if grouped.isEmpty {
                Text("No sets recorded.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(grouped, id: \.machineName) { group in
                    MachineSetGroupView(machineName: group.machineName, sets: group.sets)
                }
            }
        }
    }

    /// Groups StrengthSets by machine name, preserving set order within each group.
    private func groupedByMachine(_ sets: [StrengthSet]) -> [MachineSetGroup] {
        var order: [String] = []
        var dict: [String: [StrengthSet]] = [:]

        for set in sets.sorted(by: { $0.setNumber < $1.setNumber }) {
            let name = set.machine.name
            if dict[name] == nil {
                order.append(name)
                dict[name] = []
            }
            dict[name]!.append(set)
        }

        return order.map { MachineSetGroup(machineName: $0, sets: dict[$0]!) }
    }

    // MARK: - Cardio content

    private var cardioContent: some View {
        Group {
            if let cardio = session.cardioSession {
                VStack(alignment: .leading, spacing: 12) {
                    CardioStatRow(label: "Duration", value: String(format: "%.0f min", cardio.durationMinutes))

                    if let dist = cardio.distanceMiles {
                        CardioStatRow(label: "Distance", value: String(format: "%.2f mi", dist))
                    }

                    if let incline = cardio.incline {
                        CardioStatRow(label: "Incline", value: String(format: "%.1f%%", incline))
                    }

                    if let hr = cardio.avgHeartRate {
                        CardioStatRow(label: "Avg Heart Rate", value: String(format: "%.0f bpm", hr))
                    }
                }
            } else {
                Text("No cardio data available.")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Supporting types

private struct MachineSetGroup {
    let machineName: String
    let sets: [StrengthSet]
}

// MARK: - MachineSetGroupView

private struct MachineSetGroupView: View {
    let machineName: String
    let sets: [StrengthSet]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(machineName)
                .font(.headline)

            VStack(spacing: 4) {
                // Column headers
                HStack {
                    Text("Set")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 36, alignment: .leading)
                    Text("Weight")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Reps")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 48, alignment: .trailing)
                    Text("Done")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 40, alignment: .trailing)
                }
                .padding(.horizontal, 12)

                Divider()

                ForEach(sets.sorted(by: { $0.setNumber < $1.setNumber })) { set in
                    HStack {
                        Text("\(set.setNumber)")
                            .font(.subheadline)
                            .frame(width: 36, alignment: .leading)
                        Text(String(format: "%.1f lb", set.weight))
                            .font(.subheadline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("\(set.reps)")
                            .font(.subheadline)
                            .frame(width: 48, alignment: .trailing)
                        Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(set.isCompleted ? Color.green : Color.secondary)
                            .frame(width: 40, alignment: .trailing)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        set.isCompleted
                            ? Color.green.opacity(0.06)
                            : Color.clear
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
            .padding(.vertical, 8)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

// MARK: - CardioStatRow

private struct CardioStatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Preview

#Preview {
    let container = try! ModelContainer(
        for: User.self, Machine.self, WorkoutSession.self,
             StrengthSet.self, CardioSession.self, WorkoutFlow.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let ctx = container.mainContext
    let user = User(name: "Preview User")
    ctx.insert(user)
    let machine = Machine(name: "Bench Press", user: user)
    ctx.insert(machine)
    let session = WorkoutSession(type: .strength, user: user)
    ctx.insert(session)
    let s1 = StrengthSet(setNumber: 1, weight: 135, reps: 10, isCompleted: true, machine: machine, session: session)
    let s2 = StrengthSet(setNumber: 2, weight: 145, reps: 8, isCompleted: true, machine: machine, session: session)
    let s3 = StrengthSet(setNumber: 3, weight: 145, reps: 6, isCompleted: false, machine: machine, session: session)
    ctx.insert(s1); ctx.insert(s2); ctx.insert(s3)

    return NavigationStack {
        WorkoutDetailView(session: session)
    }
    .modelContainer(container)
}
