import Foundation

/// Things the child does in the garden that count towards quests and stickers.
enum Activity: String, Codable, CaseIterable {
    case feed, tickle, bathe, bedtime, butterfly, buy, present, splash
}

/// A small task for today, such as "Catch 3 butterflies". Three new ones each day.
struct Quest: Identifiable, Equatable {
    let id: String
    let activity: Activity
    let goal: Int
    let title: String
    let emoji: String

    static let pool: [Quest] = [
        Quest(id: "feed3", activity: .feed, goal: 3, title: "Feed your bunny 3 times", emoji: "🥕"),
        Quest(id: "feed5", activity: .feed, goal: 5, title: "Feed your bunny 5 times", emoji: "🍓"),
        Quest(id: "tickle5", activity: .tickle, goal: 5, title: "Tickle your bunny 5 times", emoji: "💖"),
        Quest(id: "tickle10", activity: .tickle, goal: 10, title: "Tickle your bunny 10 times", emoji: "💕"),
        Quest(id: "bathe2", activity: .bathe, goal: 2, title: "Give 2 bubble baths", emoji: "🫧"),
        Quest(id: "butterfly3", activity: .butterfly, goal: 3, title: "Catch 3 butterflies", emoji: "🦋"),
        Quest(id: "butterfly5", activity: .butterfly, goal: 5, title: "Catch 5 butterflies", emoji: "🦋"),
        Quest(id: "bedtime1", activity: .bedtime, goal: 1, title: "Tuck your bunny into bed", emoji: "🌙"),
    ]

    /// Dewdrops for finishing one quest, and the extra for finishing all three in a day.
    static let reward = 5
    static let allDoneBonus = 10

    /// Today's three quests: the same all day, with three different activities, changing each day.
    static func forDay(_ day: String) -> [Quest] {
        var seed = day.unicodeScalars.reduce(UInt64(7)) { $0 &* 31 &+ UInt64($1.value) }
        var picked: [Quest] = []
        var remaining = pool
        while picked.count < 3, !remaining.isEmpty {
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            let quest = remaining.remove(at: Int((seed >> 33) % UInt64(remaining.count)))
            if !picked.contains(where: { $0.activity == quest.activity }) {
                picked.append(quest)
            }
        }
        return picked
    }
}

/// What the stickers look at besides the counts in `GardenProgress`.
struct StickerContext {
    var stage: Stage
    var ownsOutfit: Bool
}

/// A sticker for the album, earned once and kept forever.
struct Sticker: Identifiable {
    let id: String
    let emoji: String
    let title: String
    /// How to earn it, shown on the empty spot.
    let hint: String
    let isEarned: (GardenProgress, StickerContext) -> Bool

    static let all: [Sticker] = [
        Sticker(id: "hello", emoji: "👋", title: "Hello, friend", hint: "Visit your bunny") { _, _ in true },
        Sticker(id: "muncher", emoji: "🥕", title: "Munch munch", hint: "Feed your bunny 10 times") { p, _ in p.count(.feed) >= 10 },
        Sticker(id: "tickles", emoji: "💖", title: "Tickle monster", hint: "Tickle your bunny 25 times") { p, _ in p.count(.tickle) >= 25 },
        Sticker(id: "bubbles", emoji: "🫧", title: "Bubble bath", hint: "Give 10 bubble baths") { p, _ in p.count(.bathe) >= 10 },
        Sticker(id: "dreams", emoji: "🌙", title: "Sweet dreams", hint: "Tuck your bunny in 5 times") { p, _ in p.count(.bedtime) >= 5 },
        Sticker(id: "butterflies", emoji: "🦋", title: "Butterfly friend", hint: "Catch 20 butterflies") { p, _ in p.count(.butterfly) >= 20 },
        Sticker(id: "presents", emoji: "🎁", title: "Lucky finder", hint: "Find 5 hidden presents") { p, _ in p.count(.present) >= 5 },
        Sticker(id: "splash", emoji: "☔️", title: "Splish splash", hint: "Splash in 10 puddles") { p, _ in p.count(.splash) >= 10 },
        Sticker(id: "shopper", emoji: "🧺", title: "Little shopper", hint: "Buy 3 things in the shop") { p, _ in p.count(.buy) >= 3 },
        Sticker(id: "dressup", emoji: "👗", title: "Dress up", hint: "Buy an outfit") { _, c in c.ownsOutfit },
        Sticker(id: "young", emoji: "🌱", title: "Growing up", hint: "Help your bunny grow") { _, c in c.stage.rawValue >= Stage.young.rawValue },
        Sticker(id: "grown", emoji: "🌳", title: "All grown", hint: "Help your bunny grow all the way") { _, c in c.stage == .grown },
        Sticker(id: "streak3", emoji: "🌼", title: "3 days in a row", hint: "Visit 3 days in a row") { p, _ in p.bestStreak >= 3 },
        Sticker(id: "streak7", emoji: "🌈", title: "A whole week", hint: "Visit 7 days in a row") { p, _ in p.bestStreak >= 7 },
        Sticker(id: "streak30", emoji: "👑", title: "Best friends", hint: "Visit 30 days in a row") { p, _ in p.bestStreak >= 30 },
        Sticker(id: "stars10", emoji: "⭐️", title: "Star helper", hint: "Finish 10 quests") { p, _ in p.stars >= 10 },
        Sticker(id: "stars50", emoji: "🌟", title: "Superstar", hint: "Finish 50 quests") { p, _ in p.stars >= 50 },
    ]
}

/// Visits in a row, the daily gift, today's quests, lifetime counts and stickers. Saved on the device.
@Observable
final class GardenProgress: Codable {
    private(set) var streak = 0
    private(set) var bestStreak = 0
    private(set) var stars = 0
    private(set) var stickers: Set<String> = []
    private var counts: [String: Int] = [:]
    private var lastVisitDay: String?
    private var lastGiftDay: String?
    private var questDay: String?
    private var questCounts: [String: Int] = [:]
    private(set) var questsDone: Set<String> = []
    private var bonusPaid = false

    private static let saveKey = "babybug.progress"
    /// Dewdrops in the gift box on each day of the week-long streak; day 7 is the big one.
    static let giftTable = [5, 5, 10, 10, 15, 15, 40]

    static func dayString(_ date: Date = .now) -> String {
        let day = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return "\(day.year ?? 0)-\(day.month ?? 0)-\(day.day ?? 0)"
    }

    func count(_ activity: Activity) -> Int {
        counts[activity.rawValue] ?? 0
    }

    // MARK: Streak and gift

    /// Counts today's visit. Returns true when today's gift box hasn't been opened yet.
    @discardableResult
    func checkIn() -> Bool {
        let today = Self.dayString()
        if lastVisitDay != today {
            let yesterday = Self.dayString(Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now)
            // Missing a day just starts the count again; nothing bad happens to the bunny.
            streak = lastVisitDay == yesterday ? streak + 1 : 1
            bestStreak = max(bestStreak, streak)
            lastVisitDay = today
            save()
        }
        return lastGiftDay != today
    }

    /// Where today sits in the 7-day gift week, 1 to 7.
    var dayOfWeek: Int { max(streak - 1, 0) % 7 + 1 }

    var giftAmount: Int { Self.giftTable[dayOfWeek - 1] }

    /// Opens today's gift and returns the dewdrops inside.
    func openGift() -> Int {
        lastGiftDay = Self.dayString()
        save()
        return giftAmount
    }

    // MARK: Quests

    var todaysQuests: [Quest] {
        Quest.forDay(Self.dayString())
    }

    func questCount(_ quest: Quest) -> Int {
        min(questDay == Self.dayString() ? questCounts[quest.activity.rawValue] ?? 0 : 0, quest.goal)
    }

    func isDone(_ quest: Quest) -> Bool {
        questDay == Self.dayString() && questsDone.contains(quest.id)
    }

    /// Notes something the child did. Returns the quests it finished, and whether that finished all three today.
    func record(_ activity: Activity) -> (finished: [Quest], allDone: Bool) {
        let today = Self.dayString()
        if questDay != today {
            questDay = today
            questCounts = [:]
            questsDone = []
            bonusPaid = false
        }
        counts[activity.rawValue, default: 0] += 1
        questCounts[activity.rawValue, default: 0] += 1

        let quests = Quest.forDay(today)
        let finished = quests.filter {
            $0.activity == activity && !questsDone.contains($0.id) && questCounts[activity.rawValue, default: 0] >= $0.goal
        }
        for quest in finished {
            questsDone.insert(quest.id)
            stars += 1
        }
        var allDone = false
        if !bonusPaid, quests.allSatisfy({ questsDone.contains($0.id) }) {
            bonusPaid = true
            allDone = true
        }
        save()
        return (finished, allDone)
    }

    // MARK: Stickers

    /// Adds any stickers just earned to the album and returns them.
    func newStickers(_ context: StickerContext) -> [Sticker] {
        let earned = Sticker.all.filter { !stickers.contains($0.id) && $0.isEarned(self, context) }
        guard !earned.isEmpty else { return [] }
        stickers.formUnion(earned.map(\.id))
        save()
        return earned
    }

    // MARK: Saving

    static func load() -> GardenProgress {
        guard
            let data = UserDefaults.standard.data(forKey: saveKey),
            let progress = try? JSONDecoder().decode(GardenProgress.self, from: data)
        else { return GardenProgress() }
        return progress
    }

    private func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.saveKey)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case streak, bestStreak, stars, stickers, counts, lastVisitDay, lastGiftDay, questDay, questCounts, questsDone, bonusPaid
    }

    init() {}

    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        streak = try c.decodeIfPresent(Int.self, forKey: .streak) ?? 0
        bestStreak = try c.decodeIfPresent(Int.self, forKey: .bestStreak) ?? 0
        stars = try c.decodeIfPresent(Int.self, forKey: .stars) ?? 0
        stickers = try c.decodeIfPresent(Set<String>.self, forKey: .stickers) ?? []
        counts = try c.decodeIfPresent([String: Int].self, forKey: .counts) ?? [:]
        lastVisitDay = try c.decodeIfPresent(String.self, forKey: .lastVisitDay)
        lastGiftDay = try c.decodeIfPresent(String.self, forKey: .lastGiftDay)
        questDay = try c.decodeIfPresent(String.self, forKey: .questDay)
        questCounts = try c.decodeIfPresent([String: Int].self, forKey: .questCounts) ?? [:]
        questsDone = try c.decodeIfPresent(Set<String>.self, forKey: .questsDone) ?? []
        bonusPaid = try c.decodeIfPresent(Bool.self, forKey: .bonusPaid) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(streak, forKey: .streak)
        try c.encode(bestStreak, forKey: .bestStreak)
        try c.encode(stars, forKey: .stars)
        try c.encode(stickers, forKey: .stickers)
        try c.encode(counts, forKey: .counts)
        try c.encodeIfPresent(lastVisitDay, forKey: .lastVisitDay)
        try c.encodeIfPresent(lastGiftDay, forKey: .lastGiftDay)
        try c.encodeIfPresent(questDay, forKey: .questDay)
        try c.encode(questCounts, forKey: .questCounts)
        try c.encode(questsDone, forKey: .questsDone)
        try c.encode(bonusPaid, forKey: .bonusPaid)
    }
}
