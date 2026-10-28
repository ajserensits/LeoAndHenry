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
        case .pepper: "Nervous Leo"
        case .eggplant: "Grumpy Leo"
        case .pea: "Snack-time Leo"
        }
    }

    var spriteName: String {
        switch self {
        case .tomato: "leo-happy"
        case .carrot: "leo-side-eye"
        case .onion: "leo-guilty"
        case .pepper: "leo-nervous"
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
        case .eggplant: Color(red: 0.24, green: 0.48, blue: 0.86)
        case .pea: Color(red: 0.38, green: 0.67, blue: 0.35)
        }
    }
}

/// A clattery thing in the porch yard. Cans stay put; bags drift on the breeze.
struct NoisyObject: Equatable {
    enum Kind: Equatable { case can, bag }
    var kind: Kind
    var hits: Int
}

/// A familiar sign of Mom hidden beneath soft garden leaves.
enum ClueKind: CaseIterable, Equatable {
    case slipper, keys, pawprints
}

struct HiddenClue: Equatable {
    let kind: ClueKind
    var cover: Int
}

/// Something that takes up a whole board cell instead of a Leo piece. Pots, crates, and beetles
/// break from matches beside them; stones only crack from power-ups. Beetles wander after each move.
struct Blocker: Equatable {
    enum Kind: Equatable { case pot, crate, stone, beetle }
    var kind: Kind
    var hits: Int
    let startingHits: Int
    var breaksFromNearbyMatches: Bool { kind != .stone }
    var isCracked: Bool { hits < startingHits }

    init(kind: Kind, hits: Int) {
        self.kind = kind
        self.hits = hits
        startingHits = hits
    }
}

struct Tile: Identifiable, Equatable {
    let id = UUID()
    var veggie: Veggie
    var powerUp: PowerUp? = nil
    /// A little treat bag on the piece's edge: clearing it gives this many extra moves.
    var bonusMoves = 0
}

enum PowerUp: Equatable {
    case rowRocket
    case columnRocket
    case gardenBomb
    case rainbowPaw
}

enum StartingBooster: String, CaseIterable, Identifiable, Hashable {
    case rocket
    case gardenBomb
    case rainbowPaw

    var id: String { rawValue }
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

struct Level: Identifiable {
    let id: String
    let chapterID: String
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
    var quietRouteSteps: Int = 0
    var mowerEvery: Int = 0
    var canCells: Int = 0
    var canDepth: Int = 1
    var bagCells: Int = 0
    var breezeEvery: Int = 0
    var clueCells: Int = 0
    var clueDepth: Int = 1
    var splashCount: Int = 0
    var splashEvery: Int = 0
    var parcelCount: Int = 0
    var knockEvery: Int = 0
    var parcelIsPad = false
    var partyEvery: Int = 0
    var potCells: Int = 0
    var crateCells: Int = 0
    var crateDepth: Int = 2
    var stoneCells: Int = 0
    var stoneDepth: Int = 1
    var beetleCount: Int = 0
    var gooCells: Int = 0

    var clearsDust: Bool { dustCells > 0 }
    var wakesLeo: Bool { sleepingCells > 0 }
    var guidesHenry: Bool { rescueSteps > 0 }
    var spreadsComfort: Bool { comfortCells > 0 }
    var followsQuietRoute: Bool { quietRouteSteps > 0 }
    var quietsNoise: Bool { canCells + bagCells > 0 }
    var findsClues: Bool { clueCells > 0 }
    var keepsLeoDry: Bool { splashCount > 0 }
    var deliversParcels: Bool { parcelCount > 0 }

    /// Every goal this level asks for, in display order. Most levels have one; finale levels combine two.
    var objectives: [Objective] {
        var result: [Objective] = []
        if clearsDust { result.append(.dust) }
        if wakesLeo { result.append(.sleep) }
        if guidesHenry { result.append(.rescue) }
        if spreadsComfort { result.append(.comfort) }
        if followsQuietRoute { result.append(.quietRoute) }
        if quietsNoise { result.append(.noise) }
        if findsClues { result.append(.clues) }
        if keepsLeoDry { result.append(.splash) }
        if deliversParcels { result.append(.parcels) }
        if amount > 0 || result.isEmpty { result.append(.collect) }
        return result
    }
    var isMultiGoal: Bool { objectives.count > 1 }
}

enum Objective: Hashable {
    case dust, sleep, rescue, comfort, quietRoute, noise, clues, splash, parcels, collect
}

struct Chapter: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let backgroundName: String
    let symbol: String
    let levelRange: Range<Int>
}

@MainActor
final class GameModel: ObservableObject {
    nonisolated static let size = boardSize
    private static let content = GameContentLoader.load()
    static let levels = content.levels
    static let chapters = content.chapters

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
    @Published var quietRoute: [Position] = []
    @Published var quietProgress = 0
    @Published var quietBursts = Set<Position>()
    @Published var mowerLoop: [Position] = []
    @Published var mowerProgress = 0
    @Published var mowerBurst = false
    @Published var noisyObjects: [Position: NoisyObject] = [:]
    @Published private(set) var initialNoise = 0
    @Published var noiseBursts = Set<Position>()
    @Published var breezeGust = false
    @Published var hiddenClues: [Position: HiddenClue] = [:]
    @Published private(set) var initialClueCount = 0
    @Published var clueBursts: [Position: ClueKind] = [:]
    @Published var splashes = Set<Position>()
    @Published private(set) var splashesSpawned = 0
    @Published private(set) var splashesCleared = 0
    @Published var dryBursts = Set<Position>()
    @Published var nudgeBursts = Set<Position>()
    @Published var parcels = Set<Position>()
    @Published private(set) var parcelsDelivered = 0
    @Published var parcelBursts = Set<Position>()
    @Published var doorKnock = false
    @Published var partyPop = false
    @Published var blockers: [Position: Blocker] = [:]
    @Published var blockerBursts = Set<Position>()
    @Published var goo = Set<Position>()
    @Published var gooBursts = Set<Position>()
    @Published var bonusBursts = Set<Position>()
    @Published var outOfMoves = false
    @Published private(set) var secondWindUsed = false
    @Published private(set) var watersLeft = GameModel.watersPerLevel
    private var gooClearedThisMove = false
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
    @Published private(set) var completedLevelIDs: Set<String>
    @Published private(set) var isDeveloperPreview = false
    @Published private(set) var rocketBoosters: Int
    @Published private(set) var gardenBombBoosters: Int
    @Published private(set) var rainbowPawBoosters: Int
    @Published private(set) var claimedBasketLevelIDs: Set<String>
    /// Built yard projects mapped to the chosen style index. Saved on-device.
    @Published private(set) var yardChoices: [String: Int]
    /// True when the level just won was a first-time win, which earns one yard treat.
    @Published private(set) var lastWinEarnedTreat = false

    static let watersPerLevel = 3
    static let secondWindMoves = 5
    static let maxGoo = 18

    var level: Level { Self.levels[levelIndex] }
    /// Chapter Ten's goo is birthday frosting; everywhere else it is garden mud.
    var gooIsFrosting: Bool { level.chapterIndex == 9 }
    /// Henry's second wind is offered once per attempt when the goal is at least three-quarters done.
    var canTakeSecondWind: Bool { !secondWindUsed && objectiveProgress * 4 >= objectiveAmount * 3 }
    var chapter: Chapter { Self.chapters[level.chapterIndex] }
    var remainingDust: Int { dustLayers.flatMap { $0 }.reduce(0, +) }
    var remainingNoise: Int { noisyObjects.values.reduce(0) { $0 + $1.hits } }
    var mowerPosition: Position? { mowerLoop.isEmpty ? nil : mowerLoop[mowerProgress % mowerLoop.count] }
    var objectiveAmount: Int { level.objectives.reduce(0) { $0 + amount(of: $1) } }
    var objectiveProgress: Int { level.objectives.reduce(0) { $0 + min(progress(of: $1), amount(of: $1)) } }
    var objectiveComplete: Bool { level.objectives.allSatisfy(isComplete) }
    var objectiveLabel: String {
        level.isMultiGoal ? "BIRTHDAY GOALS" : label(of: level.objectives[0])
    }
    var objectiveInstruction: String {
        level.isMultiGoal
            ? level.objectives.map { instruction(of: $0) }.joined(separator: " ")
            : instruction(of: level.objectives[0])
    }

    func amount(of objective: Objective) -> Int {
        switch objective {
        case .dust: initialDustLayers
        case .sleep: level.sleepingCells
        case .rescue: rescuePath.count
        case .comfort: level.comfortCells
        case .quietRoute: quietRoute.count
        case .noise: initialNoise
        case .clues: initialClueCount
        case .splash: level.splashCount
        case .parcels: level.parcelCount
        case .collect: level.amount
        }
    }

    func progress(of objective: Objective) -> Int {
        switch objective {
        case .dust: initialDustLayers - remainingDust
        case .sleep: level.sleepingCells - sleepingLeos.count
        case .rescue: rescueProgress
        case .comfort: cozyCells.count - initialCozyCells
        case .quietRoute: quietProgress
        case .noise: initialNoise - remainingNoise
        case .clues: initialClueCount - hiddenClues.count
        case .splash: splashesCleared
        case .parcels: parcelsDelivered
        case .collect: collected
        }
    }

    func isComplete(_ objective: Objective) -> Bool {
        switch objective {
        case .dust: remainingDust == 0
        case .sleep: sleepingLeos.isEmpty
        case .rescue: rescueProgress >= rescuePath.count
        case .comfort: cozyCells.count - initialCozyCells >= level.comfortCells
        case .quietRoute: quietProgress >= quietRoute.count
        case .noise: noisyObjects.isEmpty
        case .clues: hiddenClues.isEmpty
        case .splash: splashesCleared >= level.splashCount
        case .parcels: parcelsDelivered >= level.parcelCount
        case .collect: collected >= level.amount
        }
    }

    private func label(of objective: Objective) -> String {
        switch objective {
        case .dust: "CLEAR DUST"
        case .sleep: "WAKE LEO"
        case .rescue: "REACH LEO"
        case .comfort: "SPREAD COMFORT"
        case .quietRoute: "QUIET ROUTE"
        case .noise: "HUSH THE NOISE"
        case .clues: "FIND MOM'S CLUES"
        case .splash: "KEEP LEO DRY"
        case .parcels: level.parcelIsPad ? "BRING THE PADS" : "DELIVER PARCELS"
        case .collect: "COLLECT"
        }
    }

    private func instruction(of objective: Objective) -> String {
        switch objective {
        case .dust: "Match pieces beneath dusty spaces."
        case .sleep: "Match on or beside sleeping Leos."
        case .rescue: "Match beside the glowing next pawstep."
        case .comfort: "Match on or beside the cozy blanket to spread it."
        case .quietRoute: "Match beside the glowing leaf to lead Leo safely."
        case .noise: "Match on or beside cans and bags to quiet them."
        case .clues: "Match on or beside leafy patches to reveal clues."
        case .splash: "Match on or beside splashes before they reach Leo's towel."
        case .parcels: level.parcelIsPad ? "Clear pieces beneath the peanut-butter pads to bring them down to Mom." : "Clear pieces beneath parcels to bring them to the mat."
        case .collect: level.isMultiGoal ? "Collect \(level.amount) \(level.goal.name)." : level.goal.name
        }
    }

    init() {
        let defaults = UserDefaults.standard
        let knownLevelIDs = Set(Self.levels.map(\.id))
        let migratedCompletedLevelIDs: Set<String>
        if let savedIDs = defaults.array(forKey: "progress.completedLevelIDs") as? [String] {
            migratedCompletedLevelIDs = Set(savedIDs).intersection(knownLevelIDs)
        } else {
            let legacyWins = min(Self.levels.count, max(0, defaults.integer(forKey: "gardenWins")))
            migratedCompletedLevelIDs = Set(Self.levels.prefix(legacyWins).map(\.id))
        }
        completedLevelIDs = migratedCompletedLevelIDs
        wins = migratedCompletedLevelIDs.count

        let completedHighWaterMark = Self.levels.lastIndex { migratedCompletedLevelIDs.contains($0.id) }.map { $0 + 2 } ?? 1
        let savedHighWaterMark = defaults.string(forKey: "progress.highestUnlockedLevelID")
            .flatMap { id in Self.levels.firstIndex { $0.id == id } }
            .map { $0 + 1 }
            ?? defaults.integer(forKey: "unlockedLevels")
        unlocked = min(Self.levels.count, max(1, savedHighWaterMark, completedHighWaterMark))

        rocketBoosters = max(0, defaults.integer(forKey: "boosterInventory.rocket"))
        gardenBombBoosters = max(0, defaults.integer(forKey: "boosterInventory.gardenBomb"))
        rainbowPawBoosters = max(0, defaults.integer(forKey: "boosterInventory.rainbowPaw"))
        if let claimedIDs = defaults.array(forKey: "boosterBasket.claimedLevelIDs") as? [String] {
            claimedBasketLevelIDs = Set(claimedIDs).intersection(knownLevelIDs)
        } else {
            let legacyClaims = defaults.array(forKey: "boosterBasket.claimedLevels") as? [Int] ?? []
            claimedBasketLevelIDs = Set(legacyClaims.compactMap { Self.levels.indices.contains($0) ? Self.levels[$0].id : nil })
        }
        yardChoices = defaults.dictionary(forKey: "yard.choices") as? [String: Int] ?? [:]
        soundOn = defaults.object(forKey: "soundOn") == nil ? true : defaults.bool(forKey: "soundOn")
        saveProgress()
        saveClaimedBasketLevels()
        let savedLevel = defaults.string(forKey: "progress.currentLevelID")
            .flatMap { id in Self.levels.firstIndex { $0.id == id } }
            .map { min($0, unlocked - 1) }
            ?? min(max(0, defaults.integer(forKey: "currentLevel")), unlocked - 1)
        start(level: savedLevel)
    }

    func start(level requested: Int, using startingBoosters: Set<StartingBooster> = []) {
        isDeveloperPreview = false
        prepareLevel(min(max(requested, 0), unlocked - 1))
        let availableBoosters = consume(startingBoosters)
        placeStartingBoosters(availableBoosters)
        saveCurrentLevel()
    }

    func boosterCount(_ booster: StartingBooster) -> Int {
        switch booster {
        case .rocket: rocketBoosters
        case .gardenBomb: gardenBombBoosters
        case .rainbowPaw: rainbowPawBoosters
        }
    }

    func isLevelCompleted(_ index: Int) -> Bool {
        Self.levels.indices.contains(index) && completedLevelIDs.contains(Self.levels[index].id)
    }

    func shouldPlayBoosterBasket(before requestedLevel: Int) -> Bool {
        let level = min(max(requestedLevel, 0), Self.levels.count - 1)
        let localLevel = level - Self.chapters[Self.levels[level].chapterIndex].levelRange.lowerBound + 1
        return (localLevel == 3 || localLevel == 7) && !claimedBasketLevelIDs.contains(Self.levels[level].id)
    }

    func completeBoosterBasket(for level: Int, caught: [StartingBooster]) {
        guard Self.levels.indices.contains(level) else { return }
        guard claimedBasketLevelIDs.insert(Self.levels[level].id).inserted else { return }
        for booster in caught.prefix(3) {
            switch booster {
            case .rocket: rocketBoosters += 1
            case .gardenBomb: gardenBombBoosters += 1
            case .rainbowPaw: rainbowPawBoosters += 1
            }
        }
        saveBoosterInventory()
        saveClaimedBasketLevels()
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
        quietRoute = freshQuietRoute()
        quietProgress = 0
        quietBursts.removeAll()
        mowerLoop = freshMowerLoop()
        mowerProgress = 0
        mowerBurst = false
        noisyObjects = freshNoisyObjects()
        initialNoise = remainingNoise
        noiseBursts.removeAll()
        breezeGust = false
        hiddenClues = freshHiddenClues()
        initialClueCount = hiddenClues.count
        clueBursts.removeAll()
        splashes.removeAll()
        splashesSpawned = 0
        splashesCleared = 0
        dryBursts.removeAll()
        nudgeBursts.removeAll()
        if level.keepsLeoDry { for _ in 0..<min(3, level.splashCount) { spawnSplash() } }
        parcels = freshParcels()
        parcelsDelivered = 0
        parcelBursts.removeAll()
        doorKnock = false
        partyPop = false
        blockers = freshBlockers()
        blockerBursts.removeAll()
        goo = freshGoo()
        gooBursts.removeAll()
        bonusBursts.removeAll()
        outOfMoves = false
        secondWindUsed = false
        watersLeft = Self.watersPerLevel
        gooClearedThisMove = false
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
        message = "Practice run · \(level.clue)"
    }

    func developerUnlockAllLevels() {
        isDeveloperPreview = false
        unlocked = Self.levels.count
        saveProgress()
    }

    func developerCompleteThroughCurrentLevel() {
        isDeveloperPreview = false
        completedLevelIDs.formUnion(Self.levels.prefix(levelIndex + 1).map(\.id))
        wins = completedLevelIDs.count
        unlocked = min(Self.levels.count, max(unlocked, levelIndex + 2))
        saveProgress()
    }

    func developerResetProgress() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "gardenWins")
        defaults.removeObject(forKey: "unlockedLevels")
        defaults.removeObject(forKey: "currentLevel")
        defaults.removeObject(forKey: "progress.completedLevelIDs")
        defaults.removeObject(forKey: "progress.highestUnlockedLevelID")
        defaults.removeObject(forKey: "progress.currentLevelID")
        defaults.removeObject(forKey: "boosterInventory.rocket")
        defaults.removeObject(forKey: "boosterInventory.gardenBomb")
        defaults.removeObject(forKey: "boosterInventory.rainbowPaw")
        defaults.removeObject(forKey: "boosterBasket.claimedLevels")
        defaults.removeObject(forKey: "boosterBasket.claimedLevelIDs")
        defaults.removeObject(forKey: "yard.choices")
        yardChoices = [:]
        wins = 0
        completedLevelIDs.removeAll()
        unlocked = 1
        rocketBoosters = 0
        gardenBombBoosters = 0
        rainbowPawBoosters = 0
        claimedBasketLevelIDs.removeAll()
        start(level: 0)
    }

    func developerGrantStartingBoosters() {
        rocketBoosters += 10
        gardenBombBoosters += 10
        rainbowPawBoosters += 10
        saveBoosterInventory()
    }
#endif

    /// Spends treats to fix up a yard spot, starting with its first style.
    @discardableResult
    func buildYardSpot(_ id: String) -> Bool {
        guard let spot = Yard.spot(id), yardChoices[id] == nil, treats >= spot.cost else { return false }
        yardChoices[id] = 0
        UserDefaults.standard.set(yardChoices, forKey: "yard.choices")
        return true
    }

    /// Switching styles on a built spot is always free.
    func chooseYardStyle(_ id: String, style: Int) {
        guard let spot = Yard.spot(id), yardChoices[id] != nil, spot.styles.indices.contains(style) else { return }
        yardChoices[id] = style
        UserDefaults.standard.set(yardChoices, forKey: "yard.choices")
    }

    func tap(_ position: Position) {
        guard !isBusy, !outOfMoves else { return }
        guard let old = selected else { selected = position; sound(.select); return }
        if old == position { selected = nil; return }
        guard old.isAdjacent(to: position) else { selected = position; return }
        selected = nil
        Task { await attemptSwap(old, position) }
    }

    func drag(from position: Position, translation: CGSize) {
        guard !isBusy, !outOfMoves, max(abs(translation.width), abs(translation.height)) > 18 else { return }
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
        sound(.shuffle)
    }

    func water() {
        guard !isBusy, !outOfMoves else { return }
        guard watersLeft > 0 else {
            message = "The watering can is empty for this level."
            haptic(.rigid)
            return
        }
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
        } else if level.followsQuietRoute, quietProgress < quietRoute.count {
            candidates = [quietRoute[quietProgress]][...]
        } else if level.quietsNoise {
            candidates = noisyObjects.keys.shuffled().prefix(3)
        } else if level.findsClues {
            candidates = hiddenClues.keys.shuffled().prefix(3)
        } else if level.keepsLeoDry {
            candidates = splashes.shuffled().prefix(3)
        } else if level.deliversParcels {
            candidates = parcels
                .filter { $0.row < Self.size - 1 }
                .map { Position(row: $0.row + 1, col: $0.col) }
                .shuffled()
                .prefix(3)
        } else {
            candidates = positions(of: level.goal).shuffled().prefix(5)
        }
        guard !candidates.isEmpty else { return }
        watersLeft -= 1
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

    /// Henry's second wind: a few more moves, once per attempt, when the goal is nearly done.
    func takeSecondWind() {
        guard outOfMoves, canTakeSecondWind else { return }
        secondWindUsed = true
        moves += Self.secondWindMoves
        outOfMoves = false
        message = "Henry found a snack in his pocket! \(Self.secondWindMoves) more moves."
        sound(.extraMoves)
    }

    func retryLevel() {
#if DEBUG
        if isDeveloperPreview {
            startDeveloperPreview(level: levelIndex)
            return
        }
#endif
        start(level: levelIndex)
    }

    private func attemptSwap(_ a: Position, _ b: Position) async {
        if let stuck = [a, b].first(where: isFixed) {
            message = blockers[stuck] != nil
                ? "That \(blockerName(blockers[stuck]!.kind)) won't budge. Match beside it instead."
                : "That Leo is stuck in the \(gooIsFrosting ? "frosting" : "mud"). Match on or beside him to clean him off."
            haptic(.rigid)
            sound(.nope)
            return
        }
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
            sound(.nope)
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
        else if level.mowerEvery > 0, movesMade.isMultiple(of: level.mowerEvery) {
            advanceMower()
        }
        else if level.thunderEvery > 0, movesMade.isMultiple(of: level.thunderEvery) {
            rollThunder()
        }
        else if level.breezeEvery > 0, movesMade.isMultiple(of: level.breezeEvery) {
            blowBreeze()
        }
        else if level.splashEvery > 0, movesMade.isMultiple(of: level.splashEvery) {
            creepSplashes()
        }
        else if level.knockEvery > 0, movesMade.isMultiple(of: level.knockEvery) {
            ringDoorbell()
        }
        else if level.partyEvery > 0, movesMade.isMultiple(of: level.partyEvery) {
            popPartyCommotion()
        }
        if !objectiveComplete {
            moveBeetles()
            spreadGoo()
            if possibleMove() == nil { reshuffleStuckBoard() }
        }
        gooClearedThisMove = false
        if !objectiveComplete, moves <= 0 {
            outOfMoves = true
            message = canTakeSecondWind ? "So close! Henry has an idea…" : "Out of moves! Henry is ready to try again."
            haptic(.warning)
            sound(.outOfMoves)
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
            let settled = settle(expandedClearSet(from: removed))
            removed = settled.tiles
            popping = removed
            collected += removed.filter { board[$0.row][$0.col].veggie == level.goal }.count
            let dustHit = damageDust(at: removed)
            let awakened = wakeSleepingLeos(near: removed)
            let advanced = advanceRescue(near: removed)
            let warmed = spreadComfort(from: removed)
            let quietSteps = advanceQuietRoute(near: removed)
            let hushed = hushNoise(near: removed)
            let cluesFound = revealClues(near: removed)
            let dried = drySplashes(near: removed)
            let delivered = dropParcels(afterClearing: removed)
            if delivered > 0 {
                message = level.parcelIsPad
                    ? (objectiveComplete ? "Both pads reached Mom! Happy birthday, Leo and Henry!" : "Slide! \(delivered) peanut-butter pad\(delivered == 1 ? "" : "s") reached Mom.")
                    : (objectiveComplete ? "All the parcels are safe inside. The visitor is gone!" : "Thump! \(delivered) parcel\(delivered == 1 ? "" : "s") reached the doormat.")
                haptic(.success)
            } else if dried > 0 {
                message = objectiveComplete ? "Not a drop on Leo! The brothers trot over to Mom." : "Henry shook off \(dried) splash\(dried == 1 ? "" : "es"). Leo's paws stay dry."
                haptic(.success)
            } else if cluesFound > 0 {
                message = hiddenClues.isEmpty ? "Henry found the way! Mom is waiting in the warm window." : "A familiar clue! Henry knows they are getting closer to Mom."
                haptic(.success)
            } else if hushed > 0 {
                message = noisyObjects.isEmpty ? "The porch is quiet! Leo pads out beside Henry." : "Henry nudged \(hushed) noisy thing\(hushed == 1 ? "" : "s") quiet."
                haptic(.success)
            } else if quietSteps > 0 {
                message = quietProgress == quietRoute.count ? "Henry found the quiet way home! Leo is right behind him." : "This way, Leo! Henry led them one safe leaf farther."
                haptic(.success)
            } else if warmed > 0 {
                message = objectiveComplete ? "Everyone is snug under the blanket." : "Henry tucked the blanket over \(warmed) more spot\(warmed == 1 ? "" : "s")."
                haptic(.success)
            } else if advanced > 0 {
                message = rescueProgress == rescuePath.count ? "Henry reached Leo! Safe together." : "This way! Henry moved \(advanced) pawstep\(advanced == 1 ? "" : "s") closer."
                haptic(.success)
            } else if awakened > 0 {
                message = "WOOF! Henry woke \(awakened) sleepy Leo\(awakened == 1 ? "" : "s")."
                haptic(.success)
            } else if settled.brokenBlockers > 0 {
                message = blockerMessage(settled)
                haptic(.success)
            } else if settled.cleanedGoo > 0 {
                message = "Henry licked \(settled.cleanedGoo) Leo\(settled.cleanedGoo == 1 ? "" : "s") clean of \(gooIsFrosting ? "frosting" : "mud")!"
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
            sound(creation != nil ? .powerUpMade : .pop(combo: combo))
            if settled.extraMoves > 0 { message = "A treat bag! Henry earned \(settled.extraMoves) extra moves." }
            try? await Task.sleep(for: .milliseconds(260))
            collapse(removed.union(settled.freed))
            popping.removeAll()
            try? await Task.sleep(for: .milliseconds(260))
            current = matchInfo()
        }
    }

    private func activatePowerUps(at positions: [Position], swapped: (Position, Position)) async {
        let activatedKinds = positions.compactMap { board[$0.row][$0.col].powerUp }
        var clearSet = Set(positions)
        var rainbowTargets: [Position: Veggie] = [:]
        for position in positions where board[position.row][position.col].powerUp == .rainbowPaw {
            let other = position == swapped.0 ? swapped.1 : swapped.0
            rainbowTargets[position] = board[other.row][other.col].veggie
        }
        let settled = settle(expandedClearSet(from: clearSet, rainbowTargets: rainbowTargets), crackStones: activatedKinds.contains(.rainbowPaw))
        clearSet = settled.tiles
        popping = clearSet
        collected += clearSet.filter { board[$0.row][$0.col].veggie == level.goal }.count
        _ = damageDust(at: clearSet)
        let awakened = wakeSleepingLeos(near: clearSet)
        let advanced = advanceRescue(near: clearSet)
        let warmed = spreadComfort(from: clearSet)
        let quietSteps = advanceQuietRoute(near: clearSet)
        let hushed = hushNoise(near: clearSet)
        let cluesFound = revealClues(near: clearSet)
        let dried = drySplashes(near: clearSet)
        let delivered = dropParcels(afterClearing: clearSet)
        message = delivered > 0 ? "Power-up delivery! \(delivered) \(level.parcelIsPad ? "pad" : "parcel")\(delivered == 1 ? "" : "s") reached \(level.parcelIsPad ? "Mom" : "the mat")!" : dried > 0 ? "Power-up sunshine! \(dried) splash\(dried == 1 ? "" : "es") dried up!" : cluesFound > 0 ? "Power-up search! Henry uncovered \(cluesFound) clue\(cluesFound == 1 ? "" : "s")!" : hushed > 0 ? "Power-up hush! \(hushed) clatter\(hushed == 1 ? "" : "s") settled down!" : quietSteps > 0 ? "Power-up path! Henry bounded along the quiet route!" : warmed > 0 ? "Power-up hug! The blanket spread over \(warmed) spots!" : positions.contains { board[$0.row][$0.col].powerUp == .rainbowPaw }
            ? "Rainbow paw! Every matching Leo joins the chase!"
            : advanced > 0 ? "Power-up path! Henry bounded ahead \(advanced)!" : awakened > 0 ? "WOOF! Henry's power-up bark woke \(awakened)!" : "Power-up! The garden is flying!"
        haptic(.success)
        sound(powerUpSound(for: activatedKinds))
        if settled.brokenBlockers > 0 { message = "Power-up! " + blockerMessage(settled) }
        try? await Task.sleep(for: .milliseconds(320))
        collapse(clearSet.union(settled.freed))
        popping.removeAll()
        try? await Task.sleep(for: .milliseconds(260))
        let cascades = matchInfo()
        if !cascades.positions.isEmpty { await resolve(cascades) }
    }

    private func clear(_ targeted: [Position]) async {
        let settled = settle(Set(targeted))
        let positions = Array(settled.tiles)
        popping = Set(positions)
        collected += positions.filter { board[$0.row][$0.col].veggie == level.goal }.count
        let dustHit = damageDust(at: Set(positions))
        let awakened = wakeSleepingLeos(near: Set(positions))
        let advanced = advanceRescue(near: Set(positions))
        let warmed = spreadComfort(from: Set(positions))
        let quietSteps = advanceQuietRoute(near: Set(positions))
        let hushed = hushNoise(near: Set(positions))
        let cluesFound = revealClues(near: Set(positions))
        let dried = drySplashes(near: Set(positions))
        let delivered = dropParcels(afterClearing: Set(positions))
        message = delivered > 0 ? "The water swept \(delivered) \(level.parcelIsPad ? "pad" : "parcel")\(delivered == 1 ? "" : "s") down to \(level.parcelIsPad ? "Mom" : "the mat")!" : dried > 0 ? "Henry soaked up \(dried) splash\(dried == 1 ? "" : "es") with a towel." : cluesFound > 0 ? "The water uncovered \(cluesFound) familiar clue\(cluesFound == 1 ? "" : "s")!" : hushed > 0 ? "A splash of water hushed \(hushed) clatter\(hushed == 1 ? "" : "s")." : quietSteps > 0 ? "Henry found the next quiet leaf!" : warmed > 0 ? "Henry dragged the blanket over \(warmed) more spot\(warmed == 1 ? "" : "s")." : advanced > 0 ? "Henry splashed ahead \(advanced) pawstep\(advanced == 1 ? "" : "s")!" : awakened > 0 ? "WOOF! Henry woke \(awakened)!" : dustHit > 0 ? "The water settled \(dustHit) dusty spot\(dustHit == 1 ? "" : "s")." : "A little rain works wonders."
        haptic(.soft)
        sound(.water)
        try? await Task.sleep(for: .milliseconds(260))
        collapse(Set(positions).union(settled.freed))
        popping.removeAll()
        try? await Task.sleep(for: .milliseconds(230))
        let newMatches = matchInfo()
        if !newMatches.positions.isEmpty { await resolve(newMatches) }
    }

    /// Pieces fall within each stretch of a column between blockers and goo, which stay put.
    /// Every stretch refills from its own top.
    private func collapse(_ removed: Set<Position>) {
        for col in 0..<Self.size {
            var bottom = Self.size - 1
            while bottom >= 0 {
                if isFixed(Position(row: bottom, col: col)) {
                    bottom -= 1
                    continue
                }
                var top = bottom
                while top > 0, !isFixed(Position(row: top - 1, col: col)) { top -= 1 }
                var kept: [Tile] = []
                for row in stride(from: bottom, through: top, by: -1) where !removed.contains(.init(row: row, col: col)) {
                    kept.append(board[row][col])
                }
                for row in stride(from: bottom, through: top, by: -1) {
                    let index = bottom - row
                    board[row][col] = index < kept.count ? kept[index] : freshTile()
                }
                bottom = top - 1
            }
        }
    }

    /// A new piece. Now and then it carries a treat bag worth two extra moves.
    private func freshTile() -> Tile {
        let bags = board.joined().filter { $0.bonusMoves > 0 }.count
        let bonus = bags < 2 && Double.random(in: 0..<1) < 0.025 ? 2 : 0
        return Tile(veggie: .allCases.randomElement()!, bonusMoves: bonus)
    }

    private func isFixed(_ position: Position) -> Bool {
        blockers[position] != nil || goo.contains(position)
    }

    private struct Settled {
        /// Leo pieces that pop.
        var tiles = Set<Position>()
        /// Blocker cells that broke and now refill.
        var freed = Set<Position>()
        var brokenBlockers = 0
        var cleanedGoo = 0
        var extraMoves = 0
    }

    /// Works out what a set of targeted cells really does: blockers in the blast take a hit, goo
    /// comes off (the Leo underneath stays), and pieces popping beside pots, crates, beetles, or
    /// goo chip them too. Stones only crack from power-ups.
    private func settle(_ targeted: Set<Position>, crackStones: Bool = false) -> Settled {
        var result = Settled()
        var hit = Set<Position>()
        var cleaned = Set<Position>()
        for position in targeted {
            if blockers[position] != nil { hit.insert(position) }
            else if goo.contains(position) { cleaned.insert(position) }
            else { result.tiles.insert(position) }
        }
        for tile in result.tiles {
            for neighbor in tile.neighbors {
                if let blocker = blockers[neighbor], blocker.breaksFromNearbyMatches { hit.insert(neighbor) }
                if goo.contains(neighbor) { cleaned.insert(neighbor) }
            }
        }
        if crackStones { hit.formUnion(blockers.filter { $0.value.kind == .stone }.keys) }
        for position in hit {
            blockers[position]?.hits -= 1
            if (blockers[position]?.hits ?? 0) <= 0 {
                blockers[position] = nil
                result.freed.insert(position)
                result.brokenBlockers += 1
            }
        }
        if !cleaned.isEmpty {
            goo.subtract(cleaned)
            gooClearedThisMove = true
            result.cleanedGoo = cleaned.count
        }
        let bagged = result.tiles.filter { board[$0.row][$0.col].bonusMoves > 0 }
        result.extraMoves = bagged.reduce(0) { $0 + board[$1.row][$1.col].bonusMoves }
        if result.extraMoves > 0 {
            moves += result.extraMoves
            sound(.extraMoves)
        }
        if !hit.isEmpty { sound(.blockerHit) } else if !cleaned.isEmpty { sound(.gooClean) }
        blockerBursts.formUnion(hit)
        gooBursts.formUnion(cleaned)
        bonusBursts.formUnion(bagged)
        if !hit.isEmpty || !cleaned.isEmpty || !bagged.isEmpty {
            Task {
                try? await Task.sleep(for: .milliseconds(650))
                blockerBursts.subtract(hit)
                gooBursts.subtract(cleaned)
                bonusBursts.subtract(bagged)
            }
        }
        return result
    }

    private func blockerName(_ kind: Blocker.Kind) -> String {
        switch kind {
        case .pot: "flowerpot"
        case .crate: "toy crate"
        case .stone: "garden stone"
        case .beetle: "beetle"
        }
    }

    private func blockerMessage(_ settled: Settled) -> String {
        settled.brokenBlockers == 1
            ? "Crunch! Henry cleared a blocker out of Leo's way."
            : "Crunch! Henry cleared \(settled.brokenBlockers) blockers out of Leo's way."
    }

    /// After each move, every beetle wanders one square, trading places with a Leo.
    /// It never lands somewhere that would make an instant match.
    private func moveBeetles() {
        for (position, beetle) in blockers.filter({ $0.value.kind == .beetle }) {
            let options = position.neighbors.filter { !isFixed($0) && board[$0.row][$0.col].powerUp == nil }.shuffled()
            for target in options {
                swap(position, target)
                blockers[position] = nil
                blockers[target] = beetle
                if matchInfo().positions.isEmpty { break }
                blockers[target] = nil
                blockers[position] = beetle
                swap(position, target)
            }
        }
    }

    /// Goo creeps onto one more Leo after any move that didn't clean some off.
    private func spreadGoo() {
        guard level.gooCells > 0, !goo.isEmpty, !gooClearedThisMove, goo.count < Self.maxGoo else { return }
        let options = goo.flatMap(\.neighbors).filter { !isFixed($0) && board[$0.row][$0.col].powerUp == nil }
        guard let target = options.randomElement() else { return }
        goo.insert(target)
        gooBursts.insert(target)
        Task {
            try? await Task.sleep(for: .milliseconds(650))
            gooBursts.remove(target)
        }
        message = gooIsFrosting
            ? "Splat! The frosting spread onto another Leo. Clean some off to stop it."
            : "Squelch! The mud spread onto another Leo. Clean some off to stop it."
    }

    /// Blockers can leave the board with no possible swap. Henry stirs things up for free.
    private func reshuffleStuckBoard() {
        for _ in 0..<12 {
            board = freshBoard()
            if possibleMove() != nil { break }
        }
        message = "Nothing could move, so Henry gave everyone a fresh spot."
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

    private func advanceQuietRoute(near positions: Set<Position>) -> Int {
        guard level.followsQuietRoute, quietProgress < quietRoute.count else { return 0 }
        let target = quietRoute[quietProgress]
        let reached = positions.contains { cleared in
            abs(cleared.row - target.row) <= 1 && abs(cleared.col - target.col) <= 1
        }
        guard reached else { return 0 }
        quietProgress += 1
        quietBursts.insert(target)
        Task {
            try? await Task.sleep(for: .milliseconds(650))
            quietBursts.remove(target)
        }
        return 1
    }

    /// The mower travels a separate outer loop. It adds motion and story pressure but never erases progress.
    private func advanceMower() {
        guard !mowerLoop.isEmpty else { return }
        mowerProgress = (mowerProgress + 1) % mowerLoop.count
        mowerBurst = true
        haptic(.soft)
        Task {
            try? await Task.sleep(for: .milliseconds(520))
            mowerBurst = false
        }
    }

    /// Each match on or beside a can or bag takes away one rattle. Once quiet, it is gone for good.
    private func hushNoise(near positions: Set<Position>) -> Int {
        guard level.quietsNoise else { return 0 }
        let touched = noisyObjects.keys.filter { object in
            positions.contains { abs($0.row - object.row) <= 1 && abs($0.col - object.col) <= 1 }
        }
        guard !touched.isEmpty else { return 0 }
        for position in touched {
            noisyObjects[position]?.hits -= 1
            if noisyObjects[position]?.hits ?? 0 <= 0 { noisyObjects[position] = nil }
        }
        let burst = Set(touched)
        noiseBursts.formUnion(burst)
        Task {
            try? await Task.sleep(for: .milliseconds(650))
            noiseBursts.subtract(burst)
        }
        return touched.count
    }

    /// A porch breeze: bags drift one square. Never adds noise or undoes progress.
    private func blowBreeze() {
        var moved = noisyObjects
        for (position, object) in noisyObjects where object.kind == .bag {
            let options = [(0, 1), (0, -1), (1, 0), (-1, 0)]
                .map { Position(row: position.row + $0.0, col: position.col + $0.1) }
                .filter { $0.isValid && moved[$0] == nil }
            guard let target = options.randomElement() else { continue }
            moved[position] = nil
            moved[target] = object
        }
        noisyObjects = moved
        let lines = [
            "Whoosh! A breeze rattles the porch. Henry stays in front of Leo.",
            "Flap, flap! Leo ducks behind Henry until the gust settles.",
            "The wind tugs at the bags. Henry keeps an ear on every one."
        ]
        message = lines[(movesMade / max(1, level.breezeEvery) - 1) % lines.count]
        breezeGust = true
        haptic(.soft)
        Task {
            try? await Task.sleep(for: .milliseconds(520))
            breezeGust = false
        }
    }

    /// Any match on or beside a splash dries it. More splashes arrive until the level's count is used up.
    private func drySplashes(near positions: Set<Position>) -> Int {
        guard level.keepsLeoDry else { return 0 }
        let touched = splashes.filter { splash in
            positions.contains { abs($0.row - splash.row) <= 1 && abs($0.col - splash.col) <= 1 }
        }
        guard !touched.isEmpty else { return 0 }
        splashes.subtract(touched)
        splashesCleared += touched.count
        dryBursts.formUnion(touched)
        Task {
            try? await Task.sleep(for: .milliseconds(650))
            dryBursts.subtract(touched)
        }
        if splashes.isEmpty, splashesSpawned < level.splashCount { spawnSplash() }
        return touched.count
    }

    /// Splashes creep one row toward Leo's towel. Henry nudges any that would reach it back to the pool edge.
    /// Never removes progress.
    private func creepSplashes() {
        var moved = Set<Position>()
        var nudged = Set<Position>()
        for splash in splashes.sorted(by: { $0.row > $1.row }) {
            let next = Position(row: splash.row + 1, col: splash.col)
            if next.row >= Self.size - 1 {
                let home = Position(row: 0, col: splash.col)
                let target = moved.contains(home) ? splash : home
                moved.insert(target)
                if target == home { nudged.insert(home) }
            } else {
                moved.insert(moved.contains(next) ? splash : next)
            }
        }
        splashes = moved
        if splashesSpawned < level.splashCount, splashes.count < 4 { spawnSplash() }
        if !nudged.isEmpty {
            message = "Henry hopped in front of Leo and nudged the splash back to the pool!"
            nudgeBursts.formUnion(nudged)
            Task {
                try? await Task.sleep(for: .milliseconds(800))
                nudgeBursts.subtract(nudged)
            }
        } else {
            let lines = [
                "Drip, drip. The splashes inch closer. Henry keeps watch.",
                "Leo lifts one paw off the wet deck. Henry stands on the pool side.",
                "A wave sloshes over the edge. Henry is ready."
            ]
            message = lines[(movesMade / max(1, level.splashEvery) - 1) % lines.count]
        }
        haptic(.soft)
    }

    private func spawnSplash() {
        let columns = [1, 6, 3, 4, 0, 7, 2, 5]
        let open = columns.map { Position(row: 0, col: $0) }.filter { !splashes.contains($0) }
        guard splashesSpawned < level.splashCount,
              let spot = open.first(where: { $0.col == columns[splashesSpawned % columns.count] }) ?? open.first
        else { return }
        splashes.insert(spot)
        splashesSpawned += 1
    }

    /// Parcels ride downward with cleared spaces in their columns and are delivered at the bottom row.
    private func dropParcels(afterClearing positions: Set<Position>) -> Int {
        guard level.deliversParcels else { return 0 }
        var next = Set<Position>()
        var deliveredAt = Set<Position>()
        for parcel in parcels {
            let spacesBelow = positions.filter { $0.col == parcel.col && $0.row > parcel.row }.count
            let target = Position(row: min(Self.size - 1, parcel.row + spacesBelow), col: parcel.col)
            if target.row == Self.size - 1 {
                deliveredAt.insert(target)
            } else {
                next.insert(target)
            }
        }
        parcels = next
        parcelsDelivered += deliveredAt.count
        parcelBursts.formUnion(deliveredAt)
        if !deliveredAt.isEmpty {
            Task {
                try? await Task.sleep(for: .milliseconds(800))
                parcelBursts.subtract(deliveredAt)
            }
        }
        return deliveredAt.count
    }

    /// Birthday bustle: a soft glow and a reassuring line from Henry. Never undoes progress.
    private func popPartyCommotion() {
        let lines = [
            "Pop! A balloon squeaks. Leo hides behind Henry.",
            "Everyone sings at once. Henry leans against Leo until it's over.",
            "Confetti everywhere! Henry sniffs it to show Leo it's only paper."
        ]
        message = lines[(movesMade / max(1, level.partyEvery) - 1) % lines.count]
        partyPop = true
        haptic(.soft)
        sound(.party)
        Task {
            try? await Task.sleep(for: .milliseconds(600))
            partyPop = false
        }
    }

    private func ringDoorbell() {
        let lines = [
            "Knock, knock! Leo ducks low. Henry stays beside him.",
            "The doorbell rings. Henry checks the door while Leo watches from the couch.",
            "Footsteps on the mat! Henry shows Leo there is nothing to fear."
        ]
        message = lines[(movesMade / max(1, level.knockEvery) - 1) % lines.count]
        doorKnock = true
        haptic(.soft)
        sound(.knock)
        Task {
            try? await Task.sleep(for: .milliseconds(600))
            doorKnock = false
        }
    }

    /// Leafy patches may take one or two nearby matches. Revealed objects stay visible briefly.
    private func revealClues(near positions: Set<Position>) -> Int {
        guard level.findsClues else { return 0 }
        let touched = hiddenClues.keys.filter { clue in
            positions.contains { abs($0.row - clue.row) <= 1 && abs($0.col - clue.col) <= 1 }
        }
        guard !touched.isEmpty else { return 0 }
        var found: [Position: ClueKind] = [:]
        for position in touched {
            hiddenClues[position]?.cover -= 1
            if let clue = hiddenClues[position], clue.cover <= 0 {
                found[position] = clue.kind
                hiddenClues[position] = nil
            }
        }
        clueBursts.merge(found) { _, newest in newest }
        if !found.isEmpty {
            Task {
                try? await Task.sleep(for: .milliseconds(900))
                for position in found.keys { clueBursts[position] = nil }
            }
        }
        return found.count
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
        sound(.thunder)
        Task {
            try? await Task.sleep(for: .milliseconds(450))
            thunderFlash = false
        }
    }

    private func win() {
#if DEBUG
        if isDeveloperPreview {
            showingWin = true
            message = "Practice run complete — saved progress was not changed."
            lastWinEarnedTreat = false
            haptic(.success)
            return
        }
#endif
        lastWinEarnedTreat = completedLevelIDs.insert(level.id).inserted
        wins = completedLevelIDs.count
        unlocked = min(Self.levels.count, max(unlocked, levelIndex + 2))
        saveProgress(currentLevel: min(levelIndex + 1, unlocked - 1))
        showingWin = true
        haptic(.success)
        sound(.win)
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

    private func consume(_ requested: Set<StartingBooster>) -> Set<StartingBooster> {
        var consumed = Set<StartingBooster>()
        for booster in requested {
            switch booster {
            case .rocket where rocketBoosters > 0:
                rocketBoosters -= 1
                consumed.insert(booster)
            case .gardenBomb where gardenBombBoosters > 0:
                gardenBombBoosters -= 1
                consumed.insert(booster)
            case .rainbowPaw where rainbowPawBoosters > 0:
                rainbowPawBoosters -= 1
                consumed.insert(booster)
            default:
                break
            }
        }
        if !consumed.isEmpty { saveBoosterInventory() }
        return consumed
    }

    private func placeStartingBoosters(_ boosters: Set<StartingBooster>) {
        var open = (0..<(Self.size * Self.size)).map { Position(row: $0 / Self.size, col: $0 % Self.size) }.filter { !isFixed($0) }.shuffled()
        for booster in StartingBooster.allCases where boosters.contains(booster) {
            guard let position = open.popLast() else { break }
            switch booster {
            case .rocket:
                board[position.row][position.col].powerUp = Bool.random() ? .rowRocket : .columnRocket
            case .gardenBomb:
                board[position.row][position.col].powerUp = .gardenBomb
            case .rainbowPaw:
                board[position.row][position.col].powerUp = .rainbowPaw
            }
        }
        if !boosters.isEmpty { message = "Henry packed \(boosters.count) starting booster\(boosters.count == 1 ? "" : "s") for this level!" }
    }

    private func saveBoosterInventory() {
        let defaults = UserDefaults.standard
        defaults.set(rocketBoosters, forKey: "boosterInventory.rocket")
        defaults.set(gardenBombBoosters, forKey: "boosterInventory.gardenBomb")
        defaults.set(rainbowPawBoosters, forKey: "boosterInventory.rainbowPaw")
    }

    private func saveProgress(currentLevel: Int? = nil) {
        let defaults = UserDefaults.standard
        defaults.set(Array(completedLevelIDs).sorted(), forKey: "progress.completedLevelIDs")
        defaults.set(wins, forKey: "gardenWins")
        defaults.set(unlocked, forKey: "unlockedLevels")
        if unlocked > 0 {
            defaults.set(Self.levels[unlocked - 1].id, forKey: "progress.highestUnlockedLevelID")
        }
        if let currentLevel { saveCurrentLevel(currentLevel) }
    }

    private func saveCurrentLevel(_ index: Int? = nil) {
        let selectedIndex = min(max(index ?? levelIndex, 0), Self.levels.count - 1)
        let defaults = UserDefaults.standard
        defaults.set(Self.levels[selectedIndex].id, forKey: "progress.currentLevelID")
        defaults.set(selectedIndex, forKey: "currentLevel")
    }

    private func saveClaimedBasketLevels() {
        let defaults = UserDefaults.standard
        defaults.set(Array(claimedBasketLevelIDs).sorted(), forKey: "boosterBasket.claimedLevelIDs")
        let legacyIndices = Self.levels.indices.filter { claimedBasketLevelIDs.contains(Self.levels[$0].id) }
        defaults.set(legacyIndices, forKey: "boosterBasket.claimedLevels")
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

    private func freshQuietRoute() -> [Position] {
        guard level.followsQuietRoute else { return [] }
        let path: [Position] = [
            .init(row: 7, col: 0), .init(row: 6, col: 0), .init(row: 6, col: 1),
            .init(row: 5, col: 1), .init(row: 5, col: 2), .init(row: 6, col: 2),
            .init(row: 6, col: 3), .init(row: 5, col: 3), .init(row: 5, col: 4),
            .init(row: 6, col: 4), .init(row: 6, col: 5), .init(row: 5, col: 5),
            .init(row: 5, col: 6), .init(row: 6, col: 6), .init(row: 6, col: 7),
            .init(row: 5, col: 7)
        ]
        return Array(path.prefix(level.quietRouteSteps))
    }

    private func freshMowerLoop() -> [Position] {
        guard level.mowerEvery > 0 else { return [] }
        return [
            .init(row: 0, col: 7), .init(row: 0, col: 6), .init(row: 0, col: 5),
            .init(row: 0, col: 4), .init(row: 0, col: 3), .init(row: 0, col: 2),
            .init(row: 0, col: 1), .init(row: 0, col: 0), .init(row: 1, col: 0),
            .init(row: 2, col: 0), .init(row: 3, col: 0), .init(row: 3, col: 1),
            .init(row: 3, col: 2), .init(row: 3, col: 3), .init(row: 3, col: 4),
            .init(row: 3, col: 5), .init(row: 3, col: 6), .init(row: 3, col: 7),
            .init(row: 2, col: 7), .init(row: 1, col: 7)
        ]
    }

    private func freshNoisyObjects() -> [Position: NoisyObject] {
        guard level.quietsNoise else { return [:] }
        let cans: [Position] = [
            .init(row: 4, col: 1), .init(row: 4, col: 6), .init(row: 2, col: 3), .init(row: 6, col: 4),
            .init(row: 1, col: 1), .init(row: 1, col: 6), .init(row: 6, col: 1), .init(row: 6, col: 6),
            .init(row: 3, col: 4), .init(row: 5, col: 3)
        ]
        // Bags blow in from the bin on the right, like the chapter backdrop.
        let bags: [Position] = [
            .init(row: 0, col: 6), .init(row: 2, col: 7), .init(row: 1, col: 4),
            .init(row: 3, col: 6), .init(row: 0, col: 2), .init(row: 4, col: 4)
        ]
        var result: [Position: NoisyObject] = [:]
        for position in cans.prefix(level.canCells) { result[position] = .init(kind: .can, hits: max(1, level.canDepth)) }
        for position in bags.prefix(level.bagCells) { result[position] = .init(kind: .bag, hits: 1) }
        return result
    }

    private func freshHiddenClues() -> [Position: HiddenClue] {
        guard level.findsClues else { return [:] }
        let pattern: [Position] = [
            .init(row: 1, col: 1), .init(row: 1, col: 6), .init(row: 6, col: 1),
            .init(row: 6, col: 6), .init(row: 3, col: 3), .init(row: 4, col: 4),
            .init(row: 2, col: 5), .init(row: 5, col: 2), .init(row: 2, col: 2),
            .init(row: 5, col: 5), .init(row: 3, col: 6), .init(row: 4, col: 1)
        ]
        var result: [Position: HiddenClue] = [:]
        for (index, position) in pattern.prefix(level.clueCells).enumerated() {
            result[position] = .init(kind: ClueKind.allCases[index % ClueKind.allCases.count], cover: max(1, level.clueDepth))
        }
        return result
    }

    /// Places the level's blockers on fixed spots, skipping any cell an objective already uses.
    /// Parcel levels stay blocker-free because parcels slide down whole columns.
    private func freshBlockers() -> [Position: Blocker] {
        guard !level.deliversParcels else { return [:] }
        var taken = objectiveCells()
        var result: [Position: Blocker] = [:]
        func place(_ pattern: [Position], count: Int, _ blocker: Blocker) {
            for position in pattern.filter({ !taken.contains($0) }).prefix(count) {
                result[position] = blocker
                taken.insert(position)
            }
        }
        place([.init(row: 3, col: 3), .init(row: 3, col: 4), .init(row: 4, col: 3), .init(row: 4, col: 4),
               .init(row: 1, col: 1), .init(row: 1, col: 6), .init(row: 6, col: 1), .init(row: 6, col: 6),
               .init(row: 0, col: 0), .init(row: 0, col: 7)],
              count: level.crateCells, .init(kind: .crate, hits: max(2, level.crateDepth)))
        place([.init(row: 4, col: 0), .init(row: 3, col: 7), .init(row: 7, col: 3), .init(row: 7, col: 4),
               .init(row: 2, col: 0), .init(row: 5, col: 7), .init(row: 0, col: 2), .init(row: 0, col: 5)],
              count: level.stoneCells, .init(kind: .stone, hits: max(1, level.stoneDepth)))
        place([.init(row: 2, col: 2), .init(row: 2, col: 5), .init(row: 5, col: 2), .init(row: 5, col: 5),
               .init(row: 0, col: 3), .init(row: 0, col: 4), .init(row: 7, col: 0), .init(row: 7, col: 7),
               .init(row: 3, col: 0), .init(row: 4, col: 7)],
              count: level.potCells, .init(kind: .pot, hits: 1))
        place([.init(row: 1, col: 3), .init(row: 6, col: 4), .init(row: 2, col: 6), .init(row: 5, col: 1)],
              count: level.beetleCount, .init(kind: .beetle, hits: 1))
        return result
    }

    private func freshGoo() -> Set<Position> {
        guard level.gooCells > 0, !level.deliversParcels else { return [] }
        let taken = objectiveCells().union(blockers.keys)
        let pattern: [Position] = [
            .init(row: 7, col: 0), .init(row: 7, col: 7), .init(row: 0, col: 0), .init(row: 0, col: 7),
            .init(row: 7, col: 1), .init(row: 7, col: 6), .init(row: 6, col: 0), .init(row: 6, col: 7)
        ]
        return Set(pattern.filter { !taken.contains($0) }.prefix(level.gooCells))
    }

    /// Cells an objective marks, so blockers and goo never sit on top of them.
    private func objectiveCells() -> Set<Position> {
        var cells = Set<Position>()
        for row in 0..<Self.size { for col in 0..<Self.size where dustLayers[row][col] > 0 { cells.insert(.init(row: row, col: col)) } }
        cells.formUnion(sleepingLeos)
        cells.formUnion(rescuePath)
        cells.formUnion(quietRoute)
        cells.formUnion(cozyCells)
        cells.formUnion(noisyObjects.keys)
        cells.formUnion(hiddenClues.keys)
        if level.spreadsComfort {
            // Leave the blanket room to grow from the bottom center.
            for row in 5..<Self.size { for col in 2...5 { cells.insert(.init(row: row, col: col)) } }
        }
        if level.keepsLeoDry {
            for col in 2...5 { cells.insert(.init(row: Self.size - 1, col: col)) }
        }
        return cells
    }

    private func freshParcels() -> Set<Position> {
        guard level.deliversParcels else { return [] }
        let columns = [1, 6, 3, 4, 0, 7]
        return Set(columns.prefix(level.parcelCount).map { Position(row: 0, col: $0) })
    }

    private func matchInfo() -> MatchInfo {
        var info = MatchInfo()
        for row in 0..<Self.size {
            var start = 0
            for col in 1...Self.size {
                if col == Self.size || !matchable(.init(row: row, col: col), .init(row: row, col: col - 1)) {
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
                if row == Self.size || !matchable(.init(row: row, col: col), .init(row: row - 1, col: col)) {
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

    /// Two neighbors can be part of the same run: same Leo, and neither is a blocker.
    private func matchable(_ a: Position, _ b: Position) -> Bool {
        blockers[a] == nil && blockers[b] == nil && board[a.row][a.col].veggie == board[b.row][b.col].veggie
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
            for next in [Position(row: row, col: col + 1), Position(row: row + 1, col: col)] where next.isValid && !isFixed(here) && !isFixed(next) {
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
        for row in 0..<Self.size { for col in 0..<Self.size where board[row][col].veggie == veggie && blockers[.init(row: row, col: col)] == nil {
            result.append(.init(row: row, col: col))
        } }
        return result
    }

    private func swap(_ a: Position, _ b: Position) { board.swapAt(a, b) }

    private func sound(_ effect: GameAudio.Effect) {
        guard soundOn else { return }
        GameAudio.shared.play(effect)
    }

    private func powerUpSound(for kinds: [PowerUp]) -> GameAudio.Effect {
        if kinds.contains(.rainbowPaw) { return .rainbowPaw }
        if kinds.contains(.gardenBomb) { return .gardenBomb }
        return .rocket
    }

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
    /// The up-to-four cells sharing an edge with this one.
    var neighbors: [Position] {
        [Position(row: row - 1, col: col), Position(row: row + 1, col: col),
         Position(row: row, col: col - 1), Position(row: row, col: col + 1)].filter(\.isValid)
    }
}

private extension Array where Element == [Tile] {
    mutating func swapAt(_ a: Position, _ b: Position) {
        let temp = self[a.row][a.col]
        self[a.row][a.col] = self[b.row][b.col]
        self[b.row][b.col] = temp
    }
}
