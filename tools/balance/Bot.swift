import Foundation

@MainActor
struct Bot {
    let game: GameModel

    /// Cells whose involvement in a match helps the current goal.
    func targets() -> (cells: Set<Position>, goal: Veggie?) {
        var cells = Set<Position>()
        func around(_ p: Position) { cells.insert(p); cells.formUnion(p.neighbors) }
        for r in 0..<8 { for c in 0..<8 where game.dustLayers[r][c] > 0 { cells.insert(.init(row: r, col: c)) } }
        game.sleepingLeos.forEach { cells.formUnion($0.neighbors) }
        if game.rescueProgress < game.rescuePath.count { around(game.rescuePath[game.rescueProgress]) }
        if game.quietProgress < game.quietRoute.count { around(game.quietRoute[game.quietProgress]) }
        if game.level.spreadsComfort { cells.formUnion(game.comfortFrontier()) }
        game.noisyObjects.keys.forEach(around)
        game.hiddenClues.keys.forEach(around)
        game.splashes.forEach(around)
        for p in game.parcels { for r in (p.row + 1)..<8 { cells.insert(.init(row: r, col: p.col)) } }
        for (p, b) in game.blockers where b.breaksFromNearbyMatches { cells.formUnion(p.neighbors) }
        game.goo.forEach(around)
        let collecting = game.level.amount > 0 && game.collected < game.level.amount
        return (cells, collecting ? game.level.goal : nil)
    }

    func choose() -> (Position, Position)? {
        let (cells, goal) = targets()
        var best: (Double, Position, Position)?
        for r in 0..<8 { for c in 0..<8 {
            let a = Position(row: r, col: c)
            for b in [Position(row: r, col: c + 1), Position(row: r + 1, col: c)] where b.isValid {
                guard !game.isFixed(a), !game.isFixed(b) else { continue }
                var score: Double
                let ups = [a, b].filter { game.board[$0.row][$0.col].powerUp != nil }.count
                if ups > 0 {
                    score = Double(ups) * 9
                } else {
                    game.swap(a, b)
                    let m = game.matchInfo()
                    game.swap(a, b)
                    guard !m.positions.isEmpty else { continue }
                    let hits = m.positions.filter { cells.contains($0) }.count
                    let goals = goal.map { g in m.positions.filter { game.board[$0.row][$0.col].veggie == g }.count } ?? 0
                    score = Double(m.positions.count) + Double(hits) * 2.5 + Double(goals) * 2
                    if m.positions.count >= 4 { score += 4 }
                }
                score += Double.random(in: 0..<1.5)
                if best == nil || score > best!.0 { best = (score, a, b) }
            }
        } }
        return best.map { ($0.1, $0.2) }
    }
}

@main
struct Main {
    @MainActor static func main() async {
        let args = CommandLine.arguments
        let trials = args.count > 1 ? Int(args[1])! : 30
        let only = args.count > 2 ? Int(args[2]) : nil
        let real = args.count > 3
        let game = GameModel()
        game.soundOn = false
        for index in (only.map { [$0] } ?? Array(0..<GameModel.levels.count)) {
            let original = GameModel.levels[index].moves
            let cap = real ? original : 120
            GameModel.levels[index].moves = cap
            var used: [Int] = []
            for _ in 0..<trials {
                game.startDeveloperPreview(level: index)
                var guardSteps = 0
                while !game.objectiveComplete, game.moves > 0, guardSteps < 400 {
                    guardSteps += 1
                    if let (a, b) = Bot(game: game).choose() {
                        await game.attemptSwap(a, b)
                    } else {
                        game.shuffle()
                    }
                    for _ in 0..<20 { await Task.yield() }
                }
                used.append(game.objectiveComplete ? cap - game.moves : 999)
            }
            used.sort()
            func pct(_ p: Double) -> Int { used[min(used.count - 1, Int(Double(used.count) * p))] }
            print("\(index + 1)\tnow \(original)\tch\(GameModel.levels[index].chapterIndex + 1)\tP50 \(pct(0.5))\tP60 \(pct(0.6))\tP75 \(pct(0.75))\tP90 \(pct(0.9))\tfail \(used.filter { $0 == 999 }.count)\twin% \(100 * used.filter { $0 != 999 }.count / used.count)")
        }
    }
}
