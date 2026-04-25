import SwiftUI
import HealthKit

/// Displays recent HealthKit workouts and allows the user to import them.
/// Requirements: 5.2, 5.5, 5.6, 5.7
struct HealthKitImportView: View {

    // CardioLoggingViewModel is @Observable, so @State gives us observation tracking
    // while still allowing the parent to pass in the instance.
    @State private var viewModel: CardioLoggingViewModel
    /// Callback to route back to manual entry (Req 5.5)
    let onFallbackToManual: () -> Void

    init(viewModel: CardioLoggingViewModel, onFallbackToManual: @escaping () -> Void) {
        self._viewModel = State(initialValue: viewModel)
        self.onFallbackToManual = onFallbackToManual
    }

    var body: some View {
        Group {
            if viewModel.isLoadingHealthKit {
                // Req 5.7 — loading indicator
                loadingView
            } else if let error = viewModel.healthKitError {
                errorView(error: error)
            } else if viewModel.healthKitWorkouts.isEmpty {
                emptyView
            } else {
                workoutList
            }
        }
        .navigationTitle("Import from Health")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.fetchHealthKitWorkouts()
        }
    }

    // MARK: - Subviews

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.4)
            Text("Fetching workouts…")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyView: some View {
        ContentUnavailableView(
            "No Workouts Found",
            systemImage: "heart.text.square",
            description: Text("No recent cardio workouts were found in Apple Health.")
        )
    }

    private func errorView(error: Error) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.orange)

            Text(error.localizedDescription)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            if viewModel.canRetry {
                // Req 5.6 — retry option
                Button("Try Again") {
                    Task { await viewModel.fetchHealthKitWorkouts() }
                }
                .buttonStyle(.borderedProminent)
            }

            // Req 5.5 — fall back to manual entry on permission denial
            Button("Enter Manually") {
                onFallbackToManual()
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var workoutList: some View {
        List(viewModel.healthKitWorkouts, id: \.uuid) { workout in
            WorkoutRowView(workout: workout) {
                Task {
                    try? await viewModel.importHealthKitWorkout(workout)
                }
            }
        }
    }
}

// MARK: - WorkoutRowView

private struct WorkoutRowView: View {
    let workout: HKWorkout
    let onImport: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.workoutActivityType.displayName)
                    .font(.headline)
                Text(workout.startDate.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack(spacing: 12) {
                    Label(durationText, systemImage: "clock")
                    if let distance = distanceText {
                        Label(distance, systemImage: "figure.walk")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Import", action: onImport)
                .buttonStyle(.bordered)
                .controlSize(.small)
        }
        .padding(.vertical, 4)
    }

    private var durationText: String {
        let minutes = Int(workout.duration / 60)
        return "\(minutes) min"
    }

    private var distanceText: String? {
        if let stat = workout.statistics(for: HKQuantityType(.distanceWalkingRunning)),
           let miles = stat.sumQuantity()?.doubleValue(for: .mile()) {
            return String(format: "%.1f mi", miles)
        }
        if let stat = workout.statistics(for: HKQuantityType(.distanceCycling)),
           let miles = stat.sumQuantity()?.doubleValue(for: .mile()) {
            return String(format: "%.1f mi", miles)
        }
        return nil
    }
}

// MARK: - HKWorkoutActivityType display name helper

private extension HKWorkoutActivityType {
    var displayName: String {
        switch self {
        case .running: return "Run"
        case .cycling: return "Cycle"
        case .walking: return "Walk"
        case .swimming: return "Swim"
        case .rowing: return "Row"
        case .elliptical: return "Elliptical"
        case .stairClimbing: return "Stair Climb"
        case .hiking: return "Hike"
        default: return "Workout"
        }
    }
}
