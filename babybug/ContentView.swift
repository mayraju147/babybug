import SpriteKit
import SwiftUI

struct ContentView: View {
    @State private var pet = PetStats.load()
    @State private var scene = GardenScene(size: CGSize(width: 390, height: 844))
    @AppStorage("hero") private var heroChoice = ""
    @State private var showingPicker = false

    private var hero: Hero? { Hero(rawValue: heroChoice) }

    var body: some View {
        ZStack(alignment: .top) {
            SpriteView(scene: scene)
                .ignoresSafeArea()
            StatsBar(pet: pet)
                .padding(.top, 8)
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
        .fullScreenCover(isPresented: $showingPicker) {
            HeroPicker { chosen in
                heroChoice = chosen.rawValue
                scene.setHero(chosen)
                showingPicker = false
            }
        }
        .onAppear {
            scene.onFeed = {
                pet.feed()
                scene.setMood(pet.mood())
            }
            scene.onTickle = {
                pet.play()
                scene.setMood(pet.mood())
            }
            scene.onBathe = {
                pet.bathe()
                scene.setMood(pet.mood())
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
