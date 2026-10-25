import SwiftUI

struct ContentView: View {
    @StateObject private var game = GameModel()
    @State private var showGarden = false
    @State private var showingIntro = true
    @State private var showingMap = false
    @State private var showingPause = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: GameModel.size)

    var body: some View {
        ZStack {
            GeometryReader { proxy in
                if proxy.size.width > proxy.size.height {
                    ChapterOneBackdropView()
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
                        game.start(level: level)
                        withAnimation(.easeInOut(duration: 0.25)) { showingMap = false }
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
        }
        .sheet(isPresented: $showGarden) { GardenView(game: game) }
        .alert(game.levelIndex == GameModel.levels.count - 1 ? "The brothers share the feast!" : "Henry got it back!", isPresented: $game.showingWin) {
            Button("Follow Leo") {
                game.continueGarden()
                withAnimation { showingMap = true }
            }
        } message: {
            Text("Henry recovered his \(game.level.stolenItem). Leo looks innocent—but only until the next level.")
        }
    }

    private var portraitGame: some View {
        VStack(spacing: 10) {
            header
            levelHeader
            mission
            statusMessage
            board
            boosters
            Spacer(minLength: 3)
        }
        .padding(.horizontal, 12)
        .padding(.top, 4)
    }

    private func landscapeGame(in size: CGSize) -> some View {
        let boardSide = max(240, min(size.width * 0.90, size.height - 8))
        return ZStack {
            board
                .frame(width: boardSide, height: boardSide)

            VStack {
                HStack {
                    Spacer()
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { showingPause = true }
                    } label: {
                        Image(systemName: "pause.fill")
                            .font(.title2.bold())
                            .frame(width: 52, height: 52)
                            .background(.ultraThinMaterial, in: Circle())
                            .overlay(Circle().stroke(.white.opacity(0.8), lineWidth: 2))
                            .shadow(color: .black.opacity(0.18), radius: 5, y: 3)
                    }
                    .foregroundStyle(Color(red: 0.25, green: 0.38, blue: 0.27))
                    .accessibilityLabel("Pause game")
                }
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var pauseOverlay: some View {
        ZStack {
            Color.black.opacity(0.42).ignoresSafeArea()
            VStack(spacing: 13) {
                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("PAUSED").font(.system(size: 11, weight: .black)).tracking(2).foregroundStyle(.secondary)
                        Text(game.level.title).font(.system(size: 26, weight: .bold, design: .serif))
                    }
                    Spacer()
                    Button { game.soundOn.toggle() } label: {
                        Image(systemName: game.soundOn ? "speaker.wave.2.fill" : "speaker.slash.fill")
                            .frame(width: 44, height: 44)
                            .background(Color(red: 0.90, green: 0.84, blue: 0.72), in: Circle())
                    }
                    .foregroundStyle(Color(red: 0.25, green: 0.38, blue: 0.27))
                }

                mission
                statusMessage
                boosters

                HStack(spacing: 10) {
                    Button {
                        showingPause = false
                        withAnimation { showingMap = true }
                    } label: {
                        Label("Chapter Map", systemImage: "map.fill").frame(maxWidth: .infinity)
                    }
                    Button {
                        showingPause = false
                        showGarden = true
                    } label: {
                        Label("Garden", systemImage: "house.and.flag.fill").frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.bordered)

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { showingPause = false }
                } label: {
                    Label("Resume", systemImage: "play.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 5)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.31, green: 0.50, blue: 0.31))
            }
            .padding(20)
            .frame(maxWidth: 540)
            .background(Color(red: 0.97, green: 0.94, blue: 0.82), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(.white.opacity(0.9), lineWidth: 2))
            .shadow(color: .black.opacity(0.30), radius: 22, y: 10)
            .padding(18)
        }
    }

    private var statusMessage: some View {
        Text(game.message)
            .font(.system(size: 13, design: .serif).italic())
            .foregroundStyle(.secondary)
            .lineLimit(1).minimumScaleFactor(0.70)
            .frame(height: 19)
    }

    private var header: some View {
        HStack {
            Button { withAnimation { showingMap = true } } label: {
                HStack(spacing: 9) {
                    Text("❀").font(.title2).frame(width: 39, height: 39).background(Color(red: 0.28, green: 0.42, blue: 0.30)).foregroundStyle(.white).clipShape(Circle())
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Henry's Garden Chase").font(.system(size: 20, weight: .bold, design: .serif))
                        Text("tap for the chapter map").font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }.buttonStyle(.plain)
            Spacer()
            Button { game.soundOn.toggle() } label: {
                Image(systemName: game.soundOn ? "speaker.wave.2.fill" : "speaker.slash.fill")
                    .frame(width: 39, height: 39).background(.white.opacity(0.75)).clipShape(Circle()).shadow(color: .black.opacity(0.09), radius: 4, y: 3)
            }.foregroundStyle(Color(red: 0.25, green: 0.38, blue: 0.27))
        }
    }

    private var levelHeader: some View {
        HStack {
            Button { game.start(level: game.levelIndex - 1) } label: { Image(systemName: "chevron.left") }.disabled(game.levelIndex == 0)
            Spacer()
            VStack(spacing: 0) {
                Text("GARDEN PATH").font(.system(size: 9, weight: .black)).tracking(2).foregroundStyle(.secondary)
                Text(game.level.title).font(.system(size: 20, weight: .bold, design: .serif)).lineLimit(1).minimumScaleFactor(0.7)
            }
            Spacer()
            Button { game.start(level: game.levelIndex + 1) } label: { Image(systemName: "chevron.right") }.disabled(game.levelIndex >= game.unlocked - 1)
        }
        .buttonStyle(RoundButtonStyle())
    }

    private var mission: some View {
        HStack {
            metric(value: "\(game.moves)", label: "MOVES")
            Divider().frame(height: 35)
            HStack(spacing: 8) {
                VeggieView(veggie: game.level.goal, size: 37)
                VStack(alignment: .leading, spacing: 0) { Text("COLLECT").font(.system(size: 9, weight: .bold)).foregroundStyle(.secondary); Text("\(min(game.collected, game.level.amount)) / \(game.level.amount)").bold() }
            }.frame(maxWidth: .infinity)
            Divider().frame(height: 35)
            metric(value: "∞", label: "LIVES", color: .pink)
        }
        .padding(.vertical, 10).padding(.horizontal, 8)
        .background(Color(red: 0.94, green: 0.89, blue: 0.79)).clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func metric(value: String, label: String, color: Color = Color(red: 0.16, green: 0.29, blue: 0.22)) -> some View {
        VStack(spacing: 0) { Text(value).font(.title2.bold()).foregroundStyle(color); Text(label).font(.system(size: 9, weight: .bold)).tracking(1).foregroundStyle(.secondary) }.frame(maxWidth: .infinity)
    }

    private var board: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(0..<(GameModel.size * GameModel.size), id: \.self) { index in
                    let row = index / GameModel.size
                    let col = index % GameModel.size
                    let position = Position(row: row, col: col)
                    GameTileCell(
                        veggie: game.board[row][col].veggie,
                        powerUp: game.board[row][col].powerUp,
                        position: position,
                        size: side / 9.1,
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
    let selected: Bool
    let popping: Bool
    let hinting: Bool
    let tap: () -> Void
    let drag: (CGSize) -> Void

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VeggieView(veggie: veggie, size: size)
            if let powerUp { PowerUpBadge(powerUp: powerUp, size: size * 0.43) }
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
                Text("HENRY & LEO")
                    .font(.system(size: 13, weight: .black)).tracking(4).foregroundStyle(.white.opacity(0.85))
                Text("The Great Garden Chase")
                    .font(.system(size: 37, weight: .bold, design: .serif)).multilineTextAlignment(.center).foregroundStyle(.white)
                Text("Leo stole Henry's toy. Again.\nMatch the garden friends and follow the trail!")
                    .font(.subheadline).multilineTextAlignment(.center).foregroundStyle(.white.opacity(0.9)).padding(.bottom, 8)
                Button(action: play) {
                    Text("Start the chase  🐾").font(.headline).padding(.horizontal, 28).padding(.vertical, 14)
                        .background(Color(red: 0.94, green: 0.72, blue: 0.31), in: Capsule()).foregroundStyle(Color(red: 0.18, green: 0.25, blue: 0.15))
                }
            }
            .padding(.horizontal, 25).padding(.bottom, 34)
        }
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

struct ChapterOneBackdropView: View {
    var body: some View {
        Group {
            if let url = Bundle.main.url(forResource: "chapter-one-garden", withExtension: "png"),
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

struct RoundButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.frame(width: 38, height: 38).background(.white.opacity(0.8)).clipShape(Circle()).opacity(configuration.isPressed ? 0.6 : 1)
    }
}

struct GardenView: View {
    @ObservedObject var game: GameModel
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.69, green: 0.86, blue: 0.84), Color(red: 0.44, green: 0.66, blue: 0.34)], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            VStack {
                HStack { VStack(alignment: .leading) { Text("Our Cozy Corner").font(.largeTitle.bold()).fontDesign(.serif); Text(game.level.title).foregroundStyle(.secondary) }; Spacer(); Button("Done") { dismiss() }.buttonStyle(.borderedProminent).tint(Color(red: 0.29, green: 0.45, blue: 0.31)) }
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
