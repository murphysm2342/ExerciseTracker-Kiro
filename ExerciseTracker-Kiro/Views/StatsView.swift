import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Environment(UserViewModel.self) private var userViewModel
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel: StatsViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    StatsContentView(viewModel: vm)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Stats")
            .background(Color.surfaceLight)
        }
        .onAppear { setup() }
        .onChange(of: userViewModel.activeUser?.id) { setup() }
    }

    private func setup() {
        let vm = StatsViewModel(modelContext: modelContext)
        if let user = userViewModel.activeUser {
            vm.refresh(for: user)
        }
        viewModel = vm
    }
}

// MARK: - Stats Content

private struct StatsContentView: View {
    @Environment(UserViewModel.self) private var userViewModel
    var viewModel: StatsViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.sectionSpacing) {
                overviewCards
                periodPicker
                maxWeightSection
                weightTrendSection
                cardioSection
            }
            .padding()
        }
        .background(Color.surfaceLight)
    }

    // MARK: - Overview

    private var overviewCards: some View {
        HStack(spacing: DesignTokens.itemSpacing) {
            StatCard(
                title: "Total Sets",
                value: "\(viewModel.totalWorkouts)",
                systemImage: "dumbbell.fill",
                color: .strengthAccent
            )
            StatCard(
                title: "Cardio Min",
                value: String(format: "%.0f", viewModel.totalCardioMinutes),
                systemImage: "heart.fill",
                color: .cardioAccent
            )
        }
    }

    // MARK: - Period Picker

    private var periodPicker: some View {
        Picker("Period", selection: Binding(
            get: { viewModel.selectedTrendPeriod },
            set: { period in
                if let user = userViewModel.activeUser {
                    viewModel.changePeriod(period, user: user)
                }
            }
        )) {
            ForEach(StatsViewModel.TrendPeriod.allCases, id: \.self) { period in
                Text(period.rawValue).tag(period)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Max Weight Bar Chart

    private var maxWeightSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.itemSpacing) {
            Text("Max Weight by Exercise")
                .font(.headline)

            if viewModel.maxWeightByMachine.isEmpty {
                emptyChart("Log strength workouts to see max weight data.")
            } else {
                Chart(viewModel.maxWeightByMachine) { item in
                    BarMark(
                        x: .value("Weight", item.maxWeight),
                        y: .value("Exercise", item.machineName)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.brand, .brandLight],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(6)
                    .annotation(position: .trailing, spacing: 4) {
                        Text("\(Int(item.maxWeight)) lb")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .chartXAxis {
                    AxisMarks(position: .bottom) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text("\(Int(v))")
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let name = value.as(String.self) {
                                Text(name)
                                    .font(.caption)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
                .frame(height: CGFloat(max(viewModel.maxWeightByMachine.count, 1)) * 44)
                .cardStyle()
            }
        }
    }

    // MARK: - Weight Trend Line Chart

    private var weightTrendSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.itemSpacing) {
            HStack {
                Text("Weight Trend")
                    .font(.headline)
                Spacer()
                machinePicker
            }

            if viewModel.weightTrend.isEmpty {
                emptyChart("No data for this exercise yet.")
            } else {
                Chart(viewModel.weightTrend) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Max Weight", point.maxWeight)
                    )
                    .foregroundStyle(Color.strengthAccent)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))

                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value("Max Weight", point.maxWeight)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.strengthAccent.opacity(0.3), Color.strengthAccent.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Max Weight", point.maxWeight)
                    )
                    .foregroundStyle(Color.strengthAccent)
                    .symbolSize(30)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: xAxisStride)) { value in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text("\(Int(v)) lb")
                            }
                        }
                    }
                }
                .frame(height: 200)
                .cardStyle()
            }
        }
    }

    private var xAxisStride: Int {
        switch viewModel.selectedTrendPeriod {
        case .week: return 1
        case .month: return 7
        case .threeMonths: return 14
        case .all: return 30
        }
    }

    private var machinePicker: some View {
        Menu {
            ForEach(viewModel.machines) { machine in
                Button {
                    if let user = userViewModel.activeUser {
                        viewModel.selectMachine(machine, user: user)
                    }
                } label: {
                    HStack {
                        Image(systemName: MachineIconProvider.icon(for: machine.name, category: machine.category))
                        Text(machine.name)
                        if machine.id == viewModel.selectedMachine?.id {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(viewModel.selectedMachine?.name ?? "Select")
                    .font(.subheadline)
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
            .foregroundStyle(Color.brand)
        }
    }

    // MARK: - Cardio Section

    private var cardioSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.itemSpacing) {
            Text("Cardio Trends")
                .font(.headline)

            if viewModel.cardioTrend.isEmpty {
                emptyChart("Log cardio workouts to see trends.")
            } else {
                cardioDurationChart
                if viewModel.cardioTrend.contains(where: { $0.distanceMiles != nil }) {
                    cardioDistanceChart
                }
            }

            if !viewModel.cardioByType.isEmpty {
                cardioByTypeSection
            }
        }
    }

    private var cardioDurationChart: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Duration")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Chart(viewModel.cardioTrend) { point in
                BarMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value("Minutes", point.durationMinutes)
                )
                .foregroundStyle(LinearGradient.cardioGradient)
                .cornerRadius(4)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: xAxisStride)) { value in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text("\(Int(v)) min")
                        }
                    }
                }
            }
            .frame(height: 160)
        }
        .cardStyle()
    }

    private var cardioDistanceChart: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Distance")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Chart(viewModel.cardioTrend.filter { $0.distanceMiles != nil }) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Miles", point.distanceMiles ?? 0)
                )
                .foregroundStyle(Color.cardioAccent)
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 2.5))

                PointMark(
                    x: .value("Date", point.date),
                    y: .value("Miles", point.distanceMiles ?? 0)
                )
                .foregroundStyle(Color.cardioAccent)
                .symbolSize(30)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: xAxisStride)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text(String(format: "%.1f mi", v))
                        }
                    }
                }
            }
            .frame(height: 160)
        }
        .cardStyle()
    }

    // MARK: - Cardio By Type

    private var cardioByTypeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("By Activity")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Chart(viewModel.cardioByType) { stat in
                BarMark(
                    x: .value("Minutes", stat.totalMinutes),
                    y: .value("Activity", stat.machineType.displayName)
                )
                .foregroundStyle(LinearGradient.cardioGradient)
                .cornerRadius(4)
                .annotation(position: .trailing, spacing: 4) {
                    Text("\(Int(stat.totalMinutes))m")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text("\(Int(v))")
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let name = value.as(String.self) {
                            Text(name)
                                .font(.caption)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .frame(height: CGFloat(max(viewModel.cardioByType.count, 1)) * 36)

            ForEach(viewModel.cardioByType) { stat in
                HStack(spacing: 10) {
                    Image(systemName: stat.machineType.iconName)
                        .font(.caption)
                        .foregroundStyle(Color.cardioAccent)
                        .frame(width: 20)
                    Text(stat.machineType.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("\(stat.sessionCount) session\(stat.sessionCount == 1 ? "" : "s")")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        if let dist = stat.totalDistance {
                            Text(String(format: "%.1f mi", dist))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        if let hr = stat.avgHeartRate {
                            Text(String(format: "%.0f avg bpm", hr))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .cardStyle()
    }

    // MARK: - Empty Chart

    private func emptyChart(_ message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.bar.xaxis")
                .font(.title)
                .foregroundStyle(.tertiary)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .cardStyle()
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
    return StatsView()
        .environment(vm)
        .modelContainer(container)
}
