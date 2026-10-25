import SwiftUI

struct ChapterMapView: View {
    @ObservedObject var game: GameModel
    let playLevel: (Int) -> Void
    let visitGarden: () -> Void

    private var henryLevel: Int { min(max(0, game.unlocked - 1), GameModel.levels.count - 1) }
    private var leoLevel: Int { min(henryLevel + 1, GameModel.levels.count - 1) }

    var body: some View {
        ZStack {
            ChapterOneBackdropView()
                .blur(radius: 1.2)
                .ignoresSafeArea()
            LinearGradient(
                colors: [Color(red: 0.84, green: 0.93, blue: 0.79).opacity(0.60), Color(red: 0.98, green: 0.89, blue: 0.65).opacity(0.46)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ).ignoresSafeArea()

            VStack(spacing: 0) {
                chapterHeader
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 34, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .shadow(color: Color.brown.opacity(0.18), radius: 12, y: 6)

                            GardenTrail(rows: GameModel.levels.count)
                                .stroke(Color(red: 0.43, green: 0.31, blue: 0.18).opacity(0.40), style: .init(lineWidth: 15, lineCap: .round, lineJoin: .round))
                                .frame(height: CGFloat(GameModel.levels.count) * 116)
                                .padding(.horizontal, 58)

                            GardenTrail(rows: GameModel.levels.count)
                                .stroke(style: .init(lineWidth: 6, lineCap: .round, lineJoin: .round, dash: [3, 14]))
                                .foregroundStyle(Color(red: 1.00, green: 0.91, blue: 0.56).opacity(0.92))
                                .frame(height: CGFloat(GameModel.levels.count) * 116)
                                .padding(.horizontal, 58)

                            VStack(spacing: 22) {
                                ForEach(GameModel.levels.indices, id: \.self) { index in
                                    trailRow(index)
                                        .id(index)
                                }
                            }
                            .padding(.vertical, 28)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                    }
                    .onAppear { proxy.scrollTo(henryLevel, anchor: .center) }
                }
            }
        }
    }

    private var chapterHeader: some View {
        VStack(spacing: 9) {
            HStack {
                ZStack {
                    Circle().fill(Color(red: 0.30, green: 0.50, blue: 0.28).gradient)
                    Image(systemName: "leaf.fill").foregroundStyle(.white)
                }
                .frame(width: 48, height: 48)
                .overlay(Circle().stroke(.white.opacity(0.85), lineWidth: 3))
                .shadow(color: .black.opacity(0.16), radius: 4, y: 3)
                VStack(alignment: .leading, spacing: 1) {
                    Text("CHAPTER ONE").font(.system(size: 10, weight: .black)).tracking(2).foregroundStyle(.secondary)
                    Text("The Bug in the Beans").font(.system(size: 27, weight: .bold, design: .serif))
                    Text("Henry follows Leo's trail through the garden.").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Button(action: visitGarden) {
                    Image(systemName: "house.and.flag.fill")
                        .frame(width: 42, height: 42)
                        .background(.white.opacity(0.75), in: Circle())
                }
                .foregroundStyle(Color(red: 0.26, green: 0.43, blue: 0.29))
            }
            ProgressView(value: Double(game.wins), total: Double(GameModel.levels.count))
                .tint(Color(red: 0.34, green: 0.53, blue: 0.32))
        }
        .padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 14)
        .background(.regularMaterial)
        .overlay(alignment: .bottom) { Rectangle().fill(Color.white.opacity(0.62)).frame(height: 1) }
        .shadow(color: Color.brown.opacity(0.12), radius: 8, y: 4)
    }

    @ViewBuilder
    private func trailRow(_ index: Int) -> some View {
        let unlocked = index < game.unlocked
        let completed = index < game.wins
        HStack(spacing: 10) {
            if index.isMultiple(of: 2) {
                levelNode(index, unlocked: unlocked, completed: completed)
                levelCaption(index, unlocked: unlocked)
                Spacer(minLength: 25)
            } else {
                Spacer(minLength: 25)
                levelCaption(index, unlocked: unlocked)
                levelNode(index, unlocked: unlocked, completed: completed)
            }
        }
        .padding(.horizontal, 27)
        .frame(height: 94)
    }

    private func levelNode(_ index: Int, unlocked: Bool, completed: Bool) -> some View {
        Button { if unlocked { playLevel(index) } } label: {
            ZStack {
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
                    Text("\(index + 1)").font(.title2.bold()).foregroundStyle(Color(red: 0.19, green: 0.28, blue: 0.17))
                } else {
                    Image(systemName: "lock.fill").foregroundStyle(.white.opacity(0.78))
                }

                if index == henryLevel { DogTrailMarker(dog: .henry).offset(x: index.isMultiple(of: 2) ? 45 : -45, y: -37) }
                if index == leoLevel { DogTrailMarker(dog: .leo).offset(x: index.isMultiple(of: 2) ? 45 : -45, y: -37) }
            }
        }
        .buttonStyle(.plain)
        .disabled(!unlocked)
        .accessibilityLabel(unlocked ? "Level \(index + 1), \(GameModel.levels[index].title)" : "Level \(index + 1), locked")
    }

    private func levelCaption(_ index: Int, unlocked: Bool) -> some View {
        HStack(spacing: 8) {
            if !index.isMultiple(of: 2) { VeggieView(veggie: GameModel.levels[index].goal, size: 28) }
            VStack(alignment: index.isMultiple(of: 2) ? .leading : .trailing, spacing: 2) {
                Text("Level \(index + 1)").font(.caption2.bold()).foregroundStyle(.secondary)
                Text(GameModel.levels[index].title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .multilineTextAlignment(index.isMultiple(of: 2) ? .leading : .trailing)
                    .lineLimit(2)
                if unlocked { Text(GameModel.levels[index].stolenItem).font(.caption2).foregroundStyle(.secondary) }
            }
            if index.isMultiple(of: 2) { VeggieView(veggie: GameModel.levels[index].goal, size: 28) }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: 185, alignment: index.isMultiple(of: 2) ? .leading : .trailing)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(.white.opacity(0.58), lineWidth: 1))
        .opacity(unlocked ? 1 : 0.48)
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
