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

    // Row 0: 7  8  9
    // Row 1: 4  5  6
    // Row 2: 1  2  3
    // Row 3: -5  0  +5  ⌫

    private let rows: [[PadKey]] = [
        [.digit(7), .digit(8), .digit(9)],
        [.digit(4), .digit(5), .digit(6)],
        [.digit(1), .digit(2), .digit(3)],
        [.increment(-5), .digit(0), .increment(5), .delete]
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
