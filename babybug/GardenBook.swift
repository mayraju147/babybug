import SwiftUI

/// "My garden book": today's quests and the sticker album.
struct GardenBook: View {
    let progress: GardenProgress
    let onClose: () -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        ZStack {
            CandyStripes()
                .ignoresSafeArea()
            SparkleField()
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(spacing: 10) {
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

                Text("My Garden Book")
                    .font(.whimsy(34))
                    .foregroundStyle(Y2K.ink)
                    .shadow(color: .white, radius: 0, x: 2, y: 2)

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        streakCard
                        heading("Today's quests")
                        ForEach(progress.todaysQuests) { quest in
                            QuestRow(quest: quest, count: progress.questCount(quest), done: progress.isDone(quest))
                        }
                        Text("Each quest gives a star and \(Quest.reward) dewdrops. Finish all three for \(Quest.allDoneBonus) more!")
                            .font(.system(.footnote, design: .rounded))
                            .foregroundStyle(Y2K.ink.opacity(0.8))
                            .padding(.horizontal, 6)

                        heading("Stickers  \(progress.stickers.count)/\(Sticker.all.count)")
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(Sticker.all) { sticker in
                                StickerSpot(sticker: sticker, earned: progress.stickers.contains(sticker.id))
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 30)
                }
            }
        }
    }

    private func heading(_ text: String) -> some View {
        Text(text)
            .font(.whimsy(24))
            .foregroundStyle(Y2K.ink)
            .padding(.leading, 6)
    }

    private var streakCard: some View {
        VStack(spacing: 10) {
            HStack(spacing: 14) {
                Label("\(progress.streak) \(progress.streak == 1 ? "day" : "days") in a row", systemImage: "sun.max.fill")
                Label("\(progress.stars)", systemImage: "star.fill")
                    .accessibilityLabel("\(progress.stars) stars")
            }
            .font(.whimsy(20))
            .foregroundStyle(Y2K.ink)
            WeekDots(dayOfWeek: progress.dayOfWeek)
            Text("Come back tomorrow for another gift!")
                .font(.system(.footnote, design: .rounded))
                .foregroundStyle(Y2K.ink.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(.white.opacity(0.92)))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(Y2K.holo, lineWidth: 3))
    }
}

private struct QuestRow: View {
    let quest: Quest
    let count: Int
    let done: Bool

    var body: some View {
        HStack(spacing: 12) {
            Text(quest.emoji)
                .font(.system(size: 30))
                .frame(width: 48, height: 48)
                .background(Circle().fill(done ? Y2K.mint : Y2K.stripeLight))
            VStack(alignment: .leading, spacing: 6) {
                Text(quest.title)
                    .font(.whimsy(18))
                    .foregroundStyle(Y2K.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Y2K.stripeLight)
                        Capsule()
                            .fill(LinearGradient(colors: [Y2K.bubblegum, Y2K.lilac], startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * CGFloat(count) / CGFloat(quest.goal))
                    }
                }
                .frame(height: 10)
            }
            Group {
                if done {
                    Image(systemName: "star.fill")
                        .foregroundStyle(Color(red: 1, green: 0.8, blue: 0.3))
                } else {
                    Text("\(count)/\(quest.goal)")
                        .foregroundStyle(Y2K.ink)
                }
            }
            .font(.system(size: 20, weight: .bold, design: .rounded))
            .frame(width: 46)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(.white.opacity(0.92)))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(Y2K.holo, lineWidth: done ? 4 : 2))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(done ? "\(quest.title), done" : "\(quest.title), \(count) of \(quest.goal)")
    }
}

private struct StickerSpot: View {
    let sticker: Sticker
    let earned: Bool

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(earned ? Color.white : Color.white.opacity(0.45))
                    .overlay(
                        Circle().strokeBorder(earned ? AnyShapeStyle(Y2K.holo) : AnyShapeStyle(Y2K.ink.opacity(0.25)),
                                              style: StrokeStyle(lineWidth: earned ? 4 : 2, dash: earned ? [] : [5, 4]))
                    )
                    .shadow(color: earned ? Y2K.bubblegum.opacity(0.35) : .clear, radius: 5, y: 3)
                if earned {
                    Text(sticker.emoji)
                        .font(.system(size: 40))
                } else {
                    Text("?")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(Y2K.ink.opacity(0.35))
                }
            }
            .frame(width: 84, height: 84)
            .rotationEffect(.degrees(earned ? Double(sticker.id.count % 3 - 1) * 6 : 0))

            Text(earned ? sticker.title : sticker.hint)
                .font(earned ? Font.whimsy(14) : Font.system(size: 11, design: .rounded))
                .foregroundStyle(Y2K.ink.opacity(earned ? 1 : 0.7))
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .frame(minHeight: 34, alignment: .top)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(earned ? "\(sticker.title) sticker" : "Empty sticker spot: \(sticker.hint)")
    }
}
