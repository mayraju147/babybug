import SwiftUI

/// Shared Y2K sticker-page look: candy stripes, twinkling sparkles and a holographic rim.

// MARK: - Palette

enum Y2K {
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
struct CandyStripes: View {
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
struct Sparkle: Shape {
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
struct SparkleField: View {
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
struct Twinkle<Content: View>: View {
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
