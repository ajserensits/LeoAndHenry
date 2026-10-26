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
        .init(goal: .pea, amount: 0, moves: 24, title: "Sharing the Blanket", stolenItem: "shared blanket", clue: "The storm passes. Spread the blanket wide enough for two.", chapterIndex: 3, comfortCells: 40, thunderEvery: 8),

        .init(goal: .carrot, amount: 20, moves: 25, title: "Ball Behind the Marigolds", stolenItem: "orange outdoor ball", clue: "Leo borrowed Henry's ball—and the mower just started across the yard.", chapterIndex: 4, mowerEvery: 4),
        .init(goal: .tomato, amount: 0, moves: 25, title: "The Quiet Edge", stolenItem: "first safe pawsteps", clue: "Match beside the glowing leaf so Henry can show Leo the quiet way.", chapterIndex: 4, quietRouteSteps: 6, mowerEvery: 3),
        .init(goal: .onion, amount: 0, moves: 24, title: "Past the Flowerpots", stolenItem: "flowerpot hiding place", clue: "Henry leads past the marigolds while the mower loops far away.", chapterIndex: 4, quietRouteSteps: 8, mowerEvery: 3),
        .init(goal: .pepper, amount: 24, moves: 24, title: "Grass-Clipping Gust", stolenItem: "windblown ball", clue: "A puff of clippings rolls by. Henry stays between Leo and the noise.", chapterIndex: 4, mowerEvery: 3),
        .init(goal: .eggplant, amount: 0, moves: 23, title: "Henry Leads the Way", stolenItem: "shady side path", clue: "Follow Henry's leafy trail along the quiet side of the lawn.", chapterIndex: 4, quietRouteSteps: 10, mowerEvery: 2),
        .init(goal: .pea, amount: 0, moves: 23, title: "Leo Freezes", stolenItem: "brave little pause", clue: "The mower sounds close. Henry gives a gentle bark to get Leo moving.", chapterIndex: 4, sleepingCells: 8, mowerEvery: 2),
        .init(goal: .tomato, amount: 0, moves: 22, title: "Around the Hydrangeas", stolenItem: "hydrangea shortcut", clue: "The long way is the calm way. Keep following Henry's safe leaves.", chapterIndex: 4, quietRouteSteps: 12, mowerEvery: 2),
        .init(goal: .carrot, amount: 28, moves: 22, title: "The Orange Ball", stolenItem: "Henry's outdoor ball", clue: "The ball tumbles free, but Henry will not leave Leo behind.", chapterIndex: 4, mowerEvery: 3),
        .init(goal: .onion, amount: 0, moves: 23, title: "Almost Back to Mom", stolenItem: "path toward Mom", clue: "Mom is waiting by the gate. Henry knows the safest loop home.", chapterIndex: 4, quietRouteSteps: 14, mowerEvery: 2),
        .init(goal: .pea, amount: 0, moves: 25, title: "Home Along the Hedge", stolenItem: "shared orange ball", clue: "One last quiet stretch, then the brothers can bring the ball back together.", chapterIndex: 4, quietRouteSteps: 16, mowerEvery: 2),

        .init(goal: .pea, amount: 22, moves: 25, title: "Snack Bowl Snoop", stolenItem: "Henry's snack bowl", clue: "Leo is sniffing Henry's snack bowl—and the porch breeze is picking up.", chapterIndex: 5, breezeEvery: 5),
        .init(goal: .tomato, amount: 0, moves: 25, title: "The First Clatter", stolenItem: "tipped-over can", clue: "Cans rolled out of the bin. Match beside them so Henry can nudge them quiet.", chapterIndex: 5, canCells: 6),
        .init(goal: .carrot, amount: 0, moves: 25, title: "The Flapping Bag", stolenItem: "brave sniff", clue: "A plastic bag flaps like a ghost. Henry shoos it away for Leo.", chapterIndex: 5, bagCells: 3, breezeEvery: 3),
        .init(goal: .onion, amount: 0, moves: 24, title: "Rattle and Roll", stolenItem: "rolling can", clue: "Some cans rattle twice before they settle down.", chapterIndex: 5, canCells: 7, canDepth: 2),
        .init(goal: .pepper, amount: 0, moves: 24, title: "Henry Stands Firm", stolenItem: "porch step", clue: "Henry plants his paws between Leo and the noise.", chapterIndex: 5, canCells: 6, bagCells: 3, breezeEvery: 3),
        .init(goal: .eggplant, amount: 0, moves: 24, title: "Back to the Bench", stolenItem: "bench hideout", clue: "Leo darted under the bench. Henry follows the paw prints to him.", chapterIndex: 5, rescueSteps: 9, breezeEvery: 4),
        .init(goal: .pea, amount: 0, moves: 23, title: "A Gust of Bags", stolenItem: "fluttering courage", clue: "Whoosh! More bags tumble across the porch. Henry chases each one off.", chapterIndex: 5, bagCells: 6, breezeEvery: 3),
        .init(goal: .tomato, amount: 0, moves: 23, title: "The Recycling Tumble", stolenItem: "tumbled bin", clue: "The whole bin tipped over. Henry clears the noisy path one can at a time.", chapterIndex: 5, canCells: 10, canDepth: 2),
        .init(goal: .carrot, amount: 0, moves: 23, title: "Almost Quiet", stolenItem: "quiet porch", clue: "Only a few clatters left. Leo peeks out from behind Henry.", chapterIndex: 5, canCells: 8, canDepth: 2, bagCells: 4, breezeEvery: 3),
        .init(goal: .pea, amount: 0, moves: 25, title: "Sharing the Snack", stolenItem: "shared snack", clue: "Quiet the last cans and bags, then Henry shares his snack with Leo.", chapterIndex: 5, canCells: 10, canDepth: 2, bagCells: 5, breezeEvery: 2),

        .init(goal: .carrot, amount: 22, moves: 25, title: "Crumbs at the Gate", stolenItem: "crumb trail", clue: "The brothers followed snack crumbs too far—and now they cannot see Mom.", chapterIndex: 6),
        .init(goal: .tomato, amount: 0, moves: 25, title: "Mom's Pink Slipper", stolenItem: "familiar slipper", clue: "Match beside the leafy patches. Henry smells something familiar underneath.", chapterIndex: 6, clueCells: 3),
        .init(goal: .onion, amount: 0, moves: 25, title: "Keys in the Flowers", stolenItem: "keys with the paw charm", clue: "A tiny jingle! Henry searches the flowers while Leo stays close.", chapterIndex: 6, clueCells: 4),
        .init(goal: .pepper, amount: 0, moves: 24, title: "Which Way, Henry?", stolenItem: "safe garden turn", clue: "Henry chooses the gentle path and makes sure Leo follows.", chapterIndex: 6, quietRouteSteps: 8),
        .init(goal: .eggplant, amount: 0, moves: 24, title: "Leaves over the Path", stolenItem: "hidden familiar things", clue: "Some clues are tucked beneath two layers of leaves.", chapterIndex: 6, clueCells: 6, clueDepth: 2),
        .init(goal: .pea, amount: 0, moves: 24, title: "Leo Starts to Worry", stolenItem: "a little reassurance", clue: "Henry gathers comforting signs of home and stays beside Leo.", chapterIndex: 6, comfortCells: 18),
        .init(goal: .tomato, amount: 0, moves: 23, title: "Familiar Footsteps", stolenItem: "Mom's footsteps", clue: "Slipper, keys, pawprints—every clue says they are heading home.", chapterIndex: 6, clueCells: 8, clueDepth: 2),
        .init(goal: .carrot, amount: 0, moves: 23, title: "The Porch Light", stolenItem: "warm light ahead", clue: "Henry spots the porch light and leads Leo toward it one pawstep at a time.", chapterIndex: 6, rescueSteps: 11),
        .init(goal: .onion, amount: 0, moves: 23, title: "Almost Home", stolenItem: "last garden clues", clue: "The cottage is close. Find the final familiar signs along the path.", chapterIndex: 6, clueCells: 10, clueDepth: 2),
        .init(goal: .pea, amount: 0, moves: 25, title: "There You Are, Mom!", stolenItem: "the way back to Mom", clue: "Henry follows every clue until Leo sees Mom waiting in the warm window.", chapterIndex: 6, clueCells: 12, clueDepth: 2),

        .init(goal: .tomato, amount: 22, moves: 25, title: "Leo Spots the Pool", stolenItem: "Henry's pool ring", clue: "Mom wants everyone outside by the pool. Leo grabbed Henry's ring and froze.", chapterIndex: 7),
        .init(goal: .carrot, amount: 0, moves: 25, title: "First Little Splash", stolenItem: "dry paws", clue: "Splashes creep from the pool. Match on or beside them before they reach Leo's towel.", chapterIndex: 7, splashCount: 5, splashEvery: 3),
        .init(goal: .onion, amount: 0, moves: 24, title: "The Dry Way", stolenItem: "dry stepping stones", clue: "Henry shows Leo the dry stones along the edge of the patio.", chapterIndex: 7, quietRouteSteps: 8),
        .init(goal: .pepper, amount: 0, moves: 24, title: "Cannonball Next Door", stolenItem: "splash-free corner", clue: "A neighbor's cannonball sends drops flying. Henry stays between Leo and the water.", chapterIndex: 7, splashCount: 7, splashEvery: 3),
        .init(goal: .eggplant, amount: 0, moves: 24, title: "Wet Paws, Brave Paws", stolenItem: "brave little step", clue: "The splashes come a little faster. Henry nudges back any that get too close.", chapterIndex: 7, splashCount: 8, splashEvery: 2),
        .init(goal: .pea, amount: 0, moves: 24, title: "Sunny Towel Nap", stolenItem: "warm towel", clue: "Leo dozed off on the warm towel. Henry gives gentle woofs to wake him.", chapterIndex: 7, sleepingCells: 8),
        .init(goal: .tomato, amount: 0, moves: 23, title: "Pool Toy Parade", stolenItem: "floating duck", clue: "Pool toys bob by and splash the deck. Keep Leo's towel dry.", chapterIndex: 7, splashCount: 9, splashEvery: 2),
        .init(goal: .carrot, amount: 0, moves: 23, title: "Between Leo and the Water", stolenItem: "path to Mom's chair", clue: "Henry walks on the pool side so Leo can walk on the dry side.", chapterIndex: 7, quietRouteSteps: 12),
        .init(goal: .onion, amount: 0, moves: 23, title: "The Big Splash", stolenItem: "Mom's sun hat", clue: "Mom dives in! Clear the big wave of splashes before it reaches Leo.", chapterIndex: 7, splashCount: 11, splashEvery: 2),
        .init(goal: .pea, amount: 0, moves: 25, title: "Dry and Proud", stolenItem: "shared pool ring", clue: "One last splash wave, then Leo hands Henry's ring back beside Mom's chair.", chapterIndex: 7, splashCount: 12, splashEvery: 2),

        .init(goal: .tomato, amount: 22, moves: 25, title: "Squeak at the Door", stolenItem: "Henry's red squeaky bug", clue: "Leo carried Henry's toy to the front door—just as someone unfamiliar arrived.", chapterIndex: 8, knockEvery: 4),
        .init(goal: .carrot, amount: 0, moves: 25, title: "A Box on the Mat", stolenItem: "first parcel", clue: "Clear matches beneath each parcel so it can travel safely down to the doormat.", chapterIndex: 8, parcelCount: 2, knockEvery: 4),
        .init(goal: .onion, amount: 0, moves: 24, title: "Knock, Knock!", stolenItem: "couch-cushion hideout", clue: "The knock startles Leo. Henry gives a gentle bark from their cozy viewing spot.", chapterIndex: 8, sleepingCells: 7, knockEvery: 3),
        .init(goal: .pepper, amount: 0, moves: 24, title: "Bring It Inside", stolenItem: "three little parcels", clue: "Make room below the boxes while Henry keeps watch by the door.", chapterIndex: 8, parcelCount: 3, knockEvery: 3),
        .init(goal: .eggplant, amount: 0, moves: 24, title: "The Cozy Viewing Spot", stolenItem: "safe route behind the couch", clue: "Henry shows Leo where they can watch without standing near the visitor.", chapterIndex: 8, quietRouteSteps: 9, knockEvery: 4),
        .init(goal: .pea, amount: 0, moves: 23, title: "Another Delivery", stolenItem: "stack of boxes", clue: "More parcels wait outside. Clear beneath them and bring every one to the mat.", chapterIndex: 8, parcelCount: 4, knockEvery: 3),
        .init(goal: .tomato, amount: 0, moves: 23, title: "Henry Stays Close", stolenItem: "shared couch blanket", clue: "Henry settles beside Leo until the footsteps at the door sound less scary.", chapterIndex: 8, comfortCells: 22, knockEvery: 3),
        .init(goal: .carrot, amount: 0, moves: 23, title: "Packages in the Hall", stolenItem: "five safe parcels", clue: "The hallway fills with boxes, but Henry knows exactly where each one belongs.", chapterIndex: 8, parcelCount: 5, knockEvery: 2),
        .init(goal: .onion, amount: 0, moves: 23, title: "The Visitor Leaves", stolenItem: "quiet front step", clue: "The footsteps fade. Henry checks the familiar clues that mean everything is safe.", chapterIndex: 8, clueCells: 8, clueDepth: 2, knockEvery: 4),
        .init(goal: .pea, amount: 0, moves: 25, title: "Special Delivery", stolenItem: "shared squeaky bug", clue: "Bring in the last parcels, then Henry and Leo can share the toy by the sunny door.", chapterIndex: 8, parcelCount: 6, knockEvery: 2),

        .init(goal: .pea, amount: 24, moves: 25, title: "Birthday Morning", stolenItem: "first birthday sniff", clue: "It's the brothers' birthday! Leo is already sniffing around the kitchen.", chapterIndex: 9, partyEvery: 5),
        .init(goal: .tomato, amount: 0, moves: 25, title: "Party Prep Dust", stolenItem: "tidy kitchen floor", clue: "Mom tidies up for the party. Clear the dust so Leo has a calm spot.", chapterIndex: 9, dustCells: 12, dustDepth: 1, partyEvery: 5),
        .init(goal: .carrot, amount: 0, moves: 24, title: "Wrapping-Paper Rustle", stolenItem: "crinkly gift bag", clue: "Gift bags crinkle and cans clink. Henry quiets them one at a time.", chapterIndex: 9, canCells: 6, bagCells: 3, partyEvery: 4),
        .init(goal: .onion, amount: 0, moves: 24, title: "Pads on the Counter", stolenItem: "peanut-butter pads", clue: "The peanut-butter pads are up high. Clear beneath them so they slide down to Mom.", chapterIndex: 9, parcelCount: 2, parcelIsPad: true, partyEvery: 4),
        .init(goal: .pepper, amount: 0, moves: 24, title: "Leo Hides from the Hubbub", stolenItem: "quiet hiding spot", clue: "Too much party! Leo slipped away. Henry follows his pawsteps to him.", chapterIndex: 9, rescueSteps: 10, partyEvery: 4),
        .init(goal: .tomato, amount: 16, moves: 24, title: "Too Much Commotion", stolenItem: "party noisemakers", clue: "Quiet the clattery noisemakers and gather happy Leos for the party.", chapterIndex: 9, canCells: 6, partyEvery: 3),
        .init(goal: .eggplant, amount: 0, moves: 23, title: "The Hidden Treat", stolenItem: "hidden treat", clue: "Mom hid a surprise. Henry follows familiar clues while Leo stays close.", chapterIndex: 9, clueCells: 8, clueDepth: 2, partyEvery: 4),
        .init(goal: .pea, amount: 16, moves: 24, title: "Spilled Water Bowl", stolenItem: "dry party paws", clue: "Someone bumped the water bowl! Keep Leo dry and gather snack-time Leos.", chapterIndex: 9, splashCount: 6, splashEvery: 3),
        .init(goal: .carrot, amount: 0, moves: 24, title: "Two Pads, Two Brothers", stolenItem: "party blanket", clue: "Bring both pads down and spread the party blanket wide enough for two.", chapterIndex: 9, comfortCells: 12, parcelCount: 2, parcelIsPad: true, partyEvery: 3),
        .init(goal: .pea, amount: 0, moves: 26, title: "The Peanut-Butter Pad", stolenItem: "shared birthday pad", clue: "One last birthday wish: bring the pads to Mom and make a cozy spot to share them.", chapterIndex: 9, comfortCells: 18, parcelCount: 2, parcelIsPad: true, partyEvery: 4)
    ]

    static let chapters: [Chapter] = [
        .init(id: 0, title: "The Bug in the Beans", subtitle: "Henry follows Leo's pawprints through the garden.", backgroundName: "chapter-one-garden", symbol: "leaf.fill", levelRange: 0..<10),
        .init(id: 1, title: "The Vacuum Awakens", subtitle: "Henry clears a safe path through the hallway.", backgroundName: "chapter-02-vacuum-hallway", symbol: "wind", levelRange: 10..<20),
        .init(id: 2, title: "Under the Bed", subtitle: "Henry follows Leo into the coziest hiding place.", backgroundName: "chapter-03-under-the-bed", symbol: "bed.double.fill", levelRange: 20..<30),
        .init(id: 3, title: "Thunder over the Tomatoes", subtitle: "Henry keeps Leo cozy until the storm rolls past.", backgroundName: "chapter-04-thunder-tomatoes", symbol: "cloud.bolt.rain.fill", levelRange: 30..<40),
        .init(id: 4, title: "The Lawnmower Loop", subtitle: "Henry leads Leo around the quiet side of the yard.", backgroundName: "chapter-05-lawnmower-loop", symbol: "leaf.arrow.triangle.circlepath", levelRange: 40..<50),
        .init(id: 5, title: "Bags, Cans, and Courage", subtitle: "Henry clears the noisy porch one clatter at a time.", backgroundName: "chapter-06-bags-and-cans", symbol: "bag.fill", levelRange: 50..<60),
        .init(id: 6, title: "Where Is Mom?", subtitle: "Henry follows familiar clues and keeps Leo close.", backgroundName: "chapter-07-where-is-mom", symbol: "heart.text.clipboard.fill", levelRange: 60..<70),
        .init(id: 7, title: "Pool Day", subtitle: "Henry keeps Leo on the dry side of the pool.", backgroundName: "chapter-08-pool-day", symbol: "drop.fill", levelRange: 70..<80),
        .init(id: 8, title: "Special Delivery", subtitle: "Henry keeps watch while Leo waits somewhere cozy.", backgroundName: "chapter-09-special-delivery", symbol: "shippingbox.fill", levelRange: 80..<90),
        .init(id: 9, title: "The Birthday Peanut-Butter Pad", subtitle: "Henry helps Leo through the party bustle to share a birthday treat.", backgroundName: "chapter-10-birthday-pad", symbol: "birthday.cake.fill", levelRange: 90..<100)
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
        let savedWins = min(Self.levels.count, max(0, defaults.integer(forKey: "gardenWins")))
        wins = savedWins
        unlocked = min(Self.levels.count, max(1, max(defaults.integer(forKey: "unlockedLevels"), savedWins + 1)))
        soundOn = defaults.object(forKey: "soundOn") == nil ? true : defaults.bool(forKey: "soundOn")
        defaults.set(unlocked, forKey: "unlockedLevels")
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
        let quietSteps = advanceQuietRoute(near: clearSet)
        let hushed = hushNoise(near: clearSet)
        let cluesFound = revealClues(near: clearSet)
        let dried = drySplashes(near: clearSet)
        let delivered = dropParcels(afterClearing: clearSet)
        message = delivered > 0 ? "Power-up delivery! \(delivered) \(level.parcelIsPad ? "pad" : "parcel")\(delivered == 1 ? "" : "s") reached \(level.parcelIsPad ? "Mom" : "the mat")!" : dried > 0 ? "Power-up sunshine! \(dried) splash\(dried == 1 ? "" : "es") dried up!" : cluesFound > 0 ? "Power-up search! Henry uncovered \(cluesFound) clue\(cluesFound == 1 ? "" : "s")!" : hushed > 0 ? "Power-up hush! \(hushed) clatter\(hushed == 1 ? "" : "s") settled down!" : quietSteps > 0 ? "Power-up path! Henry bounded along the quiet route!" : warmed > 0 ? "Power-up hug! The blanket spread over \(warmed) spots!" : positions.contains { board[$0.row][$0.col].powerUp == .rainbowPaw }
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
        let quietSteps = advanceQuietRoute(near: Set(positions))
        let hushed = hushNoise(near: Set(positions))
        let cluesFound = revealClues(near: Set(positions))
        let dried = drySplashes(near: Set(positions))
        let delivered = dropParcels(afterClearing: Set(positions))
        message = delivered > 0 ? "The water swept \(delivered) \(level.parcelIsPad ? "pad" : "parcel")\(delivered == 1 ? "" : "s") down to \(level.parcelIsPad ? "Mom" : "the mat")!" : dried > 0 ? "Henry soaked up \(dried) splash\(dried == 1 ? "" : "es") with a towel." : cluesFound > 0 ? "The water uncovered \(cluesFound) familiar clue\(cluesFound == 1 ? "" : "s")!" : hushed > 0 ? "A splash of water hushed \(hushed) clatter\(hushed == 1 ? "" : "s")." : quietSteps > 0 ? "Henry found the next quiet leaf!" : warmed > 0 ? "Henry dragged the blanket over \(warmed) more spot\(warmed == 1 ? "" : "s")." : advanced > 0 ? "Henry splashed ahead \(advanced) pawstep\(advanced == 1 ? "" : "s")!" : awakened > 0 ? "WOOF! Henry woke \(awakened)!" : dustHit > 0 ? "The water settled \(dustHit) dusty spot\(dustHit == 1 ? "" : "s")." : "A little rain works wonders."
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
