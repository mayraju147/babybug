import SpriteKit

/// The garden: a painted background, the bunny, a treat to feed it, and any decorations bought in the shop.
/// Tap the bunny to tickle it, rub it for a bubble bath, drag the treat onto it to feed it,
/// and tap the cottage to put it to bed (tap anywhere to wake it up).
final class GardenScene: SKScene {
    var onFeed: (() -> Void)?
    var onTickle: (() -> Void)?
    var onBathe: (() -> Void)?
    /// Called when the child taps the cottage, or taps anywhere while the bunny is asleep.
    var onBedtimeTapped: (() -> Void)?
    /// Called when the child taps the bunny's name tag, to rename it.
    var onNameTapped: (() -> Void)?

    private let bunny = SKSpriteNode(imageNamed: "Bunny")
    private var carrot = SKNode()
    private var treat: ShopItem = .carrot
    private let carrotHome = CGPoint(x: 125, y: -345)
    private var draggingCarrot = false
    private var decorationNodes: [SKNode] = []
    private var decorations: [ShopItem] = []
    private var bunnyName = ""
    private var nameTag: SKNode?
    private var heroNode: SKSpriteNode?
    private var pendingHero: Hero?
    private var isBuilt = false
    private var mood: Mood = .content
    private var thoughtBubble: SKNode?
    private var stage: Stage = .baby
    private var pictureHeightScale = 1.0
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
        showDecorations()
        showNameTag()
        if let pendingHero {
            setHero(pendingHero)
        }
        showMood(mood)
    }

    /// Makes the bunny baby, young or grown. With `celebrate`, it pops up bigger with a shower of sparkles.
    func setStage(_ newStage: Stage, celebrate: Bool = false) {
        guard newStage != stage else { return }
        stage = newStage
        guard isBuilt else { return }
        showMood(mood)
        if celebrate {
            celebrateGrowing()
        }
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
        let picture = pictureName(for: mood)
        bunny.texture = SKTexture(imageNamed: picture)
        if stage != .baby, picture.hasPrefix(stage.imagePrefix),
           let pose = UIImage(named: picture), let main = UIImage(named: stage.imagePrefix) {
            // The older bunny's pictures are all painted at the same scale, so a droopy or curled-up pose
            // is drawn shorter than the upright one by the same amount.
            pictureHeightScale = pose.size.height / main.size.height
        } else {
            // Only a curled-up sleeping picture is drawn lower; an upright stand-in keeps its full height.
            pictureHeightScale = picture.hasSuffix(mood.imageSuffix) ? mood.heightScale : 1
        }
        fitBunnyToTexture()

        thoughtBubble?.removeFromParent()
        thoughtBubble = nil
        guard let thought = mood.thought else { return }

        let bubble = SKNode()
        let cloud = SKShapeNode(circleOfRadius: 26)
        cloud.fillColor = SKColor(white: 1, alpha: 0.92)
        // Bubblegum-pink rim to match the Y2K buttons.
        cloud.strokeColor = SKColor(red: 0.96, green: 0.52, blue: 0.72, alpha: 0.85)
        cloud.lineWidth = 2.5
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

        bubble.position = CGPoint(x: bunny.position.x + 70, y: bunny.position.y + stage.bunnyHeight + 20)
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

    /// The best painted picture we have for this stage and mood. Until the older bunny's pictures are added,
    /// it falls back to that stage's main pose, then to the baby's pose for the mood.
    private func pictureName(for mood: Mood) -> String {
        var candidates = [stage.imagePrefix + mood.imageSuffix]
        if stage != .baby {
            candidates.append(stage.imagePrefix)
        }
        candidates.append("Bunny" + mood.imageSuffix)
        return candidates.first { UIImage(named: $0) != nil } ?? "Bunny"
    }

    private func fitBunnyToTexture() {
        guard let texture = bunny.texture else { return }
        let height = stage.bunnyHeight * pictureHeightScale
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
        carrot.removeFromParent()
        carrot = Self.itemNode(treat, height: 76)
        carrot.name = "carrot"
        carrot.position = carrotHome
        carrot.zPosition = 1
        addChild(carrot)
    }

    /// The painted picture for a shop item, or its emoji until the picture is added.
    private static func itemNode(_ item: ShopItem, height: CGFloat) -> SKNode {
        if let image = UIImage(named: item.imageName) {
            let sprite = SKSpriteNode(texture: SKTexture(image: image))
            sprite.size = CGSize(width: height * image.size.width / image.size.height, height: height)
            return sprite
        }
        let label = SKLabelNode(text: item.emoji)
        label.fontSize = height * 0.75
        label.verticalAlignmentMode = .center
        return label
    }

    // MARK: - Name tag

    /// Shows the bunny's name on a little pill under its feet.
    func setBunnyName(_ name: String) {
        guard name != bunnyName else { return }
        bunnyName = name
        if isBuilt {
            showNameTag()
        }
    }

    private func showNameTag() {
        nameTag?.removeFromParent()
        nameTag = nil
        guard !bunnyName.isEmpty else { return }

        let label = SKLabelNode(fontNamed: AppFont.name)
        label.text = bunnyName
        label.fontSize = 20
        label.fontColor = SKColor(red: 0.19, green: 0.29, blue: 0.29, alpha: 1)
        label.verticalAlignmentMode = .center
        label.zPosition = 1

        let width = label.frame.width + 28
        let pill = SKShapeNode(rectOf: CGSize(width: width, height: 30), cornerRadius: 15)
        pill.fillColor = SKColor(white: 1, alpha: 0.92)
        pill.strokeColor = SKColor(red: 0.96, green: 0.52, blue: 0.72, alpha: 0.9)
        pill.lineWidth = 2
        pill.addChild(label)

        pill.position = CGPoint(x: bunny.position.x, y: bunny.position.y - 14)
        pill.zPosition = 2
        pill.name = "nameTag"
        addChild(pill)
        nameTag = pill
    }

    // MARK: - Shop things

    /// Puts a different treat out in the garden for the child to drag to the bunny.
    func setTreat(_ item: ShopItem) {
        guard item != treat else { return }
        treat = item
        if isBuilt {
            addCarrot()
        }
    }

    /// Shows the bought decorations at their spots in the garden.
    func setDecorations(_ items: [ShopItem]) {
        guard items != decorations else { return }
        let isNew = Set(items).subtracting(decorations)
        decorations = items
        guard isBuilt else { return }
        showDecorations(popping: isNew)
    }

    private func showDecorations(popping new: Set<ShopItem> = []) {
        decorationNodes.forEach { $0.removeFromParent() }
        decorationNodes = decorations.map { item in
            let node = Self.itemNode(item, height: item.gardenHeight)
            node.position = CGPoint(x: item.gardenSpot.x, y: item.gardenSpot.y + item.gardenHeight / 2)
            node.zPosition = 0.5
            addChild(node)
            if new.contains(item) {
                node.setScale(0)
                node.run(.sequence([.scale(to: 1.15, duration: 0.2), .scale(to: 1, duration: 0.1)]))
            }
            return node
        }
    }

    /// A little dewdrop floats up from the bunny when looking after it earns one.
    func showDewdropEarned() {
        let drop: SKNode
        if let image = UIImage(named: "Dewdrop") {
            let sprite = SKSpriteNode(texture: SKTexture(image: image))
            sprite.size = CGSize(width: 30 * image.size.width / image.size.height, height: 30)
            drop = sprite
        } else {
            let label = SKLabelNode(text: "💧")
            label.fontSize = 26
            label.verticalAlignmentMode = .center
            drop = label
        }
        drop.position = CGPoint(x: bunny.position.x - 40, y: bunny.position.y + stage.bunnyHeight * 0.8)
        drop.zPosition = 6
        addChild(drop)
        drop.run(.sequence([
            .group([
                .moveBy(x: 0, y: 70, duration: 1.0),
                .sequence([.wait(forDuration: 0.5), .fadeOut(withDuration: 0.5)]),
            ]),
            .removeFromParent(),
        ]))
    }

    // MARK: - Touch

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        if isSleeping {
            onBedtimeTapped?()
        } else if let nameTag, nameTag.calculateAccumulatedFrame().insetBy(dx: -6, dy: -6).contains(point) {
            onNameTapped?()
        } else if carrot.calculateAccumulatedFrame().insetBy(dx: -12, dy: -12).contains(point) {
            draggingCarrot = true
        } else if bunny.frame.contains(point) {
            // Decide on touch end: a quick tap tickles, rubbing back and forth washes.
            touchingBunny = true
            rubDistance = 0
            lastRubPoint = point
        } else if let heroNode, heroNode.frame.contains(point) {
            SoundPlayer.shared.play(.tap)
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
        if bunny.frame.intersects(carrot.calculateAccumulatedFrame()) {
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

    // MARK: - Growing up

    private func celebrateGrowing() {
        bunny.run(.sequence([
            .scale(to: 1.25, duration: 0.25),
            .scale(to: 0.95, duration: 0.15),
            .scale(to: 1.0, duration: 0.15),
        ]))

        let center = CGPoint(x: bunny.position.x, y: bunny.position.y + stage.bunnyHeight / 2)
        let colors: [SKColor] = [
            SKColor(red: 0.96, green: 0.52, blue: 0.72, alpha: 1),
            SKColor(red: 0.80, green: 0.72, blue: 0.98, alpha: 1),
            SKColor(red: 0.68, green: 0.86, blue: 0.99, alpha: 1),
            SKColor(red: 1.0, green: 0.88, blue: 0.45, alpha: 1),
            .white,
        ]
        for i in 0..<36 {
            let sparkle = SKLabelNode(text: i.isMultiple(of: 3) ? "♥" : "✦")
            sparkle.fontSize = .random(in: 14...28)
            sparkle.fontColor = colors[i % colors.count]
            sparkle.verticalAlignmentMode = .center
            sparkle.position = center
            sparkle.zPosition = 6
            addChild(sparkle)
            let angle = CGFloat.random(in: 0..<(2 * .pi))
            let distance = CGFloat.random(in: 90...190)
            sparkle.run(.sequence([
                .group([
                    .moveBy(x: cos(angle) * distance, y: sin(angle) * distance, duration: 1.1),
                    .rotate(byAngle: .random(in: -2...2), duration: 1.1),
                    .sequence([.wait(forDuration: 0.6), .fadeOut(withDuration: 0.5)]),
                ]),
                .removeFromParent(),
            ]))
        }

        // Words for the grown-up reading along; the sparkles do the job for little ones.
        let banner = SKLabelNode(fontNamed: AppFont.name)
        banner.text = bunnyName.isEmpty ? "Your bunny grew!" : "\(bunnyName) grew!"
        banner.fontSize = 34
        banner.fontColor = SKColor(red: 0.19, green: 0.29, blue: 0.29, alpha: 1)
        banner.position = CGPoint(x: 0, y: size.height * 0.18)
        banner.zPosition = 7
        banner.setScale(0)
        let glow = SKLabelNode(fontNamed: AppFont.name)
        glow.text = banner.text
        glow.fontSize = banner.fontSize
        glow.fontColor = .white
        glow.position = CGPoint(x: 2, y: -2)
        glow.zPosition = -1
        banner.addChild(glow)
        addChild(banner)
        banner.run(.sequence([
            .scale(to: 1.1, duration: 0.25),
            .scale(to: 1.0, duration: 0.1),
            .wait(forDuration: 2.2),
            .fadeOut(withDuration: 0.6),
            .removeFromParent(),
        ]))
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
