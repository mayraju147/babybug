import SpriteKit

/// The garden: a painted background, the bunny, and a carrot to feed it.
/// Tap the bunny to tickle it, rub it for a bubble bath, drag the carrot onto it to feed it,
/// and tap the cottage to put it to bed (tap anywhere to wake it up).
final class GardenScene: SKScene {
    var onFeed: (() -> Void)?
    var onTickle: (() -> Void)?
    var onBathe: (() -> Void)?
    /// Called when the child taps the cottage, or taps anywhere while the bunny is asleep.
    var onBedtimeTapped: (() -> Void)?

    private let bunny = SKSpriteNode(imageNamed: "Bunny")
    private let carrot = SKSpriteNode(imageNamed: "Carrot")
    private var carrotHome = CGPoint.zero
    private var draggingCarrot = false
    private var heroNode: SKSpriteNode?
    private var pendingHero: Hero?
    private var isBuilt = false
    private var mood: Mood = .content
    private var thoughtBubble: SKNode?
    private static let bunnyHeight: CGFloat = 200
    /// Where the bellflower cottage's door sits in the garden painting, in scene points.
    private static let cottageDoor = CGPoint(x: 88, y: 40)
    /// How far a finger has to rub back and forth on the bunny to count as one wash.
    private static let rubPerWash: CGFloat = 260

    private var touchingBunny = false
    private var rubDistance: CGFloat = 0
    private var lastRubPoint = CGPoint.zero
    private var isSleeping = false
    private var night: SKNode?

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
        showMood(mood)
    }

    /// Changes the bunny's picture and thought bubble to match how it feels.
    func setMood(_ newMood: Mood) {
        guard newMood != mood else { return }
        mood = newMood
        if isBuilt {
            showMood(newMood)
        }
    }

    private func showMood(_ mood: Mood) {
        // Use the painted pose for this mood if it's in the asset catalog, otherwise the default bunny.
        let name = UIImage(named: mood.imageName) != nil ? mood.imageName : "Bunny"
        bunny.texture = SKTexture(imageNamed: name)
        fitBunnyToTexture()

        thoughtBubble?.removeFromParent()
        thoughtBubble = nil
        guard let thought = mood.thought else { return }

        let bubble = SKNode()
        let cloud = SKShapeNode(circleOfRadius: 26)
        cloud.fillColor = SKColor(white: 1, alpha: 0.92)
        cloud.strokeColor = SKColor(red: 0.55, green: 0.42, blue: 0.35, alpha: 0.5)
        cloud.lineWidth = 1.2
        bubble.addChild(cloud)
        for (offset, radius) in [(CGPoint(x: -24, y: -26), 7.0), (CGPoint(x: -34, y: -38), 4.0)] {
            let dot = SKShapeNode(circleOfRadius: radius)
            dot.fillColor = cloud.fillColor
            dot.strokeColor = cloud.strokeColor
            dot.lineWidth = 1
            dot.position = offset
            bubble.addChild(dot)
        }
        let label = SKLabelNode(text: thought)
        label.fontSize = 26
        label.verticalAlignmentMode = .center
        bubble.addChild(label)

        bubble.position = CGPoint(x: bunny.position.x + 70, y: bunny.position.y + Self.bunnyHeight + 20)
        bubble.zPosition = 5
        bubble.setScale(0)
        addChild(bubble)
        bubble.run(.sequence([
            .scale(to: 1, duration: 0.25),
            .repeatForever(.sequence([
                .moveBy(x: 0, y: 6, duration: 1.2),
                .moveBy(x: 0, y: -6, duration: 1.2),
            ])),
        ]))
        thoughtBubble = bubble
    }

    private func fitBunnyToTexture() {
        guard let texture = bunny.texture else { return }
        let height = Self.bunnyHeight * mood.heightScale
        bunny.size = CGSize(width: height * texture.size().width / texture.size().height, height: height)
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
        fitBunnyToTexture()
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
        if isSleeping {
            onBedtimeTapped?()
        } else if carrot.contains(point) {
            draggingCarrot = true
        } else if bunny.frame.contains(point) {
            // Decide on touch end: a quick tap tickles, rubbing back and forth washes.
            touchingBunny = true
            rubDistance = 0
            lastRubPoint = point
        } else if let heroNode, heroNode.frame.contains(point) {
            heroNode.run(.sequence([
                .moveBy(x: 0, y: 18, duration: 0.15),
                .moveBy(x: 0, y: -18, duration: 0.15),
            ]))
        } else if hypot(point.x - Self.cottageDoor.x, point.y - Self.cottageDoor.y) < 55 {
            onBedtimeTapped?()
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        if draggingCarrot {
            carrot.position = point
        } else if touchingBunny {
            let step = hypot(point.x - lastRubPoint.x, point.y - lastRubPoint.y)
            lastRubPoint = point
            rubDistance += step
            if step > 4 {
                spawnBubble(at: point)
            }
            if rubDistance >= Self.rubPerWash {
                rubDistance = 0
                wash()
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touchingBunny {
            touchingBunny = false
            // Barely moved: treat it as a tap.
            if rubDistance < 20 {
                tickle()
            }
            return
        }
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

    // MARK: - Bedtime

    /// Dims the garden to a starry night while the bunny sleeps, and brings the day back when it wakes.
    func setSleeping(_ sleeping: Bool) {
        guard sleeping != isSleeping else { return }
        isSleeping = sleeping
        if sleeping {
            let overlay = makeNight()
            overlay.alpha = 0
            addChild(overlay)
            overlay.run(.fadeIn(withDuration: 1.2))
            night = overlay
        } else if let night {
            night.run(.sequence([.fadeOut(withDuration: 1.0), .removeFromParent()]))
            self.night = nil
        }
    }

    private func makeNight() -> SKNode {
        let overlay = SKNode()
        overlay.zPosition = 4

        let shade = SKSpriteNode(color: SKColor(red: 0.10, green: 0.12, blue: 0.30, alpha: 0.55), size: CGSize(width: size.width * 2, height: size.height))
        overlay.addChild(shade)

        // Twinkling stars in the sky.
        for _ in 0..<28 {
            let star = SKShapeNode(circleOfRadius: CGFloat.random(in: 1...2.4))
            star.fillColor = SKColor(red: 1, green: 0.97, blue: 0.8, alpha: 1)
            star.strokeColor = .clear
            star.position = CGPoint(x: .random(in: -size.width / 2...size.width / 2), y: .random(in: 60...size.height / 2))
            let twinkle = SKAction.sequence([
                .fadeAlpha(to: 0.3, duration: .random(in: 0.6...1.4)),
                .fadeAlpha(to: 1, duration: .random(in: 0.6...1.4)),
            ])
            star.run(.repeatForever(twinkle))
            overlay.addChild(star)
        }

        // A warm glow in the cottage window.
        let glow = SKShapeNode(circleOfRadius: 26)
        glow.fillColor = SKColor(red: 1, green: 0.85, blue: 0.5, alpha: 0.45)
        glow.strokeColor = .clear
        glow.glowWidth = 14
        glow.position = Self.cottageDoor
        glow.blendMode = .add
        overlay.addChild(glow)
        return overlay
    }

    // MARK: - Bath

    private func spawnBubble(at point: CGPoint) {
        let bubble = SKShapeNode(circleOfRadius: .random(in: 5...12))
        bubble.fillColor = SKColor(red: 0.85, green: 0.95, blue: 1, alpha: 0.35)
        bubble.strokeColor = SKColor(red: 0.7, green: 0.85, blue: 1, alpha: 0.9)
        bubble.lineWidth = 1.2
        bubble.position = CGPoint(x: point.x + .random(in: -14...14), y: point.y + .random(in: -14...14))
        bubble.zPosition = 3
        addChild(bubble)
        bubble.run(.sequence([
            .group([
                .moveBy(x: .random(in: -20...20), y: .random(in: 50...110), duration: 1.4),
                .fadeOut(withDuration: 1.4),
                .scale(to: 1.4, duration: 1.4),
            ]),
            .removeFromParent(),
        ]))
    }

    private func wash() {
        onBathe?()
        // A little shimmy, like shaking off water.
        let shake = SKAction.sequence([
            .moveBy(x: 6, y: 0, duration: 0.05),
            .moveBy(x: -12, y: 0, duration: 0.1),
            .moveBy(x: 6, y: 0, duration: 0.05),
        ])
        bunny.run(.repeat(shake, count: 2))
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
