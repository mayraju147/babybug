import SpriteKit
import SwiftUI

struct ContentView: View {
    @State private var pet = PetStats.load()
    @State private var inventory = Inventory.load()
    @State private var store: DewdropStore?
    @State private var showingShop = false
    @State private var scene = GardenScene(size: CGSize(width: 390, height: 844))
    @AppStorage("hero") private var heroChoice = ""
    @State private var showingPicker = false
    /// The stage the garden is showing, so a new one can be celebrated.
    @State private var shownStage: Stage = .baby

    private var hero: Hero? { Hero(rawValue: heroChoice) }

    var body: some View {
        ZStack(alignment: .top) {
            SpriteView(scene: scene)
                .ignoresSafeArea()
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
                    .font(.title3)
                    .foregroundStyle(.yellow)
                    .padding(10)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .padding(.trailing, 12)
            .padding(.top, 60)
            .accessibilityLabel("Change princess or prince")
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
                }) {
                    if let store {
                        ShopView(inventory: inventory, store: store) {
                            showingShop = false
                        }
                    }
                }
            }
            .padding(.leading, 12)
            .padding(.top, 66)
        }
        .fullScreenCover(isPresented: $showingPicker) {
            HeroPicker { chosen in
                heroChoice = chosen.rawValue
                scene.setHero(chosen)
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
                pet.feed(inventory.treat)
                if needed { earnDewdrop() }
                scene.setMood(pet.mood())
                updateStage()
            }
            scene.onTickle = {
                let needed = pet.happiness < 0.98
                pet.play()
                if needed { earnDewdrop() }
                scene.setMood(pet.mood())
                updateStage()
            }
            scene.onBathe = {
                let needed = pet.cleanliness < 0.98
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
            }
            scene.setSleeping(pet.isSleeping)
            scene.setMood(pet.mood())
            scene.setStage(pet.stage)
            scene.setTreat(inventory.treat)
            scene.setDecorations(inventory.decorations)
            shownStage = pet.stage
            if let hero {
                scene.setHero(hero)
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

    /// Looking after the bunny when it actually needs it earns a dewdrop.
    private func earnDewdrop() {
        inventory.earn()
        scene.showDewdropEarned()
    }

    private func updateStage() {
        guard pet.stage != shownStage else { return }
        shownStage = pet.stage
        scene.setStage(pet.stage, celebrate: true)
    }
}

private struct StatsBar: View {
    let pet: PetStats

    var body: some View {
        HStack(spacing: 10) {
            Meter(symbol: "carrot.fill", value: pet.hunger, tint: .orange)
            Meter(symbol: "heart.fill", value: pet.happiness, tint: .pink)
            Meter(symbol: "bubbles.and.sparkles.fill", value: pet.cleanliness, tint: .cyan)
            Meter(symbol: "moon.stars.fill", value: pet.energy, tint: .indigo)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
    }
}

private struct Meter: View {
    let symbol: String
    let value: Double
    let tint: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: symbol).foregroundStyle(tint)
            ProgressView(value: value)
                .tint(tint)
                .frame(width: 44)
        }
    }
}

#Preview {
    ContentView()
}
