import Foundation

/// In-memory stand-in so the simulation never touches real preferences.
final class SimDefaults {
    static let standard = SimDefaults()
    private var store: [String: Any] = [:]
    func set(_ value: Any?, forKey key: String) { store[key] = value }
    func integer(forKey key: String) -> Int { store[key] as? Int ?? 0 }
    func bool(forKey key: String) -> Bool { store[key] as? Bool ?? false }
    func object(forKey key: String) -> Any? { store[key] }
    func array(forKey key: String) -> [Any]? { store[key] as? [Any] }
    func dictionary(forKey key: String) -> [String: Any]? { store[key] as? [String: Any] }
    func removeObject(forKey key: String) { store[key] = nil }
}

final class UINotificationFeedbackGenerator {
    enum FeedbackType { case success, warning, error }
    func notificationOccurred(_ kind: FeedbackType) {}
}
final class UIImpactFeedbackGenerator {
    enum FeedbackStyle { case light, medium, heavy, soft, rigid }
    init(style: FeedbackStyle) {}
    func impactOccurred() {}
}

final class GameAudio {
    static let shared = GameAudio()
    enum Effect { case select, nope, pop(combo: Int), powerUpMade, rocket, gardenBomb, rainbowPaw, water, shuffle, win, thunder, knock, party, yardBuild, yardStyle, extraMoves, blockerHit, gooClean, outOfMoves }
    func play(_ effect: Effect) {}
}

enum Yard {
    struct Spot { let cost: Int; let styles: [Int] }
    static func spot(_ id: String) -> Spot? { nil }
}
extension GameModel { var treats: Int { 0 } }
