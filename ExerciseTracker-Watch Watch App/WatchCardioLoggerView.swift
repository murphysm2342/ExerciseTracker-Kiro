import SwiftUI

struct WatchCardioLoggerView: View {
    @Environment(WatchConnectivityService.self) private var connectivity
    @Environment(\.dismiss) private var dismiss

    let machineType: WatchCardioType

    @State private var durationMinutes: Double = 30
    @State private var distance: Double = 0
    @State private var heartRate: Double = 0
    @State private var activeField: CardioField = .duration
    @State private var saved = false

    private enum CardioField: String {
        case duration, distance, heartRate
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: machineType.iconName)
                        .foregroundStyle(.green)
                    Text(machineType.displayName)
                        .font(.headline)
                }

                fieldRow(label: "Duration", value: "\(Int(durationMinutes)) min", field: .duration)
                fieldRow(label: "Distance", value: distance > 0 ? String(format: "%.1f mi", distance) : "—", field: .distance)
                fieldRow(label: "Heart Rate", value: heartRate > 0 ? String(format: "%.0f bpm", heartRate) : "—", field: .heartRate)

                Spacer(minLength: 8)

                Button {
                    saveWorkout()
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Save")
                    }
                    .frame(maxWidth: .infinity)
                }
                .tint(.green)
                .disabled(durationMinutes <= 0)
            }
            .padding(.horizontal, 4)
        }
        .focusable()
        .digitalCrownRotation(
            crownBinding,
            from: 0,
            through: activeField == .duration ? 300 : activeField == .distance ? 50 : 220,
            by: crownStep,
            sensitivity: .medium
        )
        .navigationBarTitleDisplayMode(.inline)
    }

    private func fieldRow(label: String, value: String, field: CardioField) -> some View {
        let isActive = activeField == field
        return HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(isActive ? .green : .primary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(isActive ? Color.green.opacity(0.15) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .onTapGesture { activeField = field }
    }

    private var crownBinding: Binding<Double> {
        switch activeField {
        case .duration:
            return Binding(
                get: { durationMinutes },
                set: { durationMinutes = max(0, $0) }
            )
        case .distance:
            return Binding(
                get: { distance },
                set: { distance = max(0, $0) }
            )
        case .heartRate:
            return Binding(
                get: { heartRate },
                set: { heartRate = max(0, $0) }
            )
        }
    }

    private var crownStep: Double {
        switch activeField {
        case .duration:  return 1
        case .distance:  return 0.1
        case .heartRate: return 1
        }
    }

    private func saveWorkout() {
        let cardio = WatchCardioData(
            machineType: machineType.rawValue,
            durationMinutes: durationMinutes,
            distanceMiles: distance > 0 ? distance : nil,
            avgHeartRate: heartRate > 0 ? heartRate : nil,
            resistance: nil,
            floors: nil,
            speed: nil
        )
        let workout = WatchWorkout(
            id: UUID(),
            date: Date(),
            type: "cardio",
            strengthSets: [],
            cardio: cardio
        )
        connectivity.sendWorkout(workout)
        saved = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            dismiss()
        }
    }
}
