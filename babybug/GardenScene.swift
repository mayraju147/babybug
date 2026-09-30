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
    /// Called when the child catches a butterfly.
    var onButterflyCaught: (() -> Void)?
    /// Called when the child finds a present hidden in the grass.
    var onPresentFound: (() -> Void)?
    /// Called when the child splashes in a puddle after the rain.
    var onSplash: (() -> Void)?

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
    private var pendingHero: (hero: Hero, outfit: ShopItem?)?
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
    private var butterfly: SKNode?
    /// Where the bunny was last frame, so its name tag and thought bubble can follow it around.
    private var lastBunnyPosition = CGPoint.zero
    private var present: SKNode?
    private var visitors: [SKNode] = []
    private var puddles: [SKNode] = []
    private var rain: SKNode?
    /// The patch of grass the bunny hops about on, clear of the princess or prince.
    private static let meadow = CGRect(x: -30, y: -335, width: 180, height: 70)

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
            setHero(pendingHero.hero, outfit: pendingHero.outfit)
        }
        showMood(mood)
        startButterflies()
        startLife()
        startSurprises()
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
    /// An outfit shows once its painted picture is in the asset catalog; until then, the everyday clothes.
    func setHero(_ hero: Hero, outfit: ShopItem? = nil) {
        guard isBuilt else {
            pendingHero = (hero, outfit)
            return
        }
        heroNode?.removeFromParent()
        var imageName = hero.imageName
        if let outfit, UIImage(named: outfit.outfitImage(for: hero)) != nil {
            imageName = outfit.outfitImage(for: hero)
        }
        let node = SKSpriteNode(imageNamed: imageName)
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
        } else if let butterfly, butterfly.calculateAccumulatedFrame().insetBy(dx: -22, dy: -22).contains(point) {
            catchButterfly(butterfly)
        } else if let present, present.calculateAccumulatedFrame().insetBy(dx: -18, dy: -18).contains(point) {
            openPresent(present)
        } else if let visitor = visitors.first(where: { $0.calculateAccumulatedFrame().insetBy(dx: -14, dy: -14).contains(point) }) {
            greet(visitor)
        } else if let puddle = puddles.first(where: { $0.calculateAccumulatedFrame().insetBy(dx: -10, dy: -10).contains(point) }) {
            splash(puddle)
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

    // MARK: - Butterflies

    /// Now and then, while the bunny is awake, a butterfly flutters across the garden.
    private func startButterflies() {
        run(.repeatForever(.sequence([
            .wait(forDuration: 14, withRange: 12),
            .run { [weak self] in self?.sendButterfly() },
        ])), withKey: "butterflies")
    }

    private func sendButterfly() {
        guard butterfly == nil, !isSleeping else { return }
        let fromLeft = Bool.random()
        let halfWidth = size.width / 2 + 40
        let start = CGPoint(x: fromLeft ? -halfWidth : halfWidth, y: .random(in: -120...160))
        let end = CGPoint(x: -start.x, y: .random(in: -120...200))

        // A wavy, wandering path across the garden.
        let path = CGMutablePath()
        path.move(to: start)
        var previous = start
        let steps = 4
        for i in 1...steps {
            let t = CGFloat(i) / CGFloat(steps)
            let point = CGPoint(x: start.x + (end.x - start.x) * t, y: start.y + (end.y - start.y) * t)
            let lift: CGFloat = i.isMultiple(of: 2) ? -70 : 70
            let control = CGPoint(x: (previous.x + point.x) / 2, y: (previous.y + point.y) / 2 + lift)
            path.addQuadCurve(to: point, control: control)
            previous = point
        }

        let holder = SKNode()
        holder.position = start
        holder.zPosition = 5
        holder.xScale = fromLeft ? 1 : -1
        let wings = Self.butterflyNode()
        holder.addChild(wings)
        addChild(holder)
        butterfly = holder

        // Wings flap by squashing sideways towards the body.
        wings.run(.repeatForever(.sequence([
            .scaleX(to: 0.35, duration: 0.14),
            .scaleX(to: 1, duration: 0.14),
        ])), withKey: "flap")
        holder.run(.sequence([
            .follow(path, asOffset: false, orientToPath: false, duration: 10),
            .removeFromParent(),
            .run { [weak self, weak holder] in
                if self?.butterfly === holder { self?.butterfly = nil }
            },
        ]), withKey: "fly")
    }

    private static func butterflyNode() -> SKNode {
        if let image = UIImage(named: "Butterfly") {
            let sprite = SKSpriteNode(texture: SKTexture(image: image))
            let height: CGFloat = 46
            sprite.size = CGSize(width: height * image.size.width / image.size.height, height: height)
            return sprite
        }
        let label = SKLabelNode(text: "🦋")
        label.fontSize = 40
        label.verticalAlignmentMode = .center
        return label
    }

    private func catchButterfly(_ holder: SKNode) {
        butterfly = nil
        holder.removeAction(forKey: "fly")
        onButterflyCaught?()
        for _ in 0..<6 {
            let sparkle = SKLabelNode(text: Bool.random() ? "✨" : "💖")
            sparkle.fontSize = 18
            sparkle.position = holder.position
            sparkle.zPosition = 6
            addChild(sparkle)
            sparkle.run(.sequence([
                .group([
                    .moveBy(x: .random(in: -50...50), y: .random(in: 20...70), duration: 0.7),
                    .fadeOut(withDuration: 0.7),
                ]),
                .removeFromParent(),
            ]))
        }
        // A happy little loop, then away it flies.
        holder.run(.sequence([
            .scale(to: 1.4, duration: 0.15),
            .scale(to: 1, duration: 0.15),
            .group([
                .moveBy(x: 0, y: 260, duration: 1.4),
                .sequence([.wait(forDuration: 0.8), .fadeOut(withDuration: 0.6)]),
            ]),
            .removeFromParent(),
        ]))
    }

    // MARK: - Surprises

    /// Now and then something happens in the garden: a present hides in the grass, a visitor wanders by,
    /// or a rain shower leaves puddles to splash in and a rainbow.
    private func startSurprises() {
        run(.sequence([
            .wait(forDuration: 15),
            .repeatForever(.sequence([
                .run { [weak self] in self?.surprise() },
                .wait(forDuration: 40, withRange: 30),
            ])),
        ]), withKey: "surprises")
    }

    private func surprise() {
        guard !isSleeping else { return }
        let roll = Int.random(in: 0..<20)
        if roll < 8 {
            hidePresent()
        } else if roll < 15 {
            if Bool.random() { sendHedgehog() } else { sendBird() }
        } else if rain == nil {
            startRain()
        }
    }

    /// Picture from the asset catalog if it's there, otherwise an emoji stand-in.
    private static func picture(_ name: String, emoji: String, height: CGFloat) -> SKNode {
        if let image = UIImage(named: name) {
            let sprite = SKSpriteNode(texture: SKTexture(image: image))
            sprite.size = CGSize(width: height * image.size.width / image.size.height, height: height)
            return sprite
        }
        let label = SKLabelNode(text: emoji)
        label.fontSize = height * 0.8
        label.verticalAlignmentMode = .center
        return label
    }

    // Presents

    private func hidePresent() {
        guard present == nil else { return }
        let gift = Self.picture("Present", emoji: "🎁", height: 44)
        let spots = [CGPoint(x: -165, y: -330), CGPoint(x: 165, y: -365), CGPoint(x: -40, y: -390),
                     CGPoint(x: 120, y: -250), CGPoint(x: -150, y: -250)]
        gift.position = spots.randomElement() ?? .zero
        gift.zPosition = 1.5
        gift.setScale(0)
        addChild(gift)
        present = gift
        // Peeks out of the grass and wiggles now and then, so sharp eyes can spot it.
        let wiggle = SKAction.sequence([
            .rotate(toAngle: 0.15, duration: 0.08), .rotate(toAngle: -0.15, duration: 0.08),
            .rotate(toAngle: 0.1, duration: 0.08), .rotate(toAngle: 0, duration: 0.08),
            .wait(forDuration: 1.6),
        ])
        gift.run(.sequence([
            .scale(to: 1, duration: 0.3),
            .repeat(wiggle, count: 14),
            .scale(to: 0, duration: 0.3),
            .removeFromParent(),
            .run { [weak self, weak gift] in
                if self?.present === gift { self?.present = nil }
            },
        ]))
    }

    private func openPresent(_ gift: SKNode) {
        present = nil
        gift.removeAllActions()
        onPresentFound?()
        let center = gift.position
        for i in 0..<10 {
            let sparkle = SKLabelNode(text: i.isMultiple(of: 2) ? "✦" : "♥")
            sparkle.fontSize = .random(in: 14...22)
            sparkle.fontColor = i.isMultiple(of: 3) ? SKColor(red: 1, green: 0.85, blue: 0.4, alpha: 1)
                                                     : SKColor(red: 0.96, green: 0.52, blue: 0.72, alpha: 1)
            sparkle.position = center
            sparkle.zPosition = 6
            addChild(sparkle)
            let angle = CGFloat(i) / 10 * 2 * .pi
            sparkle.run(.sequence([
                .group([.moveBy(x: cos(angle) * 60, y: sin(angle) * 60 + 30, duration: 0.7), .fadeOut(withDuration: 0.7)]),
                .removeFromParent(),
            ]))
        }
        gift.run(.sequence([.scale(to: 1.5, duration: 0.15), .group([.scale(to: 0, duration: 0.25), .fadeOut(withDuration: 0.25)]), .removeFromParent()]))
    }

    // Visitors

    /// A little hedgehog wanders across the front of the garden, stops to say hello, and wanders on.
    private func sendHedgehog() {
        let hedgehog = Self.picture("Hedgehog", emoji: "🦔", height: 56)
        let edge = size.width / 2 + 50
        hedgehog.position = CGPoint(x: edge, y: -385)
        hedgehog.zPosition = 1.6
        addChild(hedgehog)
        visitors.append(hedgehog)
        let waddle = SKAction.repeatForever(.sequence([
            .rotate(toAngle: 0.06, duration: 0.2), .rotate(toAngle: -0.06, duration: 0.2),
        ]))
        hedgehog.run(waddle, withKey: "waddle")
        hedgehog.run(.sequence([
            .moveTo(x: 20, duration: 5),
            .run { [weak hedgehog] in hedgehog?.removeAction(forKey: "waddle"); hedgehog?.zRotation = 0 },
            jump(height: 12, duration: 0.3),
            .wait(forDuration: 2.5),
            .run { [weak hedgehog] in hedgehog?.run(waddle, withKey: "waddle") },
            .moveTo(x: -edge, duration: 5),
            .removeFromParent(),
            .run { [weak self, weak hedgehog] in self?.visitors.removeAll { $0 === hedgehog } },
        ]))
    }

    /// A small bird flutters across the sky.
    private func sendBird() {
        let bird = Self.picture("Bird", emoji: "🐦", height: 40)
        let edge = size.width / 2 + 40
        bird.position = CGPoint(x: edge, y: .random(in: 120...280))
        bird.zPosition = 2
        addChild(bird)
        visitors.append(bird)
        bird.run(.repeatForever(.sequence([
            .moveBy(x: 0, y: 14, duration: 0.3), .moveBy(x: 0, y: -14, duration: 0.3),
        ])))
        bird.run(.sequence([
            .moveTo(x: -edge, duration: 9),
            .removeFromParent(),
            .run { [weak self, weak bird] in self?.visitors.removeAll { $0 === bird } },
        ]))
    }

    private func greet(_ visitor: SKNode) {
        SoundPlayer.shared.play(.tap)
        visitor.run(jump(height: 18, duration: 0.3))
        for _ in 0..<4 {
            let heart = SKLabelNode(text: "♥")
            heart.fontSize = .random(in: 14...20)
            heart.fontColor = SKColor(red: 0.96, green: 0.52, blue: 0.72, alpha: 1)
            heart.position = CGPoint(x: visitor.position.x + .random(in: -20...20), y: visitor.position.y + 30)
            heart.zPosition = 6
            addChild(heart)
            heart.run(.sequence([
                .group([.moveBy(x: .random(in: -20...20), y: 50, duration: 0.9), .fadeOut(withDuration: 0.9)]),
                .removeFromParent(),
            ]))
        }
    }

    // Rain

    private func startRain() {
        let shower = SKNode()
        shower.zPosition = 4.5
        let tint = SKSpriteNode(color: SKColor(red: 0.35, green: 0.45, blue: 0.65, alpha: 0.2),
                                size: CGSize(width: size.width * 2, height: size.height))
        shower.addChild(tint)
        shower.alpha = 0
        addChild(shower)
        rain = shower

        let fall = SKAction.run { [weak self, weak shower] in
            guard let self, let shower else { return }
            for _ in 0..<3 {
                let path = CGMutablePath()
                path.move(to: .zero)
                path.addLine(to: CGPoint(x: -3, y: -16))
                let drop = SKShapeNode(path: path)
                drop.strokeColor = SKColor(red: 0.85, green: 0.93, blue: 1, alpha: 0.8)
                drop.lineWidth = 1.6
                drop.position = CGPoint(x: .random(in: -self.size.width / 2...self.size.width / 2 + 60),
                                        y: self.size.height / 2 + 20)
                shower.addChild(drop)
                drop.run(.sequence([
                    .moveBy(x: -40, y: -self.size.height - 40, duration: .random(in: 0.6...0.9)),
                    .removeFromParent(),
                ]))
            }
        }
        shower.run(.sequence([
            .fadeIn(withDuration: 1),
            .group([
                .repeat(.sequence([fall, .wait(forDuration: 0.04)]), count: 400),
                .sequence([.wait(forDuration: 5), .run { [weak self] in self?.makePuddles() }]),
            ]),
            .run { [weak self] in self?.endRain(quickly: false) },
        ]))
    }

    private func makePuddles() {
        guard puddles.isEmpty else { return }
        for spot in [CGPoint(x: -150, y: -395), CGPoint(x: 10, y: -405), CGPoint(x: 160, y: -390)] {
            let puddle = SKShapeNode(ellipseOf: CGSize(width: .random(in: 70...95), height: 20))
            puddle.fillColor = SKColor(red: 0.62, green: 0.78, blue: 0.95, alpha: 0.55)
            puddle.strokeColor = SKColor(red: 0.85, green: 0.93, blue: 1, alpha: 0.9)
            puddle.lineWidth = 1.5
            puddle.position = spot
            puddle.zPosition = 0.8
            puddle.setScale(0)
            addChild(puddle)
            puddle.run(.scale(to: 1, duration: 2))
            puddles.append(puddle)
        }
    }

    private func splash(_ puddle: SKNode) {
        SoundPlayer.shared.play(.bubble)
        onSplash?()
        for _ in 0..<8 {
            let drop = SKShapeNode(circleOfRadius: .random(in: 2.5...5))
            drop.fillColor = SKColor(red: 0.75, green: 0.88, blue: 1, alpha: 0.9)
            drop.strokeColor = .clear
            drop.position = puddle.position
            drop.zPosition = 3
            addChild(drop)
            let up = SKAction.moveBy(x: .random(in: -40...40), y: .random(in: 30...70), duration: 0.25)
            up.timingMode = .easeOut
            let down = SKAction.moveBy(x: .random(in: -10...10), y: -60, duration: 0.3)
            down.timingMode = .easeIn
            drop.run(.sequence([up, .group([down, .fadeOut(withDuration: 0.3)]), .removeFromParent()]))
        }
        puddle.run(.sequence([.scaleX(to: 1.15, duration: 0.1), .scaleX(to: 1, duration: 0.15)]))
    }

    /// Stops the rain. After a proper shower, a rainbow shows and the puddles dry up a little later.
    private func endRain(quickly: Bool) {
        guard let shower = rain else {
            if quickly { dryPuddles() }
            return
        }
        rain = nil
        shower.removeAllActions()
        shower.run(.sequence([.fadeOut(withDuration: quickly ? 0.3 : 1.5), .removeFromParent()]))
        if quickly {
            dryPuddles()
            return
        }
        showRainbow()
        run(.sequence([.wait(forDuration: 25), .run { [weak self] in self?.dryPuddles() }]))
    }

    private func dryPuddles() {
        for puddle in puddles {
            puddle.run(.sequence([.scale(to: 0, duration: 1.5), .removeFromParent()]))
        }
        puddles = []
    }

    private func showRainbow() {
        let rainbow = SKNode()
        rainbow.zPosition = -5
        let colors: [SKColor] = [
            SKColor(red: 1, green: 0.55, blue: 0.6, alpha: 1), SKColor(red: 1, green: 0.75, blue: 0.5, alpha: 1),
            SKColor(red: 1, green: 0.93, blue: 0.55, alpha: 1), SKColor(red: 0.65, green: 0.9, blue: 0.65, alpha: 1),
            SKColor(red: 0.6, green: 0.8, blue: 1, alpha: 1), SKColor(red: 0.78, green: 0.68, blue: 0.98, alpha: 1),
        ]
        for (i, color) in colors.enumerated() {
            let path = CGMutablePath()
            path.addArc(center: .zero, radius: 250 - CGFloat(i) * 10, startAngle: .pi * 0.12, endAngle: .pi * 0.88, clockwise: false)
            let band = SKShapeNode(path: path)
            band.strokeColor = color
            band.lineWidth = 10
            band.lineCap = .round
            rainbow.addChild(band)
        }
        rainbow.position = CGPoint(x: 0, y: -60)
        rainbow.alpha = 0
        addChild(rainbow)
        rainbow.run(.sequence([
            .fadeAlpha(to: 0.5, duration: 1.5),
            .wait(forDuration: 7),
            .fadeOut(withDuration: 2),
            .removeFromParent(),
        ]))
    }

    // MARK: - Bedtime

    /// Dims the garden to a starry night while the bunny sleeps, and brings the day back when it wakes.
    func setSleeping(_ sleeping: Bool) {
        guard sleeping != isSleeping else { return }
        isSleeping = sleeping
        if sleeping {
            endRain(quickly: true)
            if let butterfly {
                self.butterfly = nil
                butterfly.run(.sequence([.fadeOut(withDuration: 0.5), .removeFromParent()]))
            }
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
        // A giggly wiggle and a happy little jump, with hearts.
        let wiggle = SKAction.sequence([
            .rotate(toAngle: 0.08, duration: 0.08),
            .rotate(toAngle: -0.08, duration: 0.08),
            .rotate(toAngle: 0, duration: 0.08),
        ])
        bunny.run(.repeat(wiggle, count: 2))
        bunny.run(jump(height: 34, duration: 0.36))
        puff(["♥", "♥", "✦"], count: 5)
    }

    // MARK: - Life

    /// Every few seconds the awake bunny does something: hops about, sniffs the flowers, chases a butterfly,
    /// wiggles its nose, or does a happy jump. What it does depends on how it feels.
    private func startLife() {
        lastBunnyPosition = bunny.position
        run(.repeatForever(.sequence([
            .wait(forDuration: 5, withRange: 4),
            .run { [weak self] in self?.doSomething() },
        ])), withKey: "life")
    }

    override func update(_ currentTime: TimeInterval) {
        let dx = bunny.position.x - lastBunnyPosition.x
        let dy = bunny.position.y - lastBunnyPosition.y
        if dx != 0 || dy != 0 {
            for node in [nameTag, thoughtBubble].compactMap({ $0 }) {
                node.position = CGPoint(x: node.position.x + dx, y: node.position.y + dy)
            }
            lastBunnyPosition = bunny.position
        }
    }

    private var isBusy: Bool {
        isSleeping || touchingBunny || draggingCarrot || bunny.action(forKey: "hop") != nil
    }

    private func doSomething() {
        guard !isBusy else { return }
        switch mood {
        case .sleepy, .lonely:
            // Too tired or too sad to play: just a little nose wiggle.
            if Bool.random() { wiggleNose() }
        case .hungry:
            // Off to look for the treat.
            hop(to: CGPoint(x: carrotHome.x - 55, y: carrotHome.y + 20))
        default:
            let roll = Int.random(in: 0..<10)
            if roll < 4 {
                hop(to: CGPoint(x: .random(in: Self.meadow.minX...Self.meadow.maxX),
                                y: .random(in: Self.meadow.minY...Self.meadow.maxY)))
            } else if roll < 6 {
                sniff()
            } else if roll < 8, let butterfly {
                hop(to: CGPoint(x: butterfly.position.x, y: bunny.position.y))
            } else if mood == .happy {
                binky()
            } else {
                wiggleNose()
            }
        }
    }

    /// Hops to a spot on the meadow, a few bunny hops at a time, turning to face the way it goes.
    private func hop(to target: CGPoint, then finish: SKAction? = nil) {
        let meadow = Self.meadow
        let goal = CGPoint(x: min(max(target.x, meadow.minX), meadow.maxX),
                           y: min(max(target.y, meadow.minY), meadow.maxY))
        let dx = goal.x - bunny.position.x
        let dy = goal.y - bunny.position.y
        let distance = hypot(dx, dy)
        var steps: [SKAction] = []
        if distance > 8 {
            face(dx)
            let count = max(1, Int((distance / 50).rounded(.up)))
            for _ in 0..<count {
                steps.append(.group([
                    .moveBy(x: dx / CGFloat(count), y: dy / CGFloat(count), duration: 0.3),
                    jump(height: 20, duration: 0.3),
                ]))
                steps.append(.wait(forDuration: 0.1))
            }
        }
        if let finish { steps.append(finish) }
        guard !steps.isEmpty else { return }
        bunny.run(.sequence(steps), withKey: "hop")
    }

    /// Up and back down to where it started, springy at the top.
    private func jump(height: CGFloat, duration: TimeInterval) -> SKAction {
        let up = SKAction.moveBy(x: 0, y: height, duration: duration / 2)
        up.timingMode = .easeOut
        let down = SKAction.moveBy(x: 0, y: -height, duration: duration / 2)
        down.timingMode = .easeIn
        return .sequence([up, down])
    }

    /// The painted bunny faces right; flip it to face left when it hops that way.
    private func face(_ dx: CGFloat) {
        guard abs(dx) > 4 else { return }
        bunny.xScale = dx > 0 ? abs(bunny.xScale) : -abs(bunny.xScale)
    }

    private func wiggleNose() {
        let twitch = SKAction.sequence([
            .rotate(toAngle: 0.03, duration: 0.06),
            .rotate(toAngle: -0.03, duration: 0.06),
        ])
        bunny.run(.sequence([.repeat(twitch, count: 3), .rotate(toAngle: 0, duration: 0.06)]))
    }

    /// Hops over to a flower (or a decoration) and has a good sniff.
    private func sniff() {
        let spots = decorations.map(\.gardenSpot) + [CGPoint(x: -20, y: -330), CGPoint(x: 150, y: -300)]
        guard let spot = spots.randomElement() else { return }
        let side: CGFloat = spot.x > bunny.position.x ? -45 : 45
        let lean = SKAction.run { [weak self] in
            guard let self else { return }
            let down: CGFloat = self.bunny.xScale > 0 ? -0.12 : 0.12
            self.bunny.run(.sequence([
                .rotate(toAngle: down, duration: 0.2),
                .repeat(.sequence([.rotate(byAngle: 0.04, duration: 0.1), .rotate(byAngle: -0.04, duration: 0.1)]), count: 3),
                .rotate(toAngle: 0, duration: 0.2),
            ]))
            self.puff(["✿", "❀"], count: 3)
        }
        hop(to: CGPoint(x: spot.x + side, y: bunny.position.y), then: .sequence([.run { [weak self] in
            // Turn towards the flower before sniffing.
            guard let self else { return }
            self.face(spot.x - self.bunny.position.x)
        }, lean, .wait(forDuration: 1.2)]))
    }

    /// A happy bunny jump with a twist in the air.
    private func binky() {
        bunny.run(.group([
            jump(height: 60, duration: 0.5),
            .sequence([.rotate(toAngle: 0.35, duration: 0.2), .rotate(toAngle: 0, duration: 0.3)]),
        ]), withKey: "hop")
        puff(["♥", "✦"], count: 4)
    }

    /// A few little shapes that float up from the bunny's head and fade.
    private func puff(_ symbols: [String], count: Int) {
        let colors: [SKColor] = [
            SKColor(red: 0.96, green: 0.52, blue: 0.72, alpha: 1),
            SKColor(red: 0.80, green: 0.72, blue: 0.98, alpha: 1),
            SKColor(red: 1.0, green: 0.88, blue: 0.45, alpha: 1),
        ]
        for i in 0..<count {
            let label = SKLabelNode(text: symbols[i % symbols.count])
            label.fontSize = .random(in: 16...24)
            label.fontColor = colors[i % colors.count]
            label.verticalAlignmentMode = .center
            label.position = CGPoint(x: bunny.position.x + .random(in: -30...30),
                                     y: bunny.position.y + stage.bunnyHeight * 0.8)
            label.zPosition = 6
            addChild(label)
            label.run(.sequence([
                .group([
                    .moveBy(x: .random(in: -25...25), y: .random(in: 40...80), duration: 1.0),
                    .sequence([.wait(forDuration: 0.5), .fadeOut(withDuration: 0.5)]),
                ]),
                .removeFromParent(),
            ]))
        }
    }

    // MARK: - Growing up

    private func celebrateGrowing() {
        // Relative scaling, so a bunny facing left stays facing left.
        bunny.run(.sequence([
            .scale(by: 1.25, duration: 0.25),
            .scale(by: 0.76, duration: 0.15),
            .scale(by: 1 / (1.25 * 0.76), duration: 0.15),
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
