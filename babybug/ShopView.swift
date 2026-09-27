import SwiftUI

/// The dewdrop shop: spend dewdrops on treats for the bunny and decorations for the garden.
/// Same Y2K sticker-page look as the princess and prince picker.
struct ShopView: View {
    let inventory: Inventory
    let store: DewdropStore
    let onClose: () -> Void

    @State private var showingMore = false

    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        ZStack {
            CandyStripes()
                .ignoresSafeArea()
            SparkleField()
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(spacing: 12) {
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
                    .accessibilityLabel("Back to the garden")
                }
                .padding(.horizontal, 16)

                Text("Dewdrop Shop")
                    .font(.whimsy(36))
                    .foregroundStyle(Y2K.ink)
                    .shadow(color: .white, radius: 0, x: 2, y: 2)

                HStack(spacing: 8) {
                    DewdropCounter(count: inventory.dewdrops, size: 22)
                    Button {
                        showingMore = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 34, height: 34)
                            .background(Circle().fill(Y2K.bubblegum))
                    }
                    .accessibilityLabel("Get more dewdrops")
                }

                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        section("Treats", kind: .treat)
                        section("Garden", kind: .decoration)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 30)
                }
            }
        }
        .sheet(isPresented: $showingMore) {
            MoreDewdropsView(store: store) { showingMore = false }
        }
    }

    private func section(_ title: String, kind: ShopItem.Kind) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.whimsy(24))
                .foregroundStyle(Y2K.ink)
                .padding(.leading, 6)
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(ShopItem.allCases.filter { $0.kind == kind }) { item in
                    ShopCard(item: item, inventory: inventory) {
                        showingMore = true
                    }
                }
            }
        }
    }
}

/// A dewdrop picture and a number, in a little pill.
struct DewdropCounter: View {
    let count: Int
    var size: CGFloat = 18

    var body: some View {
        HStack(spacing: 6) {
            DewdropIcon()
                .frame(width: size, height: size)
            Text("\(count)")
                .font(.whimsy(size))
                .foregroundStyle(Y2K.ink)
                .contentTransition(.numericText())
                .animation(.spring, value: count)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background(Capsule().fill(.white.opacity(0.9)))
        .overlay(Capsule().strokeBorder(Y2K.holo, lineWidth: 2))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(count) dewdrops")
    }
}

/// The painted dewdrop once it's in the asset catalog, a plain drop until then.
struct DewdropIcon: View {
    var body: some View {
        if UIImage(named: "Dewdrop") != nil {
            Image("Dewdrop")
                .resizable()
                .scaledToFit()
        } else {
            Image(systemName: "drop.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(
                    LinearGradient(colors: [.white, Y2K.babyBlue], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
        }
    }
}

private struct ShopCard: View {
    let item: ShopItem
    let inventory: Inventory
    /// Called when the child taps something they can't afford yet.
    let onNeedMore: () -> Void

    @State private var shakes = 0
    @State private var bounce = false

    private var isOwned: Bool { inventory.owned.contains(item) }
    private var isChosen: Bool { item.kind == .treat && inventory.treat == item }
    private var canAfford: Bool { inventory.dewdrops >= item.price }

    var body: some View {
        Button(action: tap) {
            VStack(spacing: 6) {
                picture
                    .frame(height: 90)
                Text(item.title)
                    .font(.whimsy(18))
                    .foregroundStyle(Y2K.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                footer
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(LinearGradient(colors: [.white.opacity(0.95), Y2K.stripeLight.opacity(0.9)],
                                         startPoint: .top, endPoint: .bottom))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(Y2K.holo, lineWidth: isChosen ? 5 : 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .inset(by: 7)
                    .strokeBorder(Y2K.bubblegum.opacity(0.5), style: StrokeStyle(lineWidth: 1.2, dash: [4, 4]))
            )
            .opacity(isOwned || canAfford ? 1 : 0.6)
            .scaleEffect(bounce ? 1.08 : 1)
            .modifier(Shake(amount: shakes))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityText)
    }

    @ViewBuilder
    private var picture: some View {
        if UIImage(named: item.imageName) != nil {
            Image(item.imageName)
                .resizable()
                .scaledToFit()
        } else {
            Text(item.emoji)
                .font(.system(size: 60))
        }
    }

    @ViewBuilder
    private var footer: some View {
        if isChosen {
            label(Image(systemName: "checkmark"), "Chosen")
        } else if isOwned && item.kind == .treat {
            label(Image(systemName: "hand.tap.fill"), "Use")
        } else if isOwned {
            label(Image(systemName: "sparkles"), "In garden")
        } else {
            HStack(spacing: 4) {
                DewdropIcon().frame(width: 16, height: 16)
                Text("\(item.price)")
                    .font(.whimsy(17))
                    .foregroundStyle(Y2K.ink)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 3)
            .background(Capsule().fill(.white))
            .overlay(Capsule().strokeBorder(Y2K.bubblegum.opacity(0.7), lineWidth: 1.5))
        }
    }

    private func label(_ icon: Image, _ text: String) -> some View {
        HStack(spacing: 4) {
            icon.font(.system(size: 12, weight: .bold))
            Text(text).font(.whimsy(15))
        }
        .foregroundStyle(Y2K.ink)
        .padding(.horizontal, 10)
        .padding(.vertical, 3)
        .background(Capsule().fill(Y2K.mint.opacity(0.7)))
    }

    private var accessibilityText: String {
        if isChosen { return "\(item.title), chosen" }
        if isOwned { return item.title }
        return "\(item.title), \(item.price) dewdrops"
    }

    private func tap() {
        if isOwned {
            inventory.choose(item)
            pop()
        } else if inventory.buy(item) {
            pop()
        } else {
            // Not enough dewdrops yet: a little "no" wobble, then the offer of more.
            withAnimation(.linear(duration: 0.4)) { shakes += 1 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                onNeedMore()
            }
        }
    }

    private func pop() {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.45)) { bounce = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.spring) { bounce = false }
        }
    }
}

/// Side-to-side wobble, played once each time `amount` goes up by one.
private struct Shake: GeometryEffect {
    var amount: Int
    var animatableData: CGFloat

    init(amount: Int) {
        self.amount = amount
        animatableData = CGFloat(amount)
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: 8 * sin(animatableData * .pi * 4), y: 0))
    }
}

#Preview {
    let inventory = Inventory()
    ShopView(inventory: inventory, store: DewdropStore(inventory: inventory)) {}
}
