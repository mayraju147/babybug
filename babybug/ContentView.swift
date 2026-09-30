import SpriteKit
import SwiftUI

struct ContentView: View {
    @State private var pet = PetStats.load()
    @State private var inventory = Inventory.load()
    @State private var store: DewdropStore?
    @State private var showingShop = false
    @State private var scene = GardenScene(size: CGSize(width: 390, height: 844))
    @AppStorage("hero") private var heroChoice = ""
    @AppStorage("bunnyName") private var bunnyName = ""
    @AppStorage("soundOn") private var soundOn = true
    /// Butterflies caught today, so a day's catch pays out a limited number of dewdrops.
    @AppStorage("butterflyDay") private var butterflyDay = ""
    @AppStorage("butterfliesToday") private var butterfliesToday = 0
    @State private var showingNamer = false
    @State private var showingPicker = false
    /// The stage the garden is showing, so a new one can be celebrated.
    @State private var shownStage: Stage = .baby

    private var hero: Hero? { Hero(rawValue: heroChoice) }

    var body: some View {
        ZStack(alignment: .top) {
            SpriteView(scene: scene)
                .ignoresSafeArea()
                .fullScreenCover(isPresented: $showingNamer) {
                    BunnyNamer(startingName: bunnyName) { name in
                        bunnyName = name
                        scene.setBunnyName(name)
                        showingNamer = false
                    }
                }
            // A few Y2K twinkles over the garden, soft enough not to hide the painting.
            SparkleField()
                .opacity(0.6)
                .ignoresSafeArea()
                .allowsHitTesting(false)
            StatsBar(pet: pet)
                .padding(.top, 8)
                .onLongPressGesture(minimumDuration: 2) {
                    // Hidden helper for testing: hold the bars for 2 seconds to grow the bunny and get 50 dewdrops.
                    pet.growForTesting()
                    inventory.earn(50)
                    updateStage()
                }
        }
        .overlay(alignment: .topTrailing) {
            // Small crown button so a grown-up can switch between princess and prince later.
            Button {
                showingPicker = true
            } label: {
                Image(systemName: "crown.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(
                        LinearGradient(colors: [Color(red: 1, green: 0.9, blue: 0.5), Color(red: 0.93, green: 0.68, blue: 0.2)],
                                       startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: 46, height: 46)
                    .background(Circle().fill(.white.opacity(0.9)))
                    .overlay(Circle().strokeBorder(Y2K.holo, lineWidth: 2.5))
                    .shadow(color: Y2K.bubblegum.opacity(0.3), radius: 5, y: 2)
            }
            .accessibilityLabel("Change princess or prince")
            .overlay(alignment: .bottom) {
                // Sound on or off, for grown-ups (and quiet times).
                Button {
                    soundOn.toggle()
                    SoundPlayer.shared.isOn = soundOn
                } label: {
                    Image(systemName: soundOn ? "speaker.wave.2.fill" : "speaker.slash.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Y2K.ink)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(.white.opacity(0.9)))
                        .overlay(Circle().strokeBorder(Y2K.holo, lineWidth: 2))
                }
                .offset(y: 50)
                .accessibilityLabel(soundOn ? "Turn sound off" : "Turn sound on")
            }
            .padding(.trailing, 12)
            .padding(.top, 60)
        }
        .overlay(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 10) {
                DewdropCounter(count: inventory.dewdrops)
                // Big, easy-to-hit shop button for small fingers.
                Button {
                    showingShop = true
                } label: {
                    Image(systemName: "basket.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Y2K.bubblegum)
                        .frame(width: 56, height: 56)
                        .background(Circle().fill(.white.opacity(0.9)))
                        .overlay(Circle().strokeBorder(Y2K.holo, lineWidth: 3))
                        .shadow(color: Y2K.bubblegum.opacity(0.35), radius: 6, y: 3)
                }
                .accessibilityLabel("Dewdrop shop")
                .fullScreenCover(isPresented: $showingShop, onDismiss: {
                    scene.setTreat(inventory.treat)
                    scene.setDecorations(inventory.decorations)
                    if let hero { scene.setHero(hero, outfit: inventory.outfit) }
                }) {
                    if let store {
                        ShopView(inventory: inventory, store: store, hero: hero) {
                            showingShop = false
                        }
                    }
                }
            }
            .padding(.leading, 12)
            .padding(.top, 66)
        }
        .fullScreenCover(isPresented: $showingPicker, onDismiss: {
            // First time through: name the bunny straight after choosing the princess or prince.
            if bunnyName.isEmpty {
                showingNamer = true
            }
        }) {
            HeroPicker { chosen in
                heroChoice = chosen.rawValue
                scene.setHero(chosen, outfit: inventory.outfit)
                showingPicker = false
            }
        }
        .onAppear {
            // Start listening for App Store purchases straight away, so an approved "Ask to Buy" still arrives.
            if store == nil {
                store = DewdropStore(inventory: inventory)
            }
            scene.onFeed = {
                let needed = pet.hunger < 0.98
                SoundPlayer.shared.play(.munch)
                pet.feed(inventory.treat)
                if needed { earnDewdrop() }
                scene.setMood(pet.mood())
                updateStage()
            }
            scene.onTickle = {
                let needed = pet.happiness < 0.98
                SoundPlayer.shared.play(.tickle)
                pet.play()
                if needed { earnDewdrop() }
                scene.setMood(pet.mood())
                updateStage()
            }
            scene.onBathe = {
                let needed = pet.cleanliness < 0.98
                SoundPlayer.shared.play(.bubble)
                pet.bathe()
                if needed { earnDewdrop() }
                scene.setMood(pet.mood())
                updateStage()
            }
            scene.onBedtimeTapped = {
                if pet.isSleeping {
                    pet.wake()
                } else {
                    pet.sleep()
                }
                scene.setSleeping(pet.isSleeping)
                scene.setMood(pet.mood())
                SoundPlayer.shared.play(pet.isSleeping ? .bedtime : .wakeup)
                SoundPlayer.shared.playMusic(pet.isSleeping ? .night : .garden)
            }
            scene.onNameTapped = {
                showingNamer = true
            }
            scene.onButterflyCaught = {
                catchButterfly()
            }
            scene.setBunnyName(bunnyName)
            SoundPlayer.shared.playMusic(pet.isSleeping ? .night : .garden)
            scene.setSleeping(pet.isSleeping)
            scene.setMood(pet.mood())
            scene.setStage(pet.stage)
            scene.setTreat(inventory.treat)
            scene.setDecorations(inventory.decorations)
            shownStage = pet.stage
            if let hero {
                scene.setHero(hero, outfit: inventory.outfit)
                // Players from before names existed get asked once.
                if bunnyName.isEmpty {
                    showingNamer = true
                }
            } else {
                showingPicker = true
            }
        }
        .task {
            // Refresh the bars every few seconds so hunger and happiness drift down in real time.
            while !Task.isCancelled {
                pet.tick()
                scene.setMood(pet.mood())
                try? await Task.sleep(for: .seconds(5))
            }
        }
    }

    /// Each butterfly caught earns a dewdrop, up to 10 a day; after that they're just for fun.
    private func catchButterfly() {
        let day = Calendar.current.dateComponents([.year, .month, .day], from: .now)
        let today = "\(day.year ?? 0)-\(day.month ?? 0)-\(day.day ?? 0)"
        if butterflyDay != today {
            butterflyDay = today
            butterfliesToday = 0
        }
        butterfliesToday += 1
        if butterfliesToday <= 10 {
            earnDewdrop()
        } else {
            SoundPlayer.shared.play(.tickle)
        }
    }

    /// Looking after the bunny when it actually needs it earns a dewdrop.
    private func earnDewdrop() {
        inventory.earn()
        SoundPlayer.shared.play(.dewdrop)
        scene.showDewdropEarned()
    }

    private func updateStage() {
        guard pet.stage != shownStage else { return }
        shownStage = pet.stage
        scene.setStage(pet.stage, celebrate: true)
        SoundPlayer.shared.play(.grow)
    }
}

/// The four need bars, as a glossy Y2K sticker strip.
private struct StatsBar: View {
    let pet: PetStats

    var body: some View {
        HStack(spacing: 8) {
            Meter(symbol: "carrot.fill", value: pet.hunger,
                  colors: [Color(red: 1.0, green: 0.80, blue: 0.55), Color(red: 1.0, green: 0.62, blue: 0.40)])
            Meter(symbol: "heart.fill", value: pet.happiness,
                  colors: [Y2K.stripeLight, Y2K.bubblegum])
            Meter(symbol: "bubbles.and.sparkles.fill", value: pet.cleanliness,
                  colors: [Y2K.mint, Y2K.babyBlue])
            Meter(symbol: "moon.stars.fill", value: pet.energy,
                  colors: [Y2K.babyBlue, Y2K.lilac])
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Capsule().fill(.white.opacity(0.88)))
        .overlay(alignment: .top) {
            // Shine across the top, like a glossy sticker.
            Capsule()
                .fill(LinearGradient(colors: [.white.opacity(0.9), .white.opacity(0)], startPoint: .top, endPoint: .bottom))
                .frame(height: 12)
                .padding(.horizontal, 16)
                .padding(.top, 3)
                .allowsHitTesting(false)
        }
        .overlay(Capsule().strokeBorder(Y2K.holo, lineWidth: 2.5))
        .overlay(
            Capsule()
                .inset(by: 5)
                .strokeBorder(Y2K.bubblegum.opacity(0.45), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
        )
        .shadow(color: Y2K.bubblegum.opacity(0.3), radius: 6, y: 3)
    }
}

private struct Meter: View {
    let symbol: String
    let value: Double
    let colors: [Color]

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(colors[1])
                .frame(width: 24, height: 24)
                .background(Circle().fill(colors[0].opacity(0.35)))
            ZStack(alignment: .leading) {
                Capsule().fill(colors[0].opacity(0.3))
                Capsule()
                    .fill(LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(8, 40 * value))
                    .overlay(alignment: .top) {
                        Capsule().fill(.white.opacity(0.55)).frame(height: 3).padding(.horizontal, 3).padding(.top, 1.5)
                    }
                    .animation(.spring, value: value)
            }
            .frame(width: 40, height: 10)
            .overlay(Capsule().strokeBorder(.white, lineWidth: 1))
        }
    }
}

#Preview {
    ContentView()
}
