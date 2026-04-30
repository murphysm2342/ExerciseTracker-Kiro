import SwiftUI

/// Inline row for a single StrengthSet.
/// Tapping weight or reps activates the field and clears the buffer on first tap (Fix #5).
struct SetEditorView: View {
    let set: StrengthSet
    @Binding var activeFieldTarget: FieldTarget?
    let fieldBuffers: [UUID: (weight: String, reps: String)]
    let onActivate: (FieldTarget) -> Void   // routes through VM so first-tap clear works
    let onRepsAdjust: ((Int) -> Void)?
    let onDelete: (() -> Void)?

    init(
        set: StrengthSet,
        activeFieldTarget: Binding<FieldTarget?>,
        fieldBuffers: [UUID: (weight: String, reps: String)],
        onActivate: @escaping (FieldTarget) -> Void,
        onRepsAdjust: ((Int) -> Void)? = nil,
        onDelete: (() -> Void)? = nil
    ) {
        self.set = set
        self._activeFieldTarget = activeFieldTarget
        self.fieldBuffers = fieldBuffers
        self.onActivate = onActivate
        self.onRepsAdjust = onRepsAdjust
        self.onDelete = onDelete
    }

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
                onActivate(.weight(setID: set.id))
            }

            // Reps field with +/- buttons
            HStack(spacing: 4) {
                if onRepsAdjust != nil {
                    Button { onRepsAdjust?(-1) } label: {
                        Image(systemName: "minus")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.primary)
                            .frame(width: 30, height: 30)
                            .background(Circle().fill(Color(.systemGray5)))
                    }
                    .buttonStyle(.plain)
                }

                fieldButton(
                    label: repsString.isEmpty ? "0" : repsString,
                    unit: "reps",
                    isActive: activeFieldTarget == .reps(setID: set.id)
                ) {
                    onActivate(.reps(setID: set.id))
                }

                if onRepsAdjust != nil {
                    Button { onRepsAdjust?(1) } label: {
                        Image(systemName: "plus")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.primary)
                            .frame(width: 30, height: 30)
                            .background(Circle().fill(Color(.systemGray5)))
                    }
                    .buttonStyle(.plain)
                }
            }

            // Delete button (optional)
            if let onDelete {
                Button(action: onDelete) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.red.opacity(0.7))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isActive ? Color.accentColor.opacity(0.06) : Color(.systemBackground))
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
