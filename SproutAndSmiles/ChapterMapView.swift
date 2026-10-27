import SwiftUI

struct ChapterMapView: View {
    @ObservedObject var game: GameModel
    let playLevel: (Int) -> Void
    let previewLevel: (Int) -> Void
    let visitGarden: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var animateCurrentLevel = false
#if DEBUG
    @State private var showingDeveloperConsole = false
#endif

    private var mapChapter: Chapter { GameModel.chapters[game.mapChapterIndex] }
    private var displayedLevels: [Int] { Array(mapChapter.levelRange) }
    private var chapterCompleted: Int { min(mapChapter.levelRange.count, max(0, game.wins - mapChapter.levelRange.lowerBound)) }
    private var henryLevel: Int {
        min(max(mapChapter.levelRange.lowerBound, game.unlocked - 1), mapChapter.levelRange.upperBound - 1)
    }
    private var leoLevel: Int { min(henryLevel + 1, mapChapter.levelRange.upperBound - 1) }

    var body: some View {
        ZStack {
            ChapterBackdropView(chapterIndex: game.mapChapterIndex)
                .blur(radius: 0.35)
                .ignoresSafeArea()
            LinearGradient(
                colors: [Color(red: 0.84, green: 0.93, blue: 0.79).opacity(0.20), Color(red: 0.98, green: 0.89, blue: 0.65).opacity(0.12)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ).ignoresSafeArea()

            VStack(spacing: 0) {
                chapterHeader
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 34, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.48), Color(red: 1.00, green: 0.94, blue: 0.68).opacity(0.28)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .overlay {
                                    RoundedRectangle(cornerRadius: 34, style: .continuous)
                                        .stroke(Color.white.opacity(0.72), lineWidth: 2)
                                }
                                .shadow(color: Color.brown.opacity(0.16), radius: 12, y: 6)

                            MapGardenDecorations(rows: displayedLevels.count)
                                .padding(.horizontal, 22)
                                .allowsHitTesting(false)

                            GardenTrail(rows: displayedLevels.count)
                                .stroke(Color(red: 0.43, green: 0.31, blue: 0.18).opacity(0.40), style: .init(lineWidth: 15, lineCap: .round, lineJoin: .round))
                                .frame(height: CGFloat(displayedLevels.count) * 116)
                                .padding(.horizontal, 58)

                            GardenTrail(rows: displayedLevels.count)
                                .stroke(style: .init(lineWidth: 6, lineCap: .round, lineJoin: .round, dash: [3, 14]))
                                .foregroundStyle(Color(red: 1.00, green: 0.91, blue: 0.56).opacity(0.92))
                                .frame(height: CGFloat(displayedLevels.count) * 116)
                                .padding(.horizontal, 58)

                            VStack(spacing: 22) {
                                ForEach(Array(displayedLevels.enumerated()), id: \.element) { row, index in
                                    trailRow(index, row: row)
                                        .id(index)
                                }
                            }
                            .padding(.vertical, 28)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                    }
                    .onAppear { proxy.scrollTo(henryLevel, anchor: .center) }
                    .onChange(of: game.mapChapterIndex) { _, _ in
                        proxy.scrollTo(henryLevel, anchor: .center)
                    }
                }
            }
        }
        .onAppear {
            GameAudio.shared.setMusicPlaying(game.soundOn)
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 0.85).repeatForever(autoreverses: true)) {
                animateCurrentLevel = true
            }
        }
        .onChange(of: game.soundOn) { _, isOn in GameAudio.shared.setMusicPlaying(isOn) }
#if DEBUG
        .sheet(isPresented: $showingDeveloperConsole) {
            DeveloperConsoleView(game: game) { level in
                showingDeveloperConsole = false
                previewLevel(level)
            }
        }
#endif
    }

    /// Landscape phones get a shorter header so the trail keeps most of the screen.
    private var compactHeader: Bool { verticalSizeClass == .compact }

    private var chapterHeader: some View {
        VStack(spacing: compactHeader ? 6 : 9) {
            HStack {
                ZStack {
                    Circle().fill(LinearGradient(colors: [Cute.leaf, Cute.leafDeep], startPoint: .top, endPoint: .bottom))
                    Image(systemName: mapChapter.symbol).font(.system(size: 20, weight: .black)).foregroundStyle(.white)
                }
                .frame(width: compactHeader ? 42 : 50, height: compactHeader ? 42 : 50)
                .overlay(Circle().stroke(.white, lineWidth: 3))
                .shadow(color: Cute.leafDeep.opacity(0.5), radius: 0, y: 3)
                VStack(alignment: .leading, spacing: compactHeader ? 2 : 3) {
                    HStack(spacing: 8) {
                        CutePill(text: "CHAPTER \(game.mapChapterIndex + 1)", size: 9)
                        if compactHeader {
                            Text(mapChapter.subtitle).font(Cute.font(11, .bold)).foregroundStyle(Cute.cocoaSoft).lineLimit(1)
                        }
                    }
                    StickerText(mapChapter.title, size: compactHeader ? 22 : 25)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    if !compactHeader {
                        Text(mapChapter.subtitle).font(Cute.font(12, .bold)).foregroundStyle(Cute.cocoaSoft)
                    }
                }
                Spacer()
                Button { game.selectMapChapter(game.mapChapterIndex - 1) } label: {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(CuteCircleButtonStyle(size: 38))
                .disabled(game.mapChapterIndex == 0)
                .opacity(game.mapChapterIndex == 0 ? 0.35 : 1)
                Button { game.selectMapChapter(game.mapChapterIndex + 1) } label: {
                    Image(systemName: "chevron.right")
                }
                .buttonStyle(CuteCircleButtonStyle(size: 38))
                .disabled(game.mapChapterIndex == GameModel.chapters.count - 1 || !canOpenChapter(game.mapChapterIndex + 1))
                .opacity(game.mapChapterIndex == GameModel.chapters.count - 1 || !canOpenChapter(game.mapChapterIndex + 1) ? 0.35 : 1)
#if DEBUG
                Button { showingDeveloperConsole = true } label: {
                    Image(systemName: "hammer.fill")
                        .frame(width: 42, height: 42)
                        .background(Color.black.opacity(0.74), in: Circle())
                }
                .foregroundStyle(.yellow)
                .accessibilityLabel("Open developer console")
#endif
                Button { game.soundOn.toggle() } label: {
                    Image(systemName: game.soundOn ? "music.note" : "speaker.slash.fill")
                }
                .buttonStyle(CuteCircleButtonStyle(size: 42))
                .accessibilityLabel(game.soundOn ? "Turn music off" : "Turn music on")
                Button {
                    visitGarden()
                } label: {
                    Image(systemName: "house.and.flag.fill")
                }
                .buttonStyle(CuteCircleButtonStyle(size: 42))
                .overlay(alignment: .topTrailing) {
                    if game.yardProjectReady {
                        TreatIcon(size: 17)
                            .frame(width: 24, height: 24)
                            .background(Cute.berry, in: Circle())
                            .overlay(Circle().strokeBorder(.white, lineWidth: 2))
                            .offset(x: 7, y: -3)
                            .allowsHitTesting(false)
                    }
                }
                .accessibilityLabel(game.yardProjectReady ? "Our yard, treats to spend" : "Our yard")
            }
            if compactHeader {
                HStack(spacing: 10) {
                    nextStopLabel
                    CuteProgressBar(value: Double(chapterCompleted), total: Double(mapChapter.levelRange.count), height: 10)
                    completedLabel
                }
                .font(Cute.font(11, .heavy))
                .foregroundStyle(Cute.leafDeep)
            } else {
                CuteProgressBar(value: Double(chapterCompleted), total: Double(mapChapter.levelRange.count), height: 11)
                HStack(spacing: 6) {
                    nextStopLabel
                    Spacer()
                    completedLabel
                }
                .font(Cute.font(11, .heavy))
                .foregroundStyle(Cute.leafDeep)
            }
        }
        .padding(.horizontal, 20).padding(.top, compactHeader ? 8 : 12).padding(.bottom, compactHeader ? 12 : 14)
        .background(Cute.cream.opacity(0.96))
        .overlay(alignment: .bottom) {
            StitchLine()
                .stroke(Cute.stitch, style: StrokeStyle(lineWidth: 1.6, lineCap: .round, dash: [5, 4]))
                .frame(height: 2)
                .padding(.bottom, 6)
        }
        .overlay(alignment: .bottom) { Rectangle().fill(.white).frame(height: 2.5) }
        .shadow(color: Cute.cocoa.opacity(0.16), radius: 0, y: 3)
    }

    private var nextStopLabel: some View {
        HStack(spacing: 6) {
            Image(systemName: "pawprint.fill")
            Text(chapterCompleted == mapChapter.levelRange.count ? "Chapter complete!" : "Next stop: Level \(henryLevel - mapChapter.levelRange.lowerBound + 1)")
        }
        .fixedSize()
    }

    private var completedLabel: some View {
        Text("\(chapterCompleted) of \(mapChapter.levelRange.count) complete").fixedSize()
    }

    @ViewBuilder
    private func trailRow(_ index: Int, row: Int) -> some View {
        let unlocked = index < game.unlocked
        let completed = index < game.wins
        HStack(spacing: 10) {
            if row.isMultiple(of: 2) {
                levelNode(index, row: row, unlocked: unlocked, completed: completed)
                levelCaption(index, row: row, unlocked: unlocked)
                Spacer(minLength: 25)
            } else {
                Spacer(minLength: 25)
                levelCaption(index, row: row, unlocked: unlocked)
                levelNode(index, row: row, unlocked: unlocked, completed: completed)
            }
        }
        .padding(.horizontal, 27)
        .frame(height: 94)
    }

    private func levelNode(_ index: Int, row: Int, unlocked: Bool, completed: Bool) -> some View {
        Button {
            if unlocked {
                playLevel(index)
            }
        } label: {
            ZStack {
                if index == henryLevel && index >= game.wins {
                    Circle()
                        .stroke(Color.yellow.opacity(0.86), lineWidth: 5)
                        .frame(width: 85, height: 85)
                        .scaleEffect(animateCurrentLevel ? 1.12 : 0.94)
                        .opacity(animateCurrentLevel ? 0.15 : 0.85)
                }
                Circle()
                    .fill(completed ? Color(red: 0.36, green: 0.58, blue: 0.35).gradient : unlocked ? Color(red: 0.95, green: 0.72, blue: 0.31).gradient : Color.gray.opacity(0.42).gradient)
                    .frame(width: 72, height: 72)
                    .overlay(Circle().stroke(.white.opacity(0.94), lineWidth: 5))
                    .overlay(Circle().stroke(Color(red: 0.52, green: 0.37, blue: 0.17).opacity(0.55), lineWidth: 1.5).padding(5))
                    .shadow(color: completed ? Color.green.opacity(0.36) : Color.black.opacity(0.20), radius: 7, y: 4)
                Image(systemName: "leaf.fill")
                    .font(.system(size: 29, weight: .black))
                    .foregroundStyle(.white.opacity(completed ? 0.12 : 0.18))
                if completed {
                    Image(systemName: "checkmark").font(.title2.bold()).foregroundStyle(.white)
                } else if unlocked {
                    Text("\(row + 1)").font(Cute.font(26, .black)).foregroundStyle(Cute.cocoa)
                } else {
                    Image(systemName: "lock.fill").foregroundStyle(.white.opacity(0.78))
                }

                if index == henryLevel { DogTrailMarker(dog: .henry).offset(x: row.isMultiple(of: 2) ? 45 : -45, y: -37) }
                if index == leoLevel { DogTrailMarker(dog: .leo).offset(x: row.isMultiple(of: 2) ? 45 : -45, y: -37) }
            }
        }
        .buttonStyle(.plain)
        .disabled(!unlocked)
        .accessibilityLabel(unlocked ? "Level \(row + 1), \(GameModel.levels[index].title)" : "Level \(row + 1), locked")
    }

    private func levelCaption(_ index: Int, row: Int, unlocked: Bool) -> some View {
        HStack(spacing: 8) {
            if !row.isMultiple(of: 2) { levelGoalIcon(index) }
            VStack(alignment: row.isMultiple(of: 2) ? .leading : .trailing, spacing: 2) {
                Text("Level \(row + 1)").font(Cute.font(10, .black)).foregroundStyle(Cute.berryDeep)
                Text(GameModel.levels[index].title)
                    .font(Cute.font(15, .heavy))
                    .foregroundStyle(Cute.cocoa)
                    .multilineTextAlignment(row.isMultiple(of: 2) ? .leading : .trailing)
                    .lineLimit(2)
                if unlocked { Text(GameModel.levels[index].stolenItem).font(Cute.font(10, .semibold)).foregroundStyle(Cute.cocoaSoft) }
                if index == henryLevel && index >= game.wins {
                    CutePill(text: "PLAY NEXT", icon: "play.fill", size: 8)
                        .padding(.top, 2)
                }
            }
            if row.isMultiple(of: 2) { levelGoalIcon(index) }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: 185, alignment: row.isMultiple(of: 2) ? .leading : .trailing)
        .quiltedCard(fill: Cute.cream.opacity(0.94), corner: 18)
        .opacity(unlocked ? 1 : 0.55)
    }

    @ViewBuilder
    private func levelGoalIcon(_ index: Int) -> some View {
        LevelGoalIcon(level: GameModel.levels[index], size: 28)
    }

    private func canOpenChapter(_ index: Int) -> Bool {
#if DEBUG
        true
#else
        game.unlocked > GameModel.chapters[index].levelRange.lowerBound
#endif
    }
}

#if DEBUG
private struct DeveloperConsoleView: View {
    @ObservedObject var game: GameModel
    let preview: (Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var confirmingReset = false

    private let columns = [GridItem(.adaptive(minimum: 132), spacing: 10)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 5) {
                        Label("Development build only", systemImage: "ladybug.fill")
                            .font(.headline)
                            .foregroundStyle(.yellow)
                        Text("Previewing bypasses locks and never changes the real saved journey. Every chapter is available below.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.75))
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.black.opacity(0.88), in: RoundedRectangle(cornerRadius: 18))

                    HStack {
                        consoleMetric("\(game.wins)", label: "COMPLETED")
                        consoleMetric("\(game.unlocked)", label: "UNLOCKED")
                        consoleMetric("\(game.levelIndex + 1)", label: "CURRENT")
                    }

                    Text("ALL CHAPTERS · TAP ANY LEVEL TO PREVIEW")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .tracking(1.4)
                        .foregroundStyle(.secondary)

                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(GameModel.levels.indices, id: \.self) { index in
                            let level = GameModel.levels[index]
                            let localLevel = index - GameModel.chapters[level.chapterIndex].levelRange.lowerBound + 1
                            Button { preview(index) } label: {
                                VStack(alignment: .leading, spacing: 7) {
                                    HStack {
                                        Text("C\(level.chapterIndex + 1) · LEVEL \(localLevel)")
                                            .font(.system(size: 9, weight: .black))
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        Image(systemName: index < game.wins ? "checkmark.circle.fill" : index < game.unlocked ? "lock.open.fill" : "eye.fill")
                                            .foregroundStyle(index < game.wins ? .green : .orange)
                                    }
                                    HStack(spacing: 8) {
                                        LevelGoalIcon(level: level, size: 34)
                                        Text(level.title)
                                            .font(.system(size: 13, weight: .bold, design: .rounded))
                                            .multilineTextAlignment(.leading)
                                            .lineLimit(2)
                                    }
                                    Label("Preview without saving", systemImage: "play.fill")
                                        .font(.system(size: 9, weight: .semibold))
                                        .foregroundStyle(Color(red: 0.25, green: 0.47, blue: 0.28))
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity, minHeight: 112, alignment: .leading)
                                .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(index == game.levelIndex ? Color.orange : Color.black.opacity(0.08), lineWidth: index == game.levelIndex ? 3 : 1)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Text("SAVE-STATE TOOLS")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .tracking(1.4)
                        .foregroundStyle(.secondary)

                    VStack(spacing: 10) {
                        Button {
                            game.developerUnlockAllLevels()
                        } label: {
                            Label("Unlock All Levels", systemImage: "lock.open.fill")
                                .frame(maxWidth: .infinity)
                        }
                        Button {
                            game.developerCompleteThroughCurrentLevel()
                        } label: {
                            Label("Mark Through Current Level Complete", systemImage: "checkmark.seal.fill")
                                .frame(maxWidth: .infinity)
                        }
                        Button {
                            game.developerGrantStartingBoosters()
                        } label: {
                            Label("Grant 10 of Every Booster", systemImage: "shippingbox.and.arrow.backward.fill")
                                .frame(maxWidth: .infinity)
                        }
                        Button(role: .destructive) { confirmingReset = true } label: {
                            Label("Reset Player Progress", systemImage: "arrow.counterclockwise")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.bordered)
                }
                .padding(18)
            }
            .background(Color(red: 0.94, green: 0.92, blue: 0.84))
            .navigationTitle("Developer Console")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
            .alert("Reset all player progress?", isPresented: $confirmingReset) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) { game.developerResetProgress() }
            } message: {
                Text("This changes the development device's saved progress. It cannot be undone.")
            }
        }
    }

    private func consoleMetric(_ value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.title2.bold())
            Text(label).font(.system(size: 8, weight: .black)).tracking(0.8).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 13))
    }
}
#endif

private struct MapGardenDecorations: View {
    let rows: Int

    private let symbols = [
        "ladybug.fill", "leaf.fill", "carrot.fill", "sun.max.fill", "drop.fill",
        "flower.fill", "bird.fill", "basket.fill", "cloud.sun.fill", "birthday.cake.fill"
    ]

    private let colors: [Color] = [.red, .green, .orange, .yellow, .blue, .pink, .indigo, .brown, .cyan, .purple]

    var body: some View {
        GeometryReader { proxy in
            ForEach(0..<rows, id: \.self) { index in
                let leftSide = !index.isMultiple(of: 2)
                Image(systemName: symbols[index % symbols.count])
                    .font(.system(size: index.isMultiple(of: 3) ? 24 : 19, weight: .bold))
                    .foregroundStyle(colors[index % colors.count].gradient)
                    .padding(9)
                    .background(Color.white.opacity(0.70), in: Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.9), lineWidth: 1.5))
                    .shadow(color: Color.brown.opacity(0.18), radius: 3, y: 2)
                    .rotationEffect(.degrees(Double((index % 3) - 1) * 9))
                    .position(
                        x: leftSide ? proxy.size.width * 0.19 : proxy.size.width * 0.81,
                        y: 54 + CGFloat(index) * 116
                    )

                if index < rows - 1 {
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(Color(red: 0.40, green: 0.27, blue: 0.15).opacity(0.45))
                        .rotationEffect(.degrees(index.isMultiple(of: 2) ? 24 : -24))
                        .position(
                            x: proxy.size.width * (index.isMultiple(of: 2) ? 0.68 : 0.32),
                            y: 108 + CGFloat(index) * 116
                        )
                }
            }
        }
        .frame(height: CGFloat(rows) * 116)
    }
}

private enum TrailDog { case leo, henry }

private struct DogTrailMarker: View {
    let dog: TrailDog
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                if dog == .leo {
                    VeggieView(veggie: .carrot, size: 42)
                } else {
                    HenryPortraitView(size: 42)
                }
            }
            Text(dog == .leo ? "LEO" : "HENRY")
                .font(.system(size: 7, weight: .black)).padding(.horizontal, 5).padding(.vertical, 2)
                .background(.white, in: Capsule()).foregroundStyle(.black)
        }
        .shadow(color: .black.opacity(0.23), radius: 3, y: 2)
    }
}

private struct HenryPortraitView: View {
    let size: CGFloat
    var body: some View {
        Group {
            if let portrait = UIImage(named: "henry-map-marker") {
                Image(uiImage: portrait).resizable().scaledToFill()
            } else {
                Circle().fill(Color(red: 0.16, green: 0.12, blue: 0.12))
                    .overlay(Image(systemName: "pawprint.fill").foregroundStyle(.white))
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(.white, lineWidth: 2))
    }
}

private struct GardenTrail: Shape {
    let rows: Int
    func path(in rect: CGRect) -> Path {
        var path = Path()
        for index in 0..<rows {
            let x = index.isMultiple(of: 2) ? rect.minX + 32 : rect.maxX - 32
            let y = rect.minY + 47 + CGFloat(index) * 116
            if index == 0 { path.move(to: CGPoint(x: x, y: y)) }
            else { path.addCurve(to: CGPoint(x: x, y: y), control1: CGPoint(x: rect.midX, y: y - 70), control2: CGPoint(x: rect.midX, y: y - 35)) }
        }
        return path
    }
}
