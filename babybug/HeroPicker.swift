import SwiftUI

/// First-launch screen: tap the princess or the prince. Big pictures, so it works for kids who can't read yet.
/// Styled like a Y2K sticker page: candy stripes, twinkling sparkles, glossy bubble cards with holographic rims.
struct HeroPicker: View {
    let onChoose: (Hero) -> Void

    @State private var chosen: Hero?

    var body: some View {
        ZStack {
            CandyStripes()
                .ignoresSafeArea()

            SparkleField()
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(spacing: 22) {
                VStack(spacing: 6) {
                    Text("Who will look after the bunny?")
                        .font(.whimsy(34))
                        .foregroundStyle(Y2K.ink)
                        .multilineTextAlignment(.center)
                        .shadow(color: .white, radius: 0, x: 2, y: 2)
                        .shadow(color: .white.opacity(0.9), radius: 6)
                        .padding(.horizontal, 20)

                    HStack(spacing: 10) {
                        Image(systemName: "heart.fill").foregroundStyle(Y2K.bubblegum)
                        Text("pick your friend")
                            .font(.whimsy(18))
                            .foregroundStyle(Y2K.ink)
                        Image(systemName: "heart.fill").foregroundStyle(Y2K.bubblegum)
                    }
                    .font(.system(size: 12))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(.white.opacity(0.85)))
                    .overlay(Capsule().strokeBorder(Y2K.holo, lineWidth: 2))
                    .overlay(
                        Capsule()
                            .inset(by: 5)
                            .strokeBorder(Y2K.bubblegum.opacity(0.6), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    )
                }

                HStack(spacing: 16) {
                    ForEach(Hero.allCases) { hero in
                        HeroCard(hero: hero, isChosen: chosen == hero) {
                            choose(hero)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    private func choose(_ hero: Hero) {
        guard chosen == nil else { return }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.5)) {
            chosen = hero
        }
        // Let the little bounce play before moving on.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            onChoose(hero)
        }
    }
}

// MARK: - Palette

private enum Y2K {
    static let ink = Color(red: 0.19, green: 0.29, blue: 0.29)          // deep teal, like the font sample
    static let bubblegum = Color(red: 0.96, green: 0.52, blue: 0.72)
    static let stripeLight = Color(red: 0.98, green: 0.82, blue: 0.88)
    static let stripeDark = Color(red: 0.95, green: 0.70, blue: 0.80)
    static let lilac = Color(red: 0.80, green: 0.72, blue: 0.98)
    static let babyBlue = Color(red: 0.68, green: 0.86, blue: 0.99)
    static let mint = Color(red: 0.72, green: 0.96, blue: 0.86)

    /// Shimmery rainbow rim, like a holographic sticker.
    static let holo = AngularGradient(
        colors: [bubblegum, lilac, babyBlue, mint, .white, bubblegum],
        center: .center
    )
}

// MARK: - Background

/// Soft vertical candy stripes with a little painted wobble at the edges.
private struct CandyStripes: View {
    var body: some View {
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Y2K.stripeLight))
            let stripe: CGFloat = 34
            var x: CGFloat = 0
            while x < size.width {
                context.fill(Path(CGRect(x: x, y: 0, width: stripe * 0.55, height: size.height)),
                             with: .color(Y2K.stripeDark.opacity(0.75)))
                x += stripe
            }
        }
        .overlay(
            // Pale glow in the middle so the cards pop.
            RadialGradient(colors: [.white.opacity(0.55), .clear], center: .center, startRadius: 40, endRadius: 420)
        )
    }
}

/// Four-point sparkle, the classic Y2K twinkle.
private struct Sparkle: Shape {
    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let rx = rect.width / 2, ry = rect.height / 2
        let pinch: CGFloat = 0.18
        var p = Path()
        p.move(to: CGPoint(x: c.x, y: c.y - ry))
        p.addQuadCurve(to: CGPoint(x: c.x + rx, y: c.y), control: CGPoint(x: c.x + rx * pinch, y: c.y - ry * pinch))
        p.addQuadCurve(to: CGPoint(x: c.x, y: c.y + ry), control: CGPoint(x: c.x + rx * pinch, y: c.y + ry * pinch))
        p.addQuadCurve(to: CGPoint(x: c.x - rx, y: c.y), control: CGPoint(x: c.x - rx * pinch, y: c.y + ry * pinch))
        p.addQuadCurve(to: CGPoint(x: c.x, y: c.y - ry), control: CGPoint(x: c.x - rx * pinch, y: c.y - ry * pinch))
        p.closeSubpath()
        return p
    }
}

/// Sparkles, hearts and stars scattered around the page, each twinkling on its own beat.
private struct SparkleField: View {
    private struct Bit: Identifiable {
        enum Kind { case sparkle, heart, star, dot }
        let id: Int
        let kind: Kind
        let x: CGFloat, y: CGFloat   // 0...1 of the screen
        let size: CGFloat
        let color: Color
        let delay: Double
    }

    private let bits: [Bit] = [
        Bit(id: 0, kind: .sparkle, x: 0.10, y: 0.09, size: 34, color: .white, delay: 0),
        Bit(id: 1, kind: .sparkle, x: 0.88, y: 0.13, size: 26, color: Y2K.lilac, delay: 0.4),
        Bit(id: 2, kind: .heart, x: 0.78, y: 0.06, size: 22, color: Y2K.bubblegum, delay: 0.9),
        Bit(id: 3, kind: .star, x: 0.22, y: 0.19, size: 14, color: Y2K.babyBlue, delay: 1.3),
        Bit(id: 4, kind: .dot, x: 0.55, y: 0.07, size: 8, color: .white, delay: 0.2),
        Bit(id: 5, kind: .sparkle, x: 0.06, y: 0.48, size: 22, color: Y2K.babyBlue, delay: 0.7),
        Bit(id: 6, kind: .heart, x: 0.93, y: 0.52, size: 18, color: .white, delay: 1.1),
        Bit(id: 7, kind: .sparkle, x: 0.90, y: 0.83, size: 36, color: .white, delay: 0.3),
        Bit(id: 8, kind: .star, x: 0.12, y: 0.86, size: 18, color: Y2K.lilac, delay: 1.6),
        Bit(id: 9, kind: .heart, x: 0.30, y: 0.93, size: 20, color: Y2K.bubblegum, delay: 0.5),
        Bit(id: 10, kind: .sparkle, x: 0.62, y: 0.94, size: 20, color: Y2K.mint, delay: 1.0),
        Bit(id: 11, kind: .dot, x: 0.75, y: 0.90, size: 7, color: .white, delay: 1.4),
        Bit(id: 12, kind: .dot, x: 0.40, y: 0.15, size: 6, color: Y2K.bubblegum, delay: 0.6),
        Bit(id: 13, kind: .sparkle, x: 0.45, y: 0.80, size: 14, color: .white, delay: 1.8),
    ]

    var body: some View {
        GeometryReader { geo in
            ForEach(bits) { bit in
                Twinkle(delay: bit.delay) {
                    shape(for: bit)
                }
                .position(x: bit.x * geo.size.width, y: bit.y * geo.size.height)
            }
        }
    }

    @ViewBuilder
    private func shape(for bit: Bit) -> some View {
        switch bit.kind {
        case .sparkle:
            Sparkle()
                .fill(bit.color)
                .frame(width: bit.size, height: bit.size)
                .shadow(color: .white, radius: 4)
        case .heart:
            Image(systemName: "heart.fill")
                .font(.system(size: bit.size))
                .foregroundStyle(
                    LinearGradient(colors: [.white, bit.color], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .shadow(color: Y2K.bubblegum.opacity(0.4), radius: 3)
        case .star:
            Image(systemName: "star.fill")
                .font(.system(size: bit.size))
                .foregroundStyle(bit.color)
        case .dot:
            Circle()
                .fill(bit.color)
                .frame(width: bit.size, height: bit.size)
        }
    }
}

/// Gently pulses its content in size and brightness, forever.
private struct Twinkle<Content: View>: View {
    let delay: Double
    @ViewBuilder let content: Content
    @State private var on = false

    var body: some View {
        content
            .scaleEffect(on ? 1.15 : 0.8)
            .opacity(on ? 1 : 0.55)
            .rotationEffect(.degrees(on ? 8 : -8))
            .onAppear {
                withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true).delay(delay)) {
                    on = true
                }
            }
    }
}

// MARK: - Cards

private struct HeroCard: View {
    let hero: Hero
    let isChosen: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(hero.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 250)

                Text(hero.title)
                    .font(.whimsy(22))
                    .foregroundStyle(Y2K.ink)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(.white))
                    .overlay(Capsule().strokeBorder(Y2K.holo, lineWidth: 2))
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(bubble)
            .overlay(alignment: .topTrailing) {
                // Little heart sticker stuck on the corner.
                Image(systemName: "heart.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(
                        LinearGradient(colors: [.white, Y2K.bubblegum], startPoint: .top, endPoint: .bottom)
                    )
                    .shadow(color: Y2K.bubblegum.opacity(0.5), radius: 2, y: 1)
                    .rotationEffect(.degrees(15))
                    .offset(x: 6, y: -8)
            }
            .overlay(alignment: .topLeading) {
                Sparkle()
                    .fill(.white)
                    .frame(width: 20, height: 20)
                    .shadow(color: Y2K.lilac, radius: 3)
                    .offset(x: -6, y: -6)
            }
            .scaleEffect(isChosen ? 1.08 : 1)
            .shadow(color: Y2K.bubblegum.opacity(isChosen ? 0.6 : 0.25), radius: isChosen ? 16 : 8, y: 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(hero.title)
    }

    /// Glossy candy bubble: soft gradient fill, a shine across the top, a holographic rim and dotted stitching.
    private var bubble: some View {
        let shape = RoundedRectangle(cornerRadius: 30, style: .continuous)
        return shape
            .fill(
                LinearGradient(colors: [.white.opacity(0.95), Y2K.stripeLight.opacity(0.9), Y2K.lilac.opacity(0.35)],
                               startPoint: .top, endPoint: .bottom)
            )
            .overlay(alignment: .top) {
                // Shine.
                Capsule()
                    .fill(LinearGradient(colors: [.white.opacity(0.9), .white.opacity(0)], startPoint: .top, endPoint: .bottom))
                    .frame(height: 46)
                    .padding(.horizontal, 14)
                    .padding(.top, 6)
            }
            .overlay(shape.strokeBorder(Y2K.holo, lineWidth: isChosen ? 6 : 4))
            .overlay(
                shape
                    .inset(by: 9)
                    .strokeBorder(Y2K.bubblegum.opacity(0.55), style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
            )
    }
}

#Preview {
    HeroPicker { _ in }
}
