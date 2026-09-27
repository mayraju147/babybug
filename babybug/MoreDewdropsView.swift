import SwiftUI

/// "Need more dewdrops?" sheet. A grown-up check comes first, as Apple requires for purchases in kids' apps,
/// then the three dewdrop packs.
struct MoreDewdropsView: View {
    let store: DewdropStore
    let onClose: () -> Void

    @State private var unlocked = false

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
                    packs
                } else {
                    ParentalGate { unlocked = true }
                }
                Spacer()
            }
            .padding(16)
        }
        .task { await store.loadProducts() }
    }

    private var packs: some View {
        VStack(spacing: 14) {
            Text("More dewdrops")
                .font(.whimsy(32))
                .foregroundStyle(Y2K.ink)

            ForEach(DewdropPack.allCases) { pack in
                Button {
                    Task { await store.buy(pack) }
                } label: {
                    HStack(spacing: 12) {
                        DewdropIcon()
                            .frame(width: 44, height: 44)
                        Text("\(pack.dewdrops) dewdrops")
                            .font(.whimsy(22))
                            .foregroundStyle(Y2K.ink)
                        Spacer()
                        Text(store.price(of: pack))
                            .font(.system(.headline, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(Y2K.bubblegum))
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(.white.opacity(0.92)))
                    .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(Y2K.holo, lineWidth: 3))
                }
                .buttonStyle(.plain)
                .disabled(store.isBuying)
            }

            if store.isBuying {
                ProgressView()
            }
            if let message = store.message {
                Text(message)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Y2K.ink)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
            }
        }
    }
}

/// A sum a young child can't do yet, answered on a number pad. A wrong answer brings a new sum.
struct ParentalGate: View {
    let onPass: () -> Void

    @State private var a = Int.random(in: 6...9)
    @State private var b = Int.random(in: 6...9)
    @State private var answer = ""
    @State private var wrong = false

    private let keys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "⌫", "0", "OK"]

    var body: some View {
        VStack(spacing: 14) {
            Text("Ask a grown-up")
                .font(.whimsy(32))
                .foregroundStyle(Y2K.ink)
            Text("Grown-ups: what is \(a) × \(b)?")
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .foregroundStyle(Y2K.ink)

            Text(answer.isEmpty ? " " : answer)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(wrong ? .red : Y2K.ink)
                .frame(width: 140, height: 56)
                .background(RoundedRectangle(cornerRadius: 16).fill(.white.opacity(0.9)))
                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Y2K.holo, lineWidth: 2))

            LazyVGrid(columns: Array(repeating: GridItem(.fixed(76), spacing: 12), count: 3), spacing: 12) {
                ForEach(keys, id: \.self) { key in
                    Button {
                        press(key)
                    } label: {
                        Text(key)
                            .font(.system(size: 26, weight: .semibold, design: .rounded))
                            .foregroundStyle(Y2K.ink)
                            .frame(width: 76, height: 60)
                            .background(RoundedRectangle(cornerRadius: 16).fill(.white.opacity(0.9)))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func press(_ key: String) {
        wrong = false
        switch key {
        case "⌫":
            answer = String(answer.dropLast())
        case "OK":
            if Int(answer) == a * b {
                onPass()
            } else {
                wrong = true
                answer = ""
                a = Int.random(in: 6...9)
                b = Int.random(in: 6...9)
            }
        default:
            if answer.count < 3 { answer += key }
        }
    }
}
