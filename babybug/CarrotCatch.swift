import SpriteKit
import SwiftUI

/// Carrot Catch: treats fall from the sky and the child slides the bunny left and right to catch them.
/// A round lasts 30 seconds and there's no way to lose; a golden star is worth 3.
final class CatchGameScene: SKScene {
    var onScoreChange: ((Int) -> Void)?
    var onTimeChange: ((Int) -> Void)?
    var onFinish: ((Int) -> Void)?

    static let roundLength = 30

    private let bunnyImage: String
    private let catcher: SKSpriteNode
    private var falling: [(node: SKNode, value: Int)] = []
    private var score = 0
    private var timeLeft = roundLength
    private var playing = false
    private var isBuilt = false

    init(size: CGSize, bunnyImage: String) {
        self.bunnyImage = bunnyImage
        catcher = SKSpriteNode(imageNamed: bunnyImage)
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
        let garden = SKSpriteNode(imageNamed: "Garden")
        let texture = garden.texture!.size()
        garden.size = CGSize(width: size.height * texture.width / texture.height, height: size.height)
        garden.zPosition = -10
        addChild(garden)
        let wash = SKSpriteNode(color: SKColor(white: 1, alpha: 0.25), size: CGSize(width: size.width * 2, height: size.height))
        wash.zPosition = -9
        addChild(wash)

        let height: CGFloat = 150
        let art = catcher.texture!.size()
        catcher.size = CGSize(width: height * art.width / art.height, height: height)
        catcher.anchorPoint = CGPoint(x: 0.5, y: 0)
        catcher.position = CGPoint(x: 0, y: -size.height / 2 + 150)
        addChild(catcher)
    }

    func start() {
        falling.forEach { $0.node.removeFromParent() }
        falling = []
        score = 0
        timeLeft = Self.roundLength
        playing = true
        onScoreChange?(score)
        onTimeChange?(timeLeft)
        run(.repeat(.sequence([
            .wait(forDuration: 1),
            .run { [weak self] in self?.tick() },
        ]), count: Self.roundLength), withKey: "clock")
        scheduleNextTreat()
    }

    private func tick() {
        timeLeft -= 1
        onTimeChange?(timeLeft)
        if timeLeft <= 0 {
            playing = false
            removeAction(forKey: "spawn")
            SoundPlayer.shared.play(.grow)
            onFinish?(score)
        }
    }

    /// Treats come faster as the round goes on.
    private var progress: CGFloat { 1 - CGFloat(timeLeft) / CGFloat(Self.roundLength) }

    private func scheduleNextTreat() {
        guard playing else { return }
        let wait = 0.9 - 0.45 * progress
        run(.sequence([
            .wait(forDuration: wait),
            .run { [weak self] in
                self?.dropTreat()
                self?.scheduleNextTreat()
            },
        ]), withKey: "spawn")
    }

    private func dropTreat() {
        let isStar = Int.random(in: 0..<8) == 0
        let node: SKNode
        if isStar {
            let star = SKLabelNode(text: "⭐️")
            star.fontSize = 44
            star.verticalAlignmentMode = .center
            node = star
        } else {
            let (image, emoji) = [("Carrot", "🥕"), ("FoodStrawberry", "🍓"), ("FoodClover", "🍀")].randomElement()!
            if let picture = UIImage(named: image) {
                let sprite = SKSpriteNode(texture: SKTexture(image: picture))
                sprite.size = CGSize(width: 54 * picture.size.width / picture.size.height, height: 54)
                node = sprite
            } else {
                let label = SKLabelNode(text: emoji)
                label.fontSize = 42
                label.verticalAlignmentMode = .center
                node = label
            }
        }
        node.position = CGPoint(x: .random(in: -150...150), y: size.height / 2 + 40)
        node.zPosition = 2
        addChild(node)
        falling.append((node, isStar ? 3 : 1))
        let fall = SKAction.moveTo(y: -size.height / 2 - 60, duration: 3.2 - 1.4 * progress)
        node.run(.group([
            .sequence([fall, .removeFromParent()]),
            .repeatForever(.rotate(byAngle: .random(in: -1...1), duration: 1)),
        ]))
    }

    override func update(_ currentTime: TimeInterval) {
        guard playing else { return }
        // The bunny catches treats that reach its head and paws.
        let mouth = CGRect(x: catcher.position.x - catcher.size.width * 0.4,
                           y: catcher.position.y + catcher.size.height * 0.35,
                           width: catcher.size.width * 0.8,
                           height: catcher.size.height * 0.65)
        falling.removeAll { item in
            if item.node.parent == nil { return true }
            guard mouth.intersects(item.node.calculateAccumulatedFrame()) else { return false }
            caught(item.node, value: item.value)
            return true
        }
    }

    private func caught(_ node: SKNode, value: Int) {
        score += value
        onScoreChange?(score)
        SoundPlayer.shared.play(value > 1 ? .dewdrop : .munch)
        let label = SKLabelNode(fontNamed: AppFont.name)
        label.text = "+\(value)"
        label.fontSize = 28
        label.fontColor = SKColor(red: 0.96, green: 0.52, blue: 0.72, alpha: 1)
        label.position = node.position
        label.zPosition = 5
        addChild(label)
        label.run(.sequence([
            .group([.moveBy(x: 0, y: 50, duration: 0.6), .fadeOut(withDuration: 0.6)]),
            .removeFromParent(),
        ]))
        node.removeAllActions()
        node.run(.sequence([.scale(to: 0, duration: 0.12), .removeFromParent()]))
        catcher.run(.sequence([.scaleY(to: 0.92, duration: 0.06), .scaleY(to: 1, duration: 0.1)]))
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        moveCatcher(touches)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        moveCatcher(touches)
    }

    private func moveCatcher(_ touches: Set<UITouch>) {
        guard let point = touches.first?.location(in: self) else { return }
        let x = min(max(point.x, -165), 165)
        let dx = x - catcher.position.x
        if abs(dx) > 2 {
            // The painted bunny faces right; turn it to face where it's going.
            catcher.xScale = dx > 0 ? abs(catcher.xScale) : -abs(catcher.xScale)
        }
        catcher.position.x = x
    }
}

/// The Carrot Catch screen: the game, the score and clock, and the start and end cards.
struct CarrotCatchView: View {
    let bunnyName: String
    /// Called with the score when a round ends; returns the dewdrops it earned.
    let onRoundEnd: (Int) -> Int
    let onClose: () -> Void

    private enum Phase { case ready, playing, done }

    @State private var scene: CatchGameScene
    @State private var phase = Phase.ready
    @State private var score = 0
    @State private var timeLeft = CatchGameScene.roundLength
    @State private var reward = 0

    init(bunnyImage: String, bunnyName: String, onRoundEnd: @escaping (Int) -> Int, onClose: @escaping () -> Void) {
        self.bunnyName = bunnyName
        self.onRoundEnd = onRoundEnd
        self.onClose = onClose
        _scene = State(initialValue: CatchGameScene(size: CGSize(width: 390, height: 844), bunnyImage: bunnyImage))
    }

    var body: some View {
        ZStack {
            SpriteView(scene: scene)
                .ignoresSafeArea()

            VStack {
                HStack(spacing: 10) {
                    pill("🥕 \(score)")
                    pill("⏱ \(timeLeft)")
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
                .padding(.horizontal, 16)
                .padding(.top, 8)
                Spacer()
            }

            switch phase {
            case .ready:
                card {
                    Text("Carrot Catch")
                        .font(.whimsy(34))
                    Text("Slide \(bunnyName.isEmpty ? "your bunny" : bunnyName) left and right to catch the treats. Stars are worth 3!")
                        .font(.whimsy(18))
                        .multilineTextAlignment(.center)
                    bigButton("Play!") { start() }
                }
            case .playing:
                EmptyView()
            case .done:
                card {
                    Text("You caught \(score)!")
                        .font(.whimsy(34))
                    if reward > 0 {
                        HStack(spacing: 6) {
                            DewdropIcon().frame(width: 30, height: 30)
                            Text("+\(reward) dewdrops")
                                .font(.whimsy(22))
                        }
                    }
                    bigButton("Play again") { start() }
                    Button("Back to the garden", action: onClose)
                        .font(.whimsy(18))
                        .foregroundStyle(Y2K.ink)
                }
            }
        }
        .onAppear {
            scene.onScoreChange = { score = $0 }
            scene.onTimeChange = { timeLeft = $0 }
            scene.onFinish = { finalScore in
                reward = onRoundEnd(finalScore)
                withAnimation(.spring) { phase = .done }
            }
        }
    }

    private func start() {
        SoundPlayer.shared.play(.tap)
        withAnimation { phase = .playing }
        scene.start()
    }

    private func pill(_ text: String) -> some View {
        Text(text)
            .font(.whimsy(22))
            .foregroundStyle(Y2K.ink)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(Capsule().fill(.white.opacity(0.92)))
            .overlay(Capsule().strokeBorder(Y2K.holo, lineWidth: 2))
    }

    private func bigButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.whimsy(24))
                .foregroundStyle(.white)
                .padding(.horizontal, 36)
                .padding(.vertical, 12)
                .background(Capsule().fill(Y2K.bubblegum))
                .overlay(Capsule().strokeBorder(.white, lineWidth: 2))
                .shadow(color: Y2K.bubblegum.opacity(0.4), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }

    private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(spacing: 16, content: content)
            .foregroundStyle(Y2K.ink)
            .padding(24)
            .frame(maxWidth: 330)
            .background(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(LinearGradient(colors: [.white, Y2K.stripeLight], startPoint: .top, endPoint: .bottom))
            )
            .overlay(RoundedRectangle(cornerRadius: 32, style: .continuous).strokeBorder(Y2K.holo, lineWidth: 4))
            .padding(.horizontal, 16)
            .transition(.scale.combined(with: .opacity))
    }
}
