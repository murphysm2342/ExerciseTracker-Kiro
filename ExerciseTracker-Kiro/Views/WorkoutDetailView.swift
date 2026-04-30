import SwiftUI
import SwiftData

struct WorkoutDetailView: View {
    let session: WorkoutSession
    @Environment(\.modelContext) private var modelContext
    @Environment(UserViewModel.self) private var userViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var contentID = UUID()
    @State private var showDeleteConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.sectionSpacing) {
                sessionHeader
                switch session.type {
                case .strength:
                    strengthContent
                case .cardio:
                    cardioContent
                }
            }
            .padding()
        }
        .id(contentID)
        .onAppear { contentID = UUID() }
        .background(Color.surfaceLight)
        .navigationTitle(session.type == .strength ? "Strength Workout" : "Cardio Workout")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .destructiveAction) {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }
            }
        }
        .confirmationDialog(
            "Delete Workout",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                deleteWorkout()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete this workout and all its data. This cannot be undone.")
        }
    }

    private func deleteWorkout() {
        modelContext.delete(session)
        try? modelContext.save()
        dismiss()
    }

    // MARK: - Header

    private var sessionHeader: some View {
        HStack(spacing: 14) {
            IconBadge(
                systemName: session.type == .strength ? "dumbbell.fill" : "figure.run",
                color: session.type == .strength ? .strengthAccent : .cardioAccent,
                size: 48
            )

            VStack(alignment: .leading, spacing: 3) {
                Text(session.type == .strength ? "Strength" : "Cardio")
                    .font(.title2)
                    .fontWeight(.bold)
                Text(session.date.formatted(date: .long, time: .shortened))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Strength content

    private var strengthContent: some View {
        let grouped = groupedByMachine(session.strengthSets)

        return VStack(alignment: .leading, spacing: DesignTokens.itemSpacing) {
            if grouped.isEmpty {
                Text("No sets recorded.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(grouped, id: \.machineName) { group in
                    VStack(alignment: .leading, spacing: 8) {
                        MachineSetGroupView(machineName: group.machineName, sets: group.sets)

                        if let user = userViewModel.activeUser,
                           let machine = group.sets.first?.machine {
                            NavigationLink {
                                StrengthLoggingView(
                                    machine: machine,
                                    user: user,
                                    session: session,
                                    modelContext: modelContext
                                )
                            } label: {
                                Label("Edit Sets", systemImage: "pencil")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(Color.brand)
                            }
                        }
                    }
                }
            }
        }
    }

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
                VStack(spacing: DesignTokens.itemSpacing) {
                    if let type = cardio.machineType {
                        HStack(spacing: 10) {
                            Image(systemName: type.iconName)
                                .font(.title3)
                                .foregroundStyle(Color.cardioAccent)
                            Text(type.displayName)
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    HStack(spacing: DesignTokens.itemSpacing) {
                        StatCard(
                            title: "Duration",
                            value: String(format: "%.0f min", cardio.durationMinutes),
                            systemImage: "clock.fill",
                            color: .cardioAccent
                        )
                        if let dist = cardio.distanceMiles {
                            StatCard(
                                title: "Distance",
                                value: String(format: "%.2f mi", dist),
                                systemImage: "figure.walk",
                                color: .blue
                            )
                        }
                    }
                    HStack(spacing: DesignTokens.itemSpacing) {
                        if let incline = cardio.incline {
                            StatCard(
                                title: "Incline",
                                value: String(format: "%.1f%%", incline),
                                systemImage: "arrow.up.right",
                                color: .orange
                            )
                        }
                        if let hr = cardio.avgHeartRate {
                            StatCard(
                                title: "Avg Heart Rate",
                                value: String(format: "%.0f bpm", hr),
                                systemImage: "heart.fill",
                                color: .red
                            )
                        }
                    }
                    HStack(spacing: DesignTokens.itemSpacing) {
                        if let resistance = cardio.resistance {
                            StatCard(
                                title: "Resistance",
                                value: String(format: "%.0f", resistance),
                                systemImage: "dial.medium",
                                color: .purple
                            )
                        }
                        if let speed = cardio.speed {
                            StatCard(
                                title: "Speed",
                                value: String(format: "%.1f mph", speed),
                                systemImage: "gauge.with.needle",
                                color: .cyan
                            )
                        }
                    }
                    HStack(spacing: DesignTokens.itemSpacing) {
                        if let floors = cardio.floors {
                            StatCard(
                                title: "Floors",
                                value: "\(floors)",
                                systemImage: "figure.stair.stepper",
                                color: .orange
                            )
                        }
                        if let strides = cardio.strides {
                            StatCard(
                                title: "Strides",
                                value: "\(strides)",
                                systemImage: "shoeprints.fill",
                                color: .green
                            )
                        }
                    }
                    HStack(spacing: DesignTokens.itemSpacing) {
                        if let strokes = cardio.strokeCount {
                            StatCard(
                                title: "Strokes",
                                value: "\(strokes)",
                                systemImage: "oar.2.crossed",
                                color: .teal
                            )
                        }
                        if let rpm = cardio.rpm {
                            StatCard(
                                title: "RPM",
                                value: String(format: "%.0f", rpm),
                                systemImage: "arrow.trianglehead.2.counterclockwise.rotate.90",
                                color: .indigo
                            )
                        }
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
            HStack(spacing: 8) {
                IconBadge(
                    systemName: MachineIconProvider.icon(for: machineName),
                    color: .brand,
                    size: 32
                )
                Text(machineName)
                    .font(.headline)
            }

            VStack(spacing: 4) {
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
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("\(set.reps)")
                            .font(.subheadline)
                            .frame(width: 48, alignment: .trailing)
                        Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(set.isCompleted ? Color.green : Color.secondary)
                            .frame(width: 40, alignment: .trailing)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(
                        set.isCompleted
                            ? Color.green.opacity(0.06)
                            : Color.clear
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
            .padding(.vertical, 8)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.smallRadius))
        }
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
