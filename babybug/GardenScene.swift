import SpriteKit

/// Placeholder garden: shapes stand in for the painted art until it's ready.
/// Tap the bunny to tickle it; drag the carrot onto it to feed it.
final class GardenScene: SKScene {
    var onFeed: (() -> Void)?
    var onTickle: (() -> Void)?

    private let bunny = SKNode()
    private let carrot = SKShapeNode(ellipseOf: CGSize(width: 22, height: 56))
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
        backgroundColor = SKColor(red: 0.80, green: 0.90, blue: 0.97, alpha: 1)
        addGrass()
        addBunny()
        addCarrot()
    }

    // MARK: - Building the placeholder scene

    private func addGrass() {
        let grass = SKShapeNode(rectOf: CGSize(width: size.width * 2, height: size.height * 0.55))
        grass.fillColor = SKColor(red: 0.66, green: 0.83, blue: 0.55, alpha: 1)
        grass.strokeColor = .clear
        grass.position = CGPoint(x: 0, y: -size.height * 0.25)
        addChild(grass)
    }

    private func addBunny() {
        let fur = SKColor(red: 0.78, green: 0.55, blue: 0.35, alpha: 1)
        let cream = SKColor(red: 0.98, green: 0.93, blue: 0.84, alpha: 1)

        let body = SKShapeNode(ellipseOf: CGSize(width: 120, height: 130))
        body.fillColor = fur
        body.strokeColor = .clear

        let belly = SKShapeNode(ellipseOf: CGSize(width: 64, height: 76))
        belly.fillColor = cream
        belly.strokeColor = .clear
        belly.position = CGPoint(x: 0, y: -18)

        let head = SKShapeNode(circleOfRadius: 46)
        head.fillColor = fur
        head.strokeColor = .clear
        head.position = CGPoint(x: 0, y: 88)

        for side in [-1.0, 1.0] {
            let ear = SKShapeNode(ellipseOf: CGSize(width: 26, height: 80))
            ear.fillColor = fur
            ear.strokeColor = .clear
            ear.position = CGPoint(x: 20 * side, y: 150)
            ear.zRotation = -0.15 * side
            bunny.addChild(ear)

            let eye = SKShapeNode(circleOfRadius: 5)
            eye.fillColor = SKColor(white: 0.2, alpha: 1)
            eye.strokeColor = .clear
            head.addChild(eye)
            eye.position = CGPoint(x: 16 * side, y: 8)
        }

        bunny.addChild(body)
        bunny.addChild(belly)
        bunny.addChild(head)
        bunny.name = "bunny"
        bunny.position = CGPoint(x: 0, y: -60)
        addChild(bunny)

        // Gentle idle breathing.
        let breathe = SKAction.sequence([
            .scaleY(to: 1.03, duration: 1.2),
            .scaleY(to: 1.0, duration: 1.2),
        ])
        bunny.run(.repeatForever(breathe))
    }

    private func addCarrot() {
        carrot.fillColor = SKColor(red: 0.95, green: 0.55, blue: 0.25, alpha: 1)
        carrot.strokeColor = .clear
        carrot.name = "carrot"
        carrotHome = CGPoint(x: 130, y: -300)
        carrot.position = carrotHome

        let leaves = SKShapeNode(ellipseOf: CGSize(width: 18, height: 26))
        leaves.fillColor = SKColor(red: 0.40, green: 0.70, blue: 0.35, alpha: 1)
        leaves.strokeColor = .clear
        leaves.position = CGPoint(x: 0, y: 36)
        carrot.addChild(leaves)
        addChild(carrot)
    }

    // MARK: - Touch

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        if carrot.contains(point) {
            draggingCarrot = true
        } else if bunny.calculateAccumulatedFrame().contains(point) {
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
        if bunny.calculateAccumulatedFrame().intersects(carrot.frame) {
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
