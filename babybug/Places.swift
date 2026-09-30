import SpriteKit
import SwiftUI

/// Places beyond the garden to visit with the bunny. Each hides five little things to find.
enum Place: String, CaseIterable, Identifiable {
    case pond, meadow

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pond: "Lily Pond"
        case .meadow: "Sunny Meadow"
        }
    }

    var emoji: String {
        switch self {
        case .pond: "🪷"
        case .meadow: "🌻"
        }
    }

    /// Painted background in the asset catalog; until it's added, a simple drawn one stands in.
    var backgroundImage: String {
        switch self {
        case .pond: "PondBackground"
        case .meadow: "MeadowBackground"
        }
    }

    /// The things hidden here, as emoji with a name for the found list.
    var finds: [(emoji: String, name: String)] {
        switch self {
        case .pond: [("🐸", "frog"), ("🦆", "duckling"), ("🐟", "fish"), ("🐚", "shell"), ("🐞", "ladybug")]
        case .meadow: [("🐌", "snail"), ("🐝", "bee"), ("🍄", "mushroom"), ("🐞", "ladybug"), ("🪺", "nest")]
        }
    }

    /// Hiding spots in scene points (the scene is 390 by 844 with the middle at 0, 0).
    var spots: [CGPoint] {
        switch self {
        case .pond:
            [CGPoint(x: -140, y: -120), CGPoint(x: 120, y: -60), CGPoint(x: -60, y: -250), CGPoint(x: 150, y: -300),
             CGPoint(x: -150, y: 40), CGPoint(x: 40, y: 20), CGPoint(x: -20, y: -380), CGPoint(x: 160, y: 120)]
        case .meadow:
            [CGPoint(x: -150, y: -200), CGPoint(x: 140, y: -150), CGPoint(x: -40, y: -60), CGPoint(x: 90, y: -330),
             CGPoint(x: -120, y: -370), CGPoint(x: 150, y: 30), CGPoint(x: -160, y: 60), CGPoint(x: 20, y: -220)]
        }
    }
}

/// Exploring a place: tap around to find the hidden things; the bunny hops over to each tap.
final class ExploreScene: SKScene {
    var onFound: ((Int) -> Void)?

    private let place: Place
    private let bunny: SKSpriteNode
    private var hidden: [(node: SKNode, index: Int)] = []
    private var isBuilt = false

    init(size: CGSize, place: Place, bunnyImage: String) {
        self.place = place
        bunny = SKSpriteNode(imageNamed: bunnyImage)
        super.init(size: size)
        scaleMode = .aspectFill
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not used")
    }

    override func didMove(to view: SKView) {
        guard !isBuilt else { return }
        isBuilt = true
        addBackground()

        let height: CGFloat = 170
        let art = bunny.texture!.size()
        bunny.size = CGSize(width: height * art.width / art.height, height: height)
        bunny.anchorPoint = CGPoint(x: 0.5, y: 0)
        bunny.position = CGPoint(x: 0, y: -size.height / 2 + 90)
        bunny.zPosition = 3
        addChild(bunny)

        // Hide each thing at a different spot, partly tucked away and small, with a faint twinkle as a hint.
        let spots = place.spots.shuffled()
        for (index, find) in place.finds.enumerated() {
            let label = SKLabelNode(text: find.emoji)
            label.fontSize = 34
            label.verticalAlignmentMode = .center
            label.position = spots[index]
            label.zPosition = 2
            label.alpha = 0.9
            label.zRotation = .random(in: -0.4...0.4)
            addChild(label)
            let twinkle = SKLabelNode(text: "✦")
            twinkle.fontSize = 14
            twinkle.fontColor = .white
            twinkle.position = CGPoint(x: 18, y: 16)
            twinkle.alpha = 0
            label.addChild(twinkle)
            twinkle.run(.repeatForever(.sequence([
                .wait(forDuration: .random(in: 2...5)),
                .fadeIn(withDuration: 0.3),
                .fadeOut(withDuration: 0.5),
            ])))
            hidden.append((label, index))
        }
    }

    private func addBackground() {
        if UIImage(named: place.backgroundImage) != nil {
            let background = SKSpriteNode(imageNamed: place.backgroundImage)
            let texture = background.texture!.size()
            background.size = CGSize(width: size.height * texture.width / texture.height, height: size.height)
            background.zPosition = -10
            addChild(background)
            return
        }
        // Simple stand-in: sky, grass, and a pond or flowers.
        let sky = SKSpriteNode(color: SKColor(red: 0.85, green: 0.92, blue: 1, alpha: 1),
                               size: CGSize(width: size.width * 2, height: size.height))
        sky.zPosition = -10
        addChild(sky)
        let grass = SKSpriteNode(color: SKColor(red: 0.78, green: 0.9, blue: 0.7, alpha: 1),
                                 size: CGSize(width: size.width * 2, height: size.height * 0.62))
        grass.position = CGPoint(x: 0, y: -size.height * 0.19)
        grass.zPosition = -9
        addChild(grass)
        if place == .pond {
            let pond = SKShapeNode(ellipseOf: CGSize(width: 330, height: 200))
            pond.fillColor = SKColor(red: 0.6, green: 0.78, blue: 0.95, alpha: 1)
            pond.strokeColor = SKColor(red: 0.5, green: 0.68, blue: 0.85, alpha: 1)
            pond.lineWidth = 3
            pond.position = CGPoint(x: 0, y: -90)
            pond.zPosition = -8
            addChild(pond)
            for spot in [CGPoint(x: -80, y: -60), CGPoint(x: 70, y: -120), CGPoint(x: 20, y: -40)] {
                let lily = SKLabelNode(text: "🪷")
                lily.fontSize = 30
                lily.position = spot
                lily.zPosition = -7
                addChild(lily)
            }
        } else {
            for _ in 0..<22 {
                let flower = SKLabelNode(text: ["🌼", "🌸", "🌻", "🌷"].randomElement()!)
                flower.fontSize = .random(in: 18...28)
                flower.position = CGPoint(x: .random(in: -190...190), y: .random(in: -420...(-10)))
                flower.zPosition = -7
                addChild(flower)
            }
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        if let item = hidden.first(where: { $0.node.calculateAccumulatedFrame().insetBy(dx: -16, dy: -16).contains(point) }) {
            hidden.removeAll { $0.node === item.node }
            find(item.node, index: item.index)
        }
        hop(towards: point)
    }

    private func find(_ node: SKNode, index: Int) {
        SoundPlayer.shared.play(.dewdrop)
        onFound?(index)
        node.removeAllActions()
        node.run(.sequence([
            .group([.scale(to: 1.8, duration: 0.25), .rotate(toAngle: 0, duration: 0.25)]),
            .group([.moveBy(x: 0, y: 60, duration: 0.5), .fadeOut(withDuration: 0.5)]),
            .removeFromParent(),
        ]))
        for i in 0..<8 {
            let sparkle = SKLabelNode(text: i.isMultiple(of: 2) ? "✦" : "♥")
            sparkle.fontSize = 16
            sparkle.fontColor = SKColor(red: 0.96, green: 0.52, blue: 0.72, alpha: 1)
            sparkle.position = node.position
            sparkle.zPosition = 6
            addChild(sparkle)
            let angle = CGFloat(i) / 8 * 2 * .pi
            sparkle.run(.sequence([
                .group([.moveBy(x: cos(angle) * 50, y: sin(angle) * 50, duration: 0.6), .fadeOut(withDuration: 0.6)]),
                .removeFromParent(),
            ]))
        }
    }

    /// The bunny hops a little way towards where the child tapped, staying near the bottom of the screen.
    private func hop(towards point: CGPoint) {
        guard bunny.action(forKey: "hop") == nil else { return }
        let targetX = min(max(point.x, -150), 150)
        let dx = (targetX - bunny.position.x) * 0.6
        guard abs(dx) > 10 else { return }
        bunny.xScale = dx > 0 ? abs(bunny.xScale) : -abs(bunny.xScale)
        let up = SKAction.moveBy(x: dx / 2, y: 26, duration: 0.18)
        up.timingMode = .easeOut
        let down = SKAction.moveBy(x: dx / 2, y: -26, duration: 0.18)
        down.timingMode = .easeIn
        bunny.run(.sequence([up, down]), withKey: "hop")
    }
}

/// "Where shall we go?": pick a place to visit.
struct PlacesView: View {
    let bunnyImage: String
    let bunnyName: String
    /// Called when everything at a place has been found; returns the dewdrops it earned.
    let onExplored: (Place) -> Int
    let onClose: () -> Void

    @State private var visiting: Place?

    var body: some View {
        ZStack {
            CandyStripes()
                .ignoresSafeArea()
            SparkleField()
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(spacing: 18) {
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

                Text("Where shall we go?")
                    .font(.whimsy(32))
                    .foregroundStyle(Y2K.ink)
                    .shadow(color: .white, radius: 0, x: 2, y: 2)

                ForEach(Place.allCases) { place in
                    Button {
                        SoundPlayer.shared.play(.tap)
                        visiting = place
                    } label: {
                        HStack(spacing: 14) {
                            Text(place.emoji)
                                .font(.system(size: 44))
                                .frame(width: 70, height: 70)
                                .background(Circle().fill(Y2K.stripeLight))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(place.title)
                                    .font(.whimsy(24))
                                Text("Find 5 hidden friends")
                                    .font(.system(.subheadline, design: .rounded))
                            }
                            .foregroundStyle(Y2K.ink)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(Y2K.bubblegum)
                        }
                        .padding(16)
                        .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(.white.opacity(0.92)))
                        .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).strokeBorder(Y2K.holo, lineWidth: 3))
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .padding(16)
        }
        .fullScreenCover(item: $visiting) { place in
            ExploreView(place: place, bunnyImage: bunnyImage, bunnyName: bunnyName, onExplored: onExplored) {
                visiting = nil
            }
        }
    }
}

/// One place: the scene, a row showing what's been found, and a card when everything is found.
struct ExploreView: View {
    let place: Place
    let bunnyName: String
    let onExplored: (Place) -> Int
    let onClose: () -> Void

    @State private var scene: ExploreScene
    @State private var found: Set<Int> = []
    @State private var reward: Int?

    init(place: Place, bunnyImage: String, bunnyName: String, onExplored: @escaping (Place) -> Int, onClose: @escaping () -> Void) {
        self.place = place
        self.bunnyName = bunnyName
        self.onExplored = onExplored
        self.onClose = onClose
        _scene = State(initialValue: ExploreScene(size: CGSize(width: 390, height: 844), place: place, bunnyImage: bunnyImage))
    }

    var body: some View {
        ZStack {
            SpriteView(scene: scene)
                .ignoresSafeArea()

            VStack(spacing: 8) {
                HStack {
                    Text(place.title)
                        .font(.whimsy(24))
                        .foregroundStyle(Y2K.ink)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(.white.opacity(0.92)))
                        .overlay(Capsule().strokeBorder(Y2K.holo, lineWidth: 2))
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Y2K.ink)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(.white.opacity(0.9)))
                            .overlay(Circle().strokeBorder(Y2K.holo, lineWidth: 2))
                    }
                    .accessibilityLabel("Back")
                }
                // What to look for: empty until found.
                HStack(spacing: 8) {
                    ForEach(Array(place.finds.enumerated()), id: \.offset) { index, find in
                        Text(find.emoji)
                            .font(.system(size: 26))
                            .opacity(found.contains(index) ? 1 : 0.25)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(.white.opacity(0.9)))
                            .overlay(Circle().strokeBorder(found.contains(index) ? AnyShapeStyle(Y2K.holo) : AnyShapeStyle(Y2K.ink.opacity(0.2)), lineWidth: 2))
                            .accessibilityLabel(found.contains(index) ? "Found the \(find.name)" : "Find the \(find.name)")
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            if let reward {
                VStack(spacing: 14) {
                    Text("You found them all!")
                        .font(.whimsy(30))
                    if reward > 0 {
                        HStack(spacing: 6) {
                            DewdropIcon().frame(width: 30, height: 30)
                            Text("+\(reward) dewdrops")
                                .font(.whimsy(22))
                        }
                    } else {
                        Text("Come back tomorrow for more dewdrops.")
                            .font(.whimsy(16))
                            .multilineTextAlignment(.center)
                    }
                    Button(action: onClose) {
                        Text("Home to the garden")
                            .font(.whimsy(22))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 26)
                            .padding(.vertical, 12)
                            .background(Capsule().fill(Y2K.bubblegum))
                            .overlay(Capsule().strokeBorder(.white, lineWidth: 2))
                    }
                    .buttonStyle(.plain)
                }
                .foregroundStyle(Y2K.ink)
                .padding(24)
                .frame(maxWidth: 330)
                .background(
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .fill(LinearGradient(colors: [.white, Y2K.stripeLight], startPoint: .top, endPoint: .bottom))
                )
                .overlay(RoundedRectangle(cornerRadius: 32, style: .continuous).strokeBorder(Y2K.holo, lineWidth: 4))
                .transition(.scale.combined(with: .opacity))
            }
        }
        .onAppear {
            scene.onFound = { index in
                found.insert(index)
                if found.count == place.finds.count {
                    SoundPlayer.shared.play(.grow)
                    withAnimation(.spring) { reward = onExplored(place) }
                }
            }
        }
    }
}
