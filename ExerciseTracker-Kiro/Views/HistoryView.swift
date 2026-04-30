import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(UserViewModel.self) private var userViewModel
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel: HistoryViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    HistoryContentView(viewModel: vm)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("History")
            .background(Color.surfaceLight)
        }
        .onAppear { setupViewModel() }
        .onChange(of: userViewModel.activeUser?.id) { setupViewModel() }
    }

    private func setupViewModel() {
        let vm = HistoryViewModel(modelContext: modelContext)
        if let user = userViewModel.activeUser {
            vm.refresh(for: user)
        }
        viewModel = vm
    }
}

// MARK: - HistoryContentView

private struct HistoryContentView: View {
    @Environment(UserViewModel.self) private var userViewModel
    @Environment(\.modelContext) private var modelContext
    var viewModel: HistoryViewModel

    @State private var showAddStrength = false
    @State private var showAddCardio = false
    @State private var sessionToDelete: WorkoutSession?

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                WorkoutCalendarView(
                    selectedDate: Binding(
                        get: { viewModel.selectedDate },
                        set: { viewModel.selectDate($0) }
                    ),
                    workoutDays: viewModel.workoutDayComponents
                )
                .padding(.horizontal)

                Divider().padding(.vertical, 8)

                sessionListSection
                    .padding(.horizontal)
            }
        }
        .background(Color.surfaceLight)
        .onAppear {
            if let user = userViewModel.activeUser {
                viewModel.refresh(for: user)
            }
        }
        .sheet(isPresented: $showAddStrength, onDismiss: refreshAfterAdd) {
            if let user = userViewModel.activeUser, let date = viewModel.selectedDate {
                ActiveWorkoutView(user: user, modelContext: modelContext, date: date)
            }
        }
        .sheet(isPresented: $showAddCardio, onDismiss: refreshAfterAdd) {
            if let user = userViewModel.activeUser, let date = viewModel.selectedDate {
                NavigationStack {
                    CardioLoggingView(user: user, date: date)
                }
            }
        }
        .confirmationDialog(
            "Delete Workout",
            isPresented: Binding(
                get: { sessionToDelete != nil },
                set: { if !$0 { sessionToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let session = sessionToDelete {
                    deleteSession(session)
                }
            }
            Button("Cancel", role: .cancel) { sessionToDelete = nil }
        } message: {
            Text("This will permanently delete this workout and all its data.")
        }
    }

    private func deleteSession(_ session: WorkoutSession) {
        modelContext.delete(session)
        try? modelContext.save()
        sessionToDelete = nil
        if let user = userViewModel.activeUser {
            viewModel.refresh(for: user)
        }
    }

    private func refreshAfterAdd() {
        if let user = userViewModel.activeUser {
            viewModel.refresh(for: user)
        }
    }

    // MARK: - Session list

    @ViewBuilder
    private var sessionListSection: some View {
        if let selected = viewModel.selectedDate {
            VStack(alignment: .leading, spacing: DesignTokens.itemSpacing) {
                Text(selected, style: .date)
                    .font(.headline)
                    .padding(.top, 4)

                if viewModel.sessionsOnSelectedDate.isEmpty {
                    HStack(spacing: 10) {
                        Image(systemName: "moon.zzz")
                            .foregroundStyle(.tertiary)
                        Text("No workouts on this day.")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cardStyle()
                } else {
                    ForEach(viewModel.sessionsOnSelectedDate) { session in
                        InlineSessionCard(session: session)
                            .contextMenu {
                                Button(role: .destructive) {
                                    sessionToDelete = session
                                } label: {
                                    Label("Delete Workout", systemImage: "trash")
                                }
                            }
                    }
                }

                VStack(spacing: DesignTokens.itemSpacing) {
                    Button { showAddStrength = true } label: {
                        HStack(spacing: 8) {
                            IconBadge(systemName: "dumbbell.fill", color: .white, size: 28)
                            Text("Add Strength Workout")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(LinearGradient.strengthGradient)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.buttonRadius))
                    }

                    Button { showAddCardio = true } label: {
                        HStack(spacing: 8) {
                            IconBadge(systemName: "figure.run", color: .white, size: 28)
                            Text("Add Cardio Workout")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(LinearGradient.cardioGradient)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.buttonRadius))
                    }
                }
                .padding(.top, 4)
            }
        } else {
            if viewModel.sessions.isEmpty {
                ContentUnavailableView(
                    "No Workouts Yet",
                    systemImage: "calendar.badge.exclamationmark",
                    description: Text("Log a workout to see your history here.")
                )
                .padding(.top, 32)
            } else {
                Text("Tap a date on the calendar to see workouts.")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
                    .padding(.top, 8)
            }
        }
    }
}

// MARK: - Workout Calendar View

struct WorkoutCalendarView: View {
    @Binding var selectedDate: Date?
    let workoutDays: Set<DateComponents>

    @State private var displayedMonth = Date()

    private let calendar = Calendar.current
    private let daySymbols = Calendar.current.veryShortWeekdaySymbols

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Button { changeMonth(by: -1) } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.brand)
                }
                Spacer()
                Text(displayedMonth, format: .dateTime.month(.wide).year())
                    .font(.headline)
                Spacer()
                Button { changeMonth(by: 1) } label: {
                    Image(systemName: "chevron.right")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.brand)
                }
            }
            .padding(.horizontal, 4)

            HStack(spacing: 0) {
                ForEach(daySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 4) {
                ForEach(calendarDays(), id: \.self) { day in
                    if let date = day {
                        let isSelected = isSelected(date)
                        let hasWorkout = hasWorkout(on: date)
                        let isCurrentDay = isToday(date)
                        let isCurrentMonth = calendar.isDate(date, equalTo: displayedMonth, toGranularity: .month)

                        Button {
                            selectedDate = date
                        } label: {
                            Text("\(calendar.component(.day, from: date))")
                                .font(.subheadline)
                                .fontWeight(isCurrentDay ? .bold : .regular)
                                .foregroundColor(
                                    isSelected ? .white :
                                    !isCurrentMonth ? Color.secondary.opacity(0.4) :
                                    isCurrentDay ? Color.brand :
                                    .primary
                                )
                                .frame(width: 34, height: 34)
                                .background(
                                    Group {
                                        if isSelected {
                                            Circle().fill(Color.brand)
                                        } else if hasWorkout {
                                            Circle().fill(Color.brand.opacity(0.25))
                                        }
                                    }
                                )
                        }
                        .buttonStyle(.plain)
                    } else {
                        Text("")
                            .frame(width: 34, height: 34)
                    }
                }
            }
        }
        .padding()
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cornerRadius))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    private func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth) {
            displayedMonth = newMonth
        }
    }

    private func calendarDays() -> [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: displayedMonth),
              let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))
        else { return [] }

        let weekdayOfFirst = calendar.component(.weekday, from: firstOfMonth) - 1
        var days: [Date?] = Array(repeating: nil, count: weekdayOfFirst)

        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                days.append(date)
            }
        }

        while days.count % 7 != 0 {
            days.append(nil)
        }
        return days
    }

    private func isSelected(_ date: Date) -> Bool {
        guard let selected = selectedDate else { return false }
        return calendar.isDate(date, inSameDayAs: selected)
    }

    private func hasWorkout(on date: Date) -> Bool {
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        return workoutDays.contains(comps)
    }

    private func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }
}

// MARK: - InlineSessionCard

struct InlineSessionCard: View {
    let session: WorkoutSession

    var body: some View {
        NavigationLink(destination: WorkoutDetailView(session: session)) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    IconBadge(
                        systemName: session.type == .strength ? "dumbbell.fill" : "figure.run",
                        color: session.type == .strength ? .strengthAccent : .cardioAccent,
                        size: 32
                    )
                    Text(session.type == .strength ? "Strength Workout" : "Cardio Workout")
                        .font(.subheadline).fontWeight(.semibold)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                Divider()

                switch session.type {
                case .strength:
                    strengthDetail
                case .cardio:
                    cardioDetail
                }
            }
            .cardStyle()
        }
        .buttonStyle(.plain)
    }

    private var strengthDetail: some View {
        let grouped = groupedByMachine(session.strengthSets)
        return VStack(alignment: .leading, spacing: 8) {
            if grouped.isEmpty {
                Text("No sets recorded")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(grouped, id: \.machineName) { group in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: MachineIconProvider.icon(for: group.machineName))
                                .font(.caption)
                                .foregroundStyle(Color.brand)
                            Text(group.machineName)
                                .font(.caption).fontWeight(.semibold)
                        }
                        ForEach(group.sets.sorted { $0.setNumber < $1.setNumber }) { set in
                            HStack(spacing: 8) {
                                Text("Set \(set.setNumber)")
                                    .foregroundStyle(.secondary)
                                Text("\(StrengthLoggingViewModel.formatDouble(set.weight)) lb")
                                Text("\u{00D7}")
                                    .foregroundStyle(.secondary)
                                Text("\(set.reps) reps")
                                if set.isCompleted {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                }
                            }
                            .font(.caption)
                        }
                    }
                }
            }
        }
    }

    private var cardioDetail: some View {
        Group {
            if let cardio = session.cardioSession {
                VStack(alignment: .leading, spacing: 6) {
                    if let type = cardio.machineType {
                        HStack(spacing: 6) {
                            Image(systemName: type.iconName)
                                .font(.caption)
                                .foregroundStyle(Color.cardioAccent)
                            Text(type.displayName)
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                    }
                    HStack(spacing: 16) {
                        Label(String(format: "%.0f min", cardio.durationMinutes), systemImage: "clock")
                        if let dist = cardio.distanceMiles {
                            Label(String(format: "%.1f mi", dist), systemImage: "figure.walk")
                        }
                        if let hr = cardio.avgHeartRate {
                            Label(String(format: "%.0f bpm", hr), systemImage: "heart.fill")
                                .foregroundStyle(.red)
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    HStack(spacing: 16) {
                        if let resistance = cardio.resistance {
                            Label(String(format: "Res: %.0f", resistance), systemImage: "dial.medium")
                        }
                        if let floors = cardio.floors {
                            Label("\(floors) floors", systemImage: "figure.stair.stepper")
                        }
                        if let strokes = cardio.strokeCount {
                            Label("\(strokes) strokes", systemImage: "oar.2.crossed")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            } else {
                Text("Cardio session")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private struct MachineGroup {
        let machineName: String
        let sets: [StrengthSet]
    }

    private func groupedByMachine(_ sets: [StrengthSet]) -> [MachineGroup] {
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
        return order.map { MachineGroup(machineName: $0, sets: dict[$0]!) }
    }
}

// MARK: - Preview

#Preview {
    let container = try! ModelContainer(
        for: User.self, Machine.self, WorkoutSession.self,
             StrengthSet.self, CardioSession.self, WorkoutFlow.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let vm = UserViewModel(modelContext: container.mainContext)
    return HistoryView()
        .environment(vm)
        .modelContainer(container)
}
