import SpriteKit
import SwiftUI

struct ContentView: View {
    @State private var pet = PetStats.load()
    @State private var scene = GardenScene(size: CGSize(width: 390, height: 844))

    var body: some View {
        ZStack(alignment: .top) {
            SpriteView(scene: scene)
                .ignoresSafeArea()
            StatsBar(pet: pet)
                .padding(.top, 8)
        }
        .onAppear {
            scene.onFeed = { pet.feed() }
            scene.onTickle = { pet.play() }
        }
        .task {
            // Refresh the bars every few seconds so hunger and happiness drift down in real time.
            while !Task.isCancelled {
                pet.tick()
                try? await Task.sleep(for: .seconds(5))
            }
        }
    }
}

private struct StatsBar: View {
    let pet: PetStats

    var body: some View {
        HStack(spacing: 16) {
            Meter(symbol: "carrot.fill", value: pet.hunger, tint: .orange)
            Meter(symbol: "heart.fill", value: pet.happiness, tint: .pink)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
    }
}

private struct Meter: View {
    let symbol: String
    let value: Double
    let tint: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: symbol).foregroundStyle(tint)
            ProgressView(value: value)
                .tint(tint)
                .frame(width: 90)
        }
    }
}

#Preview {
    ContentView()
}
