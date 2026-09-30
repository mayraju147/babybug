import SwiftUI

/// The gift box that waits each day. Tap it to open it; coming back day after day makes the gifts bigger,
/// with the biggest on day 7. Missing a day only starts the week again.
struct DailyGift: View {
    let streak: Int
    let dayOfWeek: Int
    let amount: Int
    let onOpen: () -> Void
    let onClose: () -> Void

    @State private var opened = false
    @State private var wiggle = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text(streak > 1 ? "\(streak) days in a row!" : "Welcome back!")
                    .font(.whimsy(30))
                    .foregroundStyle(Y2K.ink)
                    .multilineTextAlignment(.center)

                WeekDots(dayOfWeek: dayOfWeek)

                if opened {
                    VStack(spacing: 8) {
                        DewdropIcon()
                            .frame(width: 70, height: 70)
                        Text("+\(amount) dewdrops")
                            .font(.whimsy(28))
                            .foregroundStyle(Y2K.ink)
                    }
                    .transition(.scale.combined(with: .opacity))

                    Button(action: onClose) {
                        Text("Yay!")
                            .font(.whimsy(22))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 36)
                            .padding(.vertical, 10)
                            .background(Capsule().fill(Y2K.bubblegum))
                            .overlay(Capsule().strokeBorder(.white, lineWidth: 2))
                    }
                    .buttonStyle(.plain)
                } else {
                    Button(action: open) {
                        Image(systemName: "gift.fill")
                            .font(.system(size: 90))
                            .foregroundStyle(
                                LinearGradient(colors: [Y2K.bubblegum, Y2K.lilac], startPoint: .top, endPoint: .bottom)
                            )
                            .rotationEffect(.degrees(wiggle ? 6 : -6))
                            .animation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true), value: wiggle)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Open your gift")

                    Text(dayOfWeek == 7 ? "A big gift today!" : "Tap to open your gift")
                        .font(.whimsy(18))
                        .foregroundStyle(Y2K.ink)
                }
            }
            .padding(24)
            .frame(maxWidth: 330)
            .background(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(LinearGradient(colors: [.white, Y2K.stripeLight], startPoint: .top, endPoint: .bottom))
            )
            .overlay(RoundedRectangle(cornerRadius: 32, style: .continuous).strokeBorder(Y2K.holo, lineWidth: 4))
            .overlay(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .inset(by: 9)
                    .strokeBorder(Y2K.bubblegum.opacity(0.5), style: StrokeStyle(lineWidth: 1.2, dash: [4, 4]))
            )
            .overlay(SparkleField().allowsHitTesting(false).clipShape(RoundedRectangle(cornerRadius: 32)))
            .padding(.horizontal, 16)
        }
        .onAppear { wiggle = true }
    }

    private func open() {
        SoundPlayer.shared.play(.grow)
        onOpen()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.55)) { opened = true }
    }
}

/// Seven little circles for the gift week: filled up to today, with a star on day 7.
struct WeekDots: View {
    let dayOfWeek: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...7, id: \.self) { day in
                ZStack {
                    Circle()
                        .fill(day <= dayOfWeek ? Y2K.bubblegum : .white)
                        .overlay(Circle().strokeBorder(Y2K.bubblegum.opacity(0.6), lineWidth: 1.5))
                    if day == 7 {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(day <= dayOfWeek ? .white : Y2K.bubblegum)
                    } else if day <= dayOfWeek {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .frame(width: 28, height: 28)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Day \(dayOfWeek) of 7")
    }
}
