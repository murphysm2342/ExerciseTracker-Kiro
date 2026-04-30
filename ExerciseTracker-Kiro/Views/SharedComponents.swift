import SwiftUI

// MARK: - CardView

struct CardView<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(DesignTokens.cardPadding)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cornerRadius))
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}

// MARK: - PrimaryButton

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
                        .font(.body.weight(.semibold))
                }
                Text(title)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(LinearGradient.brandGradient)
            .foregroundStyle(.white)
            .fontWeight(.semibold)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.buttonRadius))
            .shadow(color: .brand.opacity(0.3), radius: 6, x: 0, y: 3)
        }
    }
}

// MARK: - SecondaryButton

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
                        .font(.body.weight(.semibold))
                }
                Text(title)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(Color.cardBackground)
            .foregroundStyle(Color.brand)
            .fontWeight(.semibold)
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.buttonRadius)
                    .stroke(Color.brand.opacity(0.4), lineWidth: 1.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.buttonRadius))
        }
    }
}

// MARK: - SectionHeader

struct SectionHeader: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.title3)
            .fontWeight(.bold)
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - EmptyStateView

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
