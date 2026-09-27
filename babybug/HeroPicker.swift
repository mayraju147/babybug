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
