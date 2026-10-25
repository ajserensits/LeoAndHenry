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
        .init(goal: .pea, amount: 40, moves: 20, title: "The Garden Feast", stolenItem: "celebration supper", clue: "One last chase before the brothers share.")
    ]

    @Published var board: [[Tile]] = []
    @Published var levelIndex = 0
    @Published var moves = 0
    @Published var collected = 0
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

    var level: Level { Self.levels[levelIndex] }

    init() {
        let defaults = UserDefaults.standard
        unlocked = max(1, defaults.integer(forKey: "unlockedLevels"))
        wins = defaults.integer(forKey: "gardenWins")
        soundOn = defaults.object(forKey: "soundOn") == nil ? true : defaults.bool(forKey: "soundOn")
        let savedLevel = min(max(0, defaults.integer(forKey: "currentLevel")), unlocked - 1)
        start(level: savedLevel)
    }

    func start(level requested: Int) {
        levelIndex = min(max(requested, 0), unlocked - 1)
        moves = level.moves
        collected = 0
        selected = nil
        showingWin = false
        board = freshBoard()
        message = level.clue
        UserDefaults.standard.set(levelIndex, forKey: "currentLevel")
    }

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
        let candidates = positions(of: level.goal).shuffled().prefix(5)
        guard !candidates.isEmpty else { return }
        Task {
            isBusy = true
            await clear(Array(candidates))
            if collected >= level.amount { win() }
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

    func continueGarden() { start(level: min(levelIndex + 1, unlocked - 1)) }

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
        if collected >= level.amount { win() }
        else if moves <= 0 {
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
            if let creation {
                message = creationMessage(creation.kind)
                haptic(.success)
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
        message = positions.contains { board[$0.row][$0.col].powerUp == .rainbowPaw }
            ? "Rainbow paw! Every matching Leo joins the chase!"
            : "Power-up! The garden is flying!"
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
        message = "A little rain works wonders."
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

    private func win() {
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
