import SwiftUI

/// Grown-ups only: turn "your bunny misses you" reminders on or off.
struct RemindersView: View {
    let bunnyName: String
    let onClose: () -> Void

    @AppStorage(Reminders.onKey) private var remindersOn = false
    @State private var unlocked = false
    @State private var note: String?

    var body: some View {
        ZStack {
            CandyStripes()
                .ignoresSafeArea()

            VStack(spacing: 16) {
                HStack {
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Y2K.ink)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(.white.opacity(0.9)))
                            .overlay(Circle().strokeBorder(Y2K.holo, lineWidth: 2))
                    }
                    .accessibilityLabel("Close")
                }

                if unlocked {
                    settings
                } else {
                    ParentalGate { unlocked = true }
                }
                Spacer()
            }
            .padding(16)
        }
    }

    private var settings: some View {
        VStack(spacing: 16) {
            Text("Reminders")
                .font(.whimsy(32))
                .foregroundStyle(Y2K.ink)

            Toggle(isOn: Binding(get: { remindersOn }, set: { turnOn in
                if turnOn {
                    Task {
                        let allowed = await Reminders.requestPermission()
                        remindersOn = allowed
                        note = allowed ? nil : "Notifications are turned off for babybug. You can allow them in the Settings app."
                    }
                } else {
                    remindersOn = false
                    Reminders.cancel()
                }
            })) {
                Text("\(bunnyName.isEmpty ? "Your bunny" : bunnyName) misses you")
                    .font(.whimsy(20))
                    .foregroundStyle(Y2K.ink)
            }
            .tint(Y2K.bubblegum)
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(.white.opacity(0.92)))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(Y2K.holo, lineWidth: 3))

            Text("A gentle reminder if nobody has visited for 8 hours, and one more the next day. Never between 7pm and 9am.")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(Y2K.ink)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)

            if let note {
                Text(note)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(Y2K.ink)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
            }
        }
    }
}

#Preview {
    RemindersView(bunnyName: "Clover") {}
}
