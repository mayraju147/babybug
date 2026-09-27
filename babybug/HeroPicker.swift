import SwiftUI

/// First-launch screen: tap the princess or the prince. Big pictures, so it works for kids who can't read yet.
struct HeroPicker: View {
    let onChoose: (Hero) -> Void

    @State private var chosen: Hero?

    var body: some View {
        ZStack {
            Image("Garden")
                .resizable()
                .scaledToFill()
                .blur(radius: 8)
                .overlay(Color.white.opacity(0.35))
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Text("Who will look after the bunny?")
                    .font(.system(.title2, design: .rounded, weight: .semibold))
                    .foregroundStyle(Color(red: 0.45, green: 0.30, blue: 0.25))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

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
                    .frame(height: 260)
                Text(hero.title)
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(Color(red: 0.45, green: 0.30, blue: 0.25))
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 28))
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(Color.pink.opacity(isChosen ? 0.8 : 0), lineWidth: 4)
            )
            .scaleEffect(isChosen ? 1.08 : 1)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(hero.title)
    }
}

#Preview {
    HeroPicker { _ in }
}
