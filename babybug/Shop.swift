import CoreGraphics
import Foundation

/// Something the child can buy with dewdrops: a treat to feed the bunny, or a decoration for the garden.
enum ShopItem: String, CaseIterable, Identifiable, Codable {
    // Treats
    case carrot, strawberry, clover, cupcake
    // Garden decorations
    case flowerPot, lantern, mushroom

    enum Kind { case treat, decoration }

    var id: String { rawValue }

    var kind: Kind {
        switch self {
        case .carrot, .strawberry, .clover, .cupcake: .treat
        case .flowerPot, .lantern, .mushroom: .decoration
        }
    }

    var title: String {
        switch self {
        case .carrot: "Carrot"
        case .strawberry: "Strawberry"
        case .clover: "Clover"
        case .cupcake: "Cupcake"
        case .flowerPot: "Flower pot"
        case .lantern: "Lantern"
        case .mushroom: "Mushroom"
        }
    }

    /// Dewdrops it costs. The carrot is free and owned from the start.
    var price: Int {
        switch self {
        case .carrot: 0
        case .strawberry: 10
        case .clover: 15
        case .cupcake: 25
        case .flowerPot: 20
        case .lantern: 30
        case .mushroom: 40
        }
    }

    /// Painted picture in the asset catalog. Until it's added, `emoji` stands in.
    var imageName: String {
        switch self {
        case .carrot: "Carrot"
        case .strawberry: "FoodStrawberry"
        case .clover: "FoodClover"
        case .cupcake: "FoodCupcake"
        case .flowerPot: "DecorFlowerPot"
        case .lantern: "DecorLantern"
        case .mushroom: "DecorMushroom"
        }
    }

    var emoji: String {
        switch self {
        case .carrot: "🥕"
        case .strawberry: "🍓"
        case .clover: "🍀"
        case .cupcake: "🧁"
        case .flowerPot: "🪴"
        case .lantern: "🏮"
        case .mushroom: "🍄"
        }
    }

    /// How much a treat fills the food bar, and how much it cheers the bunny up.
    var nourishment: (food: Double, joy: Double) {
        switch self {
        case .carrot: (0.25, 0)
        case .strawberry: (0.3, 0.05)
        case .clover: (0.35, 0.05)
        case .cupcake: (0.4, 0.15)
        case .flowerPot, .lantern, .mushroom: (0, 0)
        }
    }

    /// Where a decoration stands in the garden, in scene points (the bunny sits at 45, -290).
    var gardenSpot: CGPoint {
        switch self {
        case .flowerPot: CGPoint(x: -60, y: -395)
        case .lantern: CGPoint(x: 160, y: -230)
        case .mushroom: CGPoint(x: -170, y: -390)
        default: .zero
        }
    }

    /// Height in the garden, in scene points.
    var gardenHeight: CGFloat {
        switch self {
        case .flowerPot: 70
        case .lantern: 90
        case .mushroom: 80
        default: 76
        }
    }
}

/// The child's dewdrops and what they've bought. Saved on the device between launches.
@Observable
final class Inventory: Codable {
    var dewdrops = 5
    var owned: Set<ShopItem> = [.carrot]
    /// The treat that sits in the garden, ready to drag to the bunny.
    var treat: ShopItem = .carrot

    private static let saveKey = "babybug.inventory"

    var decorations: [ShopItem] {
        ShopItem.allCases.filter { $0.kind == .decoration && owned.contains($0) }
    }

    func earn(_ amount: Int = 1) {
        dewdrops += amount
        save()
    }

    /// Buys the item if there are enough dewdrops. A bought treat is put out in the garden straight away.
    @discardableResult
    func buy(_ item: ShopItem) -> Bool {
        guard !owned.contains(item), dewdrops >= item.price else { return false }
        dewdrops -= item.price
        owned.insert(item)
        if item.kind == .treat {
            treat = item
        }
        save()
        return true
    }

    func choose(_ item: ShopItem) {
        guard item.kind == .treat, owned.contains(item) else { return }
        treat = item
        save()
    }

    static func load() -> Inventory {
        guard
            let data = UserDefaults.standard.data(forKey: saveKey),
            let inventory = try? JSONDecoder().decode(Inventory.self, from: data)
        else { return Inventory() }
        return inventory
    }

    private func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.saveKey)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case dewdrops, owned, treat
    }

    init() {}

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        dewdrops = try container.decode(Int.self, forKey: .dewdrops)
        owned = try container.decode(Set<ShopItem>.self, forKey: .owned)
        treat = try container.decode(ShopItem.self, forKey: .treat)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(dewdrops, forKey: .dewdrops)
        try container.encode(owned, forKey: .owned)
        try container.encode(treat, forKey: .treat)
    }
}
