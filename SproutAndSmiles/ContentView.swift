import SwiftUI

struct ContentView: View {
    @StateObject private var game = GameModel()
    @State private var showGarden = false
    @State private var showingIntro = true
    @State private var showingMap = false
    @State private var showingPause = false
    @State private var pendingLevel: Int?
    @State private var showingBoosterBasket = false
    @State private var showingBoosterLoadout = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: GameModel.size)

    var body: some View {
        ZStack {
            GeometryReader { proxy in
                if proxy.size.width > proxy.size.height {
                    ChapterBackdropView(chapterIndex: game.level.chapterIndex)
                        .overlay(Color.black.opacity(0.04))
                } else {
                    LinearGradient(colors: [Color(red: 0.94, green: 0.96, blue: 0.86), Color(red: 0.99, green: 0.91, blue: 0.79)], startPoint: .topLeading, endPoint: .bottomTrailing)
                }
            }
            .ignoresSafeArea()

            GeometryReader { proxy in
                if proxy.size.width > proxy.size.height {
                    landscapeGame(in: proxy.size)
                } else {
                    portraitGame
                }
            }

            if showingMap {
                ChapterMapView(
                    game: game,
                    playLevel: { level in
                        beginLevel(level)
                    },
                    previewLevel: { level in
#if DEBUG
                        game.startDeveloperPreview(level: level)
                        withAnimation(.easeInOut(duration: 0.25)) { showingMap = false }
#endif
                    },
                    visitGarden: { showGarden = true }
                )
                .transition(.move(edge: .leading).combined(with: .opacity))
                .zIndex(4)
            }

            if showingIntro {
                IntroView {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        showingIntro = false
                        showingMap = true
                    }
                }
                    .transition(.opacity)
                    .zIndex(5)
            }

            if showingPause {
                pauseOverlay
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    .zIndex(6)
            }

            if showingBoosterBasket, let level = pendingLevel {
                BoosterBasketView(chapterIndex: GameModel.levels[level].chapterIndex) { caught in
                    game.completeBoosterBasket(for: level, caught: caught)
                    withAnimation(.easeInOut(duration: 0.28)) {
                        showingBoosterBasket = false
                        showingBoosterLoadout = true
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
                .zIndex(7)
            }

            if showingBoosterLoadout, let level = pendingLevel {
                BoosterLoadoutView(game: game, levelIndex: level) { selected in
                    game.start(level: level, using: selected)
                    pendingLevel = nil
                    withAnimation(.easeInOut(duration: 0.28)) {
                        showingBoosterLoadout = false
                        showingMap = false
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
                .zIndex(7)
            }
        }
        .overlay(alignment: .topLeading) {
#if DEBUG
            if game.isDeveloperPreview && !showingMap && !showingIntro {
                Label("DEV PREVIEW · LEVEL \(game.levelIndex + 1)", systemImage: "hammer.fill")
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(Color.black.opacity(0.72), in: Capsule())
                    .foregroundStyle(.yellow)
                    .padding(8)
                    .allowsHitTesting(false)
            }
#endif
        }
        .sheet(isPresented: $showGarden) { GardenView(game: game) }
        .onChange(of: game.soundOn) { _, isOn in
            MapMusicPlayer.shared.setPlaying(isOn && !showingIntro)
        }
        .onChange(of: showingIntro) { _, isShowingIntro in
            MapMusicPlayer.shared.setPlaying(game.soundOn && !isShowingIntro)
        }
        .overlay {
            if showingFinale {
                BirthdayFinaleView {
                    game.showingWin = false
                    withAnimation { showingMap = true }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
                .zIndex(8)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: showingFinale)
        .overlay {
            if winAlertPresented.wrappedValue {
                LevelWinCard(
                    title: finishedChapter ? "\(game.chapter.title) complete!" : "Henry got it back!",
                    message: "Henry recovered his \(game.level.stolenItem). Leo looks innocent—but only until the next level.",
                    buttonTitle: "Follow Leo"
                ) {
                    game.continueGarden()
                    withAnimation { showingMap = true }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.94)))
                .zIndex(8)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: winAlertPresented.wrappedValue)
    }

    private var showingFinale: Bool { game.showingWin && game.levelIndex == GameModel.levels.count - 1 }
    private var finishedChapter: Bool { game.levelIndex + 1 == game.chapter.levelRange.upperBound }
    private var levelTag: String {
        "CHAPTER \(game.level.chapterIndex + 1) · LEVEL \(game.levelIndex - game.chapter.levelRange.lowerBound + 1)"
    }

    private func beginLevel(_ level: Int) {
        pendingLevel = level
        withAnimation(.easeInOut(duration: 0.28)) {
            if game.shouldPlayBoosterBasket(before: level) {
                showingBoosterBasket = true
            } else {
                showingBoosterLoadout = true
            }
        }
    }

    /// The final level shows the birthday finale card instead of the usual alert.
    private var winAlertPresented: Binding<Bool> {
        Binding(
            get: { game.showingWin && !showingFinale },
            set: { game.showingWin = $0 }
        )
    }

    private var portraitGame: some View {
        VStack(spacing: 10) {
            header
            levelHeader
            mission
            statusMessage
            board
            Spacer(minLength: 3)
        }
        .padding(.horizontal, 12)
        .padding(.top, 4)
    }

    private func landscapeGame(in size: CGSize) -> some View {
        let boardSide = max(240, min(size.width * 0.90, size.height - 8))
        let sideSpace = (size.width - boardSide) / 2
        let hudWidth = min(180, max(124, sideSpace - 22))
        return ZStack {
            board
                .frame(width: boardSide, height: boardSide)

            HStack {
                landscapeHUD
                    .frame(width: hudWidth)
                Spacer()
            }
            .padding(.leading, 10)
            .padding(.vertical, 12)

            VStack(alignment: .trailing) {
                HStack {
                    Spacer()
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { showingPause = true }
                    } label: {
                        Image(systemName: "pause.fill")
                    }
                    .buttonStyle(CuteCircleButtonStyle(size: 52))
                    .accessibilityLabel("Pause game")
                }
                Spacer()
                if sideSpace >= 150 {
                    HenrySpeechBubble(message: game.message, portraitSize: 40, fontSize: 12, lineLimit: 5)
                        .frame(width: min(230, sideSpace - 30))
                }
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var landscapeHUD: some View {
        VStack(spacing: 9) {
            VStack(spacing: 5) {
                CutePill(text: levelTag, size: 8)
                StickerText(game.level.title, size: 17)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.72)
            }

            VStack(spacing: 3) {
                Text("\(game.moves)")
                    .font(Cute.font(28, .black))
                    .foregroundStyle(.white)
                    .shadow(color: Cute.leafDeep, radius: 0, y: 2)
                    .contentTransition(.numericText())
                    .frame(width: 62, height: 62)
                    .background(Circle().fill(LinearGradient(colors: [Cute.leaf, Cute.leafDeep], startPoint: .top, endPoint: .bottom)))
                    .overlay(alignment: .top) {
                        Capsule().fill(.white.opacity(0.35)).frame(width: 30, height: 7).padding(.top, 7)
                    }
                    .overlay(Circle().stroke(.white, lineWidth: 3))
                    .shadow(color: Cute.leafDeep.opacity(0.55), radius: 0, y: 3)
                Text("MOVES LEFT")
                    .font(Cute.font(8, .black))
                    .tracking(1.2)
                    .foregroundStyle(Cute.cocoaSoft)
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 5) {
                HStack(spacing: 7) {
                    LevelGoalIcon(level: game.level, size: 32)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(game.objectiveLabel)
                            .font(Cute.font(8, .black))
                            .foregroundStyle(Cute.cocoaSoft)
                        if game.level.isMultiGoal {
                            ObjectiveChips(game: game, iconSize: 18)
                        } else {
                            Text("\(min(game.objectiveProgress, game.objectiveAmount)) / \(game.objectiveAmount)")
                                .font(Cute.font(18, .black))
                                .foregroundStyle(Cute.cocoa)
                                .contentTransition(.numericText())
                        }
                    }
                    Spacer(minLength: 0)
                }

                CuteProgressBar(value: Double(game.objectiveProgress), total: Double(max(1, game.objectiveAmount)), height: 11)
            }
            .padding(10)
            .background(.white.opacity(0.8), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Cute.honey, style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
            }

            Text(game.objectiveInstruction)
                .font(Cute.font(9, .bold))
                .foregroundStyle(Cute.cocoaSoft)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.8)
        }
        .padding(13)
        .quiltedCard(corner: 24)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(game.moves) moves left. \(game.objectiveLabel == "COLLECT" ? game.level.goal.name : game.objectiveLabel.capitalized) \(game.objectiveProgress) of \(game.objectiveAmount).")
    }

    private var pauseOverlay: some View {
        ZStack {
            Color.black.opacity(0.42).ignoresSafeArea()
            VStack(spacing: 13) {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        CutePill(text: "PAUSED", icon: "pause.fill", size: 10)
                        StickerText(game.level.title, size: 26)
                    }
                    Spacer()
                    Button { game.soundOn.toggle() } label: {
                        Image(systemName: game.soundOn ? "speaker.wave.2.fill" : "speaker.slash.fill")
                    }
                    .buttonStyle(CuteCircleButtonStyle(size: 44))
                }

                mission
                statusMessage

                HStack(spacing: 10) {
                    Button {
                        showingPause = false
                        withAnimation { showingMap = true }
                    } label: {
                        PauseDestinationCard(
                            icon: "map.fill",
                            decoration: "pawprint.fill",
                            title: "Chapter Map",
                            subtitle: "Follow Leo's trail",
                            colors: [Color(red: 0.95, green: 0.65, blue: 0.19), Color(red: 0.80, green: 0.38, blue: 0.16)]
                        )
                    }
                    .buttonStyle(.plain)
                    Button {
                        showingPause = false
                        showGarden = true
                    } label: {
                        PauseDestinationCard(
                            icon: "house.and.flag.fill",
                            decoration: "camera.macro",
                            title: "Garden",
                            subtitle: "See what bloomed",
                            colors: [Color(red: 0.39, green: 0.66, blue: 0.34), Color(red: 0.18, green: 0.43, blue: 0.30)]
                        )
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { showingPause = false }
                } label: {
                    Label("Resume", systemImage: "play.fill")
                }
                .buttonStyle(CuteCandyButtonStyle())
            }
            .padding(20)
            .frame(maxWidth: 540)
            .quiltedCard(corner: 30)
            .padding(18)
        }
    }

    private var statusMessage: some View {
        HenrySpeechBubble(message: game.message, portraitSize: 30, fontSize: 12, lineLimit: 1)
            .frame(height: 34)
    }

    private var header: some View {
        HStack {
            Button { withAnimation { showingMap = true } } label: {
                HStack(spacing: 9) {
                    Text("❀").font(.title2).frame(width: 39, height: 39)
                        .background(LinearGradient(colors: [Cute.berry, Cute.berryDeep], startPoint: .top, endPoint: .bottom))
                        .foregroundStyle(.white).clipShape(Circle())
                        .overlay(Circle().stroke(.white, lineWidth: 2.5))
                    VStack(alignment: .leading, spacing: 1) {
                        StickerText("Henry's Garden Chase", size: 20, colors: [Cute.leaf, Cute.leafDeep])
                        Text("tap for the chapter map").font(Cute.font(10, .bold)).foregroundStyle(Cute.cocoaSoft)
                    }
                }
            }.buttonStyle(.plain)
            Spacer()
            Button { game.soundOn.toggle() } label: {
                Image(systemName: game.soundOn ? "speaker.wave.2.fill" : "speaker.slash.fill")
            }
            .buttonStyle(CuteCircleButtonStyle(size: 39))
        }
    }

    private var levelHeader: some View {
        HStack {
            Button { beginLevel(game.levelIndex - 1) } label: { Image(systemName: "chevron.left") }.disabled(game.levelIndex == 0)
            Spacer()
            VStack(spacing: 4) {
                CutePill(text: levelTag, size: 9)
                StickerText(game.level.title, size: 21)
                    .lineLimit(1).minimumScaleFactor(0.7)
            }
            Spacer()
            Button { beginLevel(game.levelIndex + 1) } label: { Image(systemName: "chevron.right") }.disabled(game.levelIndex >= game.unlocked - 1)
        }
        .buttonStyle(CuteCircleButtonStyle(size: 38))
    }

    private var mission: some View {
        HStack {
            metric(value: "\(game.moves)", label: "MOVES")
            Divider().frame(height: 35)
            HStack(spacing: 8) {
                LevelGoalIcon(level: game.level, size: 37)
                VStack(alignment: .leading, spacing: 0) {
                    Text(game.objectiveLabel)
                        .font(Cute.font(9, .black))
                        .foregroundStyle(Cute.cocoaSoft)
                    if game.level.isMultiGoal {
                        ObjectiveChips(game: game, iconSize: 16)
                    } else {
                        Text("\(min(game.objectiveProgress, game.objectiveAmount)) / \(game.objectiveAmount)")
                            .font(Cute.font(18, .black))
                            .foregroundStyle(Cute.cocoa)
                            .contentTransition(.numericText())
                    }
                }
            }.frame(maxWidth: .infinity)
            Divider().frame(height: 35)
            metric(value: "∞", label: "LIVES", color: .pink)
        }
        .padding(.vertical, 11).padding(.horizontal, 10)
        .quiltedCard(corner: 22)
    }

    private func metric(value: String, label: String, color: Color = Cute.leafDeep) -> some View {
        VStack(spacing: 0) {
            Text(value).font(Cute.font(24, .black)).foregroundStyle(color).contentTransition(.numericText())
            Text(label).font(Cute.font(9, .black)).tracking(1).foregroundStyle(Cute.cocoaSoft)
        }
        .frame(maxWidth: .infinity)
    }

    private var board: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(0..<(GameModel.size * GameModel.size), id: \.self) { index in
                    let row = index / GameModel.size
                    let col = index % GameModel.size
                    let position = Position(row: row, col: col)
                    let rescueStep = game.rescuePath.firstIndex(of: position)
                    let quietStep = game.quietRoute.firstIndex(of: position)
                    GameTileCell(
                        veggie: game.board[row][col].veggie,
                        powerUp: game.board[row][col].powerUp,
                        position: position,
                        size: side / 9.1,
                        dustLayers: game.dustLayers[row][col],
                        sleeping: game.sleepingLeos.contains(position),
                        barking: game.barkBursts.contains(position),
                        rescueStep: rescueStep,
                        rescueProgress: game.rescueProgress,
                        rescueTotal: game.rescuePath.count,
                        rescueBurst: game.rescueBursts.contains(position),
                        cozy: game.cozyCells.contains(position),
                        comfortBurst: game.comfortBursts.contains(position),
                        quietStep: quietStep,
                        quietProgress: game.quietProgress,
                        quietTotal: game.quietRoute.count,
                        quietBurst: game.quietBursts.contains(position),
                        mower: game.mowerPosition == position,
                        mowerBurst: game.mowerBurst && game.mowerPosition == position,
                        noise: game.noisyObjects[position],
                        noiseBurst: game.noiseBursts.contains(position),
                        breezeGust: game.breezeGust,
                        clue: game.hiddenClues[position],
                        revealedClue: game.clueBursts[position],
                        towel: game.level.keepsLeoDry && row == GameModel.size - 1 && (2...5).contains(col),
                        splash: game.splashes.contains(position),
                        dryBurst: game.dryBursts.contains(position),
                        nudgeBurst: game.nudgeBursts.contains(position),
                        parcel: game.parcels.contains(position),
                        parcelBurst: game.parcelBursts.contains(position),
                        parcelIsPad: game.level.parcelIsPad,
                        selected: game.selected == position,
                        popping: game.popping.contains(position),
                        hinting: game.hint.contains(position),
                        tap: { game.tap(position) },
                        drag: { game.drag(from: position, translation: $0) }
                    )
                }
            }
            .padding(8).frame(width: side, height: side)
            .background(Color(red: 0.42, green: 0.58, blue: 0.39)).clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color(red: 0.76, green: 0.66, blue: 0.48), lineWidth: 8))
            .shadow(color: Color(red: 0.32, green: 0.26, blue: 0.17).opacity(0.28), radius: 0, y: 7)
            .overlay { ThunderGlow(active: game.thunderFlash).frame(width: side, height: side) }
            .overlay { DoorKnockGlow(active: game.doorKnock).frame(width: side, height: side) }
            .overlay { PartyGlow(active: game.partyPop).frame(width: side, height: side) }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }.aspectRatio(1, contentMode: .fit)
    }

    private var boosters: some View {
        HStack(spacing: 6) {
            BoosterButton(icon: "arrow.triangle.2.circlepath", title: "Shuffle", action: game.shuffle)
            BoosterButton(icon: "drop.fill", title: "Water", action: game.water)
            BoosterButton(icon: "sparkles", title: "Hint", action: game.showHint)
        }
    }
}

struct GameTileCell: View {
    let veggie: Veggie
    let powerUp: PowerUp?
    let position: Position
    let size: CGFloat
    let dustLayers: Int
    let sleeping: Bool
    let barking: Bool
    let rescueStep: Int?
    let rescueProgress: Int
    let rescueTotal: Int
    let rescueBurst: Bool
    let cozy: Bool
    let comfortBurst: Bool
    let quietStep: Int?
    let quietProgress: Int
    let quietTotal: Int
    let quietBurst: Bool
    let mower: Bool
    let mowerBurst: Bool
    let noise: NoisyObject?
    let noiseBurst: Bool
    let breezeGust: Bool
    let clue: HiddenClue?
    let revealedClue: ClueKind?
    let towel: Bool
    let splash: Bool
    let dryBurst: Bool
    let nudgeBurst: Bool
    let parcel: Bool
    let parcelBurst: Bool
    let parcelIsPad: Bool
    let selected: Bool
    let popping: Bool
    let hinting: Bool
    let tap: () -> Void
    let drag: (CGSize) -> Void

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if cozy { CozyBlanketOverlay(size: size) }
            if towel { PoolTowelOverlay(size: size) }
            VeggieView(veggie: veggie, size: size)
            if cozy { CozyRimOverlay(bursting: comfortBurst, size: size) }
            if let powerUp { PowerUpBadge(powerUp: powerUp, size: size * 0.43) }
            if dustLayers > 0 { DustTileOverlay(layers: dustLayers, size: size) }
            if sleeping { SleepingLeoOverlay(size: size) }
            if barking { HenryBarkBurst(size: size) }
            if let rescueStep {
                RescuePathOverlay(
                    step: rescueStep,
                    progress: rescueProgress,
                    total: rescueTotal,
                    bursting: rescueBurst,
                    size: size
                )
            }
            if let quietStep {
                QuietRouteOverlay(
                    step: quietStep,
                    progress: quietProgress,
                    total: quietTotal,
                    bursting: quietBurst,
                    size: size
                )
            }
            if mower { MowerMarkerOverlay(bursting: mowerBurst, size: size) }
            if let noise { NoisyObjectOverlay(object: noise, gust: breezeGust, size: size) }
            if noiseBurst { HushBurst(cleared: noise == nil, size: size) }
            if let clue { HiddenClueOverlay(clue: clue, size: size) }
            if let revealedClue { ClueRevealBurst(kind: revealedClue, size: size) }
            if splash { SplashOverlay(size: size) }
            if dryBurst || nudgeBurst { HenryDryBurst(text: nudgeBurst ? "BACK YOU GO!" : "DRY!", size: size) }
            if parcel { ParcelOverlay(isPad: parcelIsPad, size: size) }
            if parcelBurst { ParcelDeliveryBurst(isPad: parcelIsPad, size: size) }
        }
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .background(Color.white.opacity(0.13), in: RoundedRectangle(cornerRadius: 10))
            .scaleEffect(scale)
            .opacity(popping ? 0 : 1)
            .shadow(color: selected ? .white : .clear, radius: 6)
            .contentShape(Rectangle())
            .onTapGesture(perform: tap)
            .gesture(DragGesture(minimumDistance: 15).onEnded { drag($0.translation) })
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: popping)
            .animation(.easeInOut(duration: 0.3), value: hinting)
    }

    private var scale: CGFloat {
        if popping { return 0.05 }
        if hinting { return 1.14 }
        if selected { return 1.10 }
        return 1
    }
}

struct DustGoalIcon: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.24)
                .fill(Color(red: 0.65, green: 0.61, blue: 0.54).gradient)
            Image(systemName: "wind")
                .font(.system(size: size * 0.46, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
        .overlay(RoundedRectangle(cornerRadius: size * 0.24).stroke(.white, lineWidth: 2))
    }
}

struct SleepGoalIcon: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.24)
                .fill(Color(red: 0.31, green: 0.55, blue: 0.82).gradient)
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: size * 0.43, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
        .overlay(RoundedRectangle(cornerRadius: size * 0.24).stroke(.white, lineWidth: 2))
    }
}

struct RescueGoalIcon: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.24)
                .fill(Color(red: 0.91, green: 0.57, blue: 0.20).gradient)
            Image(systemName: "pawprint.fill")
                .font(.system(size: size * 0.44, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
        .overlay(RoundedRectangle(cornerRadius: size * 0.24).stroke(.white, lineWidth: 2))
    }
}

struct QuietRouteGoalIcon: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.24)
                .fill(Color(red: 0.34, green: 0.68, blue: 0.31).gradient)
            Image(systemName: "leaf.fill")
                .font(.system(size: size * 0.43, weight: .bold))
                .foregroundStyle(.white)
            Image(systemName: "pawprint.fill")
                .font(.system(size: size * 0.19, weight: .black))
                .foregroundStyle(Color(red: 0.33, green: 0.20, blue: 0.11))
                .offset(x: size * 0.19, y: size * 0.18)
        }
        .frame(width: size, height: size)
        .overlay(RoundedRectangle(cornerRadius: size * 0.24).stroke(.white, lineWidth: 2))
    }
}

struct NoiseGoalIcon: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.24)
                .fill(Color(red: 0.42, green: 0.53, blue: 0.62).gradient)
            Image(systemName: "speaker.slash.fill")
                .font(.system(size: size * 0.40, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
        .overlay(RoundedRectangle(cornerRadius: size * 0.24).stroke(.white, lineWidth: 2))
    }
}

struct ClueGoalIcon: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.24)
                .fill(Color(red: 0.78, green: 0.42, blue: 0.55).gradient)
            Image(systemName: "magnifyingglass")
                .font(.system(size: size * 0.43, weight: .black))
                .foregroundStyle(.white)
            Image(systemName: "heart.fill")
                .font(.system(size: size * 0.16, weight: .black))
                .foregroundStyle(Color.yellow)
                .offset(x: size * 0.17, y: -size * 0.17)
        }
        .frame(width: size, height: size)
        .overlay(RoundedRectangle(cornerRadius: size * 0.24).stroke(.white, lineWidth: 2))
    }
}

struct SplashGoalIcon: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.24)
                .fill(Color(red: 0.26, green: 0.62, blue: 0.86).gradient)
            Image(systemName: "drop.fill")
                .font(.system(size: size * 0.42, weight: .bold))
                .foregroundStyle(.white)
            Image(systemName: "sun.max.fill")
                .font(.system(size: size * 0.18, weight: .black))
                .foregroundStyle(Color.yellow)
                .offset(x: size * 0.19, y: -size * 0.19)
        }
        .frame(width: size, height: size)
        .overlay(RoundedRectangle(cornerRadius: size * 0.24).stroke(.white, lineWidth: 2))
    }
}

struct ParcelGoalIcon: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.24)
                .fill(Color(red: 0.72, green: 0.48, blue: 0.27).gradient)
            Image(systemName: "shippingbox.fill")
                .font(.system(size: size * 0.43, weight: .bold))
                .foregroundStyle(.white)
            Image(systemName: "arrow.down")
                .font(.system(size: size * 0.17, weight: .black))
                .foregroundStyle(Color.yellow)
                .offset(x: size * 0.18, y: size * 0.18)
        }
        .frame(width: size, height: size)
        .overlay(RoundedRectangle(cornerRadius: size * 0.24).stroke(.white, lineWidth: 2))
    }
}

/// Leo's striped beach towel along the bottom edge, drawn beneath the piece.
private struct PoolTowelOverlay: View {
    let size: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.18)
            .fill(
                LinearGradient(
                    stops: [
                        .init(color: Color(red: 0.99, green: 0.83, blue: 0.36), location: 0.0),
                        .init(color: Color(red: 0.99, green: 0.83, blue: 0.36), location: 0.33),
                        .init(color: .white, location: 0.33),
                        .init(color: .white, location: 0.66),
                        .init(color: Color(red: 0.98, green: 0.55, blue: 0.45), location: 0.66),
                        .init(color: Color(red: 0.98, green: 0.55, blue: 0.45), location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .opacity(0.85)
            )
            .frame(width: size * 1.02, height: size * 1.02)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

/// A pool splash: a wavy blue rim and a drop badge, keeping Leo's face clear.
private struct SplashOverlay: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    Color(red: 0.30, green: 0.68, blue: 0.95).opacity(0.95),
                    style: StrokeStyle(lineWidth: size * 0.09, lineCap: .round, dash: [size * 0.10, size * 0.05])
                )
            Image(systemName: "drop.fill")
                .font(.system(size: size * 0.20, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: size * 0.38, height: size * 0.38)
                .background(Color(red: 0.22, green: 0.56, blue: 0.86), in: Circle())
                .overlay(Circle().stroke(.white, lineWidth: 2))
                .offset(x: size * 0.29, y: -size * 0.28)
        }
        .frame(width: size * 0.94, height: size * 0.94)
        .allowsHitTesting(false)
        .accessibilityLabel("Pool splash")
    }
}

/// Henry pops in when a splash is dried or nudged back toward the pool.
private struct HenryDryBurst: View {
    let text: String
    let size: CGFloat

    var body: some View {
        ZStack {
            if let portrait = UIImage(named: "henry-map-marker") {
                Image(uiImage: portrait)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size * 0.34, height: size * 0.34)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(.white, lineWidth: 2))
                    .offset(x: -size * 0.30, y: -size * 0.28)
            }
            Text(text)
                .font(.system(size: size * 0.10, weight: .black, design: .rounded))
                .foregroundStyle(Color(red: 0.16, green: 0.42, blue: 0.66))
                .lineLimit(1)
                .fixedSize()
                .padding(.horizontal, size * 0.07)
                .padding(.vertical, size * 0.035)
                .background(.white, in: Capsule())
                .overlay(Capsule().stroke(Color(red: 0.30, green: 0.68, blue: 0.95), lineWidth: 1.5))
                .offset(y: size * 0.31)
        }
        .frame(width: size * 0.94, height: size * 0.94)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// One icon per level for HUDs and maps; two-goal finale levels show a birthday gift.
struct LevelGoalIcon: View {
    let level: Level
    let size: CGFloat

    var body: some View {
        if level.isMultiGoal {
            BirthdayGoalIcon(size: size)
        } else {
            ObjectiveIcon(objective: level.objectives[0], level: level, size: size)
        }
    }
}

struct ObjectiveIcon: View {
    let objective: Objective
    let level: Level
    let size: CGFloat

    var body: some View {
        switch objective {
        case .dust: DustGoalIcon(size: size)
        case .sleep: SleepGoalIcon(size: size)
        case .rescue: RescueGoalIcon(size: size)
        case .comfort: ComfortGoalIcon(size: size)
        case .quietRoute: QuietRouteGoalIcon(size: size)
        case .noise: NoiseGoalIcon(size: size)
        case .clues: ClueGoalIcon(size: size)
        case .splash: SplashGoalIcon(size: size)
        case .parcels: if level.parcelIsPad { PadGoalIcon(size: size) } else { ParcelGoalIcon(size: size) }
        case .collect: VeggieView(veggie: level.goal, size: size)
        }
    }
}

/// Compact per-goal progress for levels that combine two objectives.
struct ObjectiveChips: View {
    @ObservedObject var game: GameModel
    let iconSize: CGFloat

    var body: some View {
        HStack(spacing: 7) {
            ForEach(game.level.objectives, id: \.self) { objective in
                HStack(spacing: 3) {
                    ObjectiveIcon(objective: objective, level: game.level, size: iconSize)
                    Text("\(min(game.progress(of: objective), game.amount(of: objective)))/\(game.amount(of: objective))")
                        .font(.system(size: iconSize * 0.78, weight: .bold, design: .rounded))
                        .foregroundStyle(game.isComplete(objective) ? Color(red: 0.24, green: 0.55, blue: 0.27) : .primary)
                        .contentTransition(.numericText())
                }
            }
        }
        .fixedSize()
    }
}

struct BirthdayGoalIcon: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.24)
                .fill(Color(red: 0.93, green: 0.45, blue: 0.56).gradient)
            Image(systemName: "gift.fill")
                .font(.system(size: size * 0.42, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
        .overlay(RoundedRectangle(cornerRadius: size * 0.24).stroke(.white, lineWidth: 2))
    }
}

struct PadGoalIcon: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.24)
                .fill(Color(red: 0.36, green: 0.62, blue: 0.86).gradient)
            PeanutButterPadBadge(size: size * 0.66)
            Image(systemName: "arrow.down")
                .font(.system(size: size * 0.17, weight: .black))
                .foregroundStyle(Color.yellow)
                .offset(x: size * 0.20, y: size * 0.20)
        }
        .frame(width: size, height: size)
        .overlay(RoundedRectangle(cornerRadius: size * 0.24).stroke(.white, lineWidth: 2))
    }
}

/// A round rubber lick pad with a swirl of peanut butter, drawn in SwiftUI.
private struct PeanutButterPadBadge: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle().fill(Color(red: 0.30, green: 0.58, blue: 0.84))
            Circle()
                .stroke(Color.white.opacity(0.55), style: StrokeStyle(lineWidth: size * 0.05, dash: [size * 0.06, size * 0.05]))
                .padding(size * 0.12)
            Circle()
                .fill(Color(red: 0.80, green: 0.55, blue: 0.27))
                .frame(width: size * 0.46, height: size * 0.46)
            Circle()
                .trim(from: 0.05, to: 0.75)
                .stroke(Color(red: 0.93, green: 0.74, blue: 0.47), style: StrokeStyle(lineWidth: size * 0.05, lineCap: .round))
                .frame(width: size * 0.26, height: size * 0.26)
        }
        .frame(width: size, height: size)
        .overlay(Circle().stroke(.white, lineWidth: 2))
    }
}

/// A parcel rides with the piece while leaving Leo's face clear and readable.
private struct ParcelOverlay: View {
    var isPad = false
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    isPad ? Color(red: 0.36, green: 0.62, blue: 0.86).opacity(0.95) : Color(red: 0.82, green: 0.57, blue: 0.30).opacity(0.95),
                    style: StrokeStyle(lineWidth: size * 0.075, lineCap: .round, dash: [size * 0.14, size * 0.045])
                )

            if isPad {
                PeanutButterPadBadge(size: size * 0.40)
                    .offset(x: size * 0.29, y: -size * 0.28)
            } else {
                Image(systemName: "shippingbox.fill")
                    .font(.system(size: size * 0.20, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: size * 0.40, height: size * 0.40)
                    .background(Color(red: 0.67, green: 0.42, blue: 0.23), in: Circle())
                    .overlay(Circle().stroke(.white, lineWidth: 2))
                    .offset(x: size * 0.29, y: -size * 0.28)
            }

            Image(systemName: "arrow.down")
                .font(.system(size: size * 0.16, weight: .black))
                .foregroundStyle(Color(red: 0.57, green: 0.32, blue: 0.17))
                .padding(size * 0.06)
                .background(.white.opacity(0.90), in: Circle())
                .offset(x: -size * 0.30, y: size * 0.29)
        }
        .frame(width: size * 0.94, height: size * 0.94)
        .allowsHitTesting(false)
        .accessibilityLabel(isPad ? "Peanut-butter pad; clear pieces below it" : "Parcel; clear pieces below it")
    }
}

private struct ParcelDeliveryBurst: View {
    var isPad = false
    let size: CGFloat

    var body: some View {
        ZStack {
            if let portrait = UIImage(named: "henry-map-marker") {
                Image(uiImage: portrait)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size * 0.34, height: size * 0.34)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(.white, lineWidth: 2))
                    .offset(x: -size * 0.30, y: -size * 0.28)
            }
            Text(isPad ? "YUM!" : "DELIVERED!")
                .font(.system(size: size * 0.095, weight: .black, design: .rounded))
                .foregroundStyle(Color(red: 0.54, green: 0.31, blue: 0.18))
                .padding(.horizontal, size * 0.07)
                .padding(.vertical, size * 0.035)
                .background(.white, in: Capsule())
                .overlay(Capsule().stroke(Color.orange, lineWidth: 1.5))
                .offset(y: size * 0.31)
        }
        .frame(width: size * 0.94, height: size * 0.94)
        .transition(.scale(scale: 0.55).combined(with: .opacity))
        .allowsHitTesting(false)
        .accessibilityLabel(isPad ? "Peanut-butter pad reached Mom" : "Parcel delivered to the doormat")
    }
}

/// Soft leaves frame a hidden clue without obscuring the Leo expression beneath.
private struct HiddenClueOverlay: View {
    let clue: HiddenClue
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    Color(red: 0.34, green: 0.66, blue: 0.31).opacity(0.94),
                    style: StrokeStyle(lineWidth: size * 0.08, lineCap: .round, dash: [size * 0.10, size * 0.055])
                )

            Image(systemName: "leaf.fill")
                .font(.system(size: size * 0.20, weight: .black))
                .foregroundStyle(Color(red: 0.24, green: 0.58, blue: 0.25))
                .padding(size * 0.055)
                .background(.white.opacity(0.88), in: Circle())
                .offset(x: size * 0.30, y: -size * 0.28)

            Image(systemName: "questionmark")
                .font(.system(size: size * 0.16, weight: .black, design: .rounded))
                .foregroundStyle(Color(red: 0.66, green: 0.31, blue: 0.48))
                .padding(size * 0.07)
                .background(.white.opacity(0.90), in: Circle())
                .offset(x: -size * 0.30, y: size * 0.29)

            if clue.cover > 1 {
                Text("\(clue.cover)")
                    .font(.system(size: size * 0.14, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: size * 0.24, height: size * 0.24)
                    .background(Color(red: 0.30, green: 0.55, blue: 0.25), in: Circle())
                    .overlay(Circle().stroke(.white, lineWidth: 1.5))
                    .offset(x: size * 0.30, y: size * 0.29)
            }
        }
        .frame(width: size * 0.94, height: size * 0.94)
        .allowsHitTesting(false)
        .accessibilityLabel(clue.cover > 1 ? "Hidden clue under \(clue.cover) leaf layers" : "Hidden clue under leaves")
    }
}

private struct ClueRevealBurst: View {
    let kind: ClueKind
    let size: CGFloat

    private var symbol: String {
        switch kind {
        case .slipper: "heart.fill"
        case .keys: "key.fill"
        case .pawprints: "pawprint.fill"
        }
    }

    private var label: String {
        switch kind {
        case .slipper: "SLIPPER!"
        case .keys: "KEYS!"
        case .pawprints: "FOOTSTEPS!"
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(red: 0.92, green: 0.54, blue: 0.67), lineWidth: size * 0.065)

            Image(systemName: symbol)
                .font(.system(size: size * 0.22, weight: .black))
                .foregroundStyle(kind == .slipper ? Color.pink : Color(red: 0.82, green: 0.55, blue: 0.18))
                .frame(width: size * 0.40, height: size * 0.40)
                .background(.white.opacity(0.94), in: Circle())
                .overlay(Circle().stroke(.white, lineWidth: 2))
                .offset(x: -size * 0.27, y: -size * 0.26)

            Text(label)
                .font(.system(size: size * 0.095, weight: .black, design: .rounded))
                .foregroundStyle(Color(red: 0.55, green: 0.24, blue: 0.38))
                .padding(.horizontal, size * 0.065)
                .padding(.vertical, size * 0.035)
                .background(.white, in: Capsule())
                .overlay(Capsule().stroke(Color.pink, lineWidth: 1.5))
                .offset(y: size * 0.31)
        }
        .frame(width: size * 0.94, height: size * 0.94)
        .transition(.scale(scale: 0.55).combined(with: .opacity))
        .allowsHitTesting(false)
        .accessibilityLabel("Found a familiar clue from Mom")
    }
}

/// A rattly can or flapping bag: a rim plus an edge badge, so Leo's face stays readable.
private struct NoisyObjectOverlay: View {
    let object: NoisyObject
    let gust: Bool
    let size: CGFloat

    private var isBag: Bool { object.kind == .bag }
    private var rimColor: Color {
        isBag ? Color(red: 0.62, green: 0.82, blue: 0.93) : Color(red: 0.56, green: 0.60, blue: 0.64)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    rimColor.opacity(0.95),
                    style: StrokeStyle(lineWidth: size * 0.09, lineCap: .round, dash: isBag ? [6, 3] : [])
                )

            Image(systemName: isBag ? "bag.fill" : "cylinder.fill")
                .font(.system(size: size * 0.21, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: size * 0.38, height: size * 0.38)
                .background(isBag ? Color(red: 0.36, green: 0.62, blue: 0.82) : Color(red: 0.40, green: 0.44, blue: 0.50), in: Circle())
                .overlay(Circle().stroke(.white, lineWidth: 2))
                .rotationEffect(.degrees(isBag && gust ? 18 : 0))
                .offset(x: size * 0.29, y: -size * 0.28)

            if object.hits > 1 {
                Text("\(object.hits)")
                    .font(.system(size: size * 0.15, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: size * 0.25, height: size * 0.25)
                    .background(Color(red: 0.36, green: 0.40, blue: 0.45), in: Circle())
                    .overlay(Circle().stroke(.white, lineWidth: 1.5))
                    .offset(x: -size * 0.30, y: size * 0.29)
            }
        }
        .frame(width: size * 0.94, height: size * 0.94)
        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: gust)
        .allowsHitTesting(false)
        .accessibilityLabel(isBag ? "Flapping plastic bag" : object.hits > 1 ? "Rattling can, \(object.hits) clatters left" : "Rattling can")
    }
}

/// Henry pops in to settle a noise; shows "SHH!" while it still rattles, "QUIET!" once it's gone.
private struct HushBurst: View {
    let cleared: Bool
    let size: CGFloat

    var body: some View {
        ZStack {
            if let portrait = UIImage(named: "henry-map-marker") {
                Image(uiImage: portrait)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size * 0.34, height: size * 0.34)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(.white, lineWidth: 2))
                    .offset(x: -size * 0.30, y: -size * 0.28)
            }
            Text(cleared ? "QUIET!" : "SHH!")
                .font(.system(size: size * 0.11, weight: .black, design: .rounded))
                .foregroundStyle(Color(red: 0.24, green: 0.33, blue: 0.42))
                .padding(.horizontal, size * 0.07)
                .padding(.vertical, size * 0.035)
                .background(.white, in: Capsule())
                .overlay(Capsule().stroke(Color(red: 0.42, green: 0.53, blue: 0.62), lineWidth: 1.5))
                .offset(y: size * 0.31)
        }
        .frame(width: size * 0.94, height: size * 0.94)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// The leafy safe route stays around the piece rim so Leo's expression remains readable.
private struct QuietRouteOverlay: View {
    let step: Int
    let progress: Int
    let total: Int
    let bursting: Bool
    let size: CGFloat

    private var completed: Bool { step < progress }
    private var active: Bool { step == progress }
    private var destination: Bool { step == total - 1 }

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    completed ? Color.green.opacity(0.78) : active ? Color.yellow.opacity(0.98) : Color.white.opacity(0.46),
                    style: StrokeStyle(lineWidth: active ? size * 0.075 : size * 0.045, lineCap: .round, dash: active || completed ? [] : [3, 4])
                )

            Image(systemName: completed ? "checkmark.circle.fill" : "leaf.fill")
                .font(.system(size: size * 0.17, weight: .black))
                .foregroundStyle(completed ? .green : active ? Color(red: 0.28, green: 0.66, blue: 0.24) : .white.opacity(0.78))
                .padding(size * 0.05)
                .background(.white.opacity(0.86), in: Circle())
                .offset(x: -size * 0.31, y: size * 0.29)

            if active, let portrait = UIImage(named: "henry-map-marker") {
                Image(uiImage: portrait)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size * 0.34, height: size * 0.34)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(.white, lineWidth: 2))
                    .offset(x: -size * 0.30, y: -size * 0.28)
            }

            if destination {
                Image(systemName: "house.fill")
                    .font(.system(size: size * 0.15, weight: .black))
                    .foregroundStyle(Color(red: 0.82, green: 0.39, blue: 0.18))
                    .padding(size * 0.055)
                    .background(.white.opacity(0.88), in: Circle())
                    .offset(x: size * 0.31, y: -size * 0.29)
            }

            if bursting {
                Text(destination && progress >= total ? "HOME!" : "SAFE WAY!")
                    .font(.system(size: size * 0.10, weight: .black, design: .rounded))
                    .foregroundStyle(Color(red: 0.20, green: 0.38, blue: 0.17))
                    .padding(.horizontal, size * 0.07)
                    .padding(.vertical, size * 0.035)
                    .background(.white, in: Capsule())
                    .overlay(Capsule().stroke(Color.green, lineWidth: 1.5))
                    .offset(y: -size * 0.31)
            }
        }
        .frame(width: size * 0.94, height: size * 0.94)
        .allowsHitTesting(false)
        .accessibilityLabel(active ? "Henry's next quiet leaf" : completed ? "Completed quiet leaf" : "Future quiet leaf")
    }
}

/// A compact mower badge travels around the board edge without covering the match piece.
private struct MowerMarkerOverlay: View {
    let bursting: Bool
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.red.opacity(bursting ? 0.92 : 0.62), lineWidth: size * 0.055)
            ZStack {
                RoundedRectangle(cornerRadius: size * 0.035)
                    .fill(Color(red: 0.88, green: 0.18, blue: 0.13))
                    .frame(width: size * 0.25, height: size * 0.14)
                HStack(spacing: size * 0.11) {
                    Circle().fill(Color.black.opacity(0.80)).frame(width: size * 0.075, height: size * 0.075)
                    Circle().fill(Color.black.opacity(0.80)).frame(width: size * 0.075, height: size * 0.075)
                }
                .offset(y: size * 0.075)
                Path { path in
                    path.move(to: CGPoint(x: size * 0.08, y: size * 0.08))
                    path.addLine(to: CGPoint(x: size * 0.01, y: -size * 0.11))
                }
                .stroke(Color.white, style: StrokeStyle(lineWidth: size * 0.035, lineCap: .round))
            }
            .frame(width: size * 0.38, height: size * 0.38)
            .padding(size * 0.025)
            .background(.white.opacity(0.90), in: Circle())
            .offset(x: size * 0.29, y: -size * 0.28)

            if bursting {
                Text("BRRRM")
                    .font(.system(size: size * 0.10, weight: .black, design: .rounded))
                    .foregroundStyle(.red)
                    .padding(.horizontal, size * 0.06)
                    .padding(.vertical, size * 0.025)
                    .background(.white, in: Capsule())
                    .offset(x: -size * 0.18, y: -size * 0.31)
            }
        }
        .frame(width: size * 0.94, height: size * 0.94)
        .allowsHitTesting(false)
        .accessibilityLabel("Lawnmower on its outer loop")
    }
}

private struct RescuePathOverlay: View {
    let step: Int
    let progress: Int
    let total: Int
    let bursting: Bool
    let size: CGFloat

    private var completed: Bool { step < progress }
    private var active: Bool { step == progress }
    private var destination: Bool { step == total - 1 }

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    completed ? Color.green.opacity(0.68) : active ? Color.yellow.opacity(0.98) : Color.white.opacity(0.48),
                    style: StrokeStyle(lineWidth: active ? size * 0.075 : size * 0.045, lineCap: .round, dash: active || completed ? [] : [3, 4])
                )

            Image(systemName: completed ? "checkmark.circle.fill" : "pawprint.fill")
                .font(.system(size: size * 0.17, weight: .black))
                .foregroundStyle(completed ? .green : active ? Color.orange : .white.opacity(0.74))
                .padding(size * 0.045)
                .background(.white.opacity(0.80), in: Circle())
                .offset(x: -size * 0.31, y: size * 0.29)

            if active, let portrait = UIImage(named: "henry-map-marker") {
                Image(uiImage: portrait)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size * 0.34, height: size * 0.34)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(.white, lineWidth: 2))
                    .offset(x: -size * 0.30, y: -size * 0.28)
            }

            if destination {
                Image(systemName: "heart.fill")
                    .font(.system(size: size * 0.17, weight: .black))
                    .foregroundStyle(.pink)
                    .padding(size * 0.05)
                    .background(.white.opacity(0.86), in: Circle())
                    .offset(x: size * 0.31, y: -size * 0.29)
            }

            if bursting {
                Text(destination && progress >= total ? "FOUND LEO!" : "THIS WAY!")
                    .font(.system(size: size * 0.11, weight: .black, design: .rounded))
                    .foregroundStyle(Color(red: 0.22, green: 0.31, blue: 0.18))
                    .padding(.horizontal, size * 0.07)
                    .padding(.vertical, size * 0.035)
                    .background(.white, in: Capsule())
                    .overlay(Capsule().stroke(Color.orange, lineWidth: 1.5))
                    .offset(y: -size * 0.31)
            }
        }
        .frame(width: size * 0.94, height: size * 0.94)
        .allowsHitTesting(false)
        .accessibilityLabel(active ? "Henry's next pawstep" : completed ? "Completed pawstep" : "Future pawstep")
    }
}

private struct SleepingLeoOverlay: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.blue.opacity(0.035))
                .overlay(Circle().stroke(Color(red: 0.34, green: 0.61, blue: 0.91).opacity(0.88), lineWidth: size * 0.07))

            Image(systemName: "moon.fill")
                .font(.system(size: size * 0.18, weight: .bold))
                .foregroundStyle(Color(red: 0.98, green: 0.80, blue: 0.25))
                .padding(size * 0.065)
                .background(Color.white.opacity(0.84), in: Circle())
                .offset(x: -size * 0.31, y: size * 0.29)

            Text("Zz")
                .font(.system(size: size * 0.18, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, size * 0.075)
                .padding(.vertical, size * 0.035)
                .background(Color(red: 0.26, green: 0.51, blue: 0.84), in: Capsule())
                .offset(x: size * 0.27, y: -size * 0.31)
        }
        .frame(width: size * 0.94, height: size * 0.94)
        .allowsHitTesting(false)
        .accessibilityLabel("Sleeping Leo")
    }
}

private struct HenryBarkBurst: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            if let portrait = UIImage(named: "henry-map-marker") {
                Image(uiImage: portrait)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size * 0.48, height: size * 0.48)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(.white, lineWidth: 2))
                    .offset(x: -size * 0.23, y: size * 0.22)
            }
            Text("WOOF!")
                .font(.system(size: size * 0.15, weight: .black, design: .rounded))
                .foregroundStyle(Color(red: 0.19, green: 0.28, blue: 0.18))
                .padding(.horizontal, size * 0.08)
                .padding(.vertical, size * 0.05)
                .background(.white, in: Capsule())
                .overlay(Capsule().stroke(Color.orange, lineWidth: 2))
                .offset(x: size * 0.16, y: -size * 0.27)
        }
        .frame(width: size, height: size)
        .transition(.scale(scale: 0.45).combined(with: .opacity))
        .allowsHitTesting(false)
        .accessibilityLabel("Henry barks and wakes Leo")
    }
}

struct ComfortGoalIcon: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.24)
                .fill(Color(red: 0.86, green: 0.47, blue: 0.27).gradient)
            Image(systemName: "heart.fill")
                .font(.system(size: size * 0.42, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
        .overlay(RoundedRectangle(cornerRadius: size * 0.24).stroke(.white, lineWidth: 2))
    }
}

/// The blanket lies under the piece: a warm knit cell with a stitched edge, so the Leo face stays clear.
private struct CozyBlanketOverlay: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.18)
                .fill(
                    RadialGradient(
                        colors: [Color(red: 1.00, green: 0.86, blue: 0.62).opacity(0.55), Color(red: 0.91, green: 0.58, blue: 0.36).opacity(0.85)],
                        center: .center,
                        startRadius: size * 0.20,
                        endRadius: size * 0.62
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: size * 0.18)
                        .strokeBorder(
                            Color(red: 0.99, green: 0.93, blue: 0.80).opacity(0.95),
                            style: StrokeStyle(lineWidth: size * 0.045, lineCap: .round, dash: [size * 0.07, size * 0.05])
                        )
                        .padding(size * 0.04)
                }
        }
        .frame(width: size * 1.02, height: size * 1.02)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Sits on top of a cozy piece: a warm rim and a small heart badge, keeping the center clear.
private struct CozyRimOverlay: View {
    let bursting: Bool
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(red: 0.95, green: 0.60, blue: 0.30).opacity(0.92), lineWidth: size * 0.065)

            Image(systemName: "heart.fill")
                .font(.system(size: size * 0.15, weight: .black))
                .foregroundStyle(Color(red: 0.84, green: 0.36, blue: 0.24))
                .padding(size * 0.05)
                .background(.white.opacity(0.84), in: Circle())
                .offset(x: -size * 0.31, y: size * 0.29)

            if bursting {
                Text("SNUG!")
                    .font(.system(size: size * 0.11, weight: .black, design: .rounded))
                    .foregroundStyle(Color(red: 0.45, green: 0.22, blue: 0.12))
                    .padding(.horizontal, size * 0.07)
                    .padding(.vertical, size * 0.035)
                    .background(.white, in: Capsule())
                    .overlay(Capsule().stroke(Color.orange, lineWidth: 1.5))
                    .offset(y: -size * 0.31)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: size * 0.94, height: size * 0.94)
        .allowsHitTesting(false)
        .accessibilityLabel("Cozy blanket")
    }
}

/// A slow, soft brightening for thunder. Never a strobe; skipped entirely with Reduce Motion.
private struct ThunderGlow: View {
    let active: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(Color(red: 0.88, green: 0.90, blue: 1.00))
            .opacity(active && !reduceMotion ? 0.22 : 0)
            .overlay(alignment: .top) {
                Image(systemName: "cloud.bolt.rain.fill")
                    .font(.system(size: 30, weight: .bold))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(Color(red: 0.42, green: 0.47, blue: 0.62), Color(red: 0.98, green: 0.78, blue: 0.20), Color(red: 0.36, green: 0.62, blue: 0.92))
                    .padding(10)
                    .background(.white.opacity(0.85), in: Circle())
                    .offset(y: -16)
                    .opacity(active ? 1 : 0)
                    .scaleEffect(active ? 1 : 0.7)
            }
            .animation(.easeInOut(duration: 0.35), value: active)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

/// A gentle doorbell cue for Chapter Nine. It never flashes rapidly or changes progress.
/// Birthday bustle: a soft confetti glow with a balloon badge. Reduce Motion skips the glow.
private struct PartyGlow: View {
    let active: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(Color(red: 1.00, green: 0.70, blue: 0.80))
            .opacity(active && !reduceMotion ? 0.14 : 0)
            .overlay(alignment: .top) {
                HStack(spacing: 5) {
                    Image(systemName: "balloon.2.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(Color(red: 0.93, green: 0.36, blue: 0.48), Color(red: 0.36, green: 0.62, blue: 0.86))
                    Text("PARTY TIME")
                }
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(Color(red: 0.55, green: 0.22, blue: 0.33))
                .padding(.horizontal, 11)
                .padding(.vertical, 7)
                .background(.white.opacity(0.90), in: Capsule())
                .offset(y: -12)
                .opacity(active ? 1 : 0)
                .scaleEffect(active && !reduceMotion ? 1.04 : 1)
            }
            .animation(.easeInOut(duration: 0.30), value: active)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

private struct DoorKnockGlow: View {
    let active: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(Color(red: 1.00, green: 0.82, blue: 0.45))
            .opacity(active && !reduceMotion ? 0.13 : 0)
            .overlay(alignment: .top) {
                HStack(spacing: 5) {
                    Image(systemName: "door.left.hand.closed")
                    Text("KNOCK KNOCK")
                }
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(Color(red: 0.42, green: 0.27, blue: 0.17))
                .padding(.horizontal, 11)
                .padding(.vertical, 7)
                .background(.white.opacity(0.90), in: Capsule())
                .offset(y: -12)
                .opacity(active ? 1 : 0)
                .scaleEffect(active && !reduceMotion ? 1.04 : 1)
            }
            .animation(.easeInOut(duration: 0.30), value: active)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

private struct DustTileOverlay: View {
    let layers: Int
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.18)
                .fill(Color.white.opacity(layers > 1 ? 0.10 : 0.05))
                .overlay {
                    RoundedRectangle(cornerRadius: size * 0.18)
                        .stroke(
                            Color(red: 0.49, green: 0.44, blue: 0.37).opacity(layers > 1 ? 0.92 : 0.68),
                            lineWidth: layers > 1 ? size * 0.10 : size * 0.065
                        )
                }

            VStack {
                HStack {
                    dustPuff(scale: 0.20, opacity: 0.72)
                    dustPuff(scale: 0.14, opacity: 0.50)
                    Spacer()
                    dustPuff(scale: 0.17, opacity: 0.62)
                }
                Spacer()
                HStack {
                    dustPuff(scale: 0.15, opacity: 0.54)
                    Spacer()
                    dustPuff(scale: 0.21, opacity: 0.72)
                    dustPuff(scale: 0.12, opacity: 0.48)
                }
            }
            .padding(size * 0.035)

            Image(systemName: "wind")
                .font(.system(size: size * 0.20, weight: .black))
                .foregroundStyle(Color(red: 0.28, green: 0.25, blue: 0.22).opacity(0.86))
                .padding(size * 0.06)
                .background(.white.opacity(0.78), in: Circle())
                .offset(x: -size * 0.31, y: size * 0.31)

            if layers > 1 {
                Text("2")
                    .font(.system(size: size * 0.20, weight: .black))
                    .foregroundStyle(.white)
                    .padding(size * 0.07)
                    .background(Color.brown, in: Circle())
                    .offset(x: size * 0.31, y: -size * 0.31)
            }
        }
        .frame(width: size * 0.92, height: size * 0.92)
        .allowsHitTesting(false)
        .transition(.scale.combined(with: .opacity))
        .accessibilityLabel(layers > 1 ? "Two-layer dust" : "Dust")
    }

    private func dustPuff(scale: CGFloat, opacity: Double) -> some View {
        Circle()
            .fill(Color(red: 0.72, green: 0.69, blue: 0.63).opacity(opacity))
            .frame(width: size * scale, height: size * scale)
            .overlay(Circle().stroke(.white.opacity(0.45), lineWidth: 1))
    }
}

struct PowerUpBadge: View {
    let powerUp: PowerUp
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle().fill(background)
            Image(systemName: symbol)
                .font(.system(size: size * 0.50, weight: .black))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
        .overlay(Circle().stroke(.white, lineWidth: 1.5))
        .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
    }

    private var symbol: String {
        switch powerUp {
        case .rowRocket: "arrow.left.and.right"
        case .columnRocket: "arrow.up.and.down"
        case .gardenBomb: "burst.fill"
        case .rainbowPaw: "pawprint.fill"
        }
    }

    private var background: AnyShapeStyle {
        switch powerUp {
        case .rowRocket, .columnRocket: AnyShapeStyle(Color.orange.gradient)
        case .gardenBomb: AnyShapeStyle(Color.purple.gradient)
        case .rainbowPaw: AnyShapeStyle(AngularGradient(colors: [.red, .orange, .yellow, .green, .blue, .purple, .red], center: .center))
        }
    }
}

struct IntroView: View {
    let play: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            GameArtworkView()
                .ignoresSafeArea()
            LinearGradient(colors: [.clear, .black.opacity(0.12), Color(red: 0.12, green: 0.22, blue: 0.14).opacity(0.94)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack(spacing: 8) {
                CutePill(text: "HENRY & LEO", icon: "heart.fill", size: 11)
                StickerText("The Great Garden Chase", size: 37, colors: [Cute.honey, Cute.honeyDeep])
                    .multilineTextAlignment(.center)
                Text("Leo stole Henry's toy. Again.\nMatch the garden friends and follow the trail!")
                    .font(Cute.font(15, .bold)).multilineTextAlignment(.center).foregroundStyle(.white.opacity(0.92)).padding(.bottom, 8)
                Button(action: play) {
                    Text("Start the chase  🐾")
                }
                .buttonStyle(CuteCandyButtonStyle(colors: [Cute.berry, Cute.berryDeep]))
                .frame(maxWidth: 320)
            }
            .padding(.horizontal, 25).padding(.bottom, 34)
        }
    }
}

/// Closing story card after the last level: the brothers share the peanut-butter pad.
struct BirthdayFinaleView: View {
    let done: () -> Void

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                card
                    .frame(maxWidth: .infinity, minHeight: proxy.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .background(Color.black.opacity(0.45).ignoresSafeArea())
    }

    // Scrolls in short landscape layouts so the button always stays reachable.
    private var card: some View {
            VStack(spacing: 14) {
                GameArtworkView()
                    .frame(height: 190)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(alignment: .bottomTrailing) {
                        PeanutButterPadBadge(size: 58)
                            .padding(10)
                    }
                    .accessibilityHidden(true)
                CutePill(text: "HAPPY BIRTHDAY", icon: "birthday.cake.fill", fill: Cute.berry.opacity(0.85), size: 11)
                StickerText("Leo & Henry", size: 32)
                Text("Through bugs and vacuums, thunder and mowers, splashes and doorbells, Henry never left Leo's side. Now the brothers lie nose to nose and share the peanut-butter pad, one happy lick at a time.")
                    .font(Cute.font(15, .semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Label("All 100 levels complete", systemImage: "pawprint.fill")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.24, green: 0.45, blue: 0.27))
                Button(action: done) {
                    Text("Back to the map")
                }
                .buttonStyle(CuteCandyButtonStyle())
            }
            .padding(20)
            .frame(maxWidth: 420)
            .quiltedCard(corner: 30)
            .padding(24)
    }
}

struct GameArtworkView: View {
    var body: some View {
        Group {
            if let url = Bundle.main.url(forResource: "leo-henry-garden-chase", withExtension: "png"),
               let image = UIImage(contentsOfFile: url.path) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                LinearGradient(colors: [.green.opacity(0.7), .yellow.opacity(0.5)], startPoint: .top, endPoint: .bottom)
            }
        }
    }
}

struct ChapterBackdropView: View {
    let chapterIndex: Int

    var body: some View {
        Group {
            let name = GameModel.chapters[min(max(0, chapterIndex), GameModel.chapters.count - 1)].backgroundName
            if let url = Bundle.main.url(forResource: name, withExtension: "png"),
               let image = UIImage(contentsOfFile: url.path) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                LinearGradient(
                    colors: [Color(red: 0.49, green: 0.70, blue: 0.42), Color(red: 0.96, green: 0.78, blue: 0.39)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }
}

struct ChapterOneBackdropView: View {
    var body: some View { ChapterBackdropView(chapterIndex: 0) }
}

struct BoosterButton: View {
    let icon: String, title: String, action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon).frame(width: 35, height: 35).background(Color(red: 0.90, green: 0.84, blue: 0.72)).clipShape(Circle())
                VStack(alignment: .leading, spacing: 0) { Text(title).font(.caption.bold()); Text("∞").font(.caption2).foregroundStyle(.secondary) }
            }.frame(maxWidth: .infinity)
        }.buttonStyle(.plain)
    }
}

private struct PauseDestinationCard: View {
    let icon: String
    let decoration: String
    let title: String
    let subtitle: String
    let colors: [Color]

    var body: some View {
        HStack(spacing: 11) {
            ZStack {
                Circle().fill(.white.opacity(0.24))
                Image(systemName: icon)
                    .font(.system(size: 23, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 48, height: 48)
            .overlay(Circle().stroke(.white.opacity(0.44), lineWidth: 1.5))

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(Cute.font(17, .black))
                Text(subtitle)
                    .font(Cute.font(10, .bold))
                    .opacity(0.82)
            }
            .foregroundStyle(.white)
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(.white.opacity(0.82))
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, minHeight: 70)
        .background(
            LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay(alignment: .topTrailing) {
            Image(systemName: decoration)
                .font(.system(size: 32, weight: .black))
                .foregroundStyle(.white.opacity(0.12))
                .rotationEffect(.degrees(14))
                .padding(6)
        }
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.55), lineWidth: 1.5))
        .shadow(color: colors.last?.opacity(0.28) ?? .clear, radius: 5, y: 3)
    }
}

struct GardenView: View {
    @ObservedObject var game: GameModel
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.69, green: 0.86, blue: 0.84), Color(red: 0.44, green: 0.66, blue: 0.34)], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            VStack {
                HStack { VStack(alignment: .leading) { StickerText("Our Cozy Corner", size: 32); Text(game.level.title).foregroundStyle(.secondary) }; Spacer(); Button("Done") { dismiss() }.buttonStyle(.borderedProminent).tint(Color(red: 0.29, green: 0.45, blue: 0.31)) }
                Spacer()
                Text("🏡").font(.system(size: 110))
                HStack(spacing: 10) {
                    ForEach(0..<6, id: \.self) { i in Text(["🌷","🌻","🌼","🌹","🪻","🌸"][i]).font(.system(size: game.wins > i ? 43 : 25)).saturation(game.wins > i ? 1 : 0).opacity(game.wins > i ? 1 : 0.3) }
                }
                if game.wins >= 3 { Text("ᓚᘏᗢ").font(.title).foregroundStyle(.brown) }
                Text("Win levels and watch this corner bloom.").font(.headline).padding(.top)
                Spacer()
            }.padding(24)
        }
    }
}
