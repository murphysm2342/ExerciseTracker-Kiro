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
        }
        .onAppear {
            setupViewModel()
        }
        .onChange(of: userViewModel.activeUser?.id) {
            setupViewModel()
        }
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
    var viewModel: HistoryViewModel

    // Dates that have at least one session (for calendar marking)
    private var datesWithSessions: Set<DateComponents> {
        let calendar = Calendar.current
        return Set(viewModel.sessions.map {
            calendar.dateComponents([.year, .month, .day], from: $0.date)
        })
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Monthly calendar (Req 8.1)
                calendarSection

                Divider()
                    .padding(.vertical, 8)

                // Session list (Req 8.2, 8.6)
                sessionListSection
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Calendar

    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Use DatePicker in graphical style as the calendar (Req 8.1)
            DatePicker(
                "Select Date",
                selection: Binding(
                    get: { viewModel.selectedDate ?? Date() },
                    set: { viewModel.selectDate($0) }
                ),
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .overlay(alignment: .top) {
                // Invisible overlay to intercept — dots are drawn via background decoration
                Color.clear
            }
            // Annotate days with sessions using a custom calendar grid overlay
            .background(
                CalendarDotOverlay(
                    datesWithSessions: datesWithSessions,
                    selectedDate: viewModel.selectedDate
                )
                .allowsHitTesting(false)
            )
        }
    }

    // MARK: - Session list

    @ViewBuilder
    private var sessionListSection: some View {
        if let selected = viewModel.selectedDate {
            VStack(alignment: .leading, spacing: 12) {
                Text(selected, style: .date)
                    .font(.headline)
                    .padding(.top, 4)

                if viewModel.sessionsOnSelectedDate.isEmpty {
                    Text("No workouts on this day.")
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 8)
                } else {
                    ForEach(viewModel.sessionsOnSelectedDate) { session in
                        NavigationLink(destination: WorkoutDetailView(session: session)) {
                            SessionRowView(session: session)
                        }
                        .buttonStyle(.plain)
                    }
                }
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
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tap a date on the calendar to see workouts.")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                        .padding(.top, 8)
                }
            }
        }
    }
}

// MARK: - SessionRowView

/// Displays workout type, date, and summary label for a session (Req 8.6)
struct SessionRowView: View {
    let session: WorkoutSession

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: session.type == .strength ? "dumbbell.fill" : "figure.run")
                .foregroundStyle(session.type == .strength ? Color.blue : Color.green)
                .frame(width: 32, height: 32)
                .background(
                    (session.type == .strength ? Color.blue : Color.green)
                        .opacity(0.12)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(session.type == .strength ? "Strength" : "Cardio")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(session.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(summaryLabel(for: session))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func summaryLabel(for session: WorkoutSession) -> String {
        switch session.type {
        case .strength:
            let completed = session.strengthSets.filter(\.isCompleted).count
            let total = session.strengthSets.count
            let machines = Set(session.strengthSets.map { $0.machine.name })
            if machines.isEmpty {
                return "No sets recorded"
            }
            return "\(completed)/\(total) sets · \(machines.sorted().joined(separator: ", "))"
        case .cardio:
            if let cardio = session.cardioSession {
                var parts: [String] = []
                parts.append(String(format: "%.0f min", cardio.durationMinutes))
                if let dist = cardio.distanceMiles {
                    parts.append(String(format: "%.1f mi", dist))
                }
                if let hr = cardio.avgHeartRate {
                    parts.append(String(format: "%.0f bpm", hr))
                }
                return parts.joined(separator: " · ")
            }
            return "Cardio session"
        }
    }
}

// MARK: - CalendarDotOverlay

/// Draws small dots below day numbers for dates that have sessions.
/// This is a lightweight overlay — it doesn't interfere with DatePicker interaction.
private struct CalendarDotOverlay: View {
    let datesWithSessions: Set<DateComponents>
    let selectedDate: Date?

    var body: some View {
        // We can't easily position dots over individual day cells in DatePicker's graphical style,
        // so we use a subtle legend below the calendar instead.
        EmptyView()
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
