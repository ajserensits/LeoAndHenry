import SwiftUI

/// Shared playful styling: chunky rounded type, sticker headings, quilted cards, and Henry's speech bubble.
enum Cute {
    static let cocoa = Color(red: 0.36, green: 0.22, blue: 0.14)
    static let cocoaSoft = Color(red: 0.36, green: 0.22, blue: 0.14).opacity(0.68)
    static let cream = Color(red: 1.00, green: 0.97, blue: 0.89)
    static let honey = Color(red: 1.00, green: 0.80, blue: 0.36)
    static let honeyDeep = Color(red: 0.93, green: 0.58, blue: 0.18)
    static let berry = Color(red: 0.95, green: 0.43, blue: 0.56)
    static let berryDeep = Color(red: 0.80, green: 0.25, blue: 0.42)
    static let leaf = Color(red: 0.42, green: 0.70, blue: 0.38)
    static let leafDeep = Color(red: 0.24, green: 0.50, blue: 0.27)
    static let stitch = Color(red: 0.86, green: 0.68, blue: 0.48)

    static func font(_ size: CGFloat, _ weight: Font.Weight = .heavy) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

/// A sticker-style heading: candy gradient fill, a white outline, and a soft cocoa drop.
struct StickerText: View {
    let text: String
    var size: CGFloat = 22
    var colors: [Color] = [Cute.berry, Cute.berryDeep]
    var outline: Color = .white

    init(_ text: String, size: CGFloat = 22, colors: [Color] = [Cute.berry, Cute.berryDeep], outline: Color = .white) {
        self.text = text
        self.size = size
        self.colors = colors
        self.outline = outline
    }

    var body: some View {
        let width = max(1.5, size * 0.085)
        Text(text)
            .font(Cute.font(size, .black))
            .foregroundStyle(LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom))
            .shadow(color: outline, radius: 0, x: width, y: 0)
            .shadow(color: outline, radius: 0, x: -width, y: 0)
            .shadow(color: outline, radius: 0, x: 0, y: width)
            .shadow(color: outline, radius: 0, x: 0, y: -width)
            .shadow(color: Cute.cocoa.opacity(0.30), radius: 0, x: 0, y: width + 1.5)
    }
}

/// A small honey-colored label pill, e.g. "CHAPTER 1 · LEVEL 4".
struct CutePill: View {
    let text: String
    var icon: String? = "pawprint.fill"
    var fill: Color = Cute.honey
    var size: CGFloat = 10

    var body: some View {
        HStack(spacing: 4) {
            if let icon { Image(systemName: icon).font(.system(size: size * 0.9, weight: .black)) }
            Text(text).font(Cute.font(size, .black)).tracking(0.6)
        }
        .foregroundStyle(Cute.cocoa)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .padding(.horizontal, size * 0.9)
        .padding(.vertical, size * 0.38)
        .background(fill, in: Capsule())
        .overlay(Capsule().stroke(.white, lineWidth: 1.5))
        .shadow(color: Cute.honeyDeep.opacity(0.45), radius: 0, y: 2)
    }
}

/// Cream "quilted" card with a stitched border and a soft 3D lip, like the cozy blanket.
struct QuiltedCard: ViewModifier {
    var fill: Color = Cute.cream
    var corner: CGFloat = 24
    var stitch: Color = Cute.stitch

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(fill)
                    .overlay {
                        RoundedRectangle(cornerRadius: corner - 5, style: .continuous)
                            .strokeBorder(stitch.opacity(0.85), style: StrokeStyle(lineWidth: 1.6, lineCap: .round, dash: [5, 4]))
                            .padding(5)
                    }
                    .overlay(RoundedRectangle(cornerRadius: corner, style: .continuous).stroke(.white, lineWidth: 2.5))
                    .shadow(color: Cute.cocoa.opacity(0.22), radius: 0, y: 4)
                    .shadow(color: Cute.cocoa.opacity(0.18), radius: 10, y: 6)
            }
    }
}

extension View {
    func quiltedCard(fill: Color = Cute.cream, corner: CGFloat = 24, stitch: Color = Cute.stitch) -> some View {
        modifier(QuiltedCard(fill: fill, corner: corner, stitch: stitch))
    }
}

/// A plump candy progress bar with a shine stripe.
struct CuteProgressBar: View {
    let value: Double
    let total: Double
    var colors: [Color] = [Cute.leaf, Cute.leafDeep]
    var height: CGFloat = 12

    var body: some View {
        GeometryReader { proxy in
            let fraction = total > 0 ? min(1, max(0, value / total)) : 0
            ZStack(alignment: .leading) {
                Capsule().fill(Cute.cocoa.opacity(0.12))
                Capsule()
                    .fill(LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom))
                    .frame(width: max(height, proxy.size.width * fraction))
                    .overlay(alignment: .top) {
                        Capsule().fill(.white.opacity(0.45)).frame(height: height * 0.28).padding(.horizontal, height * 0.4).padding(.top, height * 0.16)
                    }
                    .opacity(fraction > 0 ? 1 : 0)
            }
            .overlay(Capsule().stroke(.white, lineWidth: 1.5))
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: fraction)
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }
}

/// Henry's portrait with a speech bubble for game messages.
struct HenrySpeechBubble: View {
    let message: String
    var portraitSize: CGFloat = 34
    var fontSize: CGFloat = 12
    var lineLimit = 2

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            Group {
                if let portrait = UIImage(named: "henry-map-marker") {
                    Image(uiImage: portrait).resizable().scaledToFill()
                } else {
                    Circle().fill(Cute.cocoa)
                }
            }
            .frame(width: portraitSize, height: portraitSize)
            .clipShape(Circle())
            .overlay(Circle().stroke(.white, lineWidth: 2.5))
            .shadow(color: Cute.cocoa.opacity(0.25), radius: 0, y: 2)
            .zIndex(1)

            BubbleTail()
                .fill(.white)
                .frame(width: 9, height: 12)
                .offset(x: 2)

            Text(message)
                .font(Cute.font(fontSize, .bold))
                .foregroundStyle(Cute.cocoa)
                .lineLimit(lineLimit)
                .minimumScaleFactor(0.75)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 11)
                .padding(.vertical, 7)
                .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: Cute.cocoa.opacity(0.16), radius: 0, y: 3)
                .contentTransition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: message)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Henry says: \(message)")
    }
}

private struct BubbleTail: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// A horizontal stitched seam, stroked with a dash by the caller.
struct StitchLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}

/// White circle button with a honey rim that squishes when pressed.
struct CuteCircleButtonStyle: ButtonStyle {
    var size: CGFloat = 40

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: size * 0.42, weight: .black))
            .foregroundStyle(Cute.cocoa)
            .frame(width: size, height: size)
            .background(Cute.cream, in: Circle())
            .overlay(Circle().stroke(Cute.honey, lineWidth: 2.5))
            .shadow(color: Cute.honeyDeep.opacity(0.45), radius: 0, y: configuration.isPressed ? 1 : 3)
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.55), value: configuration.isPressed)
    }
}

/// Big squishy candy button for the main action on a card.
struct CuteCandyButtonStyle: ButtonStyle {
    var colors: [Color] = [Cute.leaf, Cute.leafDeep]

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Cute.font(18, .black))
            .foregroundStyle(.white)
            .shadow(color: Cute.cocoa.opacity(0.35), radius: 0, y: 1.5)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom), in: Capsule())
            .overlay(alignment: .top) {
                Capsule().fill(.white.opacity(0.35)).frame(height: 7).padding(.horizontal, 22).padding(.top, 5)
            }
            .overlay(Capsule().stroke(.white, lineWidth: 2.5))
            .shadow(color: (colors.last ?? Cute.leafDeep).opacity(0.75), radius: 0, y: configuration.isPressed ? 1 : 4)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.55), value: configuration.isPressed)
    }
}

/// Celebration card shown after winning a level (replaces the plain system alert).
struct LevelWinCard: View {
    let title: String
    let message: String
    let buttonTitle: String
    var showsTreat = false
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var floating = false

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                card
                    .padding(24)
                    .frame(maxWidth: .infinity, minHeight: proxy.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .background(Color.black.opacity(0.38).ignoresSafeArea())
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) { floating = true }
        }
    }

    private var card: some View {
        VStack(spacing: 12) {
            ZStack {
                ForEach(0..<5, id: \.self) { index in
                    Image(systemName: index.isMultiple(of: 2) ? "heart.fill" : "pawprint.fill")
                        .font(.system(size: 15 + CGFloat(index % 3) * 4, weight: .black))
                        .foregroundStyle(index.isMultiple(of: 2) ? Cute.berry : Cute.honeyDeep)
                        .offset(
                            x: CGFloat([-78, -48, 52, 82, 0][index]),
                            y: CGFloat([-18, -46, -44, -10, -58][index]) + (floating ? -6 : 4)
                        )
                        .opacity(0.9)
                }
                if let portrait = UIImage(named: "henry-map-marker") {
                    Image(uiImage: portrait)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 92, height: 92)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(.white, lineWidth: 4))
                        .shadow(color: Cute.cocoa.opacity(0.25), radius: 0, y: 4)
                        .scaleEffect(floating ? 1.04 : 1)
                }
            }
            .frame(height: 104)
            .accessibilityHidden(true)

            StickerText(title, size: 28, colors: [Cute.honey, Cute.honeyDeep])
                .multilineTextAlignment(.center)
            Text(message)
                .font(Cute.font(15, .semibold))
                .foregroundStyle(Cute.cocoaSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if showsTreat {
                HStack(spacing: 6) {
                    TreatIcon(size: 22)
                    Text("+1 treat for the yard!")
                        .font(Cute.font(14, .black))
                        .foregroundStyle(Cute.leafDeep)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(.white, in: Capsule())
                .overlay(Capsule().strokeBorder(Cute.leaf.opacity(0.5), lineWidth: 2))
                .scaleEffect(floating ? 1.05 : 1)
            }
            Button(action: action) {
                Label(buttonTitle, systemImage: "pawprint.fill")
            }
            .buttonStyle(CuteCandyButtonStyle())
            .padding(.top, 4)
        }
        .padding(22)
        .frame(maxWidth: 380)
        .quiltedCard(corner: 30)
    }
}

/// Shown when a level runs out of moves. Lives are unlimited, so trying again is always free;
/// when the goal is nearly done, Henry also offers a one-time second wind.
struct OutOfMovesCard: View {
    let progress: Int
    let goal: Int
    let secondWindMoves: Int?
    let secondWind: () -> Void
    let retry: () -> Void
    let map: () -> Void

    var body: some View {
        GeometryReader { proxy in
            let wide = proxy.size.width > proxy.size.height
            ScrollView {
                Group {
                    if wide {
                        // Landscape: Henry and the message on the left, choices on the right.
                        HStack(spacing: 22) {
                            VStack(spacing: 10) { portrait(64); headline }
                                .frame(maxWidth: 280)
                            VStack(spacing: 12) { buttons }
                                .frame(maxWidth: 260)
                        }
                        .padding(22)
                        .frame(maxWidth: 620)
                    } else {
                        VStack(spacing: 12) { portrait(82); headline; buttons }
                            .padding(22)
                            .frame(maxWidth: 380)
                    }
                }
                .quiltedCard(corner: 30)
                .padding(wide ? 14 : 24)
                .frame(maxWidth: .infinity, minHeight: proxy.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .background(Color.black.opacity(0.38).ignoresSafeArea())
    }

    @ViewBuilder private func portrait(_ size: CGFloat) -> some View {
        if let image = UIImage(named: "henry-map-marker") {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
                .overlay(Circle().stroke(.white, lineWidth: 4))
                .shadow(color: Cute.cocoa.opacity(0.25), radius: 0, y: 4)
                .accessibilityHidden(true)
        }
    }

    @ViewBuilder private var headline: some View {
        CutePill(text: "OUT OF MOVES", icon: "hourglass", fill: Cute.berry, size: 10)
        StickerText(secondWindMoves == nil ? "Let's try again!" : "So close!", size: 28, colors: [Cute.honey, Cute.honeyDeep])
            .multilineTextAlignment(.center)
        CuteProgressBar(value: Double(progress), total: Double(max(goal, 1)), height: 12)
            .frame(maxWidth: 240)
        Text(secondWindMoves.map { "Henry found a snack in his pocket. Take \($0) more moves to finish?" }
             ?? "\(progress) of \(goal) done. Henry is ready to start the chase again—lives never run out.")
            .font(Cute.font(15, .semibold))
            .foregroundStyle(Cute.cocoaSoft)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder private var buttons: some View {
        if let secondWindMoves {
            Button(action: secondWind) {
                Label("+\(secondWindMoves) moves", systemImage: "takeoutbag.and.cup.and.straw.fill")
            }
            .buttonStyle(CuteCandyButtonStyle(colors: [Cute.leaf, Cute.leafDeep]))
        }
        Button(action: retry) {
            Label("Try again", systemImage: "arrow.counterclockwise")
        }
        .buttonStyle(CuteCandyButtonStyle())
        Button(action: map) {
            Text("Back to the map")
                .font(Cute.font(14, .heavy))
                .foregroundStyle(Cute.cocoaSoft)
                .underline()
        }
        .buttonStyle(.plain)
    }
}
