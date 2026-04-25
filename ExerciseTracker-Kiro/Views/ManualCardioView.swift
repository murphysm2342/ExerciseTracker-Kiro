import SwiftUI
import SwiftData

/// Manual cardio entry screen.
/// Requirements: 4.1, 4.2, 4.3, 4.4
struct ManualCardioView: View {
    @Environment(\.dismiss) private var dismiss

    @Bindable var viewModel: CardioLoggingViewModel

    @State private var durationText: String = ""
    @State private var distanceText: String = ""
    @State private var inclineText: String = ""
    @State private var heartRateText: String = ""
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

    var body: some View {
        Form {
            Section("Duration") {
                HStack {
                    TextField("e.g. 30", text: $durationText)
                        .keyboardType(.decimalPad)
                    Text("min")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Optional Details") {
                HStack {
                    TextField("Distance", text: $distanceText)
                        .keyboardType(.decimalPad)
                    Text("miles")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    TextField("Incline", text: $inclineText)
                        .keyboardType(.decimalPad)
                    Text("%")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    TextField("Avg Heart Rate", text: $heartRateText)
                        .keyboardType(.decimalPad)
                    Text("bpm")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Log Cardio")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    trySave()
                }
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
        .alert("Invalid Input", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Save

    private func trySave() {
        // Map text fields to view model properties
        viewModel.durationMinutes = Double(durationText) ?? 0
        viewModel.distanceMiles = distanceText.isEmpty ? nil : Double(distanceText)
        viewModel.incline = inclineText.isEmpty ? nil : Double(inclineText)
        viewModel.avgHeartRate = heartRateText.isEmpty ? nil : Double(heartRateText)

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
