import AVFoundation

/// Music and little sound effects. All sounds are original, made for babybug (source: project files, sound/synth.py).
/// Uses the "ambient" audio session, so the phone's silent switch mutes the game and other audio keeps playing.
/// Used only from the main thread.
final class SoundPlayer {
    static let shared = SoundPlayer()

    enum Effect: String, CaseIterable {
        case tickle, munch, bubble, dewdrop, grow, buy, nope, bedtime, wakeup, tap
    }

    enum Music: String {
        case garden = "garden_music"
        case night = "night_music"
    }

    /// Saved switch for the speaker button, so a grown-up can turn sound off.
    var isOn: Bool {
        get { UserDefaults.standard.object(forKey: "soundOn") as? Bool ?? true }
        set {
            UserDefaults.standard.set(newValue, forKey: "soundOn")
            if newValue {
                if let current { playMusic(current, force: true) }
            } else {
                musicPlayer?.stop()
            }
        }
    }

    private var effects: [Effect: AVAudioPlayer] = [:]
    private var musicPlayer: AVAudioPlayer?
    private var current: Music?

    private init() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    func play(_ effect: Effect) {
        guard isOn else { return }
        if effects[effect] == nil, let url = Bundle.main.url(forResource: effect.rawValue, withExtension: "wav") {
            effects[effect] = try? AVAudioPlayer(contentsOf: url)
            effects[effect]?.prepareToPlay()
        }
        guard let player = effects[effect] else { return }
        player.currentTime = 0
        player.play()
    }

    /// Loops a tune quietly in the background, fading from one tune to the other.
    func playMusic(_ music: Music, force: Bool = false) {
        guard force || music != current else { return }
        current = music
        guard isOn, let url = Bundle.main.url(forResource: music.rawValue, withExtension: "wav"),
              let player = try? AVAudioPlayer(contentsOf: url) else { return }
        musicPlayer?.setVolume(0, fadeDuration: 0.8)
        let old = musicPlayer
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { old?.stop() }
        player.numberOfLoops = -1
        player.volume = 0
        player.play()
        player.setVolume(0.35, fadeDuration: 1.2)
        musicPlayer = player
    }
}
