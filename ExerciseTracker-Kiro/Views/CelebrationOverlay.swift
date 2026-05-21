import SwiftUI
import Observation

@Observable final class PBCelebrationManager {
    var active: PBAchievement?

    @MainActor
    func celebrate(_ achievement: PBAchievement) {
        active = achievement
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(3))
            if self.active?.id == achievement.id {
                self.active = nil
            }
        }
    }
}

struct CelebrationOverlay: View {
    let achievement: PBAchievement

    var body: some View {
        ZStack {
            ConfettiView()
                .allowsHitTesting(false)

            VStack {
                VStack(spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: "trophy.fill")
                            .font(.title2)
                            .foregroundStyle(.yellow)
                        Text(achievement.title)
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                    Text(achievement.detail)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(
                    LinearGradient.brandGradient
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                )
                .shadow(color: .black.opacity(0.25), radius: 12, y: 4)
                .padding(.top, 60)
                .padding(.horizontal, 24)

                Spacer()
            }
        }
        .ignoresSafeArea()
        .transition(.opacity)
    }
}

// MARK: - Confetti Particle System

struct ConfettiView: View {
    private let particleCount = 110

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<particleCount, id: \.self) { i in
                    ConfettiParticle(index: i, screenSize: geo.size)
                }
            }
        }
    }
}

private struct ConfettiParticle: View {
    let index: Int
    let screenSize: CGSize

    @State private var animating = false

    private let color: Color
    private let startX: CGFloat
    private let endXOffset: CGFloat
    private let duration: Double
    private let delay: Double
    private let rotation: Double
    private let size: CGFloat
    private let shape: Int

    init(index: Int, screenSize: CGSize) {
        self.index = index
        self.screenSize = screenSize
        let colors: [Color] = [.brand, .strengthAccent, .cardioAccent, .yellow, .pink, .green, .orange, .purple, .cyan]
        var rng = SystemRandomNumberGenerator()
        self.color = colors[Int.random(in: 0..<colors.count, using: &rng)]
        self.startX = CGFloat.random(in: 0...screenSize.width, using: &rng)
        self.endXOffset = CGFloat.random(in: -120...120, using: &rng)
        self.duration = Double.random(in: 3.6...6.4, using: &rng)
        self.delay = Double.random(in: 0...2.0, using: &rng)
        self.rotation = Double.random(in: 180...720, using: &rng)
        self.size = CGFloat.random(in: 6...11, using: &rng)
        self.shape = Int.random(in: 0...2, using: &rng)
    }

    var body: some View {
        shapeView
            .frame(width: size, height: shape == 1 ? size * 0.45 : size)
            .foregroundStyle(color)
            .rotationEffect(.degrees(animating ? rotation : 0))
            .position(
                x: startX + (animating ? endXOffset : 0),
                y: animating ? screenSize.height + 50 : -30
            )
            .opacity(animating ? 0 : 1)
            .onAppear {
                withAnimation(.easeOut(duration: duration).delay(delay)) {
                    animating = true
                }
            }
    }

    @ViewBuilder
    private var shapeView: some View {
        switch shape {
        case 0: Circle()
        case 1: Rectangle()
        default: Capsule()
        }
    }
}
