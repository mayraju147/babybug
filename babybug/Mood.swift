import Foundation

/// How the bunny feels right now. Worked out from its bars and the time of day.
enum Mood: Equatable {
    case happy
    case content
    case hungry
    case lonely
    case dirty
    case sleepy

    /// Picture for this mood in the asset catalog. Falls back to the default bunny until the painted pose exists.
    var imageName: String {
        switch self {
        case .happy: "BunnyHappy"
        case .content: "Bunny"
        case .hungry: "BunnyHungry"
        case .lonely: "BunnyLonely"
        case .dirty: "Bunny"
        case .sleepy: "BunnySleepy"
        }
    }

    /// How tall the picture is compared with the upright poses. Curled up asleep, the bunny is lower and wider.
    var heightScale: Double {
        self == .sleepy ? 0.72 : 1
    }

    /// What the bunny is thinking about, shown in a little bubble above its head.
    var thought: String? {
        switch self {
        case .hungry: "🥕"
        case .lonely: "💗"
        case .dirty: "🫧"
        case .sleepy: "💤"
        case .happy, .content: nil
        }
    }
}

extension PetStats {
    /// Asleep in bed wins; then needs (hungry, lonely, dirty); then tiredness or bedtime; then how well looked after the bunny is.
    func mood(at date: Date = Date(), calendar: Calendar = .current) -> Mood {
        if isSleeping { return .sleepy }
        let hour = calendar.component(.hour, from: date)
        let isBedtime = hour >= 20 || hour < 7
        if hunger < 0.35 { return .hungry }
        if happiness < 0.35 { return .lonely }
        if cleanliness < 0.35 { return .dirty }
        if isBedtime || energy < 0.3 { return .sleepy }
        if hunger > 0.7 && happiness > 0.7 && cleanliness > 0.7 { return .happy }
        return .content
    }
}
