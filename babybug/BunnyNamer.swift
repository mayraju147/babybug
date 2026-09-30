import SwiftUI

/// "What's your bunny's name?" Kids who can't type yet can tap a ready-made name or roll the dice.
struct BunnyNamer: View {
    let startingName: String
    let onDone: (String) -> Void

    @State private var name = ""
    @FocusState private var typing: Bool

    private static let ideas = ["Clover", "Honey", "Biscuit", "Daisy", "Pip", "Mochi", "Button", "Peaches"]
    static let maxLength = 12

    private var trimmed: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        ZStack {
            CandyStripes()
                .ignoresSafeArea()
                .onTapGesture { typing = false }
            SparkleField()
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(spacing: 18) {
                Text("What's your bunny's name?")
                    .font(.whimsy(32))
                    .foregroundStyle(Y2K.ink)
                    .multilineTextAlignment(.center)
                    .shadow(color: .white, radius: 0, x: 2, y: 2)

                Image("Bunny")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 150)

                HStack(spacing: 10) {
                    TextField("Name", text: $name)
                        .font(.whimsy(26))
                        .foregroundStyle(Y2K.ink)
                        .multilineTextAlignment(.center)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                        .focused($typing)
                        .onChange(of: name) { _, newValue in
                            if newValue.count > Self.maxLength {
                                name = String(newValue.prefix(Self.maxLength))
                            }
                        }
                        .onSubmit(finish)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .background(Capsule().fill(.white.opacity(0.95)))
                        .overlay(Capsule().strokeBorder(Y2K.holo, lineWidth: 3))

                    Button {
                        name = Self.ideas.filter { $0 != name }.randomElement() ?? "Clover"
                    } label: {
                        Image(systemName: "dice.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(Y2K.bubblegum)
                            .frame(width: 52, height: 52)
                            .background(Circle().fill(.white.opacity(0.95)))
                            .overlay(Circle().strokeBorder(Y2K.holo, lineWidth: 2.5))
                    }
                    .accessibilityLabel("Pick a name for me")
                }
                .padding(.horizontal, 24)

                // Tap a name instead of typing.
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 88), spacing: 10)], spacing: 10) {
                    ForEach(Self.ideas, id: \.self) { idea in
                        Button {
                            name = idea
                        } label: {
                            Text(idea)
                                .font(.whimsy(18))
                                .foregroundStyle(Y2K.ink)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .frame(maxWidth: .infinity)
                                .background(Capsule().fill(name == idea ? Y2K.mint : .white.opacity(0.85)))
                                .overlay(Capsule().strokeBorder(Y2K.bubblegum.opacity(0.6), lineWidth: 1.5))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)

                Button(action: finish) {
                    HStack(spacing: 8) {
                        Image(systemName: "heart.fill")
                        Text("That's my bunny!")
                            .font(.whimsy(22))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(Y2K.bubblegum))
                    .overlay(Capsule().strokeBorder(.white, lineWidth: 2))
                    .shadow(color: Y2K.bubblegum.opacity(0.4), radius: 8, y: 4)
                }
                .buttonStyle(.plain)
                .disabled(trimmed.isEmpty)
                .opacity(trimmed.isEmpty ? 0.5 : 1)
            }
            .padding(.vertical, 24)
        }
        .onAppear { name = startingName }
    }

    private func finish() {
        guard !trimmed.isEmpty else { return }
        typing = false
        SoundPlayer.shared.play(.dewdrop)
        onDone(trimmed)
    }
}

#Preview {
    BunnyNamer(startingName: "") { _ in }
}
