import CoreGraphics

/// How grown-up the bunny is. It grows one step at a time on the days the child looks after it.
enum Stage: Int, Codable, CaseIterable {
    case baby
    case young
    case grown

    /// Days of care (feeding, tickling or bathing at least once that day) needed to reach this stage.
    var careDaysNeeded: Int {
        switch self {
        case .baby: 0
        case .young: 3
        case .grown: 7
        }
    }

    /// Height of the bunny standing up, in scene points. The princess and prince are 300.
    var bunnyHeight: CGFloat {
        switch self {
        case .baby: 200
        case .young: 225
        case .grown: 250
        }
    }

    /// Start of this stage's picture names in the asset catalog, e.g. "BunnyYoung" and "BunnyYoungHappy".
    var imagePrefix: String {
        switch self {
        case .baby: "Bunny"
        case .young: "BunnyYoung"
        case .grown: "BunnyGrown"
        }
    }

    static func forCareDays(_ days: Int) -> Stage {
        allCases.last { days >= $0.careDaysNeeded } ?? .baby
    }
}
