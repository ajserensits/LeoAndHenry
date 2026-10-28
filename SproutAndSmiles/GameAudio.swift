import AVFoundation

/// Everything the game plays: a looping theme per chapter (plus one for the yard) and
/// short sound effects. All audio is synthesized in code, so there are no audio files.
/// Work happens on a private queue so building a loop never stalls the UI.
/// The ambient audio session respects the silent switch and mixes with the player's own music.
final class GameAudio {
    static let shared = GameAudio()

    enum Effect: Hashable {
        case select
        case nope
        case pop(combo: Int)
        case powerUpMade
        case rocket
        case gardenBomb
        case rainbowPaw
        case water
        case shuffle
        case win
        case thunder
        case knock
        case party
        case yardBuild
        case yardStyle
        case extraMoves
        case blockerHit
        case gooClean
        case outOfMoves
    }

    /// The yard's music, after the ten chapter themes.
    static let yardTheme = MusicTheme.all.count - 1

    private let queue = DispatchQueue(label: "GameAudio")
    private let engine = AVAudioEngine()
    private let music = AVAudioPlayerNode()
    private let effectNodes = (0..<4).map { _ in AVAudioPlayerNode() }
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
    private let musicVolume: Float = 0.22
    private var configured = false
    private var musicWanted = false
    private var currentTheme = 0
    private var playingTheme: Int?
    private var loops: [Int: AVAudioPCMBuffer] = [:]
    private var effects: [Effect: AVAudioPCMBuffer] = [:]
    private var nextEffectNode = 0
    private var fadeToken = 0

    // MARK: Public API (safe to call from the main thread)

    /// Starts or stops the background music. Effects are gated by the caller's sound setting.
    func setMusicPlaying(_ shouldPlay: Bool) {
        queue.async { [self] in
            musicWanted = shouldPlay
            shouldPlay ? startMusic() : stopMusic()
        }
    }

    /// Picks the theme for a chapter (0...9) or `GameAudio.yardTheme`, crossfading if music is on.
    func setTheme(_ index: Int) {
        queue.async { [self] in
            let theme = min(max(0, index), MusicTheme.all.count - 1)
            guard theme != currentTheme else { return }
            currentTheme = theme
            guard musicWanted, playingTheme != nil else { return }
            crossfade(to: theme)
        }
    }

    func play(_ effect: Effect) {
        queue.async { [self] in
            guard ensureEngine() else { return }
            let buffer = effects[effect] ?? {
                let made = SoundEffects.render(effect, format: format)
                effects[effect] = made
                return made
            }()
            let node = effectNodes[nextEffectNode]
            nextEffectNode = (nextEffectNode + 1) % effectNodes.count
            node.stop()
            node.scheduleBuffer(buffer, at: nil)
            node.volume = 0.75
            node.play()
        }
    }

    // MARK: Engine

    @discardableResult
    private func ensureEngine() -> Bool {
        do {
            if !configured {
#if os(iOS)
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
#endif
                engine.attach(music)
                engine.connect(music, to: engine.mainMixerNode, format: format)
                for node in effectNodes {
                    engine.attach(node)
                    engine.connect(node, to: engine.mainMixerNode, format: format)
                }
                configured = true
            }
            if !engine.isRunning {
#if os(iOS)
                try AVAudioSession.sharedInstance().setActive(true)
#endif
                engine.prepare()
                try engine.start()
            }
            return true
        } catch {
            // Audio is decorative; gameplay must remain available if it fails.
            return false
        }
    }

    private func loop(for theme: Int) -> AVAudioPCMBuffer {
        if let cached = loops[theme] { return cached }
        let made = MusicTheme.all[theme].render(format: format)
        loops[theme] = made
        return made
    }

    private func startMusic() {
        guard playingTheme == nil || !music.isPlaying, ensureEngine() else { return }
        let theme = currentTheme
        music.stop()
        music.scheduleBuffer(loop(for: theme), at: nil, options: .loops)
        music.volume = musicVolume
        music.play()
        playingTheme = theme
    }

    private func stopMusic() {
        fadeToken += 1
        music.stop()
        playingTheme = nil
        if engine.isRunning { engine.pause() }
    }

    /// Fades the current loop out, swaps in the new one, and fades it back in.
    private func crossfade(to theme: Int) {
        fadeToken += 1
        let token = fadeToken
        let next = loop(for: theme)
        let steps = 8
        for step in 1...steps {
            queue.asyncAfter(deadline: .now() + 0.035 * Double(step)) { [self] in
                guard token == fadeToken else { return }
                music.volume = musicVolume * Float(steps - step) / Float(steps)
                guard step == steps else { return }
                music.stop()
                music.scheduleBuffer(next, at: nil, options: .loops)
                music.play()
                playingTheme = theme
                for upStep in 1...steps {
                    queue.asyncAfter(deadline: .now() + 0.04 * Double(upStep)) { [self] in
                        guard token == fadeToken else { return }
                        music.volume = musicVolume * Float(upStep) / Float(steps)
                    }
                }
            }
        }
    }
}

// MARK: - Music

/// One looping chapter theme. Melody steps are MIDI notes; `rest` is silence and `hold`
/// extends the previous note. `chords` lists one chord root per four melody steps.
struct MusicTheme {
    enum Voice { case pluck, musicBox, flute, marimba, steel, pizzicato, bell }
    enum Quality { case power, major, minor }

    static let rest = -1
    static let hold = -2

    let name: String
    let step: Double
    let voice: Voice
    let melody: [Int]
    let chords: [(root: Int, quality: Quality)]
    var arpeggio = 0.09
    var bass = 0.0
    var pad = 0.0
    /// Evens out loudness between themes (the garden loop is the reference at 1).
    var gain = 1.0

    private static func notes(_ text: String) -> [Int] {
        let names = ["C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11]
        return text.split(separator: " ").map { token in
            if token == "." { return rest }
            if token == "-" { return hold }
            var chars = Array(token)
            var pitch = names[String(chars.removeFirst())]!
            if chars.first == "#" { pitch += 1; chars.removeFirst() }
            if chars.first == "b" { pitch -= 1; chars.removeFirst() }
            return pitch + (Int(String(chars))! + 1) * 12
        }
    }

    /// Chord roots as MIDI numbers; a trailing "m" means minor and "p" means a bare fifth.
    private static func chords(_ text: String) -> [(root: Int, quality: Quality)] {
        text.split(separator: " ").map { token in
            switch token.last {
            case "m": (Int(token.dropLast())!, .minor)
            case "p": (Int(token.dropLast())!, .power)
            default: (Int(token)!, .major)
            }
        }
    }

    static let all: [MusicTheme] = [
        // 1. The Bug in the Beans: the original bright garden loop.
        MusicTheme(name: "Garden Trail", step: 0.30, voice: .pluck,
                   melody: [72, 76, 79, 76, 74, 77, 81, 77, 76, 79, 83, 79, 74, 77, 81, 79,
                            72, 76, 79, 84, 83, 79, 76, 74, 77, 81, 79, 76, 74, 71, 72, -1],
                   chords: chords("48p 48p 53p 53p 55p 55p 48p 48p")),
        // 2. The Vacuum Awakens: a busy cleaning-day scurry.
        MusicTheme(name: "Cleaning Day Scurry", step: 0.20, voice: .marimba,
                   melody: notes("F5 A5 C6 A5 G5 Bb5 G5 E5 F5 A5 C6 F6 E6 C6 A5 . D6 C6 Bb5 A5 G5 A5 Bb5 G5 A5 C6 F5 A5 G5 E5 F5 ."),
                   chords: chords("53 48 53 53 46 48 53 53"), arpeggio: 0.07, bass: 0.10, gain: 0.75),
        // 3. Under the Bed: a music box in a quiet room.
        MusicTheme(name: "Under-the-Bed Music Box", step: 0.36, voice: .musicBox,
                   melody: notes("A5 C6 E6 - D6 C6 B5 - C6 B5 A5 E5 A5 - - . F5 A5 C6 - B5 A5 G5 - E5 G5 B5 C6 A5 - - ."),
                   chords: chords("45m 43 45m 45m 41 43 48 45m"), arpeggio: 0.06, pad: 0.03, gain: 0.8),
        // 4. Thunder over the Tomatoes: a gentle music-box tune under a shared blanket.
        MusicTheme(name: "Blanket-Fort Music Box", step: 0.32, voice: .musicBox,
                   melody: notes("A5 C6 F6 - E6 D6 C6 - Bb5 D6 G6 - F6 E6 C6 . A5 C6 F6 A6 G6 F6 E6 C6 D6 Bb5 C6 A5 F5 - - ."),
                   chords: chords("53 48 55m 53 46 48 53 53"), arpeggio: 0.045, pad: 0.018, gain: 0.72),
        // 5. The Lawnmower Loop: a jaunty little march.
        MusicTheme(name: "Lawn March", step: 0.24, voice: .pluck,
                   melody: notes("G4 B4 D5 B4 G4 B4 D5 . C5 E5 G5 E5 D5 - . . B4 D5 G5 D5 C5 A4 F#4 A4 G4 B4 D5 F#5 G5 - . ."),
                   chords: chords("43 43 48 50 43 50 43 43"), arpeggio: 0.07, bass: 0.12),
        // 6. Bags, Cans, and Courage: brave and breezy.
        MusicTheme(name: "Brave Breeze", step: 0.26, voice: .steel,
                   melody: notes("D5 - F#5 A5 B5 A5 F#5 - G5 - E5 G5 A5 - . . B5 A5 G5 F#5 E5 F#5 G5 E5 F#5 - E5 C#5 D5 - . ."),
                   chords: chords("50 47m 43 45 43 45 45 50"), arpeggio: 0.07, bass: 0.10, gain: 0.85),
        // 7. Where Is Mom?: warm pawprints that begin gently and arrive somewhere hopeful.
        MusicTheme(name: "Homeward Pawprints", step: 0.30, voice: .pluck,
                   melody: notes("E5 G5 C6 - B5 G5 E5 - F5 A5 C6 A5 G5 - E5 . D5 F5 A5 - G5 E5 D5 - E5 G5 C6 E6 D6 B5 C6 ."),
                   chords: chords("48 43 41 48 50m 43 48 48"), arpeggio: 0.055, pad: 0.012, gain: 0.78),
        // 8. Pool Day: bouncy and summery.
        MusicTheme(name: "Pool Day Bounce", step: 0.20, voice: .steel,
                   melody: notes("C6 . G5 C6 . E6 D6 C6 A5 . C6 . G5 - . . F5 A5 C6 . D6 . C6 A5 G5 . E5 G5 C6 - . ."),
                   chords: chords("48 48 41 43 41 50m 48 48"), arpeggio: 0.06, bass: 0.12, gain: 0.85),
        // 9. Special Delivery: tiptoeing past the front door.
        MusicTheme(name: "Tiptoe Delivery", step: 0.25, voice: .pizzicato,
                   melody: notes("Bb4 . D5 . F5 . D5 . Eb5 . C5 . F4 . . . G4 . Bb4 . D5 C5 Bb4 A4 Bb4 . F4 . Bb4 - . ."),
                   chords: chords("46 46 48m 41 43m 41 46 46"), arpeggio: 0.06, bass: 0.10),
        // 10. The Birthday Peanut-Butter Pad: a party tune.
        MusicTheme(name: "Birthday Party", step: 0.22, voice: .bell,
                   melody: notes("G5 B5 D6 B5 C6 E6 - C6 B5 D6 G5 B5 A5 - . . G5 B5 D6 G6 F#6 E6 D6 C6 B5 A5 G5 F#5 G5 - . ."),
                   chords: chords("43 48 43 50 43 50 50 43"), arpeggio: 0.07, bass: 0.11, gain: 0.8),
        // Leo & Henry's Yard: cozy and homey.
        MusicTheme(name: "Our Yard", step: 0.32, voice: .flute,
                   melody: notes("E5 G5 C6 - B5 A5 G5 - A5 F5 A5 C6 G5 - . . E5 G5 C6 E6 D6 C6 B5 A5 G5 E5 F5 D5 C5 - . ."),
                   chords: chords("48 43 41 43 48 43 43 48"), arpeggio: 0.07, pad: 0.03, gain: 0.58)
    ]

    func render(format: AVAudioFormat) -> AVAudioPCMBuffer {
        let sampleRate = format.sampleRate
        let frameCount = AVAudioFrameCount(Double(melody.count) * step * sampleRate)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        let samples = buffer.floatChannelData![0]

        // Where each step's sounding note began and how long it lasts (holds extend it).
        var starts = [Int](repeating: -1, count: melody.count)
        var lengths = [Int](repeating: 0, count: melody.count)
        var current = -1
        for index in melody.indices {
            if melody[index] >= 0 { current = index } else if melody[index] == Self.rest { current = -1 }
            starts[index] = current
        }
        for index in melody.indices where starts[index] >= 0 { lengths[starts[index]] += 1 }

        for frame in 0..<Int(frameCount) {
            let time = Double(frame) / sampleRate
            let index = min(melody.count - 1, Int(time / step))
            let withinStep = time - Double(index) * step
            var value = 0.0

            let start = starts[index]
            if start >= 0 {
                let frequency = Self.frequency(melody[start])
                let within = time - Double(start) * step
                let length = Double(lengths[start]) * step
                value += lead(frequency, time: time, within: within, length: length)
            }

            let chord = chords[min(chords.count - 1, index / 4)]
            let pattern: [Int] = switch chord.quality {
            case .power: [0, 7, 12, 7]
            case .major: [0, 4, 7, 12]
            case .minor: [0, 3, 7, 12]
            }
            let arpeggioFrequency = Self.frequency(chord.root + pattern[index % 4])
            let softPulse = 0.55 + 0.45 * cos(2 * .pi * withinStep / step)
            value += sin(2 * .pi * arpeggioFrequency * time) * softPulse * arpeggio

            let withinChord = time - Double(index / 4 * 4) * step
            let chordLength = 4 * step
            let chordEdge = min(1, withinChord / 0.04, (chordLength - withinChord) / 0.04)
            if bass > 0 {
                let bassFrequency = Self.frequency(chord.root - 12)
                let bassHit = index % 2 == 0 ? exp(-3.5 * withinStep) : 0.35 * exp(-3.5 * withinStep)
                value += sin(2 * .pi * bassFrequency * time) * bassHit * bass * min(1, withinStep / 0.01)
            }
            if pad > 0 {
                let third = chord.quality == .minor ? 3 : chord.quality == .major ? 4 : 7
                for interval in [12, 12 + third, 19] {
                    value += sin(2 * .pi * Self.frequency(chord.root + interval) * time) * pad * chordEdge
                }
            }

            samples[frame] = Float(max(-0.72, min(0.72, value * gain)))
        }
        return buffer
    }

    private func lead(_ frequency: Double, time: Double, within: Double, length: Double) -> Double {
        let attack = min(1, within / 0.018)
        let release = min(1, max(0, length - within) / 0.015)
        let shape = attack * release
        switch voice {
        case .pluck:
            let decay = exp(-4.2 * within / step)
            return (sin(2 * .pi * frequency * time) * 0.30 + sin(4 * .pi * frequency * time) * 0.07) * decay * shape
        case .musicBox:
            let decay = exp(-3.0 * within)
            return (sin(2 * .pi * frequency * time) * 0.24 + sin(8 * .pi * frequency * time) * 0.05 * exp(-12 * within)) * decay * shape
        case .flute:
            let breath = min(1, within / 0.07) * release
            let vibrato = within > 0.15 ? 0.004 * sin(2 * .pi * 5 * time) : 0
            let phase = 2 * .pi * frequency * (1 + vibrato) * time
            return (sin(phase) * 0.22 + sin(2 * phase) * 0.03) * breath * (0.85 + 0.15 * exp(-3 * within))
        case .marimba:
            let decay = exp(-9 * within)
            return (sin(2 * .pi * frequency * time) * 0.32 + sin(8 * .pi * frequency * time) * 0.06 * exp(-30 * within)) * decay * shape
        case .steel:
            let decay = exp(-5 * within)
            return (sin(2 * .pi * frequency * time) * 0.22 + sin(4 * .pi * frequency * time) * 0.10 + sin(6 * .pi * frequency * time) * 0.04) * decay * shape
        case .pizzicato:
            let decay = exp(-12 * within)
            return (sin(2 * .pi * frequency * time) * 0.32 + sin(4 * .pi * frequency * time) * 0.08) * decay * shape
        case .bell:
            let decay = exp(-4 * within)
            return (sin(2 * .pi * frequency * time) * 0.22 + sin(4 * .pi * frequency * time) * 0.07 + sin(6 * .pi * frequency * time) * 0.04 * exp(-8 * within)) * decay * shape
        }
    }

    static func frequency(_ midi: Int) -> Double { 440 * pow(2, Double(midi - 69) / 12) }
}

// MARK: - Sound effects

enum SoundEffects {
    static func render(_ effect: GameAudio.Effect, format: AVAudioFormat) -> AVAudioPCMBuffer {
        switch effect {
        case .select:
            return make(0.05, format) { t in sin(2 * .pi * 1760 * t) * exp(-80 * t) * 0.14 }
        case .nope:
            return make(0.24, format) { t in
                let note = t < 0.1 ? 76 : 72
                let within = t < 0.1 ? t : t - 0.1
                return tone(MusicTheme.frequency(note), within, decay: 14, attack: 0.008) * 0.22 * (t < 0.1 ? 1 : 1.1)
            }
        case .pop(let combo):
            let scale = [72, 74, 76, 79, 81, 84, 86, 88]
            let base = MusicTheme.frequency(scale[min(scale.count - 1, max(0, combo - 1))])
            // A bubbly "bloop" that slides up half an octave; bigger cascades pop higher.
            return make(0.18, format) { t in
                let cycles = t <= 0.05 ? base * (t + 5 * t * t) : base * (0.0625 + 1.5 * (t - 0.05))
                return sin(2 * .pi * cycles) * exp(-22 * t) * min(1, t / 0.004) * 0.36
            }
        case .powerUpMade:
            return arpeggio([84, 88, 91, 96], spacing: 0.06, length: 0.6, level: 0.2, format)
        case .rocket:
            return make(0.45, format) { t in
                let tone = sin(2 * .pi * (300 * t + 1100 * t * t)) * 0.12
                return (tone + noise(t) * 0.16) * min(1, t / 0.03) * exp(-4 * t)
            }
        case .gardenBomb:
            return make(0.55, format) { t in
                let phase = 2 * .pi * (160 * t - 95 * t * t)
                return (sin(phase) * 0.36 + lowNoise(t) * 0.18) * min(1, t / 0.006) * exp(-6 * t)
            }
        case .rainbowPaw:
            return arpeggio([72, 76, 79, 84, 88, 91, 96], spacing: 0.045, length: 0.75, level: 0.18, format)
        case .water:
            return make(0.45, format) { t in
                let drops: [(start: Double, pitch: Double)] = [(0, 620), (0.07, 820), (0.15, 560), (0.23, 900), (0.31, 700)]
                return drops.reduce(0.0) { sum, drop in
                    let within = t - drop.start
                    guard within >= 0 else { return sum }
                    let phase = 2 * .pi * (drop.pitch * within + 2200 * within * within)
                    return sum + sin(phase) * exp(-30 * within) * min(1, within / 0.003) * 0.2
                }
            }
        case .shuffle:
            return make(0.35, format) { t in noise(t) * sin(.pi * t / 0.35) * 0.12 }
        case .win:
            return make(1.3, format) { t in
                var value = 0.0
                for (index, note) in [72, 76, 79].enumerated() {
                    let within = t - Double(index) * 0.11
                    if within >= 0 { value += tone(MusicTheme.frequency(note), within, decay: 7, attack: 0.006) * 0.2 }
                }
                let chordTime = t - 0.36
                if chordTime >= 0 {
                    for note in [84, 88, 91] {
                        value += tone(MusicTheme.frequency(note), chordTime, decay: 2.6, attack: 0.008) * 0.13
                    }
                }
                return value
            }
        case .thunder:
            // Kept soft: the thunder is a story beat, not a scare.
            return make(1.4, format) { t in lowNoise(t) * sin(.pi * t / 1.4) * 0.36 * (0.7 + 0.3 * sin(2 * .pi * 3 * t)) }
        case .knock:
            return make(0.3, format) { t in
                let hit: (Double) -> Double = { within in
                    within < 0 ? 0 : (sin(2 * .pi * 190 * within) * 0.32 + lowNoise(within) * 0.2) * exp(-45 * within)
                }
                return hit(t) + hit(t - 0.16)
            }
        case .party:
            return make(0.4, format) { t in
                let burst = noise(t) * exp(-40 * t) * 0.25
                let whistle = t > 0.05 ? sin(2 * .pi * (700 * (t - 0.05) + 900 * (t - 0.05) * (t - 0.05))) * 0.14 * exp(-5 * (t - 0.05)) : 0
                return burst + whistle
            }
        case .yardBuild:
            return arpeggio([79, 84, 88, 91, 96], spacing: 0.06, length: 0.8, level: 0.18, format)
        case .yardStyle:
            return render(.pop(combo: 3), format: format)
        case .extraMoves:
            return arpeggio([76, 79, 84, 88], spacing: 0.05, length: 0.5, level: 0.18, format)
        case .blockerHit:
            // A soft wooden "tock" with a little crunch.
            return make(0.25, format) { t in
                (noise(t) * exp(-35 * t) * 0.22 + sin(2 * .pi * 230 * t) * exp(-24 * t) * 0.3) * min(1, t / 0.003)
            }
        case .gooClean:
            // A squishy downward bloop.
            return make(0.24, format) { t in
                sin(2 * .pi * (520 * t - 500 * t * t)) * exp(-11 * t) * min(1, t / 0.005) * 0.28
            }
        case .outOfMoves:
            return arpeggio([67, 64, 60], spacing: 0.14, length: 0.9, level: 0.16, format)
        }
    }

    private static func make(_ duration: Double, _ format: AVAudioFormat, _ sample: (Double) -> Double) -> AVAudioPCMBuffer {
        let rate = format.sampleRate
        let count = AVAudioFrameCount(duration * rate)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: count)!
        buffer.frameLength = count
        let samples = buffer.floatChannelData![0]
        let fadeFrames = Int(0.01 * rate)
        for frame in 0..<Int(count) {
            let fadeOut = min(1, Double(Int(count) - frame) / Double(fadeFrames))
            samples[frame] = Float(max(-0.8, min(0.8, sample(Double(frame) / rate) * fadeOut)))
        }
        return buffer
    }

    private static func arpeggio(_ notes: [Int], spacing: Double, length: Double, level: Double, _ format: AVAudioFormat) -> AVAudioPCMBuffer {
        make(length, format) { t in
            notes.enumerated().reduce(0.0) { sum, item in
                let within = t - Double(item.offset) * spacing
                guard within >= 0 else { return sum }
                return sum + tone(MusicTheme.frequency(item.element), within, decay: 6, attack: 0.004) * level
            }
        }
    }

    /// A soft bell-like tone.
    private static func tone(_ frequency: Double, _ within: Double, decay: Double, attack: Double) -> Double {
        (sin(2 * .pi * frequency * within) + 0.25 * sin(4 * .pi * frequency * within)) * exp(-decay * within) * min(1, within / attack)
    }

    /// Repeatable white noise (a hash of the time), so effects sound the same every time.
    private static func noise(_ t: Double) -> Double {
        var x = UInt64(bitPattern: Int64((t * 44_100).rounded())) &* 0x9E37_79B9_7F4A_7C15
        x ^= x >> 29
        x &*= 0xBF58_476D_1CE4_E5B9
        x ^= x >> 32
        return Double(x % 20_000) / 10_000 - 1
    }

    /// Rumbly noise: averaged white noise, which keeps only the low frequencies.
    private static func lowNoise(_ t: Double) -> Double {
        let step = 1.0 / 44_100
        var sum = 0.0
        for offset in stride(from: 0, to: 24, by: 1) { sum += noise(t - Double(offset) * step) }
        return sum / 6
    }
}
