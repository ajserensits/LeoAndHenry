import Combine
import SwiftUI
import UIKit

struct BoosterLoadoutView: View {
    @ObservedObject var game: GameModel
    let levelIndex: Int
    let start: (Set<StartingBooster>) -> Void

    @State private var selected = Set<StartingBooster>()

    private var level: Level { GameModel.levels[levelIndex] }
    private var localLevel: Int {
        levelIndex - GameModel.chapters[level.chapterIndex].levelRange.lowerBound + 1
    }

    var body: some View {
        ZStack {
            ChapterBackdropView(chapterIndex: level.chapterIndex)
                .blur(radius: 5)
                .overlay(Color.black.opacity(0.36))
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 4) {
                        Text("CHAPTER \(level.chapterIndex + 1) · LEVEL \(localLevel)")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .tracking(1.5)
                            .foregroundStyle(.secondary)
                        Text(level.title)
                            .font(.system(size: 29, weight: .bold, design: .serif))
                            .multilineTextAlignment(.center)
                        Text("Pack a little help for Henry and Leo")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }

                    ViewThatFits {
                        HStack(spacing: 12) { boosterCards }
                        VStack(spacing: 10) { boosterCards }
                    }

                    Text("Selected boosters are placed on random pieces when the board opens. You can save any booster for later.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 560)

                    Button {
                        start(selected)
                    } label: {
                        Label(
                            selected.isEmpty ? "Play Without Boosters" : "Start With \(selected.count) Booster\(selected.count == 1 ? "" : "s")",
                            systemImage: "play.fill"
                        )
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(Color(red: 0.29, green: 0.55, blue: 0.30), in: RoundedRectangle(cornerRadius: 16))
                        .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: 620)
                }
                .padding(20)
                .frame(maxWidth: 760)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 28).stroke(.white.opacity(0.78), lineWidth: 2))
                .shadow(color: .black.opacity(0.24), radius: 18, y: 8)
                .padding(18)
                .frame(maxWidth: .infinity)
            }
        }
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private var boosterCards: some View {
        ForEach(StartingBooster.allCases) { booster in
            let count = game.boosterCount(booster)
            let isSelected = selected.contains(booster)
            Button {
                guard count > 0 else { return }
                if isSelected { selected.remove(booster) } else { selected.insert(booster) }
            } label: {
                VStack(spacing: 8) {
                    ZStack(alignment: .topTrailing) {
                        PowerUpBadge(powerUp: booster.previewPowerUp, size: 54)
                        Text("\(count)")
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                            .frame(minWidth: 22, minHeight: 22)
                            .background(count > 0 ? Color.black.opacity(0.76) : Color.gray, in: Circle())
                            .offset(x: 9, y: -8)
                    }
                    Text(booster.title)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                    Text(booster.subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    Image(systemName: isSelected ? "checkmark.circle.fill" : count > 0 ? "circle" : "lock.circle")
                        .font(.title3)
                        .foregroundStyle(isSelected ? .green : .secondary)
                }
                .padding(12)
                .frame(maxWidth: .infinity, minHeight: 154)
                .background(isSelected ? Color.green.opacity(0.14) : Color.white.opacity(0.68), in: RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(isSelected ? Color.green : Color.white.opacity(0.75), lineWidth: isSelected ? 3 : 1))
                .opacity(count > 0 ? 1 : 0.58)
            }
            .buttonStyle(.plain)
            .disabled(count == 0)
            .accessibilityLabel("\(booster.title), \(count) available\(isSelected ? ", selected" : "")")
        }
    }
}

struct BoosterBasketView: View {
    let chapterIndex: Int
    let finish: ([StartingBooster]) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var basketX = 0.5
    @State private var drops: [BasketDrop] = []
    @State private var caught: [StartingBooster] = []
    @State private var timeRemaining = 10.0
    @State private var spawnClock = 0.0
    @State private var finished = false
    @State private var wobble = false

    private let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ChapterBackdropView(chapterIndex: chapterIndex)
                    .blur(radius: 4)
                    .overlay(Color(red: 0.10, green: 0.20, blue: 0.12).opacity(0.58))
                    .ignoresSafeArea()

                ForEach(drops) { drop in
                    BasketDropView(kind: drop.kind)
                        .frame(width: min(proxy.size.width, proxy.size.height) * 0.10)
                        .position(x: drop.x * proxy.size.width, y: drop.y * proxy.size.height)
                        .allowsHitTesting(false)
                }

                VStack {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("HENRY'S BOOSTER BASKET")
                                .font(.system(size: 19, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                            Text("Drag anywhere to help Henry catch up to three boosters")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.82))
                        }
                        Spacer()
                        VStack(spacing: 2) {
                            Text("\(Int(ceil(timeRemaining)))")
                                .font(.system(size: 30, weight: .black, design: .rounded))
                            Text("SECONDS")
                                .font(.system(size: 8, weight: .black, design: .rounded))
                                .tracking(1.2)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 7)
                        .background(.black.opacity(0.35), in: Capsule())
                    }
                    .padding(18)

                    HStack(spacing: 8) {
                        ForEach(0..<3, id: \.self) { index in
                            if caught.indices.contains(index) {
                                PowerUpBadge(powerUp: caught[index].previewPowerUp, size: 38)
                            } else {
                                Circle()
                                    .stroke(.white.opacity(0.55), style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
                                    .frame(width: 38, height: 38)
                            }
                        }
                    }
                    .padding(.horizontal, 13)
                    .padding(.vertical, 8)
                    .background(.black.opacity(0.28), in: Capsule())

                    Spacer()
                }

                HenryBasketCharacter(full: caught.count >= 3, wobble: wobble)
                    .frame(width: min(proxy.size.width * 0.18, 170), height: min(proxy.size.height * 0.28, 190))
                    .position(x: basketX * proxy.size.width, y: proxy.size.height * 0.84)
                    .animation(reduceMotion ? nil : .spring(response: 0.18, dampingFraction: 0.70), value: basketX)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        basketX = min(0.92, max(0.08, value.location.x / max(1, proxy.size.width)))
                    }
            )
            .onReceive(timer) { _ in tick() }
            .onAppear { spawnDrop() }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Henry's Booster Basket mini game. Drag horizontally to catch falling boosters.")
    }

    private func tick() {
        guard !finished else { return }
        timeRemaining -= 0.05
        spawnClock += 0.05

        if spawnClock >= 0.48, timeRemaining > 2.0 {
            spawnClock = 0
            spawnDrop()
        }

        var survivors: [BasketDrop] = []
        for var drop in drops {
            drop.y += drop.speed * (reduceMotion ? 0.72 : 1)
            let inBasket = (0.70...0.88).contains(drop.y) && abs(drop.x - basketX) < 0.105
            if inBasket {
                catchDrop(drop.kind)
            } else if drop.y < 1.08 {
                survivors.append(drop)
            }
        }
        drops = survivors

        if timeRemaining <= 0 {
            finished = true
            finish(Array(caught.prefix(3)))
        }
    }

    private func spawnDrop() {
        drops.append(
            BasketDrop(
                kind: BasketDropKind.random(),
                x: Double.random(in: 0.10...0.90),
                y: -0.08,
                speed: Double.random(in: 0.010...0.014)
            )
        )
    }

    private func catchDrop(_ kind: BasketDropKind) {
        switch kind {
        case .booster(let booster):
            if caught.count < 3 { caught.append(booster) }
        case .silly:
            guard !reduceMotion else { return }
            wobble = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { wobble = false }
        }
    }
}

private struct BasketDrop: Identifiable {
    let id = UUID()
    let kind: BasketDropKind
    let x: Double
    var y: Double
    let speed: Double
}

private enum BasketDropKind {
    case booster(StartingBooster)
    case silly(String, Color)

    static func random() -> BasketDropKind {
        switch Int.random(in: 0..<100) {
        case 0..<38: .booster(.rocket)
        case 38..<60: .booster(.gardenBomb)
        case 60..<72: .booster(.rainbowPaw)
        case 72..<82: .silly("socks", .mint)
        case 82..<92: .silly("tennisball.fill", .yellow)
        default: .silly("leaf.fill", .orange)
        }
    }
}

private struct BasketDropView: View {
    let kind: BasketDropKind

    var body: some View {
        switch kind {
        case .booster(let booster):
            PowerUpBadge(powerUp: booster.previewPowerUp, size: 48)
                .shadow(color: .white.opacity(0.70), radius: 7)
        case .silly(let symbol, let color):
            Image(systemName: symbol)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(color)
                .frame(width: 48, height: 48)
                .background(.white.opacity(0.90), in: Circle())
                .overlay(Circle().stroke(.white, lineWidth: 2))
        }
    }
}

private struct HenryBasketCharacter: View {
    let full: Bool
    let wobble: Bool

    var body: some View {
        ZStack(alignment: .top) {
            if let portrait = UIImage(named: "henry-map-marker") {
                Image(uiImage: portrait)
                    .resizable()
                    .scaledToFit()
                    .clipShape(Circle())
                    .overlay(Circle().stroke(.white, lineWidth: 4))
                    .shadow(color: .black.opacity(0.35), radius: 8, y: 5)
                    .padding(.top, 27)
            } else {
                Image(systemName: "dog.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.brown)
                    .padding(.top, 27)
            }

            ZStack {
                Capsule()
                    .fill(Color(red: 0.72, green: 0.48, blue: 0.24).gradient)
                    .frame(width: 86, height: 30)
                Capsule()
                    .stroke(Color(red: 0.40, green: 0.24, blue: 0.12), lineWidth: 4)
                    .frame(width: 86, height: 30)
                if full {
                    Text("FULL!")
                        .font(.caption2.weight(.black))
                        .foregroundStyle(.white)
                }
            }
            .rotationEffect(.degrees(wobble ? 10 : 0))
        }
    }
}

extension StartingBooster {
    var title: String {
        switch self {
        case .rocket: "Rocket Basket"
        case .gardenBomb: "Garden Bomb"
        case .rainbowPaw: "Rainbow Paw"
        }
    }

    var subtitle: String {
        switch self {
        case .rocket: "Starts as a row or column rocket"
        case .gardenBomb: "Clears a burst around one piece"
        case .rainbowPaw: "Joins every matching Leo"
        }
    }

    var previewPowerUp: PowerUp {
        switch self {
        case .rocket: .rowRocket
        case .gardenBomb: .gardenBomb
        case .rainbowPaw: .rainbowPaw
        }
    }
}
