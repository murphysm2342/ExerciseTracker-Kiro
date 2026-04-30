import SwiftUI
import SwiftData

struct ManualCardioView: View {
    @Environment(\.dismiss) private var dismiss

    @Bindable var viewModel: CardioLoggingViewModel

    @State private var durationText: String = ""
    @State private var distanceText: String = ""
    @State private var inclineText: String = ""
    @State private var heartRateText: String = ""
    @State private var resistanceText: String = ""
    @State private var floorsText: String = ""
    @State private var stridesText: String = ""
    @State private var strokeCountText: String = ""
    @State private var speedText: String = ""
    @State private var rpmText: String = ""
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

    var body: some View {
        Form {
            machineTypePicker

            Section("Duration") {
                HStack {
                    TextField("e.g. 30", text: $durationText)
                        .keyboardType(.decimalPad)
                    Text("min")
                        .foregroundStyle(.secondary)
                }
            }

            machineSpecificFields

            Section("Heart Rate") {
                HStack {
                    TextField("Avg Heart Rate", text: $heartRateText)
                        .keyboardType(.decimalPad)
                    Text("bpm")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(viewModel.machineType.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { trySave() }
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.brand)
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
        .alert("Invalid Input", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Machine Type Picker

    private var machineTypePicker: some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(CardioMachineType.allCases) { type in
                        Button {
                            viewModel.machineType = type
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: type.iconName)
                                    .font(.title3)
                                Text(type.displayName)
                                    .font(.caption2)
                                    .lineLimit(1)
                            }
                            .frame(width: 80, height: 70)
                            .background(
                                viewModel.machineType == type
                                    ? Color.brand.opacity(0.15)
                                    : Color.clear
                            )
                            .foregroundStyle(
                                viewModel.machineType == type
                                    ? Color.brand
                                    : .secondary
                            )
                            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.smallRadius))
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.smallRadius)
                                    .stroke(
                                        viewModel.machineType == type ? Color.brand : Color.clear,
                                        lineWidth: 1.5
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
    }

    // MARK: - Machine-Specific Fields

    @ViewBuilder
    private var machineSpecificFields: some View {
        switch viewModel.machineType {
        case .treadmill:
            treadmillFields
        case .elliptical:
            ellipticalFields
        case .stairStepper:
            stairStepperFields
        case .stationaryBike:
            bikeFields
        case .rowingMachine:
            rowingFields
        }
    }

    private var treadmillFields: some View {
        Section("Treadmill Details") {
            fieldRow("Distance", text: $distanceText, unit: "miles")
            fieldRow("Incline", text: $inclineText, unit: "%")
            fieldRow("Avg Speed", text: $speedText, unit: "mph")
        }
    }

    private var ellipticalFields: some View {
        Section("Elliptical Details") {
            fieldRow("Distance", text: $distanceText, unit: "miles")
            fieldRow("Resistance", text: $resistanceText, unit: "level")
            fieldRow("Strides", text: $stridesText, unit: "total", keyboard: .numberPad)
        }
    }

    private var stairStepperFields: some View {
        Section("Stair Stepper Details") {
            fieldRow("Floors", text: $floorsText, unit: "floors", keyboard: .numberPad)
            fieldRow("Resistance", text: $resistanceText, unit: "level")
        }
    }

    private var bikeFields: some View {
        Section("Bike Details") {
            fieldRow("Distance", text: $distanceText, unit: "miles")
            fieldRow("Resistance", text: $resistanceText, unit: "level")
            fieldRow("Avg RPM", text: $rpmText, unit: "rpm")
        }
    }

    private var rowingFields: some View {
        Section("Rowing Details") {
            fieldRow("Distance", text: $distanceText, unit: "meters")
            fieldRow("Strokes", text: $strokeCountText, unit: "total", keyboard: .numberPad)
            fieldRow("Resistance", text: $resistanceText, unit: "level")
        }
    }

    private func fieldRow(
        _ label: String,
        text: Binding<String>,
        unit: String,
        keyboard: UIKeyboardType = .decimalPad
    ) -> some View {
        HStack {
            TextField(label, text: text)
                .keyboardType(keyboard)
            Text(unit)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Save

    private func trySave() {
        viewModel.durationMinutes = Double(durationText) ?? 0
        viewModel.distanceMiles = distanceText.isEmpty ? nil : Double(distanceText)
        viewModel.incline = inclineText.isEmpty ? nil : Double(inclineText)
        viewModel.avgHeartRate = heartRateText.isEmpty ? nil : Double(heartRateText)
        viewModel.resistance = resistanceText.isEmpty ? nil : Double(resistanceText)
        viewModel.floors = floorsText.isEmpty ? nil : Int(floorsText)
        viewModel.strides = stridesText.isEmpty ? nil : Int(stridesText)
        viewModel.strokeCount = strokeCountText.isEmpty ? nil : Int(strokeCountText)
        viewModel.speed = speedText.isEmpty ? nil : Double(speedText)
        viewModel.rpm = rpmText.isEmpty ? nil : Double(rpmText)

        do {
            try viewModel.saveManualSession()
            dismiss()
        } catch CardioLoggingError.invalidDuration {
            errorMessage = "Duration must be greater than zero."
            showError = true
        } catch {
            errorMessage = "Save failed: \(error.localizedDescription)"
            showError = true
        }
    }
}
