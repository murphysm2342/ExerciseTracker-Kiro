import SwiftUI

/// Inline row for a single StrengthSet.
/// Tapping weight or reps field activates it and routes NumberPad input (Req 3.3).
/// Completed sets are visually distinguished (Req 3.5).
struct SetEditorView: View {
    let set: StrengthSet
    @Binding var activeFieldTarget: FieldTarget?
    let fieldBuffers: [UUID: (weight: String, reps: String)]
    let onComplete: () -> Void

    private var isActive: Bool {
        switch activeFieldTarget {
        case .weight(let id), .reps(let id): return id == set.id
        case nil: return false
        }
    }

    private var weightString: String {
        fieldBuffers[set.id]?.weight ?? StrengthLoggingViewModel.formatDouble(set.weight)
    }

    private var repsString: String {
        fieldBuffers[set.id]?.reps ?? "\(set.reps)"
    }

    var body: some View {
        HStack(spacing: 12) {
            // Set number
            Text("Set \(set.setNumber)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 50, alignment: .leading)

            // Weight field
            fieldButton(
                label: weightString.isEmpty ? "0" : weightString,
                unit: "lbs",
                isActive: activeFieldTarget == .weight(setID: set.id)
            ) {
                activeFieldTarget = .weight(setID: set.id)
            }

            // Reps field
            fieldButton(
                label: repsString.isEmpty ? "0" : repsString,
                unit: "reps",
                isActive: activeFieldTarget == .reps(setID: set.id)
            ) {
                activeFieldTarget = .reps(setID: set.id)
            }

            // Complete toggle (Req 3.5)
            Button(action: onComplete) {
                Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(set.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(set.isCompleted
                      ? Color.green.opacity(0.08)
                      : (isActive ? Color.accentColor.opacity(0.06) : Color(.systemBackground)))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isActive ? Color.accentColor : Color(.systemGray5), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func fieldButton(
        label: String,
        unit: String,
        isActive: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(label)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(isActive ? Color.accentColor : .primary)
                Text(unit)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isActive ? Color.accentColor.opacity(0.12) : Color(.systemGray6))
            )
        }
        .buttonStyle(.plain)
    }
}
