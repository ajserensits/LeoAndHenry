import Foundation
import SwiftUI
import UIKit

private let boardSize = 8

enum Veggie: String, CaseIterable, Codable {
    case tomato, carrot, onion, pepper, eggplant, pea

    var name: String {
        switch self {
        case .tomato: "Happy Leo"
        case .carrot: "Side-eye Leo"
        case .onion: "Guilty Leo"
        case .pepper: "Excited Leo"
        case .eggplant: "Grumpy Leo"
        case .pea: "Snack-time Leo"
        }
    }

    var spriteName: String {
        switch self {
        case .tomato: "leo-happy"
        case .carrot: "leo-side-eye"
        case .onion: "leo-guilty"
        case .pepper: "leo-excited"
        case .eggplant: "leo-grumpy"
        case .pea: "leo-lick"
        }
    }

    var color: Color {
        switch self {
        case .tomato: Color(red: 0.91, green: 0.36, blue: 0.29)
        case .carrot: Color(red: 0.95, green: 0.56, blue: 0.22)
        case .onion: Color(red: 0.80, green: 0.57, blue: 0.78)
        case .pepper: Color(red: 0.94, green: 0.75, blue: 0.24)
        case .eggplant: Color(red: 0.39, green: 0.29, blue: 0.56)
        case .pea: Color(red: 0.38, green: 0.67, blue: 0.35)
        }
    }
}

struct Tile: Identifiable, Equatable {
    let id = UUID()
    var veggie: Veggie
    var powerUp: PowerUp? = nil
}

enum PowerUp: Equatable {
    case rowRocket
    case columnRocket
    case gardenBomb
    case rainbowPaw
}

private struct MatchInfo {
    var positions = Set<Position>()
    var horizontalRuns: [[Position]] = []
    var verticalRuns: [[Position]] = []
}

private struct PowerUpCreation {
    let position: Position
    let kind: PowerUp
}

struct Level {
    let goal: Veggie
    let amount: Int
    let moves: Int
    let title: String
    let stolenItem: String
    let clue: String
    var chapterIndex: Int = 0
    var dustCells: Int = 0
    var dustDepth: Int = 0
    var sleepingCells: Int = 0
    var rescueSteps: Int = 0
    var comfortCells: Int = 0
    var thunderEvery: Int = 0

    var clearsDust: Bool { dustCells > 0 }
    var wakesLeo: Bool { sleepingCells > 0 }
    var guidesHenry: Bool { rescueSteps > 0 }
    var spreadsComfort: Bool { comfortCells > 0 }
}

struct Chapter: Identifiable {
    let id: Int
    let title: String
    let subtitle: String
    let backgroundName: String
    let symbol: String
    let levelRange: Range<Int>
}

@MainActor
final class GameModel: ObservableObject {
    nonisolated static let size = boardSize
    static let levels: [Level] = [
        .init(goal: .tomato, amount: 16, moves: 25, title: "The Bug in the Beans", stolenItem: "red plush bug", clue: "Leo dashed toward the tomato patch!"),
        .init(goal: .carrot, amount: 20, moves: 24, title: "The Missing Biscuit", stolenItem: "crunchy biscuit", clue: "A trail of crumbs leads past the carrots."),
        .init(goal: .onion, amount: 22, moves: 24, title: "Dinner on the Run", stolenItem: "dinner bowl", clue: "Henry heard a suspicious clink by the herbs."),
        .init(goal: .pepper, amount: 25, moves: 23, title: "The Squeaky Hedge", stolenItem: "squeaky toy", clue: "Squeak! Leo is hiding near the peppers."),
        .init(goal: .eggplant, amount: 27, moves: 23, title: "Sock Among the Lavender", stolenItem: "favorite sock", clue: "A fluffy brown tail vanished by the gate."),
        .init(goal: .pea, amount: 30, moves: 22, title: "The Picnic Pilferer", stolenItem: "picnic snack", clue: "Leo left tiny pawprints through the peas."),
        .init(goal: .tomato, amount: 32, moves: 22, title: "Ball in the Brambles", stolenItem: "red ball", clue: "Henry spotted the ball beyond the tomatoes."),
        .init(goal: .carrot, amount: 34, moves: 21, title: "The Great Carrot Caper", stolenItem: "carrot treat", clue: "This clue has Leo written all over it."),
        .init(goal: .onion, amount: 36, moves: 21, title: "Moonlight Munchies", stolenItem: "bedtime snack", clue: "A midnight rustle wakes determined Henry."),
        .init(goal: .pea, amount: 40, moves: 20, title: "The Garden Feast", stolenItem: "celebration supper", clue: "One last chase before the brothers share."),

        .init(goal: .carrot, amount: 18, moves: 25, title: "Follow the Crumbs", stolenItem: "crunchy biscuit", clue: "Henry spots biscuit crumbs beside the laundry basket.", chapterIndex: 1),
        .init(goal: .tomato, amount: 0, moves: 25, title: "Dust Bunny Detour", stolenItem: "dusty pawprints", clue: "Match on the dusty tiles to clear a quiet path.", chapterIndex: 1, dustCells: 8, dustDepth: 1),
        .init(goal: .onion, amount: 0, moves: 24, title: "Behind the Basket", stolenItem: "hidden biscuit", clue: "Leo is tucked behind the basket. Clear the dust so Henry can see him.", chapterIndex: 1, dustCells: 12, dustDepth: 1),
        .init(goal: .pepper, amount: 0, moves: 24, title: "The Vacuum Wakes", stolenItem: "dropped biscuit", clue: "The vacuum rumbles. Henry stands between it and Leo.", chapterIndex: 1, dustCells: 10, dustDepth: 2),
        .init(goal: .eggplant, amount: 0, moves: 23, title: "A Quiet Corner", stolenItem: "comfort blanket", clue: "Clear the thickest dust and make Leo a quiet corner.", chapterIndex: 1, dustCells: 14, dustDepth: 2),
        .init(goal: .pea, amount: 0, moves: 23, title: "Nap Behind the Hamper", stolenItem: "runaway biscuit", clue: "Make matches beside sleeping Leos so Henry can bark them awake.", chapterIndex: 1, sleepingCells: 6),
        .init(goal: .tomato, amount: 0, moves: 22, title: "Two Layers of Trouble", stolenItem: "favorite toy", clue: "Some dust bunnies need two good matches before they tumble away.", chapterIndex: 1, dustCells: 18, dustDepth: 2),
        .init(goal: .carrot, amount: 0, moves: 22, title: "Henry Takes the Lead", stolenItem: "safe hallway", clue: "Henry leads the way one clean pawstep at a time.", chapterIndex: 1, dustCells: 20, dustDepth: 2),
        .init(goal: .onion, amount: 0, moves: 21, title: "The Great Wake-Up Call", stolenItem: "doorway clue", clue: "Henry needs one more chorus of barks before everyone heads outside.", chapterIndex: 1, sleepingCells: 12),
        .init(goal: .pea, amount: 0, moves: 24, title: "Safe in the Sunshine", stolenItem: "shared biscuit", clue: "One final cleanup, then Henry and Leo can share the biscuit outside.", chapterIndex: 1, dustCells: 24, dustDepth: 2),

        .init(goal: .tomato, amount: 18, moves: 25, title: "The Noise Upstairs", stolenItem: "red plush ladybug", clue: "A sudden thump sends Leo—and Henry's ladybug—under the bed.", chapterIndex: 2),
        .init(goal: .carrot, amount: 0, moves: 25, title: "Dust Under the Bed", stolenItem: "dusty pawprints", clue: "Clear the soft dust bunnies so Henry can crawl underneath.", chapterIndex: 2, dustCells: 10, dustDepth: 1),
        .init(goal: .onion, amount: 0, moves: 24, title: "Henry Squeezes In", stolenItem: "first pawsteps", clue: "Match beside the glowing pawstep to guide Henry toward Leo.", chapterIndex: 2, rescueSteps: 6),
        .init(goal: .pepper, amount: 0, moves: 24, title: "Between the Slippers", stolenItem: "safe route", clue: "Follow the pawprints around the slippers and boxes.", chapterIndex: 2, rescueSteps: 8),
        .init(goal: .eggplant, amount: 0, moves: 23, title: "The Sock Fort", stolenItem: "striped sock", clue: "Two layers of fluff stand between the brothers.", chapterIndex: 2, dustCells: 14, dustDepth: 2),
        .init(goal: .pea, amount: 0, moves: 23, title: "Follow My Pawsteps", stolenItem: "comfort trail", clue: "Henry keeps crawling, one gentle pawstep at a time.", chapterIndex: 2, rescueSteps: 10),
        .init(goal: .tomato, amount: 24, moves: 22, title: "The Ladybug Clue", stolenItem: "red plush ladybug", clue: "Henry spots a flash of red beside Leo's fluffy paw.", chapterIndex: 2),
        .init(goal: .carrot, amount: 0, moves: 22, title: "Almost There, Leo", stolenItem: "shared blanket", clue: "Only a few more careful pawsteps to reach Leo.", chapterIndex: 2, rescueSteps: 12),
        .init(goal: .onion, amount: 0, moves: 22, title: "A Gentle Wake-Up", stolenItem: "cozy hiding place", clue: "A few quiet woofs let Leo know Henry is close.", chapterIndex: 2, sleepingCells: 8),
        .init(goal: .pea, amount: 0, moves: 24, title: "Out From Under", stolenItem: "red plush ladybug", clue: "Guide Henry all the way to Leo, then bring the ladybug into the light.", chapterIndex: 2, rescueSteps: 13),

        .init(goal: .eggplant, amount: 20, moves: 25, title: "The Cozy Spot Thief", stolenItem: "cozy blanket spot", clue: "Leo has claimed Henry's blanket spot—just as the first thunder rumbles.", chapterIndex: 3, thunderEvery: 6),
        .init(goal: .tomato, amount: 0, moves: 25, title: "Tuck In, Leo", stolenItem: "warm blanket", clue: "Match beside the blanket to spread it over Leo's shivery side.", chapterIndex: 3, comfortCells: 10, thunderEvery: 6),
        .init(goal: .carrot, amount: 0, moves: 24, title: "Henry Brings a Slipper", stolenItem: "Mom's slipper", clue: "Henry fetches a slipper that smells like Mom. The blanket grows.", chapterIndex: 3, comfortCells: 16, thunderEvery: 5),
        .init(goal: .onion, amount: 0, moves: 24, title: "Ladybug Delivery", stolenItem: "red plush ladybug", clue: "Guide Henry across the sunroom to bring Leo his favorite ladybug.", chapterIndex: 3, rescueSteps: 8, thunderEvery: 5),
        .init(goal: .pepper, amount: 0, moves: 24, title: "Rain on the Windows", stolenItem: "quiet corner", clue: "Raindrops drum on the glass. Keep the blanket spreading.", chapterIndex: 3, comfortCells: 22, thunderEvery: 5),
        .init(goal: .pea, amount: 26, moves: 23, title: "A Snack for Courage", stolenItem: "storm snack", clue: "Leo is too nervous to eat—unless Henry shares his snack.", chapterIndex: 3, thunderEvery: 5),
        .init(goal: .eggplant, amount: 0, moves: 23, title: "The Loudest Clap", stolenItem: "brave moment", clue: "The biggest boom yet. Henry pulls the blanket wider.", chapterIndex: 3, comfortCells: 28, thunderEvery: 4),
        .init(goal: .tomato, amount: 0, moves: 22, title: "Every Comfort Thing", stolenItem: "pile of toys", clue: "Henry carries every favorite toy to Leo, one trip at a time.", chapterIndex: 3, rescueSteps: 11, thunderEvery: 4),
        .init(goal: .carrot, amount: 0, moves: 22, title: "Rumbles Fading", stolenItem: "sleepy calm", clue: "The thunder rolls farther away. Just a little more blanket.", chapterIndex: 3, comfortCells: 34, thunderEvery: 6),
        .init(goal: .pea, amount: 0, moves: 24, title: "Sharing the Blanket", stolenItem: "shared blanket", clue: "The storm passes. Spread the blanket wide enough for two.", chapterIndex: 3, comfortCells: 40, thunderEvery: 8)
    ]

    static let chapters: [Chapter] = [
        .init(id: 0, title: "The Bug in the Beans", subtitle: "Henry follows Leo's pawprints through the garden.", backgroundName: "chapter-one-garden", symbol: "leaf.fill", levelRange: 0..<10),
        .init(id: 1, title: "The Vacuum Awakens", subtitle: "Henry clears a safe path through the hallway.", backgroundName: "chapter-02-vacuum-hallway", symbol: "wind", levelRange: 10..<20),
        .init(id: 2, title: "Under the Bed", subtitle: "Henry follows Leo into the coziest hiding place.", backgroundName: "chapter-03-under-the-bed", symbol: "bed.double.fill", levelRange: 20..<30),
        .init(id: 3, title: "Thunder over the Tomatoes", subtitle: "Henry keeps Leo cozy until the storm rolls past.", backgroundName: "chapter-04-thunder-tomatoes", symbol: "cloud.bolt.rain.fill", levelRange: 30..<40)
    ]

    @Published var board: [[Tile]] = []
    @Published var levelIndex = 0
    @Published var moves = 0
    @Published var collected = 0
    @Published var dustLayers = Array(repeating: Array(repeating: 0, count: boardSize), count: boardSize)
    @Published private(set) var initialDustLayers = 0
    @Published var sleepingLeos = Set<Position>()
    @Published var barkBursts = Set<Position>()
    @Published var rescuePath: [Position] = []
    @Published var rescueProgress = 0
    @Published var rescueBursts = Set<Position>()
    @Published var cozyCells = Set<Position>()
    @Published private(set) var initialCozyCells = 0
    @Published var comfortBursts = Set<Position>()
    @Published var thunderFlash = false
    private var movesMade = 0
    @Published var mapChapterIndex = 0
    @Published var selected: Position?
    @Published var popping = Set<Position>()
    @Published var hint = Set<Position>()
    @Published var message = "Match three veggie friends!"
    @Published var showingWin = false
    @Published var soundOn: Bool {
        didSet { UserDefaults.standard.set(soundOn, forKey: "soundOn") }
    }
    @Published var isBusy = false
    @Published private(set) var unlocked: Int
    @Published private(set) var wins: Int
    @Published private(set) var isDeveloperPreview = false

    var level: Level { Self.levels[levelIndex] }
    var chapter: Chapter { Self.chapters[level.chapterIndex] }
    var remainingDust: Int { dustLayers.flatMap { $0 }.reduce(0, +) }
    var objectiveAmount: Int {
        if level.clearsDust { return initialDustLayers }
        if level.wakesLeo { return level.sleepingCells }
        if level.guidesHenry { return rescuePath.count }
        if level.spreadsComfort { return level.comfortCells }
        return level.amount
    }
    var objectiveProgress: Int {
        if level.clearsDust { return initialDustLayers - remainingDust }
        if level.wakesLeo { return level.sleepingCells - sleepingLeos.count }
        if level.guidesHenry { return rescueProgress }
        if level.spreadsComfort { return cozyCells.count - initialCozyCells }
        return collected
    }
    var objectiveComplete: Bool {
        if level.clearsDust { return remainingDust == 0 }
        if level.wakesLeo { return sleepingLeos.isEmpty }
        if level.guidesHenry { return rescueProgress >= rescuePath.count }
        if level.spreadsComfort { return cozyCells.count - initialCozyCells >= level.comfortCells }
        return collected >= level.amount
    }
    var objectiveLabel: String {
        if level.clearsDust { return "CLEAR DUST" }
        if level.wakesLeo { return "WAKE LEO" }
        if level.guidesHenry { return "REACH LEO" }
        if level.spreadsComfort { return "SPREAD COMFORT" }
        return "COLLECT"
    }
    var objectiveInstruction: String {
        if level.clearsDust { return "Match pieces beneath dusty spaces." }
        if level.wakesLeo { return "Match on or beside sleeping Leos." }
        if level.guidesHenry { return "Match beside the glowing next pawstep." }
        if level.spreadsComfort { return "Match on or beside the cozy blanket to spread it." }
        return level.goal.name
    }

    init() {
        let defaults = UserDefaults.standard
        unlocked = max(1, defaults.integer(forKey: "unlockedLevels"))
        wins = defaults.integer(forKey: "gardenWins")
        soundOn = defaults.object(forKey: "soundOn") == nil ? true : defaults.bool(forKey: "soundOn")
        let savedLevel = min(max(0, defaults.integer(forKey: "currentLevel")), unlocked - 1)
        start(level: savedLevel)
    }

    func start(level requested: Int) {
        isDeveloperPreview = false
        prepareLevel(min(max(requested, 0), unlocked - 1))
        UserDefaults.standard.set(levelIndex, forKey: "currentLevel")
    }

    private func prepareLevel(_ requested: Int) {
        levelIndex = min(max(requested, 0), Self.levels.count - 1)
        moves = level.moves
        collected = 0
        selected = nil
        showingWin = false
        board = freshBoard()
        dustLayers = freshDustLayers()
        initialDustLayers = remainingDust
        sleepingLeos = freshSleepingLeos()
        barkBursts.removeAll()
        rescuePath = freshRescuePath()
        rescueProgress = 0
        rescueBursts.removeAll()
        cozyCells = freshCozyCells()
        initialCozyCells = cozyCells.count
        comfortBursts.removeAll()
        thunderFlash = false
        movesMade = 0
        mapChapterIndex = level.chapterIndex
        message = level.clue
    }

    func selectMapChapter(_ requested: Int) {
        let index = min(max(0, requested), Self.chapters.count - 1)
#if DEBUG
        mapChapterIndex = index
#else
        if unlocked > Self.chapters[index].levelRange.lowerBound { mapChapterIndex = index }
#endif
    }

#if DEBUG
    /// Opens locked content without touching the player's genuine progression.
    func startDeveloperPreview(level requested: Int) {
        isDeveloperPreview = true
        prepareLevel(requested)
        message = "Developer preview · \(level.clue)"
    }

    func developerUnlockAllLevels() {
        isDeveloperPreview = false
        unlocked = Self.levels.count
        UserDefaults.standard.set(unlocked, forKey: "unlockedLevels")
    }

    func developerCompleteThroughCurrentLevel() {
        isDeveloperPreview = false
        wins = min(Self.levels.count, max(wins, levelIndex + 1))
        unlocked = min(Self.levels.count, max(unlocked, wins + 1))
        UserDefaults.standard.set(wins, forKey: "gardenWins")
        UserDefaults.standard.set(unlocked, forKey: "unlockedLevels")
    }

    func developerResetProgress() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "gardenWins")
        defaults.removeObject(forKey: "unlockedLevels")
        defaults.removeObject(forKey: "currentLevel")
        wins = 0
        unlocked = 1
        start(level: 0)
    }
#endif

    func tap(_ position: Position) {
        guard !isBusy else { return }
        guard let old = selected else { selected = position; return }
        if old == position { selected = nil; return }
        guard old.isAdjacent(to: position) else { selected = position; return }
        selected = nil
        Task { await attemptSwap(old, position) }
    }

    func drag(from position: Position, translation: CGSize) {
        guard !isBusy, max(abs(translation.width), abs(translation.height)) > 18 else { return }
        let target: Position
        if abs(translation.width) > abs(translation.height) {
            target = .init(row: position.row, col: position.col + (translation.width > 0 ? 1 : -1))
        } else {
            target = .init(row: position.row + (translation.height > 0 ? 1 : -1), col: position.col)
        }
        guard target.isValid else { return }
        selected = nil
        Task { await attemptSwap(position, target) }
    }

    func shuffle() {
        guard !isBusy else { return }
        board = freshBoard()
        message = "Everyone found a fresh patch of sunshine."
        haptic(.soft)
    }

    func water() {
        guard !isBusy else { return }
        let candidates: ArraySlice<Position>
        if level.clearsDust {
            let dusty = (0..<Self.size).flatMap { row in
                (0..<Self.size).compactMap { col in
                    dustLayers[row][col] > 0 ? Position(row: row, col: col) : nil
                }
            }
            candidates = dusty.shuffled().prefix(5)
        } else if level.wakesLeo {
            candidates = Array(sleepingLeos).shuffled().prefix(3)
        } else if level.guidesHenry, rescueProgress < rescuePath.count {
            candidates = [rescuePath[rescueProgress]][...]
        } else if level.spreadsComfort {
            candidates = comfortFrontier().shuffled().prefix(4)
        } else {
            candidates = positions(of: level.goal).shuffled().prefix(5)
        }
        guard !candidates.isEmpty else { return }
        Task {
            isBusy = true
            await clear(Array(candidates))
            if objectiveComplete { win() }
            isBusy = false
        }
    }

    func showHint() {
        hint.removeAll()
        if let pair = possibleMove() {
            hint = Set(pair)
            message = "Two friends are wiggling with an idea."
            Task {
                try? await Task.sleep(for: .seconds(1.8))
                hint.removeAll()
            }
        } else { shuffle() }
    }

    func continueGarden() {
#if DEBUG
        if isDeveloperPreview {
            startDeveloperPreview(level: min(levelIndex + 1, Self.levels.count - 1))
            return
        }
#endif
        start(level: min(levelIndex + 1, unlocked - 1))
    }

    private func attemptSwap(_ a: Position, _ b: Position) async {
        isBusy = true
        swap(a, b)
        try? await Task.sleep(for: .milliseconds(180))

        let activated = [a, b].filter { board[$0.row][$0.col].powerUp != nil }
        if !activated.isEmpty {
            moves -= 1
            await activatePowerUps(at: activated, swapped: (a, b))
            finishMove()
            return
        }

        let found = matchInfo()
        guard !found.positions.isEmpty else {
            swap(a, b)
            message = "Those two would rather stay neighbors."
            haptic(.rigid)
            isBusy = false
            return
        }
        moves -= 1
        await resolve(found, preferredCreationPositions: [b, a])
        finishMove()
    }

    private func finishMove() {
        movesMade += 1
        if objectiveComplete { win() }
        else if level.thunderEvery > 0, movesMade.isMultiple(of: level.thunderEvery) {
            rollThunder()
        }
        if !objectiveComplete, moves <= 0 {
            moves += 10
            message = "Ten extra moves, on the house!"
        }
        isBusy = false
    }

    private func resolve(_ initial: MatchInfo, preferredCreationPositions: [Position] = []) async {
        var current = initial
        var combo = 0
        while !current.positions.isEmpty {
            combo += 1
            let creation = choosePowerUp(for: current, preferred: combo == 1 ? preferredCreationPositions : [])
            var removed = current.positions
            if let creation {
                removed.remove(creation.position)
                board[creation.position.row][creation.position.col].powerUp = creation.kind
            }
            removed = expandedClearSet(from: removed)
            popping = removed
            collected += removed.filter { board[$0.row][$0.col].veggie == level.goal }.count
            let dustHit = damageDust(at: removed)
            let awakened = wakeSleepingLeos(near: removed)
            let advanced = advanceRescue(near: removed)
            let warmed = spreadComfort(from: removed)
            if warmed > 0 {
                message = objectiveComplete ? "Everyone is snug under the blanket." : "Henry tucked the blanket over \(warmed) more spot\(warmed == 1 ? "" : "s")."
                haptic(.success)
            } else if advanced > 0 {
                message = rescueProgress == rescuePath.count ? "Henry reached Leo! Safe together." : "This way! Henry moved \(advanced) pawstep\(advanced == 1 ? "" : "s") closer."
                haptic(.success)
            } else if awakened > 0 {
                message = "WOOF! Henry woke \(awakened) sleepy Leo\(awakened == 1 ? "" : "s")."
                haptic(.success)
            } else if let creation {
                message = creationMessage(creation.kind)
                haptic(.success)
            } else if dustHit > 0 {
                message = remainingDust == 0 ? "The hallway is clear! Henry found a safe path." : "Poof! \(dustHit) dust layer\(dustHit == 1 ? "" : "s") cleared."
                haptic(.soft)
            } else {
                message = combo > 1 ? "\(combo)x cascade! Leo is everywhere." : "Lovely! A happy little row."
                haptic(.soft)
            }
            try? await Task.sleep(for: .milliseconds(260))
            collapse(removed)
            popping.removeAll()
            try? await Task.sleep(for: .milliseconds(260))
            current = matchInfo()
        }
    }

    private func activatePowerUps(at positions: [Position], swapped: (Position, Position)) async {
        var clearSet = Set(positions)
        var rainbowTargets: [Position: Veggie] = [:]
        for position in positions where board[position.row][position.col].powerUp == .rainbowPaw {
            let other = position == swapped.0 ? swapped.1 : swapped.0
            rainbowTargets[position] = board[other.row][other.col].veggie
        }
        clearSet = expandedClearSet(from: clearSet, rainbowTargets: rainbowTargets)
        popping = clearSet
        collected += clearSet.filter { board[$0.row][$0.col].veggie == level.goal }.count
        _ = damageDust(at: clearSet)
        let awakened = wakeSleepingLeos(near: clearSet)
        let advanced = advanceRescue(near: clearSet)
        let warmed = spreadComfort(from: clearSet)
        message = warmed > 0 ? "Power-up hug! The blanket spread over \(warmed) spots!" : positions.contains { board[$0.row][$0.col].powerUp == .rainbowPaw }
            ? "Rainbow paw! Every matching Leo joins the chase!"
            : advanced > 0 ? "Power-up path! Henry bounded ahead \(advanced)!" : awakened > 0 ? "WOOF! Henry's power-up bark woke \(awakened)!" : "Power-up! The garden is flying!"
        haptic(.success)
        try? await Task.sleep(for: .milliseconds(320))
        collapse(clearSet)
        popping.removeAll()
        try? await Task.sleep(for: .milliseconds(260))
        let cascades = matchInfo()
        if !cascades.positions.isEmpty { await resolve(cascades) }
    }

    private func clear(_ positions: [Position]) async {
        popping = Set(positions)
        collected += positions.filter { board[$0.row][$0.col].veggie == level.goal }.count
        let dustHit = damageDust(at: Set(positions))
        let awakened = wakeSleepingLeos(near: Set(positions))
        let advanced = advanceRescue(near: Set(positions))
        let warmed = spreadComfort(from: Set(positions))
        message = warmed > 0 ? "Henry dragged the blanket over \(warmed) more spot\(warmed == 1 ? "" : "s")." : advanced > 0 ? "Henry splashed ahead \(advanced) pawstep\(advanced == 1 ? "" : "s")!" : awakened > 0 ? "WOOF! Henry woke \(awakened)!" : dustHit > 0 ? "The water settled \(dustHit) dusty spot\(dustHit == 1 ? "" : "s")." : "A little rain works wonders."
        haptic(.soft)
        try? await Task.sleep(for: .milliseconds(260))
        collapse(Set(positions))
        popping.removeAll()
        try? await Task.sleep(for: .milliseconds(230))
        let newMatches = matchInfo()
        if !newMatches.positions.isEmpty { await resolve(newMatches) }
    }

    private func collapse(_ removed: Set<Position>) {
        for col in 0..<Self.size {
            var kept: [Tile] = []
            for row in stride(from: Self.size - 1, through: 0, by: -1) where !removed.contains(.init(row: row, col: col)) {
                kept.append(board[row][col])
            }
            for row in stride(from: Self.size - 1, through: 0, by: -1) {
                let index = Self.size - 1 - row
                board[row][col] = index < kept.count ? kept[index] : Tile(veggie: .allCases.randomElement()!)
            }
        }
    }

    private func damageDust(at positions: Set<Position>) -> Int {
        var damaged = 0
        for position in positions where dustLayers[position.row][position.col] > 0 {
            dustLayers[position.row][position.col] -= 1
            damaged += 1
        }
        return damaged
    }

    private func wakeSleepingLeos(near positions: Set<Position>) -> Int {
        let awakened = sleepingLeos.filter { sleeper in
            positions.contains { cleared in
                abs(cleared.row - sleeper.row) <= 1 && abs(cleared.col - sleeper.col) <= 1
            }
        }
        guard !awakened.isEmpty else { return 0 }
        let awakenedSet = Set(awakened)
        sleepingLeos.subtract(awakenedSet)
        barkBursts.formUnion(awakenedSet)
        Task {
            try? await Task.sleep(for: .milliseconds(720))
            barkBursts.subtract(awakenedSet)
        }
        return awakenedSet.count
    }

    private func advanceRescue(near positions: Set<Position>) -> Int {
        guard level.guidesHenry, rescueProgress < rescuePath.count else { return 0 }
        let target = rescuePath[rescueProgress]
        let reached = positions.contains { cleared in
            abs(cleared.row - target.row) <= 1 && abs(cleared.col - target.col) <= 1
        }
        guard reached else { return 0 }
        let newlyReached: Set<Position> = [target]
        rescueProgress += 1
        rescueBursts.formUnion(newlyReached)
        Task {
            try? await Task.sleep(for: .milliseconds(650))
            rescueBursts.subtract(newlyReached)
        }
        return 1
    }

    /// Each connected group of cleared cells that touches the blanket becomes cozy.
    private func spreadComfort(from cleared: Set<Position>) -> Int {
        guard level.spreadsComfort else { return 0 }
        var remaining = cleared
        var warmed = Set<Position>()
        while let start = remaining.first {
            var group: Set<Position> = [start]
            var queue = [start]
            remaining.remove(start)
            while let current = queue.popLast() {
                for next in remaining where abs(next.row - current.row) <= 1 && abs(next.col - current.col) <= 1 {
                    remaining.remove(next)
                    group.insert(next)
                    queue.append(next)
                }
            }
            let touchesBlanket = group.contains { cell in
                cozyCells.contains { abs($0.row - cell.row) <= 1 && abs($0.col - cell.col) <= 1 }
            }
            if touchesBlanket { warmed.formUnion(group.subtracting(cozyCells)) }
        }
        guard !warmed.isEmpty else { return 0 }
        cozyCells.formUnion(warmed)
        comfortBursts.formUnion(warmed)
        Task {
            try? await Task.sleep(for: .milliseconds(650))
            comfortBursts.subtract(warmed)
        }
        return warmed.count
    }

    /// Cold cells directly beside the blanket.
    private func comfortFrontier() -> [Position] {
        (0..<Self.size).flatMap { row in
            (0..<Self.size).compactMap { col in
                let cell = Position(row: row, col: col)
                guard !cozyCells.contains(cell) else { return nil }
                return cozyCells.contains { abs($0.row - row) <= 1 && abs($0.col - col) <= 1 } ? cell : nil
            }
        }
    }

    /// A harmless rumble: a soft flash and a reassuring line from Henry. Never undoes progress.
    private func rollThunder() {
        let lines = [
            "Rumble! Leo flattens his ears. Henry scoots closer.",
            "Boom! Leo hides his nose. Henry stays right beside him.",
            "Crackle! Henry leans against Leo until it passes."
        ]
        message = lines[(movesMade / max(1, level.thunderEvery) - 1) % lines.count]
        thunderFlash = true
        haptic(.rigid)
        Task {
            try? await Task.sleep(for: .milliseconds(450))
            thunderFlash = false
        }
    }

    private func win() {
#if DEBUG
        if isDeveloperPreview {
            showingWin = true
            message = "Developer preview complete — saved progress was not changed."
            haptic(.success)
            return
        }
#endif
        wins = max(wins, levelIndex + 1)
        unlocked = min(Self.levels.count, max(unlocked, levelIndex + 2))
        UserDefaults.standard.set(wins, forKey: "gardenWins")
        UserDefaults.standard.set(unlocked, forKey: "unlockedLevels")
        UserDefaults.standard.set(min(levelIndex + 1, unlocked - 1), forKey: "currentLevel")
        showingWin = true
        haptic(.success)
    }

    private func freshBoard() -> [[Tile]] {
        var result = Array(repeating: Array(repeating: Tile(veggie: .tomato), count: Self.size), count: Self.size)
        for row in 0..<Self.size {
            for col in 0..<Self.size {
                var type: Veggie
                repeat { type = .allCases.randomElement()! }
                while (col >= 2 && result[row][col - 1].veggie == type && result[row][col - 2].veggie == type)
                    || (row >= 2 && result[row - 1][col].veggie == type && result[row - 2][col].veggie == type)
                result[row][col] = Tile(veggie: type)
            }
        }
        return result
    }

    private func freshDustLayers() -> [[Int]] {
        var result = Array(repeating: Array(repeating: 0, count: Self.size), count: Self.size)
        guard level.clearsDust else { return result }
        let pattern: [Position] = [
            .init(row: 3, col: 3), .init(row: 3, col: 4), .init(row: 4, col: 3), .init(row: 4, col: 4),
            .init(row: 2, col: 3), .init(row: 2, col: 4), .init(row: 5, col: 3), .init(row: 5, col: 4),
            .init(row: 3, col: 2), .init(row: 4, col: 2), .init(row: 3, col: 5), .init(row: 4, col: 5),
            .init(row: 1, col: 2), .init(row: 1, col: 5), .init(row: 6, col: 2), .init(row: 6, col: 5),
            .init(row: 2, col: 1), .init(row: 5, col: 1), .init(row: 2, col: 6), .init(row: 5, col: 6),
            .init(row: 0, col: 1), .init(row: 0, col: 6), .init(row: 7, col: 1), .init(row: 7, col: 6)
        ]
        for position in pattern.prefix(level.dustCells) {
            result[position.row][position.col] = max(1, level.dustDepth)
        }
        return result
    }

    private func freshSleepingLeos() -> Set<Position> {
        guard level.wakesLeo else { return [] }
        let pattern: [Position] = [
            .init(row: 1, col: 1), .init(row: 1, col: 6), .init(row: 6, col: 1), .init(row: 6, col: 6),
            .init(row: 3, col: 3), .init(row: 4, col: 4), .init(row: 2, col: 4), .init(row: 5, col: 3),
            .init(row: 3, col: 1), .init(row: 4, col: 6), .init(row: 1, col: 3), .init(row: 6, col: 4)
        ]
        return Set(pattern.prefix(level.sleepingCells))
    }

    private func freshRescuePath() -> [Position] {
        guard level.guidesHenry else { return [] }
        let path: [Position] = [
            .init(row: 6, col: 0), .init(row: 6, col: 1), .init(row: 5, col: 1),
            .init(row: 5, col: 2), .init(row: 4, col: 2), .init(row: 4, col: 3),
            .init(row: 3, col: 3), .init(row: 3, col: 4), .init(row: 2, col: 4),
            .init(row: 2, col: 5), .init(row: 1, col: 5), .init(row: 1, col: 6),
            .init(row: 1, col: 7)
        ]
        return Array(path.prefix(level.rescueSteps))
    }

    private func freshCozyCells() -> Set<Position> {
        guard level.spreadsComfort else { return [] }
        // Leo's blanket spot at the bottom center of the board.
        return [.init(row: 7, col: 3), .init(row: 7, col: 4)]
    }

    private func matchInfo() -> MatchInfo {
        var info = MatchInfo()
        for row in 0..<Self.size {
            var start = 0
            for col in 1...Self.size {
                if col == Self.size || board[row][col].veggie != board[row][col - 1].veggie {
                    if col - start >= 3 {
                        let run = (start..<col).map { Position(row: row, col: $0) }
                        info.horizontalRuns.append(run)
                        info.positions.formUnion(run)
                    }
                    start = col
                }
            }
        }
        for col in 0..<Self.size {
            var start = 0
            for row in 1...Self.size {
                if row == Self.size || board[row][col].veggie != board[row - 1][col].veggie {
                    if row - start >= 3 {
                        let run = (start..<row).map { Position(row: $0, col: col) }
                        info.verticalRuns.append(run)
                        info.positions.formUnion(run)
                    }
                    start = row
                }
            }
        }
        return info
    }

    private func choosePowerUp(for info: MatchInfo, preferred: [Position]) -> PowerUpCreation? {
        let horizontalPositions = Set(info.horizontalRuns.flatMap { $0 })
        let verticalPositions = Set(info.verticalRuns.flatMap { $0 })
        let intersections = horizontalPositions.intersection(verticalPositions)
        if let center = preferred.first(where: intersections.contains) ?? intersections.first {
            return .init(position: center, kind: .gardenBomb)
        }

        if let run = (info.horizontalRuns + info.verticalRuns).first(where: { $0.count >= 5 }) {
            let spot = preferred.first(where: { run.contains($0) }) ?? run[run.count / 2]
            return .init(position: spot, kind: .rainbowPaw)
        }

        if let run = info.horizontalRuns.first(where: { $0.count == 4 }) {
            let spot = preferred.first(where: { run.contains($0) }) ?? run[run.count / 2]
            return .init(position: spot, kind: .rowRocket)
        }
        if let run = info.verticalRuns.first(where: { $0.count == 4 }) {
            let spot = preferred.first(where: { run.contains($0) }) ?? run[run.count / 2]
            return .init(position: spot, kind: .columnRocket)
        }
        return nil
    }

    private func expandedClearSet(from initial: Set<Position>, rainbowTargets: [Position: Veggie] = [:]) -> Set<Position> {
        var result = initial
        var queue = Array(initial)
        var processed = Set<Position>()
        while let position = queue.popLast() {
            guard processed.insert(position).inserted else { continue }
            guard let power = board[position.row][position.col].powerUp else { continue }
            var additions = Set<Position>()
            switch power {
            case .rowRocket:
                for col in 0..<Self.size { additions.insert(.init(row: position.row, col: col)) }
            case .columnRocket:
                for row in 0..<Self.size { additions.insert(.init(row: row, col: position.col)) }
            case .gardenBomb:
                for row in max(0, position.row - 1)...min(Self.size - 1, position.row + 1) {
                    for col in max(0, position.col - 1)...min(Self.size - 1, position.col + 1) {
                        additions.insert(.init(row: row, col: col))
                    }
                }
            case .rainbowPaw:
                let target = rainbowTargets[position] ?? board[position.row][position.col].veggie
                additions.formUnion(positions(of: target))
            }
            for added in additions where result.insert(added).inserted { queue.append(added) }
        }
        return result
    }

    private func creationMessage(_ power: PowerUp) -> String {
        switch power {
        case .rowRocket, .columnRocket: "Four Leos! You made a garden rocket."
        case .rainbowPaw: "Five Leos! You made a rainbow paw."
        case .gardenBomb: "L-shaped Leo match! You made a garden bomb."
        }
    }

    private func possibleMove() -> [Position]? {
        for row in 0..<Self.size { for col in 0..<Self.size {
            let here = Position(row: row, col: col)
            for next in [Position(row: row, col: col + 1), Position(row: row + 1, col: col)] where next.isValid {
                swap(here, next)
                let works = !matchInfo().positions.isEmpty
                swap(here, next)
                if works { return [here, next] }
            }
        }}
        return nil
    }

    private func positions(of veggie: Veggie) -> [Position] {
        var result: [Position] = []
        for row in 0..<Self.size { for col in 0..<Self.size where board[row][col].veggie == veggie { result.append(.init(row: row, col: col)) } }
        return result
    }

    private func swap(_ a: Position, _ b: Position) { board.swapAt(a, b) }

    private func haptic(_ kind: UINotificationFeedbackGenerator.FeedbackType) {
        guard soundOn else { return }
        UINotificationFeedbackGenerator().notificationOccurred(kind)
    }

    private func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard soundOn else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

struct Position: Hashable {
    let row: Int
    let col: Int
    var isValid: Bool { (0..<boardSize).contains(row) && (0..<boardSize).contains(col) }
    func isAdjacent(to other: Position) -> Bool { abs(row - other.row) + abs(col - other.col) == 1 }
}

private extension Array where Element == [Tile] {
    mutating func swapAt(_ a: Position, _ b: Position) {
        let temp = self[a.row][a.col]
        self[a.row][a.col] = self[b.row][b.col]
        self[b.row][b.col] = temp
    }
}
