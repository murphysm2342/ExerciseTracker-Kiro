import SwiftUI

// MARK: - App Colors

extension Color {
    static let brand = Color(red: 0.35, green: 0.4, blue: 0.95)
    static let brandLight = Color(red: 0.55, green: 0.5, blue: 1.0)
    static let strengthAccent = Color(red: 0.95, green: 0.55, blue: 0.2)
    static let cardioAccent = Color(red: 0.2, green: 0.78, blue: 0.65)

    static let surfaceLight = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.14, green: 0.14, blue: 0.16, alpha: 1)
            : UIColor(red: 0.97, green: 0.97, blue: 0.98, alpha: 1)
    })

    static let cardBackground = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.18, green: 0.18, blue: 0.22, alpha: 1)
            : UIColor.white
    })

    static let subtleText = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.62, green: 0.62, blue: 0.68, alpha: 1)
            : UIColor(red: 0.44, green: 0.44, blue: 0.50, alpha: 1)
    })
}

// MARK: - Gradients

extension LinearGradient {
    static let brandGradient = LinearGradient(
        colors: [.brand, .brandLight],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let strengthGradient = LinearGradient(
        colors: [.strengthAccent, Color(red: 1.0, green: 0.7, blue: 0.3)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardioGradient = LinearGradient(
        colors: [.cardioAccent, Color(red: 0.3, green: 0.9, blue: 0.75)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Design Tokens

enum DesignTokens {
    static let cornerRadius: CGFloat = 16
    static let buttonRadius: CGFloat = 14
    static let smallRadius: CGFloat = 10
    static let cardPadding: CGFloat = 16
    static let sectionSpacing: CGFloat = 24
    static let itemSpacing: CGFloat = 12
}

// MARK: - View Extensions

extension View {
    func cardStyle() -> some View {
        self
            .padding(DesignTokens.cardPadding)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cornerRadius))
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
    }

    func gradientCardStyle(_ gradient: LinearGradient) -> some View {
        self
            .padding(DesignTokens.cardPadding)
            .background(gradient)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cornerRadius))
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }

    func statBadgeStyle() -> some View {
        self
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
    }
}

// MARK: - Icon Badge

struct IconBadge: View {
    let systemName: String
    let color: Color
    var size: CGFloat = 36

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size * 0.45, weight: .semibold))
            .foregroundStyle(color)
            .frame(width: size, height: size)
            .background(color.opacity(0.14))
            .clipShape(RoundedRectangle(cornerRadius: size * 0.28))
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let systemImage: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            IconBadge(systemName: systemImage, color: color, size: 32)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}
