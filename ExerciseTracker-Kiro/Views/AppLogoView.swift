import SwiftUI

struct AppLogoView: View {
    var size: CGFloat = 80

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.22)
                .fill(LinearGradient.brandGradient)
                .frame(width: size, height: size)

            VStack(spacing: size * 0.02) {
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: size * 0.3, weight: .bold))
                    .foregroundStyle(.white)

                TrendLine(size: size)
                    .stroke(.white.opacity(0.9), style: StrokeStyle(lineWidth: size * 0.035, lineCap: .round, lineJoin: .round))
                    .frame(width: size * 0.5, height: size * 0.18)
            }
        }
    }
}

private struct TrendLine: Shape {
    let size: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: 0, y: h * 0.85))
        path.addCurve(
            to: CGPoint(x: w, y: h * 0.1),
            control1: CGPoint(x: w * 0.3, y: h * 0.6),
            control2: CGPoint(x: w * 0.65, y: h * 0.0)
        )
        return path
    }
}

struct AppLogoSmall: View {
    var body: some View {
        AppLogoView(size: 36)
    }
}

// MARK: - Icon Export View

struct AppIconExportView: View {
    @State private var exportError: String?
    @State private var shareImage: UIImage?
    @State private var showShareSheet = false

    var body: some View {
        VStack(spacing: 24) {
            Text("App Icon Generator")
                .font(.headline)

            AppLogoView(size: 200)

            if let error = exportError {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
            }

            Button("Export 1024x1024 Icon") {
                renderAndShare()
            }
            .buttonStyle(.borderedProminent)
            .tint(.brand)

            Text("Save to Photos or AirDrop to your Mac, then drag it into\nAssets.xcassets > AppIcon in Xcode.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
        .sheet(isPresented: $showShareSheet) {
            if let image = shareImage {
                ShareSheet(items: [image])
            }
        }
    }

    @MainActor
    private func renderAndShare() {
        let size: CGFloat = 1024
        let renderer = ImageRenderer(content:
            AppLogoView(size: size)
                .frame(width: size, height: size)
        )
        renderer.scale = 1.0

        guard let image = renderer.uiImage else {
            exportError = "Failed to render icon."
            return
        }

        exportError = nil
        shareImage = image
        showShareSheet = true
    }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    VStack(spacing: 24) {
        AppLogoView(size: 120)
        AppLogoView(size: 80)
        AppLogoView(size: 48)
    }
    .padding()
}

#Preview("Icon Export") {
    AppIconExportView()
}
