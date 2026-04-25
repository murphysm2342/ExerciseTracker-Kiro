import SwiftUI

// MARK: - CardView

/// A container with rounded corners and a subtle shadow/background.
/// Use to visually group related content across screens.
struct CardView<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}

// MARK: - PrimaryButton

/// Prominent action button with accent color background and white text.
struct PrimaryButton: View {
    let title: String
    let systemImage: String?
    let action: () -> Void

    init(_ title: String, systemImage: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = systemImage {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.accentColor)
            .foregroundStyle(.white)
            .fontWeight(.semibold)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - SecondaryButton

/// Secondary action button with a bordered style.
struct SecondaryButton: View {
    let title: String
    let systemImage: String?
    let action: () -> Void

    init(_ title: String, systemImage: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = systemImage {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color(.systemBackground))
            .foregroundStyle(Color.accentColor)
            .fontWeight(.semibold)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.accentColor, lineWidth: 1.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - SectionHeader

/// Styled section header text used above content groups.
struct SectionHeader: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - EmptyStateView

/// Generic empty state view used when a list has no content.
struct EmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String

    init(_ title: String, message: String, systemImage: String) {
        self.title = title
        self.message = message
        self.systemImage = systemImage
    }

    var body: some View {
        ContentUnavailableView(
            title,
            systemImage: systemImage,
            description: Text(message)
        )
    }
}

// MARK: - Previews

#Preview("CardView") {
    CardView {
        VStack(alignment: .leading, spacing: 4) {
            Text("Card Title").font(.headline)
            Text("Some detail text here.").foregroundStyle(.secondary)
        }
    }
    .padding()
}

#Preview("Buttons") {
    VStack(spacing: 16) {
        PrimaryButton("Start Strength Workout", systemImage: "dumbbell") {}
        SecondaryButton("Start Cardio Workout", systemImage: "figure.run") {}
    }
    .padding()
}

#Preview("SectionHeader") {
    SectionHeader("Last Workout")
        .padding()
}
