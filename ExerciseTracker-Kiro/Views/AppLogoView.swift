import SwiftUI

struct AppLogoView: View {
    var size: CGFloat = 80

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.22)
                .fill(LinearGradient.brandGradient)
                .frame(width: size, height: size)

            TrendLine()
                .stroke(.white.opacity(0.18), style: StrokeStyle(lineWidth: size * 0.07, lineCap: .round, lineJoin: .round))
                .frame(width: size * 0.75, height: size * 0.55)

            Image(systemName: "dumbbell.fill")
                .font(.system(size: size * 0.42, weight: .bold))
                .foregroundStyle(.white)
        }
    }
}

private struct TrendLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: 0, y: h * 0.8))
        path.addCurve(
            to: CGPoint(x: w, y: h * 0.15),
            control1: CGPoint(x: w * 0.3, y: h * 0.9),
            control2: CGPoint(x: w * 0.6, y: h * 0.05)
        )
        return path
    }
}

struct AppLogoSmall: View {
    var body: some View {
        AppLogoView(size: 36)
    }
}

#Preview {
    VStack(spacing: 24) {
        AppLogoView(size: 120)
        AppLogoView(size: 80)
        AppLogoView(size: 48)
    }
    .padding()
}
