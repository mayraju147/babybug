import Foundation

/// The bunny's needs, from 0 (empty) to 1 (full). Saved on the device between launches.
@Observable
final class PetStats: Codable {
    var hunger: Double = 1
    var happiness: Double = 1
    var cleanliness: Double = 1
    var energy: Double = 1
    /// True while the bunny is tucked up in bed after the child tapped the cottage.
    var isSleeping = false
    var lastUpdated = Date()

    /// How much each need drops per hour while you're away. Gentle, so the bunny never "dies".
    private static let hungerPerHour = 0.08
    private static let happinessPerHour = 0.06
    private static let cleanlinessPerHour = 0.05
    private static let energyPerHour = 0.05
    /// Sleep refills energy quickly (about half a minute from empty), so bedtime feels rewarding to a small child.
    private static let restPerHour = 120.0
    private static let saveKey = "babybug.petStats"

    func feed() {
        tick()
        hunger = min(1, hunger + 0.25)
        save()
    }

    func play() {
        tick()
        happiness = min(1, happiness + 0.1)
        save()
    }

    func bathe() {
        tick()
        cleanliness = min(1, cleanliness + 0.25)
        save()
    }

    func sleep() {
        tick()
        isSleeping = true
        save()
    }

    func wake() {
        tick()
        isSleeping = false
        save()
    }

    /// Lowers the needs by however much real time has passed since the last update.
    func tick(now: Date = Date()) {
        let hours = now.timeIntervalSince(lastUpdated) / 3600
        guard hours > 0 else { return }
        hunger = max(0, hunger - hours * Self.hungerPerHour)
        happiness = max(0, happiness - hours * Self.happinessPerHour)
        cleanliness = max(0, cleanliness - hours * Self.cleanlinessPerHour)
        if isSleeping {
            energy = min(1, energy + hours * Self.restPerHour)
        } else {
            energy = max(0, energy - hours * Self.energyPerHour)
        }
        lastUpdated = now
        save()
    }

    static func load() -> PetStats {
        guard
            let data = UserDefaults.standard.data(forKey: saveKey),
            let stats = try? JSONDecoder().decode(PetStats.self, from: data)
        else { return PetStats() }
        stats.tick()
        return stats
    }

    private func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.saveKey)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case hunger, happiness, cleanliness, energy, isSleeping, lastUpdated
    }

    init() {}

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        hunger = try container.decode(Double.self, forKey: .hunger)
        happiness = try container.decode(Double.self, forKey: .happiness)
        // Saves from before bath and bedtime existed don't have these yet.
        cleanliness = try container.decodeIfPresent(Double.self, forKey: .cleanliness) ?? 1
        energy = try container.decodeIfPresent(Double.self, forKey: .energy) ?? 1
        isSleeping = try container.decodeIfPresent(Bool.self, forKey: .isSleeping) ?? false
        lastUpdated = try container.decode(Date.self, forKey: .lastUpdated)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(hunger, forKey: .hunger)
        try container.encode(happiness, forKey: .happiness)
        try container.encode(cleanliness, forKey: .cleanliness)
        try container.encode(energy, forKey: .energy)
        try container.encode(isSleeping, forKey: .isSleeping)
        try container.encode(lastUpdated, forKey: .lastUpdated)
    }
}
