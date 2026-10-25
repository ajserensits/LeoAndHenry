import SwiftUI

struct VeggieView: View {
    let veggie: Veggie
    var size: CGFloat = 44

    var body: some View {
        Group {
            if let portrait = UIImage(named: veggie.spriteName) {
                Image(uiImage: portrait)
                    .resizable()
                    .scaledToFill()
                    .clipShape(Circle())
                    .overlay(Circle().stroke(.white.opacity(0.65), lineWidth: max(1, size * 0.04)))
                    .shadow(color: .black.opacity(0.22), radius: 2, y: 2)
            } else {
                ZStack {
                    Circle().fill(veggie.color.gradient)
                    Image(systemName: "pawprint.fill").foregroundStyle(.white)
                }
            }
        }
        .frame(width: size, height: size)
        .accessibilityLabel(veggie.name)
    }
}

struct LeafCrown: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.addLine(to: CGPoint(x: 0, y: rect.height * 0.42))
        p.addLine(to: CGPoint(x: rect.width * 0.35, y: rect.height * 0.48))
        p.addLine(to: CGPoint(x: rect.midX, y: 0))
        p.addLine(to: CGPoint(x: rect.width * 0.65, y: rect.height * 0.48))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.height * 0.28))
        p.closeSubpath()
        return p
    }
}

struct Smile: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY), control: CGPoint(x: rect.midX, y: rect.maxY))
        return p
    }
}
