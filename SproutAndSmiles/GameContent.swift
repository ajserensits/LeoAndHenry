import Foundation

enum GameContentLoader {
    struct Content {
        let levels: [Level]
        let chapters: [Chapter]
    }

    private struct Manifest: Decodable {
        let formatVersion: Int
        let chapters: [String]
    }

    private struct ChapterFile: Decodable {
        let id: String
        let title: String
        let subtitle: String
        let backgroundName: String
        let symbol: String
        let levels: [LevelFile]
    }

    private struct LevelFile: Decodable {
        let id: String
        let goal: Veggie
        let amount: Int
        let moves: Int
        let title: String
        let stolenItem: String
        let clue: String
        let dustCells: Int?
        let dustDepth: Int?
        let sleepingCells: Int?
        let rescueSteps: Int?
        let comfortCells: Int?
        let thunderEvery: Int?
        let quietRouteSteps: Int?
        let mowerEvery: Int?
        let canCells: Int?
        let canDepth: Int?
        let bagCells: Int?
        let breezeEvery: Int?
        let clueCells: Int?
        let clueDepth: Int?
        let splashCount: Int?
        let splashEvery: Int?
        let parcelCount: Int?
        let knockEvery: Int?
        let parcelIsPad: Bool?
        let partyEvery: Int?
        let potCells: Int?
        let crateCells: Int?
        let crateDepth: Int?
        let stoneCells: Int?
        let stoneDepth: Int?
        let beetleCount: Int?
        let gooCells: Int?

        func level(chapterID: String, chapterIndex: Int) -> Level {
            Level(
                id: id,
                chapterID: chapterID,
                goal: goal,
                amount: amount,
                moves: moves,
                title: title,
                stolenItem: stolenItem,
                clue: clue,
                chapterIndex: chapterIndex,
                dustCells: dustCells ?? 0,
                dustDepth: dustDepth ?? 0,
                sleepingCells: sleepingCells ?? 0,
                rescueSteps: rescueSteps ?? 0,
                comfortCells: comfortCells ?? 0,
                thunderEvery: thunderEvery ?? 0,
                quietRouteSteps: quietRouteSteps ?? 0,
                mowerEvery: mowerEvery ?? 0,
                canCells: canCells ?? 0,
                canDepth: canDepth ?? 1,
                bagCells: bagCells ?? 0,
                breezeEvery: breezeEvery ?? 0,
                clueCells: clueCells ?? 0,
                clueDepth: clueDepth ?? 1,
                splashCount: splashCount ?? 0,
                splashEvery: splashEvery ?? 0,
                parcelCount: parcelCount ?? 0,
                knockEvery: knockEvery ?? 0,
                parcelIsPad: parcelIsPad ?? false,
                partyEvery: partyEvery ?? 0,
                potCells: potCells ?? 0,
                crateCells: crateCells ?? 0,
                crateDepth: crateDepth ?? 2,
                stoneCells: stoneCells ?? 0,
                stoneDepth: stoneDepth ?? 1,
                beetleCount: beetleCount ?? 0,
                gooCells: gooCells ?? 0
            )
        }
    }

    static func load(bundle: Bundle = .main) -> Content {
        do {
            let manifest: Manifest = try decode("chapters.json", from: bundle)
            guard manifest.formatVersion == 1 else {
                throw ContentError("Unsupported content format version \(manifest.formatVersion).")
            }
            guard !manifest.chapters.isEmpty else {
                throw ContentError("The chapter manifest is empty.")
            }

            var levels: [Level] = []
            var chapters: [Chapter] = []
            var chapterIDs = Set<String>()
            var levelIDs = Set<String>()

            for filename in manifest.chapters {
                let chapterDefinition: ChapterFile = try decode(filename, from: bundle)
                guard chapterIDs.insert(chapterDefinition.id).inserted else {
                    throw ContentError("Duplicate chapter ID: \(chapterDefinition.id).")
                }
                guard !chapterDefinition.levels.isEmpty else {
                    throw ContentError("Chapter \(chapterDefinition.id) has no levels.")
                }

                let chapterIndex = chapters.count
                let firstLevel = levels.count
                for levelDefinition in chapterDefinition.levels {
                    guard levelIDs.insert(levelDefinition.id).inserted else {
                        throw ContentError("Duplicate level ID: \(levelDefinition.id).")
                    }
                    guard levelDefinition.moves > 0, levelDefinition.amount >= 0 else {
                        throw ContentError("Level \(levelDefinition.id) has invalid moves or amount.")
                    }
                    levels.append(levelDefinition.level(chapterID: chapterDefinition.id, chapterIndex: chapterIndex))
                }
                chapters.append(
                    Chapter(
                        id: chapterDefinition.id,
                        title: chapterDefinition.title,
                        subtitle: chapterDefinition.subtitle,
                        backgroundName: chapterDefinition.backgroundName,
                        symbol: chapterDefinition.symbol,
                        levelRange: firstLevel..<levels.count
                    )
                )
            }

            return Content(levels: levels, chapters: chapters)
        } catch {
            fatalError("Unable to load game content: \(error.localizedDescription)")
        }
    }

    private static func decode<T: Decodable>(_ filename: String, from bundle: Bundle) throws -> T {
        guard let url = bundle.url(forResource: filename, withExtension: nil) else {
            throw ContentError("Missing bundled content file: \(filename).")
        }
        do {
            return try JSONDecoder().decode(T.self, from: Data(contentsOf: url))
        } catch {
            throw ContentError("Could not decode \(filename): \(error.localizedDescription)")
        }
    }

    private struct ContentError: LocalizedError {
        let message: String
        init(_ message: String) { self.message = message }
        var errorDescription: String? { message }
    }

}
