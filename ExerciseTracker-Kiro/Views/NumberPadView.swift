import SwiftUI

// MARK: - NumberPadAction

enum NumberPadAction {
    case digit(Int)
    case delete
    case increment(Int)
}

// MARK: - NumberPadView

/// A 4×3 custom number pad that never triggers the system keyboard.
/// Always visible; not dismissible.
/// Requirements: 10.1, 10.2, 10.3, 10.4, 10.5, 10.6, 10.7
struct NumberPadView: View {
    let onAction: (NumberPadAction) -> Void

    // Layout: 4 rows × 3 columns
    // Row 0: 7  8  9
    // Row 1: 4  5  6
    // Row 2: 1  2  3
    // Row 3: -5  0  +5   (delete replaces one of these — see below)
    // Final layout per design: digits 0–9, delete, +5, –5
    // Row 3: –5  0  +5
    // Delete key placed at row 2, col 2 position → shift 3 to row 2 col 1
    // Actual grid:
    // Row 0: 7  8  9
    // Row 1: 4  5  6
    // Row 2: 1  2  3
    // Row 3: –5  0  +5
    // Delete: replaces one key — design says 4×3 with digits 0–9, delete, +5, –5 = 12 keys total
    // 10 digits + delete + +5 + –5 = 13 → one digit must share or delete replaces a slot
    // Standard phone pad: 1-9 (row 0-2), then bottom row has –5, 0, +5, delete = 4 keys but only 3 cols
    // Resolution: bottom row = –5 | 0 | +5, and delete replaces "3" position (row 2, col 2)
    // Final:
    // Row 0: 7  8  9
    // Row 1: 4  5  6
    // Row 2: 1  2  ⌫
    // Row 3: –5  0  +5

    private let rows: [[PadKey]] = [
        [.digit(7), .digit(8), .digit(9)],
        [.digit(4), .digit(5), .digit(6)],
        [.digit(1), .digit(2), .delete],
        [.increment(-5), .digit(0), .increment(5)]
    ]

    var body: some View {
        VStack(spacing: 8) {
            ForEach(0..<rows.count, id: \.self) { rowIndex in
                HStack(spacing: 8) {
                    ForEach(0..<rows[rowIndex].count, id: \.self) { colIndex in
                        let key = rows[rowIndex][colIndex]
                        PadKeyButton(key: key, onAction: onAction)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
    }
}

// MARK: - PadKey

private enum PadKey {
    case digit(Int)
    case delete
    case increment(Int)

    var label: String {
        switch self {
        case .digit(let d):     return "\(d)"
        case .delete:           return "⌫"
        case .increment(let n): return n > 0 ? "+\(n)" : "\(n)"
        }
    }

    var action: NumberPadAction {
        switch self {
        case .digit(let d):     return .digit(d)
        case .delete:           return .delete
        case .increment(let n): return .increment(n)
        }
    }
}

// MARK: - PadKeyButton

private struct PadKeyButton: View {
    let key: PadKey
    let onAction: (NumberPadAction) -> Void

    var body: some View {
        Button {
            onAction(key.action)
        } label: {
            Text(key.label)
                .font(.title2.weight(.medium))
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(Color(.systemBackground))
                .cornerRadius(10)
                .shadow(color: .black.opacity(0.06), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    NumberPadView { action in
        print("Action: \(action)")
    }
}
