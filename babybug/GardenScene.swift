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
    private var heroNode: SKSpriteNode?
    private var pendingHero: Hero?
    private var isBuilt = false

    override init(size: CGSize) {
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
        addBunny()
        addCarrot()
        if let pendingHero {
            setHero(pendingHero)
        }
    }

    /// Shows the chosen princess or prince standing beside the bunny, replacing any earlier choice.
    func setHero(_ hero: Hero) {
        guard isBuilt else {
            pendingHero = hero
            return
        }
        heroNode?.removeFromParent()
        let node = SKSpriteNode(imageNamed: hero.imageName)
        node.anchorPoint = CGPoint(x: 0.5, y: 0)
        let height: CGFloat = 300
        let texture = node.texture!.size()
        node.size = CGSize(width: height * texture.width / texture.height, height: height)
        node.position = CGPoint(x: -120, y: -300)
        node.zPosition = -1
        node.name = "hero"
        addChild(node)
        heroNode = node

        // Gentle idle sway.
        let sway = SKAction.sequence([
            .rotate(toAngle: 0.025, duration: 1.8),
            .rotate(toAngle: -0.025, duration: 1.8),
        ])
        sway.timingMode = .easeInEaseOut
        node.run(.repeatForever(sway))
    }

    // MARK: - Building the scene

    private func addBackground() {
        let garden = SKSpriteNode(imageNamed: "Garden")
        // Fill the screen height and keep the painting's proportions; the sides are cropped.
        let texture = garden.texture!.size()
        garden.size = CGSize(width: size.height * texture.width / texture.height, height: size.height)
        garden.zPosition = -10
        addChild(garden)
    }

    private func addBunny() {
        // Anchor at the feet so breathing stretches upwards from the ground.
        bunny.anchorPoint = CGPoint(x: 0.5, y: 0)
        let height: CGFloat = 250
        bunny.size = CGSize(width: height * bunny.texture!.size().width / bunny.texture!.size().height, height: height)
        bunny.position = CGPoint(x: 45, y: -290)
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
        carrot.size = CGSize(width: 40, height: 76)
        carrot.name = "carrot"
        carrotHome = CGPoint(x: 125, y: -345)
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
        } else if let heroNode, heroNode.frame.contains(point) {
            heroNode.run(.sequence([
                .moveBy(x: 0, y: 18, duration: 0.15),
                .moveBy(x: 0, y: -18, duration: 0.15),
            ]))
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
