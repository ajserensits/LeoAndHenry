import SwiftUI

// MARK: - Yard catalog

struct YardStyle {
    let name: String
    let image: String
}

/// One decorating project in Leo and Henry's backyard. Positions are fractions of the
/// painted yard stage: `anchor` is where the bottom-center of the sprite sits, `width`
/// is the sprite's width as a share of the stage width.
struct YardSpot: Identifiable {
    let id: String
    let name: String
    let cost: Int
    let henryLine: String
    let styles: [YardStyle]
    let anchor: CGPoint
    let width: CGFloat
}

enum Yard {
    static let backgroundName = "yard-background"
    /// The painted stage's aspect ratio (1672 x 941).
    static let stageAspect: CGFloat = 1672 / 941

    static let spots: [YardSpot] = [
        .init(id: "flowers", name: "Flower Bed", cost: 1,
              henryLine: "Henry planted flowers by the fence. Leo is sniffing every single one.",
              styles: [.init(name: "Tulips", image: "yard-flowers-1"), .init(name: "Sunflowers", image: "yard-flowers-2"), .init(name: "Lavender", image: "yard-flowers-3")],
              anchor: CGPoint(x: 0.22, y: 0.38), width: 0.23),
        .init(id: "doghouse", name: "Doghouse", cost: 3,
              henryLine: "A house for two! Leo claimed the comfy side before Henry got inside.",
              styles: [.init(name: "Red Barn", image: "yard-doghouse-1"), .init(name: "Blue Cottage", image: "yard-doghouse-2"), .init(name: "Pink Castle", image: "yard-doghouse-3")],
              anchor: CGPoint(x: 0.30, y: 0.64), width: 0.18),
        .init(id: "splash", name: "Splash Spot", cost: 5,
              henryLine: "Henry tested the water first. Leo is keeping his paws dry… for now.",
              styles: [.init(name: "Paddling Pool", image: "yard-splash-1"), .init(name: "Duck Pool", image: "yard-splash-2"), .init(name: "Stone Fountain", image: "yard-splash-3")],
              anchor: CGPoint(x: 0.82, y: 0.95), width: 0.21),
        .init(id: "nap", name: "Nap Spot", cost: 8,
              henryLine: "The perfect nap spot. Henry saved Leo the sunny half.",
              styles: [.init(name: "Striped Bed", image: "yard-nap-1"), .init(name: "Knit Basket", image: "yard-nap-2"), .init(name: "Canopy Bed", image: "yard-nap-3")],
              anchor: CGPoint(x: 0.17, y: 0.95), width: 0.18),
        .init(id: "toys", name: "Toy Box", cost: 11,
              henryLine: "All the toys in one place. Henry's ladybug keeps ending up on Leo's side.",
              styles: [.init(name: "Wicker Basket", image: "yard-toys-1"), .init(name: "Wooden Chest", image: "yard-toys-2"), .init(name: "Garden Bucket", image: "yard-toys-3")],
              anchor: CGPoint(x: 0.41, y: 0.83), width: 0.12),
        .init(id: "bench", name: "Mom's Bench", cost: 14,
              henryLine: "Mom's bench! Now everyone can watch the sunset together.",
              styles: [.init(name: "Wicker Loveseat", image: "yard-bench-1"), .init(name: "Garden Bench", image: "yard-bench-2"), .init(name: "Porch Swing", image: "yard-bench-3")],
              anchor: CGPoint(x: 0.73, y: 0.66), width: 0.18),
        .init(id: "tree", name: "Shade Tree", cost: 17,
              henryLine: "Shade at last. Henry keeps watch while Leo naps under the leaves.",
              styles: [.init(name: "Apple Tree", image: "yard-tree-1"), .init(name: "Cherry Blossom", image: "yard-tree-2"), .init(name: "Lemon Tree", image: "yard-tree-3")],
              anchor: CGPoint(x: 0.895, y: 0.46), width: 0.19),
        .init(id: "arch", name: "Garden Arch", cost: 20,
              henryLine: "The grand finish! Henry and Leo walk through it side by side.",
              styles: [.init(name: "Rose Arch", image: "yard-arch-1"), .init(name: "Lantern Arch", image: "yard-arch-2"), .init(name: "Party Arch", image: "yard-arch-3")],
              anchor: CGPoint(x: 0.59, y: 0.29), width: 0.16)
    ]

    static func spot(_ id: String) -> YardSpot? { spots.first { $0.id == id } }
}

extension GameModel {
    /// One treat for every level won for the first time, minus what the yard has used.
    var treatsSpent: Int { Yard.spots.filter { yardChoices[$0.id] != nil }.reduce(0) { $0 + $1.cost } }
    var treats: Int { max(0, wins - treatsSpent) }
    var yardProjectReady: Bool {
        Yard.spots.contains { yardChoices[$0.id] == nil && $0.cost <= treats }
    }
}

// MARK: - Yard screen

struct YardView: View {
    @ObservedObject var game: GameModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var selectedID: String?
    @State private var message = "Win levels to earn treats, then spend them to fix up the yard!"
    @State private var justBuilt: String?
    @State private var hoppingDog: String?
    @State private var bubbleVisible = true
    @State private var bubbleToken = 0

    private var selected: YardSpot? { selectedID.flatMap(Yard.spot) }

    var body: some View {
        GeometryReader { proxy in
            let landscape = proxy.size.width > proxy.size.height
            ZStack {
                backdrop
                stage(in: proxy.size, landscape: landscape)
                VStack(spacing: 0) {
                    topBar
                    Spacer(minLength: 0)
                    if bubbleVisible {
                        HStack(alignment: .bottom) {
                            HenrySpeechBubble(message: message, portraitSize: 42, fontSize: 13, lineLimit: 3)
                                .frame(maxWidth: landscape ? 320 : .infinity)
                                .onTapGesture { withAnimation { bubbleVisible = false } }
                            Spacer(minLength: 0)
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                if let spot = selected {
                    panelLayer(spot, landscape: landscape)
                }
            }
        }
        .background(Cute.cream.ignoresSafeArea())
        .onAppear { say(greeting) }
    }

    private var greeting: String {
        if Yard.spots.allSatisfy({ game.yardChoices[$0.id] != nil }) {
            return "The yard is finished! Tap anything to try a different style."
        }
        if game.yardProjectReady { return "You have treats to spend! Tap a sparkly spot to fix it up." }
        return "Win levels to earn treats, then spend them to fix up the yard!"
    }

    // MARK: Layers

    private var backdrop: some View {
        Color.clear.overlay {
            if let image = UIImage(named: Yard.backgroundName) {
                Image(uiImage: image).resizable().scaledToFill().blur(radius: 14).overlay(Color.white.opacity(0.12))
            } else {
                LinearGradient(colors: [Color(red: 0.69, green: 0.86, blue: 0.84), Cute.leaf], startPoint: .top, endPoint: .bottom)
            }
        }
        .clipped()
        .ignoresSafeArea()
        .onTapGesture { deselect() }
    }

    private func stage(in size: CGSize, landscape: Bool) -> some View {
        let stageSize: CGSize = {
            let width = min(size.width, size.height * Yard.stageAspect)
            return CGSize(width: width, height: width / Yard.stageAspect)
        }()
        return ZStack(alignment: .topLeading) {
            Group {
                if let image = UIImage(named: Yard.backgroundName) {
                    Image(uiImage: image).resizable()
                } else {
                    Color(red: 0.55, green: 0.75, blue: 0.40)
                }
            }
            .frame(width: stageSize.width, height: stageSize.height)
            .onTapGesture { deselect() }

            ForEach(Yard.spots.sorted { $0.anchor.y < $1.anchor.y }) { spot in
                spotView(spot, stage: stageSize)
            }
            dog("henry", image: "yard-dog-henry", anchor: CGPoint(x: 0.46, y: 0.985), width: 0.105, stage: stageSize)
            dog("leo", image: "yard-dog-leo", anchor: CGPoint(x: 0.61, y: 0.995), width: 0.12, stage: stageSize)
        }
        .frame(width: stageSize.width, height: stageSize.height)
        .clipShape(RoundedRectangle(cornerRadius: landscape ? 0 : 22, style: .continuous))
    }

    @ViewBuilder
    private func spotView(_ spot: YardSpot, stage: CGSize) -> some View {
        let anchor = CGPoint(x: spot.anchor.x * stage.width, y: spot.anchor.y * stage.height)
        if let choice = game.yardChoices[spot.id], let image = UIImage(named: spot.styles[min(choice, spot.styles.count - 1)].image) {
            let width = spot.width * stage.width
            let height = width * image.size.height / max(1, image.size.width)
            Image(uiImage: image)
                .resizable()
                .frame(width: width, height: height)
                .shadow(color: selectedID == spot.id ? .white : .clear, radius: 6)
                .scaleEffect(justBuilt == spot.id ? 1.08 : 1, anchor: .bottom)
                .position(x: anchor.x, y: anchor.y - height / 2)
                .onTapGesture { select(spot) }
                .transition(.scale(scale: 0.2, anchor: .bottom).combined(with: .opacity))
                .accessibilityElement()
                .accessibilityLabel("\(spot.name), \(spot.styles[min(choice, spot.styles.count - 1)].name)")
                .accessibilityAddTraits(.isButton)
        } else {
            BuildMarker(cost: spot.cost, affordable: spot.cost <= game.treats, selected: selectedID == spot.id, reduceMotion: reduceMotion)
                .position(x: anchor.x, y: anchor.y - 26)
                .onTapGesture { select(spot) }
                .accessibilityElement()
                .accessibilityLabel("Fix up the \(spot.name) for \(spot.cost) treats")
                .accessibilityAddTraits(.isButton)
        }
    }

    private func dog(_ id: String, image name: String, anchor: CGPoint, width: CGFloat, stage: CGSize) -> some View {
        Group {
            if let image = UIImage(named: name) {
                let w = width * stage.width
                let h = w * image.size.height / max(1, image.size.width)
                Image(uiImage: image)
                    .resizable()
                    .frame(width: w, height: h)
                    .offset(y: hoppingDog == id ? -14 : 0)
                    .position(x: anchor.x * stage.width, y: anchor.y * stage.height - h / 2)
                    .onTapGesture { pet(id) }
                    .accessibilityElement()
                    .accessibilityLabel(id == "leo" ? "Leo" : "Henry")
                    .accessibilityAddTraits(.isButton)
            }
        }
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            Button { dismiss() } label: { Image(systemName: "chevron.left") }
                .buttonStyle(CuteCircleButtonStyle(size: 42))
                .accessibilityLabel("Back")
            VStack(alignment: .leading, spacing: 2) {
                CutePill(text: "OUR YARD", icon: "house.fill", fill: Cute.leaf, size: 9)
                StickerText("Leo & Henry's Yard", size: 24, colors: [Cute.berry, Cute.berryDeep])
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            Spacer(minLength: 8)
            TreatCounter(treats: game.treats)
        }
    }

    @ViewBuilder
    private func panelLayer(_ spot: YardSpot, landscape: Bool) -> some View {
        let basePanel = SpotPanel(
            spot: spot,
            choice: game.yardChoices[spot.id],
            treats: game.treats,
            build: { build(spot) },
            choose: { choose(spot, $0) },
            close: deselect
        )
        // In landscape, open on the far side from the spot so it stays visible.
        let onLeft = landscape && spot.anchor.x > 0.5
        let panel = basePanel
            .frame(maxWidth: landscape ? 270 : 420)
            .transition(.move(edge: landscape ? (onLeft ? .leading : .trailing) : .bottom).combined(with: .opacity))

        if landscape {
            HStack {
                if onLeft { panel; Spacer() } else { Spacer(); panel }
            }
            .padding(.horizontal, 14)
            .padding(.top, 64)
            .padding(.bottom, 10)
        } else {
            VStack { Spacer(); panel }
                .padding(.horizontal, 14)
                .padding(.bottom, 74)
        }
    }

    // MARK: Actions

    /// Shows Henry's bubble, then tucks it away so it never hides the yard for long.
    private func say(_ text: String, for seconds: Double = 5) {
        message = text
        bubbleToken += 1
        let token = bubbleToken
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { bubbleVisible = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            guard token == bubbleToken else { return }
            withAnimation(.easeInOut(duration: 0.3)) { bubbleVisible = false }
        }
    }

    private func select(_ spot: YardSpot) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { selectedID = spot.id }
        if game.yardChoices[spot.id] == nil {
            let needed = spot.cost - game.treats
            say(needed <= 0
                ? "The \(spot.name.lowercased()) needs some love. Want to fix it up?"
                : "Win \(needed) more level\(needed == 1 ? "" : "s") to fix up the \(spot.name.lowercased())!")
        } else {
            say("Pick a style for the \(spot.name.lowercased())!")
        }
    }

    private func deselect() {
        guard selectedID != nil else { return }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { selectedID = nil }
    }

    private func build(_ spot: YardSpot) {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.6)) {
            guard game.buildYardSpot(spot.id) else { return }
            justBuilt = spot.id
            say(spot.henryLine, for: 7)
        }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        if game.soundOn { GameAudio.shared.play(.yardBuild) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { justBuilt = nil }
        }
    }

    private func choose(_ spot: YardSpot, _ style: Int) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            game.chooseYardStyle(spot.id, style: style)
            justBuilt = spot.id
        }
        say("Ooh, the \(spot.styles[style].name.lowercased())! Leo approves.")
        UISelectionFeedbackGenerator().selectionChanged()
        if game.soundOn { GameAudio.shared.play(.yardStyle) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { justBuilt = nil }
        }
    }

    private func pet(_ id: String) {
        let lines = id == "leo"
            ? ["Leo! That's my ladybug. …Fine, you can hold it a little longer.",
               "Leo wiggles. He has definitely stolen something today.",
               "Don't worry, Leo. Henry checked the whole yard. Nothing scary here."]
            : ["Henry is on guard. The yard is safe for Leo.",
               "Henry wags. He likes the yard best when Leo is in it.",
               "Henry's job: protect Leo, find toys, and supervise decorating."]
        say(lines.randomElement() ?? lines[0])
        withAnimation(.spring(response: 0.22, dampingFraction: 0.45)) { hoppingDog = id }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.55)) { hoppingDog = nil }
        }
    }
}

// MARK: - Pieces

/// A little dog-treat bone drawn in the cute theme colors.
struct TreatIcon: View {
    var size: CGFloat = 22

    var body: some View {
        let knob = size * 0.38
        ZStack {
            ForEach(0..<4, id: \.self) { corner in
                Circle()
                    .frame(width: knob, height: knob)
                    .offset(x: (corner < 2 ? -1 : 1) * size * 0.34, y: (corner.isMultiple(of: 2) ? -1 : 1) * size * 0.13)
            }
            Capsule().frame(width: size * 0.72, height: size * 0.3)
        }
        .foregroundStyle(LinearGradient(colors: [Cute.cream, Cute.stitch], startPoint: .top, endPoint: .bottom))
        .frame(width: size, height: size * 0.62)
        .shadow(color: Cute.cocoa.opacity(0.55), radius: 0, x: 0, y: 1.2)
        .rotationEffect(.degrees(-18))
        .accessibilityHidden(true)
    }
}

private struct TreatCounter: View {
    let treats: Int

    var body: some View {
        HStack(spacing: 6) {
            TreatIcon(size: 26)
            Text("\(treats)")
                .font(Cute.font(20, .black))
                .foregroundStyle(Cute.cocoa)
                .contentTransition(.numericText())
                .animation(.spring, value: treats)
        }
        .padding(.leading, 10)
        .padding(.trailing, 14)
        .padding(.vertical, 6)
        .background(Cute.cream, in: Capsule())
        .overlay(Capsule().strokeBorder(.white, lineWidth: 3))
        .shadow(color: Cute.cocoa.opacity(0.22), radius: 0, y: 3)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(treats) treats")
    }
}

/// A sparkly "fix me up" marker for a yard spot that hasn't been decorated yet.
private struct BuildMarker: View {
    let cost: Int
    let affordable: Bool
    let selected: Bool
    let reduceMotion: Bool

    @State private var bob = false

    var body: some View {
        VStack(spacing: 3) {
            ZStack {
                Circle()
                    .fill(affordable ? Cute.honey : Color.white.opacity(0.85))
                    .frame(width: 40, height: 40)
                    .overlay(Circle().strokeBorder(.white, lineWidth: 3))
                    .shadow(color: Cute.cocoa.opacity(0.3), radius: 0, y: 3)
                Image(systemName: affordable ? "sparkles" : "lock.fill")
                    .font(.system(size: affordable ? 19 : 15, weight: .black))
                    .foregroundStyle(affordable ? .white : Cute.cocoaSoft)
            }
            .scaleEffect(selected ? 1.15 : 1)
            HStack(spacing: 3) {
                TreatIcon(size: 14)
                Text("\(cost)").font(Cute.font(12, .black)).foregroundStyle(Cute.cocoa)
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(Cute.cream, in: Capsule())
            .overlay(Capsule().strokeBorder(.white, lineWidth: 1.5))
        }
        .padding(8)
        .background(
            Ellipse()
                .stroke(Color.white.opacity(0.85), style: StrokeStyle(lineWidth: 2.5, dash: [6, 5]))
                .frame(width: 92, height: 34)
                .offset(y: 30)
        )
        .offset(y: affordable && bob ? -5 : 0)
        .onAppear {
            guard affordable, !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) { bob = true }
        }
        .contentShape(Rectangle())
    }
}

private struct SpotPanel: View {
    let spot: YardSpot
    let choice: Int?
    let treats: Int
    let build: () -> Void
    let choose: (Int) -> Void
    let close: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    CutePill(text: choice == nil ? "YARD PROJECT" : "PICK A STYLE", icon: "sparkles", size: 9)
                    StickerText(spot.name, size: 22)
                }
                Spacer(minLength: 4)
                Button(action: close) { Image(systemName: "xmark") }
                    .buttonStyle(CuteCircleButtonStyle(size: 32))
                    .accessibilityLabel("Close")
            }

            if let choice {
                HStack(spacing: 8) {
                    ForEach(spot.styles.indices, id: \.self) { index in
                        Button { choose(index) } label: {
                            StyleThumb(style: spot.styles[index], picked: index == choice)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(spot.styles[index].name)
                        .accessibilityAddTraits(index == choice ? .isSelected : [])
                    }
                }
                Text("Change styles any time—it's free!")
                    .font(Cute.font(11, .bold))
                    .foregroundStyle(Cute.cocoaSoft)
            } else {
                HStack(spacing: 8) {
                    ForEach(spot.styles.indices, id: \.self) { index in
                        StyleThumb(style: spot.styles[index], picked: false)
                    }
                }
                .opacity(0.9)
                Text("Fix it up, then pick your favorite of three styles.")
                    .font(Cute.font(12, .bold))
                    .foregroundStyle(Cute.cocoaSoft)
                    .fixedSize(horizontal: false, vertical: true)
                if treats >= spot.cost {
                    Button(action: build) {
                        HStack(spacing: 6) {
                            Text("Fix it up for")
                            TreatIcon(size: 20)
                            Text("\(spot.cost)")
                        }
                    }
                    .buttonStyle(CuteCandyButtonStyle(colors: [Cute.leaf, Cute.leafDeep]))
                    .frame(maxWidth: .infinity)
                } else {
                    HStack(spacing: 6) {
                        TreatIcon(size: 18)
                        Text("Needs \(spot.cost) · you have \(treats)")
                            .font(Cute.font(13, .heavy))
                            .foregroundStyle(Cute.cocoa)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(Color.white.opacity(0.7), in: Capsule())
                }
            }
        }
        .padding(14)
        .quiltedCard(corner: 22)
    }
}

private struct StyleThumb: View {
    let style: YardStyle
    let picked: Bool

    var body: some View {
        VStack(spacing: 3) {
            Group {
                if let image = UIImage(named: style.image) {
                    Image(uiImage: image).resizable().scaledToFit().padding(5)
                } else {
                    Image(systemName: "photo").foregroundStyle(Cute.cocoaSoft)
                }
            }
            .frame(width: 64, height: 58)
            .background(picked ? Cute.honey.opacity(0.45) : Color.white.opacity(0.8), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(picked ? Cute.honeyDeep : .white, lineWidth: picked ? 3 : 2)
            )
            Text(style.name)
                .font(Cute.font(9, .heavy))
                .foregroundStyle(Cute.cocoa)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(width: 66)
        }
    }
}
