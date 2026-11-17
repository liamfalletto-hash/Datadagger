import SwiftUI
import UIKit
import CoreText

// The arcade UI kit: chunky glossy blocks with thick outlines, white text with a heavy stroke,
// striped panels, and wear (grime, cracks) that grows as Earth Health falls.

// MARK: - Fonts

enum ArcadeFont {
    static let displayName = "LuckiestGuy-Regular"
    static let bodyName = "Fredoka-Bold"

    /// Registers the fonts in the Fonts folder. Call once at launch, before any view appears.
    static func register() {
        let files = ["LuckiestGuy-Regular", "Fredoka-Bold", "Fredoka-SemiBold"]
        var bundles = [Bundle.main]
        if let urls = Bundle.main.urls(forResourcesWithExtension: "bundle", subdirectory: nil) {
            bundles += urls.compactMap { Bundle(url: $0) }
        }
        bundles += Bundle.allBundles
        for file in files {
            for bundle in bundles {
                let url = bundle.url(forResource: file, withExtension: "ttf")
                    ?? bundle.url(forResource: file, withExtension: "ttf", subdirectory: "Fonts")
                if let url = url {
                    CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
                    break
                }
            }
        }
    }

    // If a font failed to load, fall back to the system's rounded font so the game still looks right.
    static let hasDisplay = UIFont(name: displayName, size: 12) != nil
    static let hasBody = UIFont(name: bodyName, size: 12) != nil

    static func display(_ size: CGFloat) -> Font {
        hasDisplay ? .custom(displayName, fixedSize: size) : .system(size: size, weight: .black, design: .rounded)
    }

    static func body(_ size: CGFloat) -> Font {
        hasBody ? .custom(bodyName, fixedSize: size) : .system(size: size, weight: .bold, design: .rounded)
    }
}

// MARK: - Colors

enum Arcade {
    static let ink = Color(red: 0.05, green: 0.05, blue: 0.08)
    static let gold = Color(red: 1.0, green: 0.86, blue: 0.32)
    static let mint = Color(red: 0.66, green: 1.0, blue: 0.5)
    static let smogText = Color(red: 0.79, green: 0.8, blue: 0.88)

    enum Tint { case green, yellow, red, purple, blue, orange, slate, grey, pink, cyan }

    static func base(_ tint: Tint) -> (RGB, RGB) {
        switch tint {
        case .green: return (RGB(0.54, 0.96, 0.37), RGB(0.13, 0.70, 0.23))
        case .yellow: return (RGB(1.0, 0.92, 0.42), RGB(1.0, 0.70, 0.0))
        case .red: return (RGB(1.0, 0.48, 0.42), RGB(0.88, 0.15, 0.23))
        case .purple: return (RGB(0.81, 0.61, 1.0), RGB(0.48, 0.25, 0.95))
        case .blue: return (RGB(0.44, 0.84, 1.0), RGB(0.11, 0.50, 0.88))
        case .orange: return (RGB(1.0, 0.76, 0.42), RGB(1.0, 0.42, 0.10))
        case .slate: return (RGB(0.55, 0.59, 0.68), RGB(0.30, 0.34, 0.42))
        case .grey: return (RGB(0.81, 0.83, 0.86), RGB(0.48, 0.51, 0.57))
        case .pink: return (RGB(1.0, 0.60, 0.88), RGB(0.77, 0.19, 0.61))
        case .cyan: return (RGB(0.44, 0.90, 0.96), RGB(0.08, 0.59, 0.72))
        }
    }

    /// Colors fade to grey, then rust, as the planet dies (decay 0 = pristine, 1 = dead).
    static func weathered(_ c: RGB, _ decay: Double) -> RGB {
        let grey = (c.r + c.g + c.b) / 3
        let faded = RGB.mix(c, RGB(grey, grey, grey), 0.55 * decay)
        let rusty = RGB(faded.r * 1.05 + 0.08, faded.g * 0.85, faded.b * 0.7)
        return RGB.mix(faded, rusty, max(0, decay - 0.4) * 0.6) * (1 - 0.1 * decay)
    }

    static func colors(_ tint: Tint, decay: Double) -> (Color, Color) {
        let pair = base(tint)
        return (weathered(pair.0, decay).color, weathered(pair.1, decay).color)
    }

    // Panel colors by Earth phase: bright blue → grey → rust red.
    static let bodyTop: Palette.Triple = (RGB(0.13, 0.27, 0.52), RGB(0.22, 0.24, 0.27), RGB(0.30, 0.12, 0.08))
    static let bodyBottom: Palette.Triple = (RGB(0.07, 0.15, 0.32), RGB(0.13, 0.14, 0.16), RGB(0.17, 0.06, 0.04))
    static let cardTop: Palette.Triple = (RGB(0.20, 0.40, 0.74), RGB(0.33, 0.36, 0.40), RGB(0.48, 0.20, 0.12))
    static let cardBottom: Palette.Triple = (RGB(0.12, 0.27, 0.54), RGB(0.22, 0.24, 0.27), RGB(0.32, 0.12, 0.07))
    static let headerTop: Palette.Triple = (RGB(0.40, 0.80, 1.0), RGB(0.68, 0.71, 0.75), RGB(1.0, 0.60, 0.30))
    static let headerBottom: Palette.Triple = (RGB(0.10, 0.48, 0.90), RGB(0.38, 0.42, 0.47), RGB(0.80, 0.22, 0.10))
    static let barTop: Palette.Triple = (RGB(0.62, 1, 0.45), RGB(0.82, 0.84, 0.76), RGB(1, 0.75, 0.42))
    static let barBottom: Palette.Triple = (RGB(0.13, 0.7, 0.23), RGB(0.52, 0.54, 0.46), RGB(0.86, 0.36, 0.10))
    static let phaseText: Palette.Triple = (RGB(0.72, 1, 0.6), RGB(0.9, 0.89, 0.81), RGB(1, 0.77, 0.54))
    static let moveTop: Palette.Triple = (RGB(1.0, 0.67, 0.29), RGB(0.78, 0.68, 0.52), RGB(0.86, 0.45, 0.22))
    static let moveBottom: Palette.Triple = (RGB(0.94, 0.44, 0.11), RGB(0.55, 0.47, 0.36), RGB(0.62, 0.25, 0.10))
    static let purpleTop: Palette.Triple = (RGB(0.45, 0.30, 0.85), RGB(0.42, 0.40, 0.50), RGB(0.47, 0.22, 0.30))
    static let purpleBottom: Palette.Triple = (RGB(0.26, 0.15, 0.58), RGB(0.27, 0.26, 0.33), RGB(0.30, 0.11, 0.15))

    /// Icon colors for the eight building tiers.
    static let tierPalette: [(RGB, RGB)] = [
        (RGB(0.56, 0.71, 1.0), RGB(0.24, 0.39, 0.84)),
        (RGB(0.54, 0.96, 0.56), RGB(0.12, 0.66, 0.29)),
        (RGB(0.44, 0.90, 0.96), RGB(0.08, 0.59, 0.72)),
        (RGB(0.71, 0.64, 1.0), RGB(0.35, 0.26, 0.88)),
        (RGB(1.0, 0.70, 0.42), RGB(0.88, 0.38, 0.11)),
        (RGB(0.44, 0.78, 1.0), RGB(0.10, 0.42, 0.85)),
        (RGB(1.0, 0.88, 0.48), RGB(0.85, 0.60, 0.10)),
        (RGB(1.0, 0.60, 0.88), RGB(0.77, 0.19, 0.61)),
    ]

    static func tierColors(_ i: Int) -> (RGB, RGB) { tierPalette[i % tierPalette.count] }
}

// MARK: - Earth Health in the environment

private struct EarthHealthKey: EnvironmentKey {
    static let defaultValue: Double = 100
}

extension EnvironmentValues {
    /// Earth Health (0...100), rounded so the UI only redraws its wear every couple of percent.
    var earthHealth: Double {
        get { self[EarthHealthKey.self] }
        set { self[EarthHealthKey.self] = newValue }
    }
}

// MARK: - Text and icons

/// White (or colored) text with a thick black outline and a drop shadow.
struct StrokeText: View {
    let text: String
    let size: CGFloat
    var color: Color = .white
    var display = true
    var stroke: CGFloat? = nil

    init(_ text: String, size: CGFloat, color: Color = .white, display: Bool = true, stroke: CGFloat? = nil) {
        self.text = text
        self.size = size
        self.color = color
        self.display = display
        self.stroke = stroke
    }

    var body: some View {
        let w = stroke ?? max(1.4, size * 0.1)
        let font = display ? ArcadeFont.display(size) : ArcadeFont.body(size)
        ZStack {
            Text(text).font(font).foregroundColor(Arcade.ink).offset(y: w * 1.6)
            ForEach(0..<8, id: \.self) { i in
                let a = Double(i) * Double.pi / 4
                Text(text).font(font).foregroundColor(Arcade.ink)
                    .offset(x: CGFloat(cos(a)) * w, y: CGFloat(sin(a)) * w)
            }
            Text(text).font(font).foregroundColor(color)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .padding(.horizontal, w)
        .padding(.top, w)
        .padding(.bottom, w * 1.6)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
    }
}

/// An SF Symbol with a black outline.
struct OutlinedSymbol: View {
    let name: String
    let size: CGFloat
    var color: Color = .white

    init(_ name: String, size: CGFloat, color: Color = .white) {
        self.name = name
        self.size = size
        self.color = color
    }

    var body: some View {
        let w = max(1.5, size * 0.08)
        ZStack {
            ForEach(0..<8, id: \.self) { i in
                let a = Double(i) * Double.pi / 4
                Image(systemName: name)
                    .font(.system(size: size, weight: .black))
                    .foregroundColor(Arcade.ink)
                    .offset(x: CGFloat(cos(a)) * w, y: CGFloat(sin(a)) * w)
            }
            Image(systemName: name)
                .font(.system(size: size, weight: .black))
                .foregroundColor(color)
        }
        .accessibilityHidden(true)
    }
}

/// The gold token coin.
struct CoinIcon: View {
    var size: CGFloat = 46

    var body: some View {
        let edge = Color(red: 0.72, green: 0.38, blue: 0.04)
        ZStack {
            Circle().fill(RadialGradient(colors: [Color(red: 1, green: 0.96, blue: 0.69), Color(red: 1, green: 0.82, blue: 0.23), Color(red: 0.95, green: 0.6, blue: 0.05)],
                                         center: UnitPoint(x: 0.35, y: 0.3), startRadius: 0, endRadius: size * 0.65))
            Circle().strokeBorder(Arcade.ink, lineWidth: max(2, size * 0.065))
            RoundedRectangle(cornerRadius: size * 0.06, style: .continuous)
                .fill(Color(red: 1, green: 0.95, blue: 0.69))
                .overlay(RoundedRectangle(cornerRadius: size * 0.06, style: .continuous).strokeBorder(edge, lineWidth: max(1.5, size * 0.06)))
                .frame(width: size * 0.36, height: size * 0.36)
                .rotationEffect(.degrees(45))
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// A tiny planet for the HUD, colored by Earth Health.
struct MiniGlobe: View {
    let health: Double
    var size: CGFloat = 24

    var body: some View {
        let ocean = Palette.rgb(EarthRenderer.oceanT, health)
        let land = Palette.c(EarthRenderer.grassT, health)
        ZStack {
            Circle().fill(RadialGradient(colors: [(ocean * 1.8).color, ocean.color, (ocean * 0.6).color],
                                         center: UnitPoint(x: 0.35, y: 0.3), startRadius: 0, endRadius: size * 0.7))
            Ellipse().fill(land).frame(width: size * 0.45, height: size * 0.36).offset(x: -size * 0.12, y: -size * 0.06)
            Ellipse().fill(land).frame(width: size * 0.3, height: size * 0.26).offset(x: size * 0.2, y: size * 0.2)
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().strokeBorder(Arcade.ink, lineWidth: 2.5))
        .accessibilityHidden(true)
    }
}

/// A row of chunky segments, like an arcade health bar.
struct Segments: View {
    let count: Int
    let filled: Int
    let top: Color
    let bottom: Color
    var height: CGFloat = 11

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<count, id: \.self) { k in
                let shape = RoundedRectangle(cornerRadius: 3, style: .continuous)
                ZStack {
                    if k < filled {
                        shape.fill(LinearGradient(colors: [top, bottom], startPoint: .top, endPoint: .bottom))
                    } else {
                        shape.fill(Color(red: 0.15, green: 0.16, blue: 0.23))
                    }
                    shape.strokeBorder(Arcade.ink, lineWidth: 2)
                }
                .frame(height: height)
            }
        }
        .accessibilityHidden(true)
    }
}

/// A square icon tile with an optional level badge.
struct IconTile: View {
    let symbol: String
    let colors: (RGB, RGB)
    var size: CGFloat = 54
    var level: Int? = nil
    var muted = false
    @Environment(\.earthHealth) var health

    var body: some View {
        let decay = 1 - health / 100
        let top = muted ? Color(red: 0.23, green: 0.25, blue: 0.32) : Arcade.weathered(colors.0, decay).color
        let bottom = muted ? Color(red: 0.16, green: 0.17, blue: 0.22) : Arcade.weathered(colors.1, decay).color
        let shape = RoundedRectangle(cornerRadius: size * 0.26, style: .continuous)
        ZStack(alignment: .bottomTrailing) {
            ZStack {
                shape.fill(LinearGradient(colors: [top, bottom], startPoint: .topLeading, endPoint: .bottomTrailing))
                shape.strokeBorder(LinearGradient(colors: [Color.white.opacity(0.45), Color.white.opacity(0)], startPoint: .top, endPoint: .center), lineWidth: 3)
                    .padding(3)
                OutlinedSymbol(symbol, size: size * 0.46, color: muted ? Color(white: 0.8) : .white)
                shape.strokeBorder(Arcade.ink, lineWidth: 3)
            }
            .frame(width: size, height: size)
            if let level = level {
                LevelBadge(value: level)
                    .offset(x: 10, y: 10)
            }
        }
    }
}

struct LevelBadge: View {
    let value: Int

    var body: some View {
        StrokeText("\(value)", size: 13)
            .frame(minWidth: 26, minHeight: 26)
            .padding(.horizontal, 2)
            .background(Capsule().fill(LinearGradient(colors: [Color(red: 1, green: 0.92, blue: 0.42), Color(red: 1, green: 0.7, blue: 0)], startPoint: .top, endPoint: .bottom)))
            .overlay(Capsule().strokeBorder(Arcade.ink, lineWidth: 3))
    }
}

/// Red notification badge.
struct CountBadge: View {
    let value: Int

    var body: some View {
        StrokeText("\(value)", size: 13)
            .frame(minWidth: 24, minHeight: 24)
            .background(Circle().fill(LinearGradient(colors: [Color(red: 1, green: 0.48, blue: 0.42), Color(red: 0.88, green: 0.15, blue: 0.23)], startPoint: .top, endPoint: .bottom)))
            .overlay(Circle().strokeBorder(Arcade.ink, lineWidth: 3))
    }
}

// MARK: - Blocks, buttons and panels

/// A glossy block: gradient, top shine, bottom shade and a thick outline.
struct ArcadeFace: View {
    let top: Color
    let bottom: Color
    var radius: CGFloat = 14

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        ZStack {
            shape.fill(LinearGradient(colors: [top, bottom], startPoint: .top, endPoint: .bottom))
            shape.fill(LinearGradient(colors: [Color.black.opacity(0), Color.black.opacity(0.2)], startPoint: UnitPoint(x: 0.5, y: 0.7), endPoint: .bottom))
            GeometryReader { geo in
                RoundedRectangle(cornerRadius: min(radius * 0.7, geo.size.height * 0.2), style: .continuous)
                    .fill(LinearGradient(colors: [Color.white.opacity(0.6), Color.white.opacity(0.1)], startPoint: .top, endPoint: .bottom))
                    .frame(width: max(0, geo.size.width - 8), height: geo.size.height * 0.42)
                    .offset(x: 4, y: 3)
            }
            shape.strokeBorder(Arcade.ink, lineWidth: 3)
        }
    }
}

/// Chunky arcade button: sits on a black "lip" and pushes down when pressed.
struct ArcadeButtonStyle: ButtonStyle {
    var tint: Arcade.Tint
    var radius: CGFloat = 14
    @Environment(\.isEnabled) var isEnabled
    @Environment(\.earthHealth) var health

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        let face = Arcade.colors(isEnabled ? tint : .slate, decay: 1 - health / 100)
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        return configuration.label
            .background(ArcadeFace(top: face.0, bottom: face.1, radius: radius))
            .offset(y: pressed ? 4 : 0)
            .background(shape.fill(Arcade.ink).offset(y: 5))
            .scaleEffect(pressed ? 0.97 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.55), value: pressed)
            .padding(.bottom, 5)
    }
}

/// Just shrinks a little when pressed.
struct PressScale: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.5), value: configuration.isPressed)
    }
}

/// Diagonal stripes, the classic arcade panel texture.
struct Stripes: View {
    var opacity: Double = 0.07
    var spacing: CGFloat = 18

    var body: some View {
        Canvas { ctx, size in
            var p = Path()
            var x: CGFloat = -size.height
            while x < size.width + size.height {
                p.move(to: CGPoint(x: x, y: size.height))
                p.addLine(to: CGPoint(x: x + size.height, y: 0))
                x += spacing
            }
            ctx.stroke(p, with: .color(Color.white.opacity(opacity)), lineWidth: spacing / 2)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Grime and cracks that appear as the planet dies.
struct Wear: View {
    var seed: Int
    @Environment(\.earthHealth) var health

    var body: some View {
        let decay = 1 - health / 100
        if decay > 0.2 {
            Canvas { ctx, size in
                Wear.paint(&ctx, size, seed: seed, decay: decay)
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }

    static func paint(_ c: inout GraphicsContext, _ size: CGSize, seed: Int, decay: Double) {
        let w = Double(size.width)
        let h = Double(size.height)
        let grime = (decay - 0.2) / 0.8
        let dirt = Color(red: 0.12, green: 0.07, blue: 0.03)
        for k in 0..<(3 + Int(grime * 6)) {
            let at = CGPoint(x: G.rnd(seed + k, 1) * w, y: G.rnd(seed + k, 2) * h)
            let r = 14 + G.rnd(seed + k, 3) * 36
            G.ellipse(&c, at, r * 1.3, r, shading: G.radial(at, 0, r * 1.3, [(0, dirt.opacity(0.32 * grime)), (1, dirt.opacity(0))]))
        }
        c.fill(Path(CGRect(origin: .zero, size: size)), with: G.linear(CGPoint(x: 0, y: h), CGPoint(x: 0, y: h * 0.55), [
            (0, dirt.opacity(0.35 * grime)), (1, dirt.opacity(0)),
        ]))
        guard decay > 0.35 else { return }
        let cracks = Int(((decay - 0.35) * 5 * max(1, w * h / 30_000) + 0.5).rounded(.down))
        for k in 0..<cracks {
            let side = Int(G.rnd(seed + k, 4) * 4)
            var x = side == 1 ? w : (side == 3 ? 0 : G.rnd(seed + k, 5) * w)
            var y = side == 0 ? 0 : (side == 2 ? h : G.rnd(seed + k, 6) * h)
            var angle = atan2(h / 2 - y, w / 2 - x) + (G.rnd(seed + k, 7) - 0.5) * 1.2
            let length = 14 + G.rnd(seed + k, 8) * 26
            var pts = [CGPoint(x: x, y: y)]
            for s in 0..<5 {
                angle += (G.rnd(seed + k * 7 + s, 9) - 0.5) * 1.1
                x += cos(angle) * length / 3
                y += sin(angle) * length / 3
                pts.append(CGPoint(x: x, y: y))
            }
            G.stroke(&c, pts, Color(red: 0.04, green: 0.04, blue: 0.06).opacity(0.85), 2.2, closed: false)
            G.stroke(&c, pts.map { CGPoint(x: $0.x + 1, y: $0.y + 1) }, Color.white.opacity(0.45), 1, closed: false)
            let b = pts[2]
            let branch = [b, CGPoint(x: Double(b.x) + cos(angle + 1) * 10, y: Double(b.y) + sin(angle + 1) * 10),
                          CGPoint(x: Double(b.x) + cos(angle + 0.6) * 18, y: Double(b.y) + sin(angle + 0.6) * 18)]
            G.stroke(&c, branch, Color(red: 0.04, green: 0.04, blue: 0.06).opacity(0.8), 1.6, closed: false)
        }
    }
}

/// Yellow-and-black tape stuck over things once the planet is nearly dead.
struct HazardTape: View {
    var body: some View {
        Canvas { ctx, size in
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(red: 1, green: 0.82, blue: 0.23)))
            var stripes = Path()
            var x: CGFloat = -size.height
            while x < size.width {
                stripes.move(to: CGPoint(x: x, y: size.height))
                stripes.addLine(to: CGPoint(x: x + 8, y: size.height))
                stripes.addLine(to: CGPoint(x: x + 8 + size.height, y: 0))
                stripes.addLine(to: CGPoint(x: x + size.height, y: 0))
                stripes.closeSubpath()
                x += 16
            }
            ctx.fill(stripes, with: .color(Arcade.ink))
        }
        .frame(width: 70, height: 18)
        .overlay(Rectangle().stroke(Arcade.ink, lineWidth: 2))
        .shadow(color: Color.black.opacity(0.4), radius: 0, x: 0, y: 2)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// A striped, outlined block with a hard drop shadow, in the current Earth-phase colors.
struct ArcadePanel: ViewModifier {
    var seed: Int = 0
    var top: Palette.Triple = Arcade.cardTop
    var bottom: Palette.Triple = Arcade.cardBottom
    var radius: CGFloat = 16
    var dashed = false
    @Environment(\.earthHealth) var health

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        let decay = 1 - health / 100
        content
            .background(
                ZStack {
                    if dashed {
                        shape.fill(Color.black.opacity(0.35))
                    } else {
                        shape.fill(LinearGradient(colors: [Palette.c(top, health), Palette.c(bottom, health)], startPoint: .top, endPoint: .bottom))
                        Stripes(opacity: 0.07 - 0.04 * decay).clipShape(shape)
                        Wear(seed: seed).clipShape(shape)
                    }
                    if dashed {
                        shape.strokeBorder(Color.white.opacity(0.35), style: StrokeStyle(lineWidth: 3, dash: [8, 6]))
                    } else {
                        shape.strokeBorder(Arcade.ink, lineWidth: 3)
                    }
                }
            )
            .background(shape.fill(Arcade.ink.opacity(dashed ? 0.3 : 1)).offset(y: 4))
    }
}

extension View {
    func arcadePanel(seed: Int = 0, top: Palette.Triple = Arcade.cardTop, bottom: Palette.Triple = Arcade.cardBottom, radius: CGFloat = 16, dashed: Bool = false) -> some View {
        modifier(ArcadePanel(seed: seed, top: top, bottom: bottom, radius: radius, dashed: dashed))
    }
}

/// A rectangle with only its top corners rounded (for the bottom sheet).
struct TopRounded: Shape {
    var radius: CGFloat

    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addArc(tangent1End: CGPoint(x: r.minX, y: r.minY), tangent2End: CGPoint(x: r.maxX, y: r.minY), radius: radius)
        p.addArc(tangent1End: CGPoint(x: r.maxX, y: r.minY), tangent2End: CGPoint(x: r.maxX, y: r.maxY), radius: radius)
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

/// Smog haze, or falling ash with a pulsing red alarm, over the whole screen.
struct WeatherOverlay: View {
    let health: Double

    var body: some View {
        if health < 33 {
            TimelineView(.animation(minimumInterval: 1.0 / 24.0)) { timeline in
                Canvas { ctx, size in
                    let t = timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 10_000)
                    let W = Double(size.width), H = Double(size.height)
                    var ash = Path()
                    for k in 0..<70 {
                        let x = (G.rnd(k, 91) * W + sin(t * 0.7 + Double(k)) * 18).truncatingRemainder(dividingBy: W)
                        let y = (G.rnd(k, 92) * H + t * (14 + 22 * G.rnd(k, 93))).truncatingRemainder(dividingBy: H)
                        let r = 0.8 + G.rnd(k, 94) * 1.6
                        ash.addEllipse(in: CGRect(x: x, y: y, width: r * 3, height: r * 2))
                    }
                    ctx.fill(ash, with: .color(Color(red: 0.86, green: 0.8, blue: 0.75).opacity(0.55)))
                    let pulse = 0.2 + 0.1 * sin(t * 2.2)
                    let center = CGPoint(x: W / 2, y: H / 2)
                    ctx.fill(Path(CGRect(origin: .zero, size: size)), with: G.radial(center, min(W, H) * 0.5, max(W, H) * 0.65, [
                        (0, Color(red: 1, green: 0.16, blue: 0.08).opacity(0)), (1, Color(red: 1, green: 0.16, blue: 0.08).opacity(pulse)),
                    ]))
                }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        } else if health < 66 {
            LinearGradient(colors: [Color(red: 0.35, green: 0.33, blue: 0.27).opacity(0.25), Color(red: 0.35, green: 0.33, blue: 0.27).opacity(0.05), Color.clear],
                           startPoint: .top, endPoint: .bottom)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }
}

// MARK: - Fact styling

extension Fact {
    var symbol: String {
        switch id {
        case "one-prompt": return "text.bubble.fill"
        case "electricity-today", "electricity-2030", "us-share": return "bolt.fill"
        case "power-sources": return "sun.max.fill"
        case "cooling": return "snowflake"
        case "ai-site": return "building.2.fill"
        case "scale": return "chart.bar.fill"
        case "water-direct", "water-hidden": return "drop.fill"
        case "ewaste", "ewaste-trend": return "trash.fill"
        case "where": return "globe.americas.fill"
        default: return "leaf.fill"
        }
    }

    var tint: (RGB, RGB) {
        switch id {
        case "electricity-today", "electricity-2030", "us-share", "power-sources": return Arcade.base(.yellow)
        case "cooling", "one-prompt": return Arcade.base(.cyan)
        case "ai-site", "scale": return Arcade.base(.purple)
        case "water-direct", "water-hidden": return Arcade.base(.blue)
        case "ewaste", "ewaste-trend": return Arcade.base(.orange)
        default: return Arcade.base(.green)
        }
    }
}

extension ModelNode {
    var symbol: String {
        switch id {
        case "memory": return "memorychip"
        case "warm": return "flame.fill"
        case "distill": return "wand.and.stars"
        case "green": return "leaf.fill"
        default: return "gearshape.2.fill"
        }
    }

    var tint: (RGB, RGB) {
        switch id {
        case "memory": return Arcade.base(.cyan)
        case "warm": return Arcade.base(.orange)
        case "distill": return Arcade.base(.purple)
        case "green": return Arcade.base(.green)
        default: return Arcade.base(.grey)
        }
    }
}
