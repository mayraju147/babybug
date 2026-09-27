import SpriteKit

/// The garden: a painted background, the bunny, and a carrot to feed it.
/// Tap the bunny to tickle it; drag the carrot onto it to feed it.
final class GardenScene: SKScene {
    var onFeed: (() -> Void)?
    var onTickle: (() -> Void)?

    private let bunny = SKSpriteNode(imageNamed: "Bunny")
    private let carrot = SKSpriteNode(imageNamed: "Carrot")
    private var carrotHome = CGPoint.zero
    private var draggingCarrot = false

    override init(size: CGSize) {
        super.init(size: size)
        scaleMode = .aspectFill
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not used")
    }

    override func didMove(to view: SKView) {
        guard children.isEmpty else { return }
        addBackground()
        addBunny()
        addCarrot()
    }

    // MARK: - Building the scene

    private func addBackground() {
        let garden = SKSpriteNode(imageNamed: "Garden")
        garden.size = size
        garden.zPosition = -10
        addChild(garden)
    }

    private func addBunny() {
        // Anchor at the feet so breathing stretches upwards from the ground.
        bunny.anchorPoint = CGPoint(x: 0.5, y: 0)
        let height: CGFloat = 230
        bunny.size = CGSize(width: height * bunny.texture!.size().width / bunny.texture!.size().height, height: height)
        bunny.position = CGPoint(x: 0, y: -290)
        bunny.name = "bunny"
        addChild(bunny)

        // Gentle idle breathing.
        let breathe = SKAction.sequence([
            .scaleY(to: 1.02, duration: 1.4),
            .scaleY(to: 1.0, duration: 1.4),
        ])
        breathe.timingMode = .easeInEaseOut
        bunny.run(.repeatForever(breathe))
    }

    private func addCarrot() {
        carrot.size = CGSize(width: 34, height: 64)
        carrot.name = "carrot"
        carrotHome = CGPoint(x: 135, y: -300)
        carrot.position = carrotHome
        carrot.zPosition = 1
        addChild(carrot)
    }

    // MARK: - Touch

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        if carrot.contains(point) {
            draggingCarrot = true
        } else if bunny.frame.contains(point) {
            tickle()
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard draggingCarrot, let point = touches.first?.location(in: self) else { return }
        carrot.position = point
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard draggingCarrot else { return }
        draggingCarrot = false
        if bunny.frame.intersects(carrot.frame) {
            feed()
        }
        carrot.run(.move(to: carrotHome, duration: 0.3))
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }

    // MARK: - Reactions

    private func tickle() {
        onTickle?()
        let wiggle = SKAction.sequence([
            .rotate(toAngle: 0.08, duration: 0.08),
            .rotate(toAngle: -0.08, duration: 0.08),
            .rotate(toAngle: 0, duration: 0.08),
        ])
        bunny.run(.repeat(wiggle, count: 2))
    }

    private func feed() {
        onFeed?()
        let hop = SKAction.sequence([
            .moveBy(x: 0, y: 30, duration: 0.15),
            .moveBy(x: 0, y: -30, duration: 0.15),
        ])
        bunny.run(hop)
    }
}
