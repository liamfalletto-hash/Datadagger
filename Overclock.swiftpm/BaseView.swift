import SwiftUI

// The player's base, drawn in isometric 2.5D with SwiftUI Canvas.
// Stage 0 Bedroom → 1 Warehouse → 2 Server Hall → 3 Campus → 4 Horizon Megacenter.
// Stage 5 (Planetary Core) shows the globe from EarthView instead.
// The sky in every window, the backdrop and the outdoor scenes follow Earth Health.

struct BaseState {
    let stage: Int
    let owned: [Int]
    let health: Double
    let income: Double
    let pollution: Double
    let overclock: Bool
}

struct BaseView: View {
    @EnvironmentObject var game: Game
    /// Space reserved at the top for the HUD, so rooms sit below it.
    var top: CGFloat = 0

    var body: some View {
        let state = BaseState(
            stage: min(game.locationStage, 4), owned: game.owned, health: game.health,
            income: game.incomePerSecond, pollution: game.pollutionPerSecond, overclock: game.isOverclocking
        )
        let inset = top
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 100_000)
                Scenes.draw(&context, size: size, time: t, state: state, top: inset)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Your base: \(Config.locations[min(game.locationStage, Config.locations.count - 1)].name)")
    }
}

/// Tap anywhere on the stage to earn Tokens, with a floating "+◈" number.
struct TapToEarn: ViewModifier {
    @EnvironmentObject var game: Game
    @State private var sparks: [Spark] = []

    struct Spark: Identifiable {
        let id = UUID()
        let text: String
        let at: CGPoint
        var rise = false
    }

    func body(content: Content) -> some View {
        content
            .overlay {
                ZStack {
                    ForEach(sparks) { s in
                        StrokeText(s.text, size: 22, color: Arcade.gold)
                            .position(x: s.at.x, y: s.at.y - (s.rise ? 70 : 0))
                            .opacity(s.rise ? 0 : 1)
                    }
                }
                .allowsHitTesting(false)
            }
            .contentShape(Rectangle())
            .gesture(SpatialTapGesture().onEnded { value in tap(at: value.location) })
            .accessibilityAddTraits(.isButton)
    }

    private func tap(at point: CGPoint) {
        let gained = game.tapPlanet()
        let spark = Spark(text: "+" + Fmt.num(gained), at: point)
        sparks.append(spark)
        let id = spark.id
        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 0.8)) {
                if let i = sparks.firstIndex(where: { $0.id == id }) { sparks[i].rise = true }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
            sparks.removeAll { $0.id == id }
        }
    }
}

// MARK: - Drawing helpers

enum G {
    /// Stable pseudo-random number in 0..<1.
    static func rnd(_ i: Int, _ salt: Double) -> Double {
        let x = sin(Double(i) * 12.9898 + salt * 78.233) * 43758.5453
        return x - floor(x)
    }

    static func path(_ pts: [CGPoint], closed: Bool = true) -> Path {
        var p = Path()
        guard let first = pts.first else { return p }
        p.move(to: first)
        for q in pts.dropFirst() { p.addLine(to: q) }
        if closed { p.closeSubpath() }
        return p
    }

    static func fill(_ c: inout GraphicsContext, _ pts: [CGPoint], _ color: Color) {
        c.fill(path(pts), with: .color(color))
    }

    static func fill(_ c: inout GraphicsContext, _ pts: [CGPoint], shading: GraphicsContext.Shading) {
        c.fill(path(pts), with: shading)
    }

    static func stroke(_ c: inout GraphicsContext, _ pts: [CGPoint], _ color: Color, _ width: CGFloat, closed: Bool = true) {
        c.stroke(path(pts, closed: closed), with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
    }

    static func line(_ c: inout GraphicsContext, _ a: CGPoint, _ b: CGPoint, _ color: Color, _ width: CGFloat) {
        var p = Path()
        p.move(to: a)
        p.addLine(to: b)
        c.stroke(p, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round))
    }

    static func ellipseRect(_ center: CGPoint, _ rx: CGFloat, _ ry: CGFloat) -> CGRect {
        let x = max(0.1, rx)
        let y = max(0.1, ry)
        return CGRect(x: center.x - x, y: center.y - y, width: x * 2, height: y * 2)
    }

    static func ellipse(_ c: inout GraphicsContext, _ center: CGPoint, _ rx: CGFloat, _ ry: CGFloat, _ color: Color) {
        c.fill(Path(ellipseIn: ellipseRect(center, rx, ry)), with: .color(color))
    }

    static func ellipse(_ c: inout GraphicsContext, _ center: CGPoint, _ rx: CGFloat, _ ry: CGFloat, shading: GraphicsContext.Shading) {
        c.fill(Path(ellipseIn: ellipseRect(center, rx, ry)), with: shading)
    }

    static func gradient(_ stops: [(Double, Color)]) -> Gradient {
        Gradient(stops: stops.map { Gradient.Stop(color: $0.1, location: $0.0) })
    }

    static func linear(_ a: CGPoint, _ b: CGPoint, _ stops: [(Double, Color)]) -> GraphicsContext.Shading {
        .linearGradient(gradient(stops), startPoint: a, endPoint: b)
    }

    static func radial(_ center: CGPoint, _ r0: CGFloat, _ r1: CGFloat, _ stops: [(Double, Color)]) -> GraphicsContext.Shading {
        .radialGradient(gradient(stops), center: center, startRadius: r0, endRadius: r1)
    }

    static func bbox(_ pts: [CGPoint]) -> CGRect {
        var minX = CGFloat.greatestFiniteMagnitude, minY = CGFloat.greatestFiniteMagnitude
        var maxX = -CGFloat.greatestFiniteMagnitude, maxY = -CGFloat.greatestFiniteMagnitude
        for p in pts {
            minX = min(minX, p.x)
            minY = min(minY, p.y)
            maxX = max(maxX, p.x)
            maxY = max(maxY, p.y)
        }
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    static func vignette(_ c: inout GraphicsContext, _ size: CGSize, _ alpha: Double) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        c.fill(Path(CGRect(origin: .zero, size: size)), with: radial(center, min(size.width, size.height) * 0.32, max(size.width, size.height) * 0.78, [
            (0, Color.black.opacity(0)), (1, Color.black.opacity(alpha)),
        ]))
    }
}

enum Plane { case xy, xz, yz }

/// Isometric projection: world x runs to the lower right, y to the lower left, z up.
struct Iso {
    var origin: CGPoint
    var s: CGFloat

    func p(_ x: Double, _ y: Double, _ z: Double = 0) -> CGPoint {
        CGPoint(x: origin.x + CGFloat(x - y) * s * 0.866, y: origin.y + CGFloat(x + y) * s * 0.5 - CGFloat(z) * s)
    }

    func floor(_ x: Double, _ y: Double, _ w: Double, _ d: Double, z: Double = 0) -> [CGPoint] {
        [p(x, y, z), p(x + w, y, z), p(x + w, y + d, z), p(x, y + d, z)]
    }

    /// Rectangle on the back-right wall (the plane y = 0).
    func wallR(_ x: Double, _ z: Double, _ w: Double, _ h: Double, y: Double = 0) -> [CGPoint] {
        [p(x, y, z), p(x + w, y, z), p(x + w, y, z + h), p(x, y, z + h)]
    }

    /// Rectangle on the back-left wall (the plane x = 0).
    func wallL(_ y: Double, _ z: Double, _ d: Double, _ h: Double, x: Double = 0) -> [CGPoint] {
        [p(x, y, z), p(x, y + d, z), p(x, y + d, z + h), p(x, y, z + h)]
    }

    /// A rectangle on a front-facing plane y = fy (the face that looks toward the lower left).
    func faceY(_ x0: Double, _ x1: Double, _ fy: Double, _ z0: Double, _ z1: Double) -> [CGPoint] {
        [p(x0, fy, z0), p(x1, fy, z0), p(x1, fy, z1), p(x0, fy, z1)]
    }

    func circle(_ cx: Double, _ cy: Double, _ cz: Double, _ r: Double, _ plane: Plane, n: Int = 16) -> [CGPoint] {
        (0..<n).map { i -> CGPoint in
            let a = Double(i) / Double(n) * 2 * Double.pi
            let u = cos(a) * r
            let v = sin(a) * r
            switch plane {
            case .xy: return p(cx + u, cy + v, cz)
            case .xz: return p(cx + u, cy, cz + v)
            case .yz: return p(cx, cy + u, cz + v)
            }
        }
    }

    /// Fits a w x d room with walls h high into the canvas, below `top` (space kept for the HUD).
    static func fit(_ size: CGSize, top: CGFloat = 0, w: Double, d: Double, h: Double, below: Double = 0, zoom: Double = 1) -> Iso {
        let height = max(1, size.height - top)
        let byWidth = size.width / CGFloat((w + d) * 0.866 * 1.08)
        let byHeight = height / CGFloat((w + d) * 0.5 + h + below + 0.6)
        let s = CGFloat(zoom) * min(byWidth, byHeight)
        let ox = size.width / 2 - CGFloat(w - d) / 2 * s * 0.866
        let total = CGFloat((w + d) * 0.5 + h + below) * s
        return Iso(origin: CGPoint(x: ox, y: top + (height - total) / 2 + CGFloat(h) * s + s * 0.15), s: s)
    }

    /// Gradient that follows height on a vertical plane. Stops go bottom → top.
    func zGrad(_ plane: Plane, _ x: Double, _ y: Double, _ z0: Double, _ z1: Double, _ stops: [(Double, Color)]) -> GraphicsContext.Shading {
        let a = p(x, y, z0)
        let dist = CGFloat(z1 - z0) * s * 0.866
        let nx: CGFloat = plane == .xz ? 0.5 : -0.5
        let end = CGPoint(x: a.x + nx * dist, y: a.y - 0.866 * dist)
        return G.linear(a, end, stops)
    }

    /// Shaded, outlined box. `base` is the color of the lit side.
    func box(_ c: inout GraphicsContext, _ x: Double, _ y: Double, _ w: Double, _ d: Double, _ h: Double, _ base: RGB,
             z0: Double = 0, tf: Double = 1.16, lf: Double = 0.96, rf: Double = 0.72, outline: Bool = true) {
        let z1 = z0 + h
        let lw = max(1.1, s * 0.034)
        let left = faceY(x, x + w, y + d, z0, z1)
        let right = [p(x + w, y, z0), p(x + w, y + d, z0), p(x + w, y + d, z1), p(x + w, y, z1)]
        G.fill(&c, left, shading: zGrad(.xz, x, y + d, z0, z1, [(0, (base * (lf * 0.82)).color), (1, (base * lf).color)]))
        G.fill(&c, right, shading: zGrad(.yz, x + w, y, z0, z1, [(0, (base * (rf * 0.82)).color), (1, (base * rf).color)]))
        G.fill(&c, floor(x, y, w, d, z: z1), (base * tf).color)
        if outline {
            G.stroke(&c, [p(x, y + d, z1), p(x + w, y + d, z1), p(x + w, y, z1)], Color.white.opacity(0.22), lw, closed: false)
            G.line(&c, p(x + w, y + d, z0), p(x + w, y + d, z1), Color.white.opacity(0.10), lw)
            let silhouette = [p(x, y, z1), p(x + w, y, z1), p(x + w, y, z0), p(x + w, y + d, z0), p(x, y + d, z0), p(x, y + d, z1)]
            G.stroke(&c, silhouette, Props.outline, lw)
        }
    }

    func shadow(_ c: inout GraphicsContext, _ x: Double, _ y: Double, _ w: Double, _ d: Double, _ alpha: Double = 0.3) {
        G.fill(&c, floor(x - 0.05, y - 0.05, w + 0.3, d + 0.3, z: 0.001), Color.black.opacity(alpha * 0.4))
        G.fill(&c, floor(x, y, w + 0.12, d + 0.12, z: 0.002), Color.black.opacity(alpha))
    }
}

/// Collects things to draw and paints them back to front.
struct DrawList {
    private var items: [(Double, (inout GraphicsContext) -> Void)] = []

    mutating func add(_ depth: Double, _ draw: @escaping (inout GraphicsContext) -> Void) {
        items.append((depth, draw))
    }

    mutating func append(_ other: DrawList) {
        items.append(contentsOf: other.items)
    }

    func draw(_ c: inout GraphicsContext) {
        for item in items.sorted(by: { $0.0 < $1.0 }) { item.1(&c) }
    }
}

/// Things standing on the ground: those behind the building are drawn before its walls.
struct PropLists {
    var back = DrawList()
    var front = DrawList()

    mutating func put(_ x: Double, _ y: Double, _ draw: @escaping (inout GraphicsContext) -> Void) {
        if x < 0 || y < 0 { back.add(x + y, draw) } else { front.add(x + y, draw) }
    }
}

// MARK: - Props

enum Props {
    static let outline = Color(red: 0.165, green: 0.094, blue: 0.055).opacity(0.72)

    struct Look {
        var shirt: RGB
        var seated = false
        var headphones = false
        var hardhat = false
        var back = false
        var pants = RGB(0.22, 0.26, 0.40)
        var hair = RGB(0.23, 0.15, 0.09)
    }

    struct RoomLook {
        let floor: RGB, wallR: RGB, wallL: RGB, cap: RGB, slab: RGB, base: RGB
    }

    static let rackBody = [RGB(0.32, 0.34, 0.40), RGB(0.17, 0.20, 0.19), RGB(0.11, 0.12, 0.16)]
    static let rackLED = [RGB(0.35, 1, 0.6), RGB(0.45, 1, 0.4), RGB(0.35, 0.72, 1)]
    static let hot = RGB(1, 0.35, 0.2)

    /// The sky behind the rooms. It follows Earth Health: blue with birds, grey smog, orange dust.
    static func sky(_ c: inout GraphicsContext, _ size: CGSize, health h: Double, t: Double, horizon hz: Double) {
        let W = Double(size.width)
        let H = Double(size.height)
        c.fill(Path(CGRect(origin: .zero, size: size)), with: G.linear(.zero, CGPoint(x: 0, y: H), [
            (0, Palette.c(Palette.skyTop, h)), (1, Palette.c(Palette.skyBottom, h)),
        ]))
        // Sun with a soft glow; it turns pale in smog and blood-red in ash.
        let sun = Palette.rgb(Palette.sun, h)
        let sp = CGPoint(x: W * 0.84, y: H * 0.3)
        let sr = H * (0.05 + 0.03 * (1 - h / 100))
        G.ellipse(&c, sp, sr * 4, sr * 4, shading: G.radial(sp, 0, sr * 4, [(0, sun.col(0.5)), (1, sun.col(0))]))
        G.ellipse(&c, sp, sr, sr, sun.col(0.95))
        // Distant hills, then factories and smoke as the planet gets sicker.
        let land = Palette.rgb(Palette.land, h)
        let hillsFar = Palette.rgb(Palette.skyBottom, h)
        var far = Path()
        far.move(to: CGPoint(x: 0, y: hz + 2))
        for i in 0...24 {
            let x = W * Double(i) / 24
            far.addLine(to: CGPoint(x: x, y: hz - H * 0.035 - sin(Double(i) * 0.9) * H * 0.025 - G.rnd(i, 81) * H * 0.02))
        }
        far.addLine(to: CGPoint(x: W, y: hz + 2))
        far.closeSubpath()
        c.fill(far, with: .color(RGB.mix(hillsFar, land, 0.3).color))
        if h < 85 {
            let stacks = min(8, Int((85 - h) / 10) + 1)
            let smoke = Palette.rgb(Palette.smoke, h)
            for k in 0..<stacks {
                let fx = W * (0.06 + 0.88 * G.rnd(k, 82))
                let fh = H * (0.05 + 0.04 * G.rnd(k, 83))
                let fw = max(2, W * 0.012)
                let baseY = hz - H * 0.02
                c.fill(Path(CGRect(x: fx, y: baseY - fh, width: fw, height: fh + 4)), with: .color((land * 0.45).col(0.95)))
                for j in 0..<5 {
                    let p = (t * 0.08 + Double(j) / 5 + G.rnd(k, 84)).truncatingRemainder(dividingBy: 1)
                    let r = fw * (1 + p * 4)
                    let at = CGPoint(x: fx + fw / 2 + p * W * 0.05, y: baseY - fh - p * H * 0.18)
                    G.ellipse(&c, at, r, r, smoke.col(0.45 * (1 - p)))
                }
            }
        }
        // Puffy clouds drifting by
        let cloud = Palette.rgb(Palette.cloud, h)
        for k in 0..<5 {
            let span = W + 160
            let x = (G.rnd(k, 85) * span + t * (4 + 4 * G.rnd(k, 86))).truncatingRemainder(dividingBy: span) - 80
            let y = H * (0.12 + 0.4 * G.rnd(k, 87))
            let w = W * (0.12 + 0.1 * G.rnd(k, 88))
            let a = 0.55 + 0.3 * h / 100
            G.ellipse(&c, CGPoint(x: x, y: y), w * 0.5, w * 0.17, cloud.col(a))
            G.ellipse(&c, CGPoint(x: x - w * 0.18, y: y - w * 0.06), w * 0.24, w * 0.15, cloud.col(a))
            G.ellipse(&c, CGPoint(x: x + w * 0.12, y: y - w * 0.11), w * 0.3, w * 0.2, cloud.col(a))
        }
        // Birds while the air is still clean
        if h > 70 {
            var birds = Path()
            for k in 0..<4 {
                let bx = (G.rnd(k, 89) * W + t * (14 + 6 * G.rnd(k, 90))).truncatingRemainder(dividingBy: W + 40) - 20
                let by = H * (0.18 + 0.25 * G.rnd(k, 91)) + sin(t * 1.3 + Double(k)) * 4
                let flap = 2.5 + 1.5 * sin(t * 9 + Double(k) * 2)
                birds.move(to: CGPoint(x: bx - 5, y: by - flap))
                birds.addQuadCurve(to: CGPoint(x: bx, y: by), control: CGPoint(x: bx - 2.5, y: by - flap))
                birds.addQuadCurve(to: CGPoint(x: bx + 5, y: by - flap), control: CGPoint(x: bx + 2.5, y: by - flap))
            }
            c.stroke(birds, with: .color(Color(red: 0.1, green: 0.14, blue: 0.22).opacity(0.75)), style: StrokeStyle(lineWidth: 1.4, lineCap: .round, lineJoin: .round))
        }
        // Low haze in smog and dust storms in ash
        if h < 66 {
            let haze = Palette.rgb(Palette.smoke, h)
            c.fill(Path(CGRect(origin: .zero, size: size)), with: G.linear(CGPoint(x: 0, y: H * 0.4), CGPoint(x: 0, y: H), [
                (0, haze.col(0)), (1, haze.col(0.35 * (66 - h) / 66)),
            ]))
        }
    }

    enum GroundKind { case lawn, yard, lot, open }

    static let lawnT: Palette.Triple = (RGB(0.40, 0.70, 0.29), RGB(0.50, 0.51, 0.42), RGB(0.64, 0.46, 0.28))

    /// Where the ground meets the sky, just above the back corner of the building.
    static func horizon(_ size: CGSize, _ iso: Iso) -> Double {
        max(Double(size.height) * 0.18, Double(iso.p(0, 0, 0).y) - Double(iso.s) * 1.2)
    }

    /// Ground that fills everything below the horizon, around a building of w x d.
    static func ground(_ c: inout GraphicsContext, _ size: CGSize, _ iso: Iso, horizon hy: Double, health h: Double, kind: GroundKind, w RW: Double, d RD: Double) {
        let W = Double(size.width), H = Double(size.height)
        let g0 = Palette.rgb(lawnT, h)
        let below = CGRect(x: 0, y: hy, width: W, height: max(0, H - hy))
        var g = c
        g.clip(to: Path(below))
        g.fill(Path(below), with: G.linear(CGPoint(x: 0, y: hy), CGPoint(x: 0, y: H), [(0, (g0 * 1.04).color), (1, (g0 * 0.82).color)]))
        for k in 0..<70 {
            let x = -12 + G.rnd(k, 101) * (RW + 26)
            let y = -12 + G.rnd(k, 102) * (RD + 26)
            G.fill(&g, iso.circle(x, y, 0, 0.5 + G.rnd(k, 103) * 1.2, .xy, n: 12), (g0 * (G.rnd(k, 104) > 0.5 ? 1.12 : 0.88)).col(0.45))
        }
        var tufts = Path()
        for k in 0..<260 {
            let x = -12 + G.rnd(k, 105) * (RW + 26)
            let y = -12 + G.rnd(k, 106) * (RD + 26)
            tufts.move(to: iso.p(x, y, 0))
            tufts.addLine(to: iso.p(x + 0.04, y, 0.16))
        }
        g.stroke(tufts, with: .color((g0 * 0.7).col(0.8)), lineWidth: 1)
        if h < 35 {
            // Cracked, dry earth
            var cracks = Path()
            for k in 0..<40 {
                var x = -8 + G.rnd(k, 107) * (RW + 18)
                var y = -8 + G.rnd(k, 108) * (RD + 18)
                cracks.move(to: iso.p(x, y))
                for j in 0..<4 {
                    x += (G.rnd(k * 5 + j, 109) - 0.3) * 1.2
                    y += (G.rnd(k * 5 + j, 110) - 0.5) * 1.2
                    cracks.addLine(to: iso.p(x, y))
                }
            }
            g.stroke(cracks, with: .color(Color(red: 0.24, green: 0.12, blue: 0.06).opacity(0.5 * (35 - h) / 35)), lineWidth: 1.2)
        }
        if kind == .yard || kind == .lot {
            let pad = kind == .lot ? 2.2 : 1.4
            let apron = kind == .lot ? Color(red: 0.62, green: 0.64, blue: 0.67) : Color(red: 0.56, green: 0.57, blue: 0.6)
            G.fill(&g, iso.floor(-pad, -pad, RW + pad * 2, RD + pad * 2, z: 0.001), apron)
            for k in 1..<6 {
                let x = -pad + Double(k) * (RW + pad * 2) / 6
                G.line(&g, iso.p(x, -pad, 0.002), iso.p(x, RD + pad, 0.002), Color.black.opacity(0.1), 1)
            }
        }
        if kind == .yard {
            G.fill(&g, iso.floor(-14, RD + 1.6, RW + 30, 1.6, z: 0.002), Color(red: 0.24, green: 0.25, blue: 0.28))
            for k in 0..<14 {
                G.fill(&g, iso.floor(-12 + Double(k) * 2.4, RD + 2.35, 1.2, 0.1, z: 0.003), Color(red: 1, green: 0.88, blue: 0.43).opacity(0.85))
            }
        }
        if kind == .lawn {
            for k in 0..<7 {
                let stone = iso.circle(RW + 0.6 + Double(k) * 0.75, RD - 0.6 + Double(k) * 0.55, 0.002, 0.28, .xy, n: 10)
                G.fill(&g, stone, Color(red: 0.72, green: 0.7, blue: 0.66))
            }
        }
    }

    /// The far ground dissolves into the sky haze, so the scene has no hard edge.
    static func horizonFade(_ c: inout GraphicsContext, _ size: CGSize, horizon hy: Double, health h: Double) {
        let H = Double(size.height)
        let haze = Palette.rgb(Palette.skyBottom, h)
        c.fill(Path(CGRect(x: 0, y: hy - 1, width: Double(size.width), height: H * 0.2 + 1)), with: G.linear(CGPoint(x: 0, y: hy - 1), CGPoint(x: 0, y: hy + H * 0.2), [
            (0, haze.color), (1, haze.col(0)),
        ]))
    }

    /// Trees, bushes, fences and vehicles around a building.
    static func groundProps(_ iso: Iso, health h: Double, t: Double, kind: GroundKind, w RW: Double, d RD: Double) -> PropLists {
        var lists = PropLists()
        let treeSpots: [(Double, Double)] = kind == .lot
            ? [(-3, 2), (RW + 2.5, -2.5), (-2.5, RD - 1)]
            : [(-2.8, 1.5), (-3.6, 4.2), (2.5, -2.8), (RW + 2.2, -1.8), (RW + 3.4, 2.2), (-2.2, RD + 1.8), (RW + 1.8, RD + 2.6)]
        for (k, spot) in treeSpots.enumerated() {
            let scale = 0.9 + G.rnd(k, 121) * 0.5
            lists.put(spot.0, spot.1) { g in Props.healthTree(&g, iso, x: spot.0, y: spot.1, scale: scale, health: h, seed: k) }
        }
        if h > 55 {
            let leaf = Palette.rgb(Palette.landDetail, h)
            for k in 0..<8 {
                let x: Double
                let y: Double
                if kind == .lawn {
                    x = k % 2 == 1 ? -1 - G.rnd(k, 122) * 1.5 : G.rnd(k, 123) * RW
                    y = k % 2 == 1 ? G.rnd(k, 124) * RD : -1 - G.rnd(k, 125) * 1.2
                } else {
                    x = -1.2 - G.rnd(k, 122)
                    y = G.rnd(k, 124) * RD
                }
                let flowers = h > 75 && k % 3 == 0
                lists.put(x, y) { g in
                    let p = iso.p(x, y, 0.18)
                    let r = iso.s * 0.26
                    G.ellipse(&g, p, r * 1.2, r * 0.8, leaf.color)
                    G.ellipse(&g, CGPoint(x: p.x - r * 0.3, y: p.y - r * 0.3), r * 0.6, r * 0.45, (leaf * 1.3).color)
                    if flowers {
                        G.ellipse(&g, CGPoint(x: p.x + r * 0.4, y: p.y - r * 0.2), 2, 2, Color(red: 1, green: 0.44, blue: 0.66))
                        G.ellipse(&g, CGPoint(x: p.x - r * 0.5, y: p.y), 2, 2, Color(red: 1, green: 0.88, blue: 0.4))
                    }
                }
            }
        }
        switch kind {
        case .lawn:
            // Picket fence behind the house
            lists.put(-0.6, -1.2) { g in
                for k in 0...16 {
                    iso.box(&g, -0.6 + Double(k) * 0.45, -1.3, 0.08, 0.06, 0.5, RGB(0.95, 0.94, 0.9), outline: false)
                }
                G.line(&g, iso.p(-0.6, -1.27, 0.35), iso.p(RW + 0.6, -1.27, 0.35), Color(red: 0.94, green: 0.94, blue: 0.91), max(1, iso.s * 0.05))
            }
        case .yard:
            // Delivery truck by the loading door
            lists.put(-2.6, 6.4) { g in
                iso.box(&g, -2.9, 6.2, 2.0, 1.0, 1.0, RGB(0.92, 0.92, 0.95), z0: 0.15)
                iso.box(&g, -0.8, 6.35, 0.7, 0.75, 0.75, RGB(0.95, 0.35, 0.3), z0: 0.15)
                G.fill(&g, iso.wallL(6.5, 0.6, 0.48, 0.25, x: -0.05), Color(red: 0.16, green: 0.24, blue: 0.35).opacity(0.85))
                for wx in [-2.5, -1.4, -0.4] {
                    G.ellipse(&g, iso.p(wx, 7.25, 0.12), iso.s * 0.16, iso.s * 0.16, Color(red: 0.1, green: 0.11, blue: 0.13))
                }
            }
        case .lot:
            // Outdoor cooling units and a chain-link fence
            for k in 0..<4 {
                let x = RW + 0.6
                let y = 0.6 + Double(k) * 2.2
                lists.put(x, y) { g in
                    iso.box(&g, x, y, 1.1, 1.5, 0.6, RGB(0.74, 0.77, 0.8))
                    G.fill(&g, iso.circle(x + 0.55, y + 0.4, 0.601, 0.3, .xy, n: 14), Color(red: 0.15, green: 0.16, blue: 0.18))
                    G.fill(&g, iso.circle(x + 0.55, y + 1.1, 0.601, 0.3, .xy, n: 14), Color(red: 0.15, green: 0.16, blue: 0.18))
                    let a = t * 8 + Double(k)
                    G.line(&g, iso.p(x + 0.55 + cos(a) * 0.26, y + 0.4 + sin(a) * 0.26, 0.602), iso.p(x + 0.55 - cos(a) * 0.26, y + 0.4 - sin(a) * 0.26, 0.602), Color(red: 0.78, green: 0.82, blue: 0.86), 1)
                }
            }
            lists.put(RW + 2.4, RD + 2.4) { g in
                let fz = 0.8
                let wire = Color(red: 0.35, green: 0.37, blue: 0.41).opacity(0.9)
                let corners: [(Double, Double)] = [(-2.2, RD + 2.2), (RW + 2.2, RD + 2.2), (RW + 2.2, -2.2)]
                for k in 0..<(corners.count - 1) {
                    let (ax, ay) = corners[k]
                    let (bx, by) = corners[k + 1]
                    let n = max(1, Int((hypot(bx - ax, by - ay) / 1.2).rounded()))
                    for j in 0...n {
                        let x = ax + (bx - ax) * Double(j) / Double(n)
                        let y = ay + (by - ay) * Double(j) / Double(n)
                        G.line(&g, iso.p(x, y, 0), iso.p(x, y, fz), wire, 1.2)
                    }
                    G.line(&g, iso.p(ax, ay, fz), iso.p(bx, by, fz), wire, 1.2)
                    G.fill(&g, [iso.p(ax, ay, 0), iso.p(bx, by, 0), iso.p(bx, by, fz), iso.p(ax, ay, fz)], Color(red: 0.59, green: 0.63, blue: 0.67).opacity(0.12))
                }
            }
        case .open:
            break
        }
        return lists
    }

    /// A tree whose leaves thin out with the planet; below ~25% Health it is dead and bare.
    static func healthTree(_ c: inout GraphicsContext, _ iso: Iso, x: Double, y: Double, scale k: Double, health h: Double, seed: Int) {
        let base = iso.p(x, y, 0)
        G.ellipse(&c, CGPoint(x: base.x + iso.s * 0.15, y: base.y + iso.s * 0.08), iso.s * 0.5 * k, iso.s * 0.25 * k, Color.black.opacity(0.22))
        iso.box(&c, x - 0.07, y - 0.07, 0.14, 0.14, 0.6 * k, RGB(0.45, 0.3, 0.2), outline: false)
        if h < 22 + G.rnd(seed, 131) * 10 {
            let top = iso.p(x, y, 0.6 * k)
            var branches = Path()
            for b in 0..<4 {
                let a = -Double.pi / 2 + (Double(b) - 1.5) * 0.5
                let length = Double(iso.s) * (0.35 + 0.15 * G.rnd(seed + b, 132)) * k
                branches.move(to: top)
                branches.addLine(to: CGPoint(x: Double(top.x) + cos(a) * length, y: Double(top.y) + sin(a) * length))
            }
            c.stroke(branches, with: .color(Color(red: 0.29, green: 0.19, blue: 0.13)), style: StrokeStyle(lineWidth: max(1.2, iso.s * 0.05), lineCap: .round))
            return
        }
        let col = Palette.rgb(Palette.landDetail, h)
        let cp = iso.p(x, y, 0.95 * k)
        let r = iso.s * 0.55 * CGFloat(k) * CGFloat(0.6 + 0.4 * min(1, h / 70))
        G.ellipse(&c, cp, r, r * 0.95, (col * 0.8).color)
        G.ellipse(&c, CGPoint(x: cp.x - r * 0.2, y: cp.y - r * 0.25), r * 0.8, r * 0.72, col.color)
        G.ellipse(&c, CGPoint(x: cp.x - r * 0.35, y: cp.y - r * 0.45), r * 0.35, r * 0.3, (col * 1.35).col(0.8))
        c.stroke(Path(ellipseIn: G.ellipseRect(cp, r * 0.98, r * 0.98)), with: .color(outline.opacity(0.6)), lineWidth: 1.2)
    }

    /// A cutaway room standing on the ground: two back walls with thickness, caps, baseboards and a low curb.
    static func roomShell(_ c: inout GraphicsContext, _ iso: Iso, _ W: Double, _ D: Double, _ H: Double, _ o: RoomLook) {
        let T = 0.2
        let lw = max(1, iso.s * 0.03)
        for k in stride(from: 3, through: 1, by: -1) {
            let grow = Double(k)
            G.fill(&c, iso.floor(-T - 0.1 * grow, -T - 0.1 * grow, W + T + 0.25 * grow, D + T + 0.25 * grow, z: 0.001), Color.black.opacity(0.07))
        }
        iso.box(&c, -T, D, W + T + 0.12, 0.12, 0.1, o.slab, z0: -0.02, tf: 1.05)
        iso.box(&c, W, -T, 0.12, D + T, 0.1, o.slab, z0: -0.02, tf: 1.05)
        G.fill(&c, iso.floor(0, 0, W, D), o.floor.color)
        G.fill(&c, iso.wallR(0, 0, W, H), shading: iso.zGrad(.xz, 0, 0, 0, H, [(0, (o.wallR * 0.84).color), (1, (o.wallR * 1.04).color)]))
        G.fill(&c, iso.wallL(0, 0, D, H), shading: iso.zGrad(.yz, 0, 0, 0, H, [(0, (o.wallL * 0.82).color), (1, (o.wallL * 1.02).color)]))
        G.fill(&c, iso.wallR(0, 0, W, 0.14), o.base.color)
        G.fill(&c, iso.wallL(0, 0, D, 0.14), (o.base * 0.88).color)
        G.line(&c, iso.p(0, 0, 0.14), iso.p(W, 0, 0.14), Color.white.opacity(0.25), 1)
        G.line(&c, iso.p(0, 0, 0.14), iso.p(0, D, 0.14), Color.white.opacity(0.18), 1)
        for k in 1...3 {
            let band = 0.1 * Double(k)
            G.fill(&c, iso.floor(0, 0, W, band, z: 0.001), Color.black.opacity(0.06))
            G.fill(&c, iso.floor(0, 0, band, D, z: 0.001), Color.black.opacity(0.06))
        }
        G.line(&c, iso.p(0, 0, 0), iso.p(0, 0, H), Color.black.opacity(0.28), lw * 1.4)
        let capR = iso.floor(-T, -T, W + T, T, z: H)
        let capL = iso.floor(-T, 0, T, D, z: H)
        let endR = [iso.p(W, -T, 0), iso.p(W, 0, 0), iso.p(W, 0, H), iso.p(W, -T, H)]
        let endL = [iso.p(-T, D, 0), iso.p(0, D, 0), iso.p(0, D, H), iso.p(-T, D, H)]
        G.fill(&c, capR, o.cap.color)
        G.fill(&c, capL, o.cap.color)
        G.fill(&c, endR, (o.cap * 0.72).color)
        G.fill(&c, endL, (o.cap * 0.86).color)
        for q in [capR, capL, endR, endL] { G.stroke(&c, q, outline, lw) }
    }

    /// A window in a back wall showing the planet outside (colors follow Earth Health).
    static func window(_ c: inout GraphicsContext, _ iso: Iso, rightWall: Bool, _ a: Double, _ z: Double, _ len: Double, _ hgt: Double, health: Double, t: Double) {
        let q = rightWall ? iso.wallR(a, z, len, hgt) : iso.wallL(a, z, len, hgt)
        let bb = G.bbox(q)
        let bx = Double(bb.minX), by = Double(bb.minY), bw = Double(bb.width), bh = Double(bb.height)
        var g = c
        g.clip(to: G.path(q))
        g.fill(Path(bb), with: G.linear(CGPoint(x: 0, y: bb.minY), CGPoint(x: 0, y: bb.maxY), [
            (0, Palette.c(Palette.skyTop, health)), (1, Palette.c(Palette.skyBottom, health)),
        ]))
        let sun = Palette.rgb(Palette.sun, health)
        let sp = CGPoint(x: bx + bw * 0.72, y: by + bh * 0.3)
        let sr = max(2.5, bh * 0.12)
        G.ellipse(&g, sp, sr * 2.8, sr * 2.8, shading: G.radial(sp, 0, sr * 2.8, [(0, sun.col(0.55)), (1, sun.col(0))]))
        G.ellipse(&g, sp, sr, sr, sun.col(0.95))
        let cloud = Palette.rgb(Palette.cloud, health)
        for k in 0..<3 {
            let span = bw + 60
            let drift = (G.rnd(k, 3) * span + t * Double(5 + k * 2)).truncatingRemainder(dividingBy: span)
            let cx = bx + drift - 30
            let cy = by + bh * (0.2 + 0.17 * Double(k))
            let w = bw * 0.24
            G.ellipse(&g, CGPoint(x: cx, y: cy), w * 0.5, w * 0.16, cloud.col(0.85))
            G.ellipse(&g, CGPoint(x: cx + w * 0.22, y: cy - w * 0.08), w * 0.28, w * 0.15, cloud.col(0.85))
        }
        let land = Palette.rgb(Palette.land, health)
        G.ellipse(&g, CGPoint(x: bx + bw * 0.2, y: by + bh * 1.02), bw * 0.55, bh * 0.3, (land * 0.78).color)
        G.ellipse(&g, CGPoint(x: bx + bw * 0.85, y: by + bh * 1.06), bw * 0.6, bh * 0.3, land.color)
        if health < 85 {
            // Smokestacks appear on the horizon as the planet gets sicker.
            let n = min(5, Int((85 - health) / 14) + 1)
            let smoke = Palette.rgb(Palette.smoke, health)
            for k in 0..<n {
                let fx = bx + bw * (0.12 + 0.76 * G.rnd(k, 9))
                let fh = bh * (0.22 + 0.16 * G.rnd(k, 10))
                let fw = max(1.5, bw * 0.035)
                g.fill(Path(CGRect(x: fx, y: by + bh - fh, width: fw, height: fh)), with: .color(Color(red: 0.1, green: 0.1, blue: 0.12).opacity(0.9)))
                for j in 0..<4 {
                    let pp = (t * 0.15 + Double(j) / 4 + G.rnd(k, 11)).truncatingRemainder(dividingBy: 1)
                    let r = fw * (0.8 + pp * 2.4)
                    let at = CGPoint(x: fx + fw / 2 + pp * bw * 0.12, y: by + bh - fh - pp * bh * 0.5)
                    G.ellipse(&g, at, r, r, smoke.col(0.5 * (1 - pp)))
                }
            }
        }
        g.fill(Path(bb), with: G.linear(CGPoint(x: bb.minX, y: bb.minY), CGPoint(x: bb.maxX, y: bb.maxY), [
            (0, Color.white.opacity(0.22)), (0.4, Color.white.opacity(0)), (0.55, Color.white.opacity(0.08)), (0.62, Color.white.opacity(0)),
        ]))
        let lw = max(1.5, iso.s * 0.075)
        let frame = Color(red: 0.96, green: 0.97, blue: 1).opacity(0.95)
        G.stroke(&c, q, frame, lw)
        if rightWall {
            G.line(&c, iso.p(a + len / 2, 0, z), iso.p(a + len / 2, 0, z + hgt), frame, lw * 0.55)
            G.line(&c, iso.p(a, 0, z + hgt * 0.55), iso.p(a + len, 0, z + hgt * 0.55), frame, lw * 0.55)
        } else {
            G.line(&c, iso.p(0, a + len / 2, z), iso.p(0, a + len / 2, z + hgt), frame, lw * 0.55)
            G.line(&c, iso.p(0, a, z + hgt * 0.55), iso.p(0, a + len, z + hgt * 0.55), frame, lw * 0.55)
        }
    }

    static func led(_ c: inout GraphicsContext, _ at: CGPoint, _ r: CGFloat, _ color: RGB, _ on: Double, halo: Bool = true) {
        if halo { G.ellipse(&c, at, r * 2.6, r * 2.6, color.col(0.18 * on)) }
        G.ellipse(&c, at, r, r, color.col(0.25 + 0.75 * on))
    }

    /// A server rack. style 0 = home server, 1 = GPU cluster, 2 = data hall rack.
    static func rack(_ c: inout GraphicsContext, _ iso: Iso, x: Double, y: Double, w: Double, d: Double, h: Double,
                     style: Int, t: Double, seed: Int, overclock: Bool) {
        let body = rackBody[style]
        let ledColor = overclock ? hot : rackLED[style]
        let fy = y + d + 0.002
        let r = max(0.7, iso.s * 0.026)
        iso.shadow(&c, x, y, w, d, 0.28)
        iso.box(&c, x, y, w, d, h, body)
        if style == 1 {
            let accent = RGB(0.35, 0.95, 0.45)
            for f in 0..<2 {
                let cz = h * (0.3 + 0.4 * Double(f))
                let cx = x + w / 2
                let fr = min(w, h) * 0.22
                G.fill(&c, iso.circle(cx, fy, cz, fr, .xz, n: 18), Color(red: 0.02, green: 0.03, blue: 0.03).opacity(0.9))
                let spin = t * (overclock ? 30 : 9) + Double(f + seed)
                for k in 0..<4 {
                    let a = spin + Double(k) * Double.pi / 2
                    let blade = [iso.p(cx, fy, cz),
                                 iso.p(cx + cos(a) * fr * 0.9, fy, cz + sin(a) * fr * 0.9),
                                 iso.p(cx + cos(a + 0.7) * fr * 0.8, fy, cz + sin(a + 0.7) * fr * 0.8)]
                    G.fill(&c, blade, Color(red: 0.47, green: 0.55, blue: 0.53).opacity(0.7))
                }
                G.stroke(&c, iso.circle(cx, fy, cz, fr, .xz, n: 18), (overclock ? hot : accent).col(0.9), max(1, iso.s * 0.03))
            }
            G.fill(&c, iso.floor(x + 0.06, y + 0.22, w - 0.12, 0.08, z: h + 0.001), accent.col(0.9))
            for l in 0..<3 {
                let on = sin(t * 3 + Double(seed + l)) > 0 ? 1.0 : 0.2
                led(&c, iso.p(x + 0.12 + Double(l) * 0.08, fy, h - 0.1), r, ledColor, on)
            }
            return
        }
        let units = max(3, Int((h / 0.17).rounded()))
        let uh = (h - 0.16) / Double(units)
        let halo = style != 2
        for u in 0..<units {
            let z0 = 0.08 + Double(u) * uh
            let z1 = z0 + uh * 0.78
            G.fill(&c, iso.faceY(x + 0.05, x + w - 0.05, fy, z0, z1), (body * 0.5).color)
            if style == 0 {
                G.line(&c, iso.p(x + 0.08, fy, z1 - uh * 0.15), iso.p(x + w * 0.5, fy, z1 - uh * 0.15), Color.white.opacity(0.10), 1)
            }
            for l in 0..<2 {
                let speed = overclock ? 16 : 2 + G.rnd(seed * 7 + u, Double(l)) * 5
                let on = sin(t * speed + Double(seed * 3) + Double(u) * 1.7 + Double(l)) > 0.1
                let amber = l == 1 && G.rnd(seed + u, 4) > 0.8 && !overclock
                led(&c, iso.p(x + w - 0.12 - Double(l) * 0.09, fy, z0 + uh * 0.4), r, amber ? RGB(1, 0.72, 0.2) : ledColor, on ? 1 : 0.15, halo: halo)
            }
        }
        if style == 2 {
            let glass = iso.faceY(x + 0.02, x + w - 0.02, fy + 0.002, 0.04, h - 0.04)
            G.fill(&c, glass, shading: iso.zGrad(.xz, x, fy, 0, h, [(0, Color.white.opacity(0)), (0.65, Color.white.opacity(0.04)), (1, Color.white.opacity(0.15))]))
        }
        for v in 0..<3 {
            let vz = h * (0.3 + Double(v) * 0.18)
            G.line(&c, iso.p(x + w + 0.002, y + 0.1, vz), iso.p(x + w + 0.002, y + d - 0.1, vz), Color.black.opacity(0.35), 1)
        }
    }

    static func person(_ c: inout GraphicsContext, _ iso: Iso, x: Double, y: Double, t: Double, seed: Int, _ o: Look) {
        let s = iso.s
        let bob = sin(t * (o.seated ? 6 : 3) + Double(seed)) * 0.012
        var zb = 0.5
        if !o.seated {
            G.ellipse(&c, iso.p(x, y, 0), s * 0.3, s * 0.16, Color.black.opacity(0.25))
            let step = sin(t * 6 + Double(seed)) * 0.05
            iso.box(&c, x - 0.13, y - 0.06 + step, 0.11, 0.12, 0.45, o.pants, outline: false)
            iso.box(&c, x + 0.02, y - 0.06 - step, 0.11, 0.12, 0.45, o.pants, outline: false)
            zb = 0.45
        }
        iso.box(&c, x - 0.26, y - 0.06, 0.09, 0.13, 0.34, o.shirt * 0.85, z0: zb + 0.06 + bob, outline: false)
        iso.box(&c, x - 0.17, y - 0.11, 0.34, 0.22, 0.42, o.shirt, z0: zb + bob)
        iso.box(&c, x + 0.17, y - 0.06, 0.09, 0.13, 0.34, o.shirt * 0.85, z0: zb + 0.06 + bob, outline: false)
        let hz = zb + 0.44 + bob
        let skin = RGB(1.0, 0.82, 0.62)
        let ink = Color(red: 0.1, green: 0.1, blue: 0.13)
        iso.box(&c, x - 0.15, y - 0.15, 0.3, 0.3, 0.3, skin, z0: hz)
        if !o.back {
            // A simple face on the side that looks toward the camera
            let fy = y + 0.152
            G.fill(&c, iso.faceY(x - 0.08, x - 0.04, fy, hz + 0.15, hz + 0.2), ink)
            G.fill(&c, iso.faceY(x + 0.04, x + 0.08, fy, hz + 0.15, hz + 0.2), ink)
            G.stroke(&c, [iso.p(x - 0.06, fy, hz + 0.09), iso.p(x, fy, hz + 0.07), iso.p(x + 0.06, fy, hz + 0.09)], ink, 1, closed: false)
        }
        iso.box(&c, x - 0.16, y - 0.16, 0.32, 0.32, 0.08, o.hair, z0: hz + 0.3)
        if o.back {
            iso.box(&c, x - 0.16, y + 0.06, 0.32, 0.1, 0.22, o.hair, z0: hz + 0.1, outline: false)
        }
        if o.headphones {
            let hc = iso.p(x, y, hz + 0.18)
            let r = s * 0.2
            var band = Path()
            band.addArc(center: CGPoint(x: hc.x, y: hc.y - r * 0.4), radius: r * 1.15, startAngle: .radians(Double.pi * 1.08), endAngle: .radians(Double.pi * 1.92), clockwise: false)
            c.stroke(band, with: .color(Color(red: 0.11, green: 0.12, blue: 0.15)), lineWidth: max(1.5, r * 0.28))
            let cup = RGB(0.91, 0.29, 0.37)
            iso.box(&c, x - 0.2, y - 0.06, 0.05, 0.12, 0.14, cup, z0: hz + 0.08, outline: false)
            iso.box(&c, x + 0.15, y - 0.06, 0.05, 0.12, 0.14, cup, z0: hz + 0.08, outline: false)
        }
        if o.hardhat {
            iso.box(&c, x - 0.18, y - 0.18, 0.36, 0.36, 0.1, RGB(1, 0.79, 0.24), z0: hz + 0.32)
        }
    }

    static func desk(_ c: inout GraphicsContext, _ iso: Iso, x: Double, y: Double, w: Double, d: Double, t: Double, monitors: Int, overclock: Bool) {
        let top = RGB(0.74, 0.55, 0.37)
        let leg = RGB(0.26, 0.26, 0.30)
        iso.shadow(&c, x, y, w, d, 0.2)
        G.fill(&c, iso.floor(x + 0.05, y + 0.05, w - 0.1, d - 0.1, z: 0.002), Color.black.opacity(0.22))
        // Gaming PC with an RGB strip
        iso.box(&c, x + 0.25, y + 0.1, 0.3, 0.6, 0.62, RGB(0.13, 0.13, 0.17))
        let strip = RGB.hue(t * 0.12)
        G.fill(&c, iso.faceY(x + 0.29, x + 0.33, y + 0.701, 0.06, 0.56), strip.color)
        let gp = iso.p(x + 0.31, y + 0.75, 0.3)
        G.ellipse(&c, gp, iso.s * 0.4, iso.s * 0.4, shading: G.radial(gp, 0, iso.s * 0.4, [(0, strip.col(0.35)), (1, strip.col(0))]))
        iso.box(&c, x + 0.02, y + 0.04, 0.07, d - 0.08, 0.68, leg)
        iso.box(&c, x + w - 0.62, y + 0.04, 0.58, d - 0.08, 0.68, top * 0.9)
        for k in 1..<3 {
            let fy = y + d - 0.04 + 0.002
            let dz = Double(k) * 0.226
            G.line(&c, iso.p(x + w - 0.6, fy, dz), iso.p(x + w - 0.06, fy, dz), Color(red: 0.16, green: 0.1, blue: 0.06).opacity(0.5), 1)
            G.ellipse(&c, iso.p(x + w - 0.33, fy, dz - 0.1), iso.s * 0.06, iso.s * 0.025, Color(red: 0.23, green: 0.23, blue: 0.27))
        }
        iso.box(&c, x, y, w, d, 0.07, top, z0: 0.68)
        let slot = (w - 0.3) / Double(monitors)
        for m in 0..<monitors {
            let mw = min(0.9, slot - 0.06)
            let mx = x + 0.15 + Double(m) * slot + (slot - mw) / 2
            let fy = y + 0.251
            iso.box(&c, mx + mw / 2 - 0.16, y + 0.17, 0.32, 0.18, 0.02, leg, z0: 0.75, outline: false)
            iso.box(&c, mx + mw / 2 - 0.04, y + 0.2, 0.08, 0.05, 0.15, leg, z0: 0.77, outline: false)
            iso.box(&c, mx, y + 0.2, mw, 0.05, 0.56, RGB(0.09, 0.10, 0.13), z0: 0.86)
            G.fill(&c, iso.faceY(mx + 0.04, mx + mw - 0.04, fy, 0.9, 1.38), shading: iso.zGrad(.xz, mx, fy, 0.9, 1.38, [
                (0, Color(red: 0.04, green: 0.086, blue: 0.15)), (1, Color(red: 0.078, green: 0.19, blue: 0.31)),
            ]))
            let scroll = Int(t * 2)
            let codeColors = [RGB(0.4, 0.9, 1), RGB(1, 0.5, 0.75), RGB(1, 0.85, 0.4), RGB(0.5, 1, 0.7)]
            for k in 0..<7 {
                let idx = k + scroll + m * 13
                let lz = 1.32 - Double(k) * 0.062
                let indent = (G.rnd(idx, 5) > 0.6 ? 0.07 : 0) + (G.rnd(idx, 6) > 0.85 ? 0.07 : 0)
                let len = (0.12 + G.rnd(idx, 7) * 0.42) * (mw - 0.16) / 0.82
                let col = overclock ? hot : codeColors[Int(G.rnd(idx, 8) * 4) % 4]
                G.line(&c, iso.p(mx + 0.08 + indent, fy + 0.002, lz), iso.p(mx + 0.08 + indent + len, fy + 0.002, lz), col.col(0.9), max(1, iso.s * 0.034))
            }
            let gc = iso.p(mx + mw / 2, fy, 1.12)
            let glow = overclock ? RGB(1, 0.35, 0.24) : RGB(0.35, 0.78, 1)
            G.ellipse(&c, gc, iso.s * 1.4, iso.s * 1.1, shading: G.radial(gc, 0, iso.s * 1.4, [(0, glow.col(0.2)), (1, glow.col(0))]))
        }
        iso.box(&c, x + w / 2 - 0.36, y + 0.47, 0.62, 0.2, 0.025, RGB(0.2, 0.21, 0.26), z0: 0.75, outline: false)
        iso.box(&c, x + w / 2 + 0.36, y + 0.52, 0.09, 0.13, 0.03, RGB(0.2, 0.21, 0.26), z0: 0.75, outline: false)
        iso.box(&c, x + w - 0.42, y + 0.2, 0.12, 0.12, 0.14, RGB(0.95, 0.95, 0.97), z0: 0.75, outline: false)
        G.fill(&c, iso.floor(x + w - 0.41, y + 0.21, 0.1, 0.1, z: 0.891), Color(red: 0.35, green: 0.21, blue: 0.125))
    }

    static func chairSeat(_ c: inout GraphicsContext, _ iso: Iso, x: Double, y: Double, color: RGB) {
        iso.shadow(&c, x - 0.3, y - 0.3, 0.6, 0.6, 0.18)
        for k in 0..<5 {
            let a = Double(k) / 5 * 2 * Double.pi + 0.3
            G.line(&c, iso.p(x, y, 0.07), iso.p(x + cos(a) * 0.32, y + sin(a) * 0.32, 0.04), Color(red: 0.16, green: 0.18, blue: 0.21), max(1.5, iso.s * 0.06))
        }
        iso.box(&c, x - 0.04, y - 0.04, 0.08, 0.08, 0.36, RGB(0.3, 0.32, 0.38), z0: 0.04, outline: false)
        iso.box(&c, x - 0.28, y - 0.28, 0.56, 0.56, 0.1, color, z0: 0.4)
    }

    static func chairBack(_ c: inout GraphicsContext, _ iso: Iso, x: Double, y: Double, color: RGB, accent: RGB) {
        iso.box(&c, x - 0.28, y + 0.2, 0.56, 0.1, 0.6, color, z0: 0.48)
        G.fill(&c, iso.faceY(x - 0.07, x + 0.07, y + 0.302, 0.56, 1.02), accent.color)
    }

    static func bed(_ c: inout GraphicsContext, _ iso: Iso, x: Double, y: Double) {
        let wood = RGB(0.58, 0.40, 0.27)
        iso.shadow(&c, x, y, 1.5, 2.3, 0.22)
        iso.box(&c, x, y - 0.12, 1.5, 0.12, 0.95, wood)
        iso.box(&c, x, y, 1.5, 2.3, 0.3, wood)
        iso.box(&c, x + 0.05, y + 0.05, 1.4, 2.2, 0.17, RGB(0.94, 0.94, 0.98), z0: 0.3)
        iso.box(&c, x + 0.2, y + 0.15, 1.1, 0.48, 0.13, RGB(1, 1, 1), z0: 0.47)
        iso.box(&c, x + 0.02, y + 0.9, 1.46, 1.42, 0.07, RGB(0.36, 0.48, 0.9), z0: 0.42)
        iso.box(&c, x + 0.02, y + 0.9, 1.46, 0.22, 0.075, RGB(0.95, 0.95, 1), z0: 0.42)
    }

    static func fan(_ c: inout GraphicsContext, _ iso: Iso, x: Double, y: Double, t: Double, overclock: Bool) {
        G.ellipse(&c, iso.p(x, y, 0.02), iso.s * 0.32, iso.s * 0.18, Color(red: 0.17, green: 0.18, blue: 0.23))
        iso.box(&c, x - 0.03, y - 0.03, 0.06, 0.06, 0.66, RGB(0.78, 0.8, 0.85), z0: 0.02, outline: false)
        let cz = 0.95, R = 0.3, cy = y + 0.03
        G.fill(&c, iso.circle(x, cy, cz, R, .xz, n: 22), Color(red: 0.11, green: 0.125, blue: 0.17).opacity(0.8))
        let spin = t * (overclock ? 40 : 16)
        for k in 0..<3 {
            let a = spin + Double(k) * 2 * Double.pi / 3
            let blade = [iso.p(x, cy + 0.01, cz),
                         iso.p(x + cos(a) * R * 0.9, cy + 0.01, cz + sin(a) * R * 0.9),
                         iso.p(x + cos(a + 0.6) * R * 0.85, cy + 0.01, cz + sin(a + 0.6) * R * 0.85)]
            G.fill(&c, blade, Color(red: 0.78, green: 0.86, blue: 1).opacity(0.6))
        }
        G.stroke(&c, iso.circle(x, cy + 0.02, cz, R, .xz, n: 22), Color(red: 0.88, green: 0.9, blue: 0.94).opacity(0.95), max(1, iso.s * 0.045))
        G.stroke(&c, iso.circle(x, cy + 0.02, cz, R * 0.55, .xz, n: 16), Color(red: 0.88, green: 0.9, blue: 0.94).opacity(0.45), 1)
        G.ellipse(&c, iso.p(x, cy + 0.03, cz), iso.s * 0.05, iso.s * 0.05, Color(red: 0.91, green: 0.93, blue: 0.96))
    }

    static func plant(_ c: inout GraphicsContext, _ iso: Iso, x: Double, y: Double, z: Double, scale k: Double = 1) {
        iso.box(&c, x - 0.12 * k, y - 0.12 * k, 0.24 * k, 0.24 * k, 0.22 * k, RGB(0.85, 0.45, 0.32), z0: z)
        let cp = iso.p(x, y, z + 0.3 * k)
        let r = iso.s * 0.17 * CGFloat(k)
        let leaf = RGB(0.25, 0.65, 0.32)
        for i in 0..<5 {
            let a = Double(i) / 5 * 2 * Double.pi
            let at = CGPoint(x: cp.x + CGFloat(cos(a)) * r * 0.8, y: cp.y + CGFloat(sin(a)) * r * 0.45 - r * 0.2)
            G.ellipse(&c, at, r * 0.75, r * 0.5, (leaf * (0.8 + 0.2 * Double(i % 2))).color)
        }
        G.ellipse(&c, CGPoint(x: cp.x, y: cp.y - r * 0.6), r * 0.7, r * 0.55, (leaf * 1.15).color)
    }

    static func pallet(_ c: inout GraphicsContext, _ iso: Iso, x: Double, y: Double, boxes n: Int) {
        iso.shadow(&c, x, y, 1.1, 1.1, 0.25)
        iso.box(&c, x, y, 1.1, 1.1, 0.13, RGB(0.74, 0.57, 0.36))
        for k in 1..<5 {
            G.line(&c, iso.p(x, y + Double(k) * 0.22, 0.131), iso.p(x + 1.1, y + Double(k) * 0.22, 0.131), Color(red: 0.24, green: 0.16, blue: 0.08).opacity(0.35), 1)
        }
        for i in 0..<n {
            let bx = x + 0.05 + Double(i % 2) * 0.52
            let by = y + 0.05 + Double((i / 2) % 2) * 0.52
            let bz = 0.13 + Double(i / 4) * 0.44
            iso.box(&c, bx, by, 0.48, 0.48, 0.42, RGB(0.82, 0.64, 0.43), z0: bz)
            G.line(&c, iso.p(bx, by + 0.24, bz + 0.422), iso.p(bx + 0.48, by + 0.24, bz + 0.422), Color(red: 1, green: 0.94, blue: 0.84).opacity(0.7), max(1, iso.s * 0.05))
        }
    }

    static func dataHall(_ c: inout GraphicsContext, _ iso: Iso, x: Double, y: Double, t: Double, seed k: Int) {
        let w = 2.7, d = 1.9, h = 0.95
        iso.shadow(&c, x, y, w, d, 0.25)
        iso.box(&c, x, y, w, d, h, RGB(0.88, 0.9, 0.94))
        let fy = y + d + 0.002
        for i in 1..<9 {
            let fx = x + Double(i) * w / 9
            G.line(&c, iso.p(fx, fy, 0.05), iso.p(fx, fy, h - 0.1), Color.black.opacity(0.12), 1)
        }
        G.fill(&c, iso.faceY(x + 0.15, x + w - 0.15, fy, 0.5, 0.68), RGB(0.35, 0.85, 1).col(0.6 + 0.25 * sin(t * 1.5 + Double(k))))
        G.fill(&c, iso.faceY(x + 0.3, x + 0.62, fy, 0, 0.38), Color(red: 0.29, green: 0.32, blue: 0.4))
        G.fill(&c, iso.faceY(x, x + w, fy, h - 0.09, h - 0.03), RGB(0.24, 0.93, 0.7).color)
        for u in 0..<3 {
            let ux = x + 0.3 + Double(u) * 0.8
            let uy = y + 0.6
            iso.box(&c, ux, uy, 0.55, 0.55, 0.2, RGB(0.64, 0.67, 0.72), z0: h)
            let fz = h + 0.201
            G.fill(&c, iso.circle(ux + 0.275, uy + 0.275, fz, 0.2, .xy, n: 14), Color(red: 0.125, green: 0.137, blue: 0.17))
            let a = t * 9 + Double(u + k)
            let blade = Color(red: 0.78, green: 0.82, blue: 0.86)
            G.line(&c, iso.p(ux + 0.275 + cos(a) * 0.17, uy + 0.275 + sin(a) * 0.17, fz), iso.p(ux + 0.275 - cos(a) * 0.17, uy + 0.275 - sin(a) * 0.17, fz), blade, 1)
            G.line(&c, iso.p(ux + 0.275 - sin(a) * 0.17, uy + 0.275 + cos(a) * 0.17, fz), iso.p(ux + 0.275 + sin(a) * 0.17, uy + 0.275 - cos(a) * 0.17, fz), blade, 1)
        }
    }

    static func coolingTower(_ c: inout GraphicsContext, _ iso: Iso, x cx: Double, y cy: Double) {
        let TH = 1.7, rb = 0.66, rw = 0.44
        let zw = TH * 0.68
        let k = (rb - rw) / (zw * zw)
        func radius(_ z: Double) -> Double { rw + k * (z - zw) * (z - zw) }
        let sx = Double(iso.s) * 1.2247
        let sy = Double(iso.s) * 0.7071
        let b = iso.p(cx, cy, 0)
        G.ellipse(&c, CGPoint(x: b.x + iso.s * 0.15, y: b.y + iso.s * 0.08), rb * sx * 1.15, rb * sy * 1.15, Color.black.opacity(0.25))
        var left: [CGPoint] = []
        var right: [CGPoint] = []
        for i in 0...14 {
            let z = TH * Double(i) / 14
            let p = iso.p(cx, cy, z)
            left.append(CGPoint(x: Double(p.x) - radius(z) * sx, y: Double(p.y)))
            right.append(CGPoint(x: Double(p.x) + radius(z) * sx, y: Double(p.y)))
        }
        var arc: [CGPoint] = []
        for i in 0...12 {
            let a = Double(i) / 12 * Double.pi
            arc.append(CGPoint(x: Double(b.x) + cos(a) * rb * sx, y: Double(b.y) + sin(a) * rb * sy))
        }
        let base = RGB(0.82, 0.83, 0.84)
        let body = left + right.reversed() + arc
        G.fill(&c, body, shading: G.linear(CGPoint(x: Double(b.x) - rb * sx, y: 0), CGPoint(x: Double(b.x) + rb * sx, y: 0), [
            (0, (base * 1.12).color), (0.4, base.color), (1, (base * 0.62).color),
        ]))
        let stripeLow = iso.p(cx, cy, TH * 0.86)
        let r1 = radius(TH * 0.86) * sx
        let r2 = radius(TH * 0.92) * sx
        let stripe = [CGPoint(x: Double(stripeLow.x) - r1, y: Double(stripeLow.y)), CGPoint(x: Double(stripeLow.x) + r1, y: Double(stripeLow.y)),
                      CGPoint(x: Double(stripeLow.x) + r2, y: Double(stripeLow.y) - Double(iso.s) * 0.1), CGPoint(x: Double(stripeLow.x) - r2, y: Double(stripeLow.y) - Double(iso.s) * 0.1)]
        G.fill(&c, stripe, Color(red: 0.86, green: 0.27, blue: 0.24).opacity(0.75))
        G.stroke(&c, body, outline, max(1, iso.s * 0.034))
        let tp = iso.p(cx, cy, TH)
        let rt = radius(TH)
        G.ellipse(&c, tp, rt * sx, rt * sy, (base * 1.15).color)
        G.ellipse(&c, tp, rt * sx * 0.84, rt * sy * 0.84, Color(red: 0.1, green: 0.12, blue: 0.14))
    }

    static func tree(_ c: inout GraphicsContext, _ iso: Iso, x: Double, y: Double, scale k: Double, health: Double) {
        let g = iso.p(x, y, 0)
        G.ellipse(&c, CGPoint(x: g.x + iso.s * 0.12, y: g.y + iso.s * 0.06), iso.s * 0.4 * k, iso.s * 0.2 * k, Color.black.opacity(0.22))
        iso.box(&c, x - 0.05, y - 0.05, 0.1, 0.1, 0.35 * k, RGB(0.45, 0.3, 0.2), outline: false)
        let col = Palette.rgb(Palette.landDetail, health)
        let cp = iso.p(x, y, 0.6 * k)
        let r = iso.s * 0.36 * CGFloat(k)
        G.ellipse(&c, cp, r, r * 0.95, (col * 0.82).color)
        G.ellipse(&c, CGPoint(x: cp.x - r * 0.2, y: cp.y - r * 0.25), r * 0.78, r * 0.72, col.color)
        G.ellipse(&c, CGPoint(x: cp.x - r * 0.35, y: cp.y - r * 0.45), r * 0.32, r * 0.28, (col * 1.35).col(0.8))
    }

    static func smokePuffs(_ c: inout GraphicsContext, from b: CGPoint, height: CGFloat, spread: CGFloat, count: Int, t: Double, health: Double, seed: Int) {
        let col = Palette.rgb(Palette.smoke, health)
        for i in 0..<count {
            let p = (t * (0.1 + 0.06 * G.rnd(i + seed, 2)) + G.rnd(i + seed, 3)).truncatingRemainder(dividingBy: 1)
            let px = Double(b.x) + sin(t + Double(i)) * 4 * p + p * Double(spread) * (G.rnd(i, 4) - 0.1)
            let py = Double(b.y) - p * Double(height)
            let r = Double(height) * (0.06 + p * 0.22)
            G.ellipse(&c, CGPoint(x: px, y: py), r, r, col.col((1 - p) * 0.45))
        }
    }
}

// MARK: - Scenes

enum Scenes {
    static func draw(_ c: inout GraphicsContext, size: CGSize, time t: Double, state s: BaseState, top: CGFloat = 0) {
        switch s.stage {
        case 0: bedroom(&c, size, t, s, top)
        case 1: warehouse(&c, size, t, s, top)
        case 2: serverHall(&c, size, t, s, top)
        case 3: campus(&c, size, t, s, top)
        default: horizon(&c, size, t, s)
        }
    }

    // MARK: Stage 0: Bedroom

    static func bedroom(_ c: inout GraphicsContext, _ size: CGSize, _ t: Double, _ st: BaseState, _ top: CGFloat) {
        let RW = 6.0, RD = 6.0, RH = 3.0
        let iso = Iso.fit(size, top: top, w: RW, d: RD, h: RH, below: 0.35, zoom: 0.8)
        let hy = Props.horizon(size, iso)
        Props.sky(&c, size, health: st.health, t: t, horizon: hy)
        Props.ground(&c, size, iso, horizon: hy, health: st.health, kind: .lawn, w: RW, d: RD)
        Props.horizonFade(&c, size, horizon: hy, health: st.health)
        let props = Props.groundProps(iso, health: st.health, t: t, kind: .lawn, w: RW, d: RD)
        props.back.draw(&c)
        let wood = RGB(0.68, 0.47, 0.30)
        Props.roomShell(&c, iso, RW, RD, RH, Props.RoomLook(floor: wood, wallR: RGB(0.66, 0.72, 0.9), wallL: RGB(0.53, 0.58, 0.77),
                                                            cap: RGB(0.92, 0.93, 0.98), slab: RGB(0.44, 0.32, 0.24), base: RGB(0.95, 0.96, 1)))
        for k in 0..<17 {
            let a = 0.12 + Double(k) * 0.35
            G.fill(&c, iso.wallR(a, 0.16, 0.12, RH - 0.2), Color.white.opacity(0.05))
            G.fill(&c, iso.wallL(a, 0.16, 0.12, RH - 0.2), Color.white.opacity(0.035))
        }
        // Floor planks
        let seam = Color(red: 0.27, green: 0.16, blue: 0.08).opacity(0.35)
        for r in 0..<12 {
            let y = Double(r) * 0.5
            let off = (Double(r) * 0.77).truncatingRemainder(dividingBy: 1.6)
            var xs: [Double] = [0]
            var x = off + 0.4
            while x < RW { xs.append(x); x += 1.6 }
            xs.append(RW)
            for i in 0..<(xs.count - 1) {
                let tone = 0.9 + G.rnd(r * 17 + i, 2) * 0.16
                G.fill(&c, iso.floor(xs[i], y, xs[i + 1] - xs[i], 0.5, z: 0.001), (wood * tone).color)
                if i > 0 { G.line(&c, iso.p(xs[i], y, 0.002), iso.p(xs[i], y + 0.5, 0.002), seam, 1) }
            }
            G.line(&c, iso.p(0, y, 0.002), iso.p(RW, y, 0.002), seam, 1)
        }
        G.fill(&c, iso.floor(0, 0, RW, RD, z: 0.003), shading: G.linear(iso.p(0, 0), iso.p(RW, RD), [(0, Color.white.opacity(0.07)), (1, Color.black.opacity(0.1))]))
        let sky = Palette.rgb(Palette.skyBottom, st.health)
        let sunPatch = [iso.p(3.0, 0.05, 0.004), iso.p(4.4, 0.05, 0.004), iso.p(5.2, 2.2, 0.004), iso.p(3.8, 2.2, 0.004)]
        G.fill(&c, sunPatch, RGB.mix(sky, RGB(1, 0.95, 0.8), 0.6).col(0.16))
        // Rug
        let rx = 1.7, ry = 2.5, rw = 2.8, rd = 2.4
        let rug = RGB(0.2, 0.36, 0.55)
        let accent = RGB(0.98, 0.78, 0.35)
        G.fill(&c, iso.floor(rx, ry, rw, rd, z: 0.005), rug.color)
        G.fill(&c, iso.floor(rx + 0.15, ry + 0.15, rw - 0.3, rd - 0.3, z: 0.006), (rug * 0.8).color)
        G.stroke(&c, iso.floor(rx + 0.26, ry + 0.26, rw - 0.52, rd - 0.52, z: 0.007), accent.col(0.85), max(1, iso.s * 0.035))
        let cx = rx + rw / 2, cy = ry + rd / 2
        G.stroke(&c, [iso.p(cx, cy - 0.6, 0.007), iso.p(cx + 0.7, cy, 0.007), iso.p(cx, cy + 0.6, 0.007), iso.p(cx - 0.7, cy, 0.007)], accent.col(0.75), max(1, iso.s * 0.03))
        for k in 0...14 {
            let fy = ry + Double(k) * rd / 14
            G.line(&c, iso.p(rx + rw, fy, 0.005), iso.p(rx + rw + 0.12, fy, 0.005), (rug * 1.3).col(0.9), 1)
        }
        // Window with curtains, and wall decorations
        G.line(&c, iso.p(2.15, 0.05, 2.62), iso.p(4.55, 0.05, 2.62), Color(red: 0.23, green: 0.2, blue: 0.25), max(1.5, iso.s * 0.05))
        Props.window(&c, iso, rightWall: true, 2.55, 1.25, 1.6, 1.2, health: st.health, t: t)
        iso.box(&c, 2.45, 0, 1.8, 0.14, 0.05, RGB(0.96, 0.96, 0.99), z0: 1.19)
        let curtain = RGB(0.9, 0.42, 0.38)
        for a0 in [2.15, 4.2] {
            for k in 0..<4 {
                let x0 = a0 + Double(k) * 0.09
                G.fill(&c, iso.faceY(x0, x0 + 0.09, 0.04, 0.95, 2.6), (curtain * (k % 2 == 1 ? 0.8 : 1)).color)
            }
        }
        let neon = RGB(0.24, 0.93, 0.78)
        G.fill(&c, iso.wallL(1.5, 1.3, 1.05, 1.25), Color(red: 0.1, green: 0.12, blue: 0.24))
        G.fill(&c, iso.wallL(1.62, 2.36, 0.81, 0.1), Color(red: 1, green: 0.42, blue: 0.6))
        G.fill(&c, iso.wallL(1.78, 1.62, 0.5, 0.5), neon.color)
        G.fill(&c, iso.wallL(1.88, 1.72, 0.3, 0.3), Color(red: 0.1, green: 0.12, blue: 0.24))
        for k in 0..<4 {
            let py = 1.84 + Double(k) * 0.12
            G.line(&c, iso.p(0, py, 1.62), iso.p(0, py, 1.52), neon.color, 1)
            G.line(&c, iso.p(0, py, 2.12), iso.p(0, py, 2.22), neon.color, 1)
        }
        G.stroke(&c, iso.wallL(1.5, 1.3, 1.05, 1.25), Color(red: 0.98, green: 0.98, blue: 1).opacity(0.9), max(1, iso.s * 0.04))
        iso.box(&c, 0, 3.5, 0.32, 1.5, 0.06, RGB(0.7, 0.5, 0.33), z0: 1.95)
        let books = [RGB(0.9, 0.3, 0.3), RGB(0.3, 0.5, 0.95), RGB(1, 0.8, 0.3), RGB(0.35, 0.8, 0.5), RGB(0.7, 0.4, 0.9)]
        for b in 0..<5 {
            iso.box(&c, 0.04, 3.58 + Double(b) * 0.15, 0.22, 0.12, 0.28 + G.rnd(b, 3) * 0.08, books[b], z0: 2.01, outline: false)
        }
        Props.plant(&c, iso, x: 0.16, y: 4.7, z: 2.01, scale: 0.9)
        let clock = (5.25, 2.35)
        G.fill(&c, iso.circle(clock.0, 0.02, clock.1, 0.26, .xz, n: 20), Color(red: 0.97, green: 0.97, blue: 0.98))
        G.stroke(&c, iso.circle(clock.0, 0.02, clock.1, 0.26, .xz, n: 20), Color(red: 0.18, green: 0.2, blue: 0.25), max(1, iso.s * 0.04))
        let minute = t * 0.6, hour = t * 0.05
        let hand = Color(red: 0.18, green: 0.2, blue: 0.25)
        G.line(&c, iso.p(clock.0, 0.03, clock.1), iso.p(clock.0 + cos(minute) * 0.2, 0.03, clock.1 + sin(minute) * 0.2), hand, 1)
        G.line(&c, iso.p(clock.0, 0.03, clock.1), iso.p(clock.0 + cos(hour) * 0.13, 0.03, clock.1 + sin(hour) * 0.13), hand, 1.6)

        var list = DrawList()
        let oc = st.overclock
        list.add(1.4) { g in Props.desk(&g, iso, x: 0.25, y: 0.25, w: 2.0, d: 0.8, t: t, monitors: 1, overclock: oc) }
        list.add(2.85) { g in Props.chairSeat(&g, iso, x: 1.25, y: 1.7, color: RGB(0.85, 0.22, 0.3)) }
        list.add(2.95) { g in Props.person(&g, iso, x: 1.25, y: 1.62, t: t, seed: 1, Props.Look(shirt: RGB(1, 0.62, 0.22), seated: true, headphones: true, back: true)) }
        list.add(3.05) { g in Props.chairBack(&g, iso, x: 1.25, y: 1.7, color: RGB(0.85, 0.22, 0.3), accent: RGB(1, 0.85, 0.3)) }
        list.add(5.2) { g in Props.bed(&g, iso, x: 0.12, y: 3.45) }
        list.add(4.3) { g in Props.fan(&g, iso, x: 3.75, y: 0.55, t: t, overclock: oc) }
        list.add(10.2) { g in Props.plant(&g, iso, x: 5.45, y: 5.3, z: 0, scale: 1.25) }
        list.add(7.6) { g in
            for k in 0..<3 { iso.box(&g, 2.5, 5.0, 0.7, 0.7, 0.07, RGB(0.95, 0.9, 0.82), z0: Double(k) * 0.075) }
            G.fill(&g, iso.faceY(2.6, 3.1, 5.701, 0.18, 0.21), Color(red: 0.82, green: 0.24, blue: 0.2))
        }
        let slots: [(Double, Double)] = [(4.4, 0.3), (5.15, 0.3), (4.4, 1.1), (5.15, 1.1)]
        for k in 0..<min(st.owned[0], slots.count) {
            let (x, y) = slots[k]
            list.add(x + y + 0.6) { g in Props.rack(&g, iso, x: x, y: y, w: 0.62, d: 0.62, h: 1.0, style: 0, t: t, seed: k, overclock: oc) }
        }
        list.append(props.front)
        list.draw(&c)
        G.vignette(&c, size, 0.38)
    }

    // MARK: Stage 1: Warehouse

    static func warehouse(_ c: inout GraphicsContext, _ size: CGSize, _ t: Double, _ st: BaseState, _ top: CGFloat) {
        let RW = 10.0, RD = 10.0, RH = 3.4
        let iso = Iso.fit(size, top: top, w: RW, d: RD, h: RH, below: 0.35, zoom: 0.8)
        let hy = Props.horizon(size, iso)
        Props.sky(&c, size, health: st.health, t: t, horizon: hy)
        Props.ground(&c, size, iso, horizon: hy, health: st.health, kind: .yard, w: RW, d: RD)
        Props.horizonFade(&c, size, horizon: hy, health: st.health)
        let props = Props.groundProps(iso, health: st.health, t: t, kind: .yard, w: RW, d: RD)
        props.back.draw(&c)
        Props.roomShell(&c, iso, RW, RD, RH, Props.RoomLook(floor: RGB(0.58, 0.6, 0.63), wallR: RGB(0.55, 0.63, 0.72), wallL: RGB(0.46, 0.53, 0.63),
                                                            cap: RGB(0.76, 0.8, 0.87), slab: RGB(0.33, 0.35, 0.4), base: RGB(0.4, 0.42, 0.46)))
        let joint = Color.black.opacity(0.13)
        for k in 1..<4 {
            let v = Double(k) * 2.5
            G.line(&c, iso.p(v, 0, 0.002), iso.p(v, RD, 0.002), joint, 1)
            G.line(&c, iso.p(0, v, 0.002), iso.p(RW, v, 0.002), joint, 1)
        }
        for k in 0..<12 {
            G.fill(&c, iso.circle(G.rnd(k, 51) * RW, G.rnd(k, 52) * RD, 0.003, 0.3 + G.rnd(k, 53) * 0.6, .xy, n: 14), Color.black.opacity(0.05))
        }
        // Corrugated walls over a concrete-block base
        for k in 0..<40 {
            let a = Double(k) * 0.25
            let rib = k % 2 == 1 ? Color.white.opacity(0.06) : Color.black.opacity(0.05)
            G.fill(&c, iso.wallR(a, 0.72, 0.1, RH - 0.95), rib)
            G.fill(&c, iso.wallL(a, 0.72, 0.1, RH - 0.95), k % 2 == 1 ? Color.white.opacity(0.04) : Color.black.opacity(0.05))
        }
        G.fill(&c, iso.wallR(0, 0.14, RW, 0.58), Color(red: 0.5, green: 0.51, blue: 0.54))
        G.fill(&c, iso.wallL(0, 0.14, RD, 0.58), Color(red: 0.43, green: 0.44, blue: 0.47))
        let mortar = Color.black.opacity(0.15)
        for k in 0..<17 {
            let a = Double(k) * 0.6
            G.line(&c, iso.p(a + 0.3, 0, 0.14), iso.p(a + 0.3, 0, 0.43), mortar, 1)
            G.line(&c, iso.p(a, 0, 0.43), iso.p(a, 0, 0.72), mortar, 1)
            G.line(&c, iso.p(0, a + 0.3, 0.14), iso.p(0, a + 0.3, 0.43), mortar, 1)
            G.line(&c, iso.p(0, a, 0.43), iso.p(0, a, 0.72), mortar, 1)
        }
        G.line(&c, iso.p(0, 0, 0.43), iso.p(RW, 0, 0.43), mortar, 1)
        G.line(&c, iso.p(0, 0, 0.43), iso.p(0, RD, 0.43), mortar, 1)
        for (a, len) in [(0.5, 2.4), (3.85, 2.4), (7.2, 2.4)] {
            Props.window(&c, iso, rightWall: true, a, 2.25, len, 0.7, health: st.health, t: t)
        }
        let steel = RGB(0.27, 0.36, 0.52)
        for cx in [3.3, 6.65] { iso.box(&c, cx, 0, 0.22, 0.2, RH, steel) }
        iso.box(&c, 0, 4.9, 0.2, 0.22, RH, steel)
        iso.box(&c, 0, 0, RW, 0.14, 0.16, steel, z0: RH - 0.3, outline: false)
        // Roll-up door, hazard stripes and floor markings
        G.fill(&c, iso.wallL(6.2, 0, 2.6, 2.4), shading: iso.zGrad(.yz, 0, 6.2, 0, 2.4, [(0, Color(red: 0.52, green: 0.54, blue: 0.57)), (1, Color(red: 0.7, green: 0.72, blue: 0.75))]))
        for k in 1..<12 { G.line(&c, iso.p(0, 6.2, Double(k) * 0.2), iso.p(0, 8.8, Double(k) * 0.2), Color.black.opacity(0.2), 1) }
        G.stroke(&c, iso.wallL(6.2, 0, 2.6, 2.4), Color(red: 0.12, green: 0.14, blue: 0.18).opacity(0.6), max(1, iso.s * 0.04))
        for k in 0..<10 { G.fill(&c, iso.floor(0, 6.2 + Double(k) * 0.26, 0.4, 0.13, z: 0.004), Color(red: 0.98, green: 0.78, blue: 0.16).opacity(0.9)) }
        G.stroke(&c, iso.floor(2.8, 0.4, 6.9, 7.5, z: 0.004), Color(red: 0.98, green: 0.78, blue: 0.16).opacity(0.8), max(1, iso.s * 0.045))
        // Whiteboard
        G.fill(&c, iso.wallL(1.35, 1.2, 1.7, 1.0), Color(red: 0.95, green: 0.96, blue: 0.98))
        G.stroke(&c, iso.wallL(1.35, 1.2, 1.7, 1.0), Color(red: 0.54, green: 0.58, blue: 0.65), max(1, iso.s * 0.04))
        let markers = [Color(red: 0.24, green: 0.48, blue: 1), Color(red: 1, green: 0.35, blue: 0.35), Color(red: 0.17, green: 0.71, blue: 0.45), Color(red: 0.24, green: 0.48, blue: 1)]
        for k in 0..<4 {
            let z = 1.95 - Double(k) * 0.2
            G.line(&c, iso.p(0, 1.5, z), iso.p(0, 1.5 + 0.4 + G.rnd(k, 3) * 0.9, z + 0.05), markers[k], max(1, iso.s * 0.035))
        }
        let lamps: [(Double, Double)] = [(4.6, 2.6), (7.6, 2.6), (4.6, 6.0), (7.6, 6.0)]
        for (lx, ly) in lamps {
            let pc = iso.p(lx, ly, 0.004)
            G.ellipse(&c, pc, iso.s * 1.7, iso.s * 1.0, shading: G.radial(pc, 0, iso.s * 1.7, [(0, Color(red: 1, green: 0.94, blue: 0.78).opacity(0.18)), (1, Color(red: 1, green: 0.94, blue: 0.78).opacity(0))]))
        }

        var list = DrawList()
        let oc = st.overclock
        list.add(1.4) { g in Props.desk(&g, iso, x: 0.25, y: 0.25, w: 2.2, d: 0.8, t: t, monitors: 2, overclock: oc) }
        list.add(2.95) { g in Props.chairSeat(&g, iso, x: 1.35, y: 1.7, color: RGB(0.25, 0.3, 0.45)) }
        list.add(3.0) { g in Props.person(&g, iso, x: 1.35, y: 1.62, t: t, seed: 1, Props.Look(shirt: RGB(1, 0.62, 0.22), seated: true, headphones: true, back: true)) }
        list.add(3.1) { g in Props.chairBack(&g, iso, x: 1.35, y: 1.7, color: RGB(0.25, 0.3, 0.45), accent: RGB(0.24, 0.93, 0.7)) }
        list.add(7.8) { g in Props.pallet(&g, iso, x: 0.5, y: 6.3, boxes: 6) }
        list.add(9.0) { g in Props.pallet(&g, iso, x: 0.5, y: 7.6, boxes: 4) }
        let home = min(st.owned[0], 24)
        let gpus = min(st.owned[1], 24)
        for k in 0..<(home + gpus) {
            let x = 3.1 + Double(k % 8) * 0.8
            let y = 0.85 + Double(k / 8) * 1.45
            let style = k < home ? 0 : 1
            list.add(x + y + 0.6) { g in Props.rack(&g, iso, x: x, y: y, w: 0.62, d: 0.62, h: style == 1 ? 1.35 : 1.0, style: style, t: t, seed: k, overclock: oc) }
        }
        for k in 0..<min(3, st.owned[1] / 10) {
            let y = 1.85 + Double(k) * 1.45
            let x = 3.2 + (sin(t * 0.3 + Double(k)) * 0.5 + 0.5) * 5.8
            list.add(x + y) { g in Props.person(&g, iso, x: x, y: y, t: t, seed: 5 + k, Props.Look(shirt: RGB(0.25, 0.6, 0.95), hardhat: true)) }
        }
        list.append(props.front)
        list.draw(&c)
        // Hanging lamps with soft light cones
        for (lx, ly) in lamps {
            let top = iso.p(lx, ly, 3.05)
            let bottom = iso.p(lx, ly, 0)
            let cone = [CGPoint(x: top.x - iso.s * 0.2, y: top.y), CGPoint(x: top.x + iso.s * 0.2, y: top.y),
                        CGPoint(x: bottom.x + iso.s * 1.3, y: bottom.y), CGPoint(x: bottom.x - iso.s * 1.3, y: bottom.y)]
            G.fill(&c, cone, shading: G.linear(top, bottom, [(0, Color(red: 1, green: 0.94, blue: 0.78).opacity(0.14)), (1, Color(red: 1, green: 0.94, blue: 0.78).opacity(0))]))
            G.line(&c, iso.p(lx, ly, 3.12), iso.p(lx, ly, RH + 0.4), Color(red: 0.12, green: 0.14, blue: 0.18).opacity(0.8), 1)
            G.ellipse(&c, CGPoint(x: top.x, y: top.y - iso.s * 0.06), iso.s * 0.26, iso.s * 0.12, Color(red: 0.17, green: 0.2, blue: 0.26))
            G.ellipse(&c, top, iso.s * 0.18, iso.s * 0.07, Color(red: 1, green: 0.95, blue: 0.81))
        }
        G.vignette(&c, size, 0.38)
    }

    // MARK: Stage 2: Server Hall

    static func serverHall(_ c: inout GraphicsContext, _ size: CGSize, _ t: Double, _ st: BaseState, _ top: CGFloat) {
        let RW = 12.0, RD = 12.0, RH = 3.4
        let iso = Iso.fit(size, top: top, w: RW, d: RD, h: RH, below: 0.35, zoom: 0.8)
        let hy = Props.horizon(size, iso)
        Props.sky(&c, size, health: st.health, t: t, horizon: hy)
        Props.ground(&c, size, iso, horizon: hy, health: st.health, kind: .lot, w: RW, d: RD)
        Props.horizonFade(&c, size, horizon: hy, health: st.health)
        let props = Props.groundProps(iso, health: st.health, t: t, kind: .lot, w: RW, d: RD)
        props.back.draw(&c)
        Props.roomShell(&c, iso, RW, RD, RH, Props.RoomLook(floor: RGB(0.6, 0.64, 0.7), wallR: RGB(0.17, 0.2, 0.29), wallL: RGB(0.13, 0.16, 0.23),
                                                            cap: RGB(0.34, 0.38, 0.5), slab: RGB(0.17, 0.19, 0.26), base: RGB(0.1, 0.12, 0.16)))
        for k in 1..<Int(RW) {
            let v = Double(k)
            G.line(&c, iso.p(v, 0, 0.002), iso.p(v, RD, 0.002), Color.black.opacity(0.16), 1)
            G.line(&c, iso.p(0, v, 0.002), iso.p(RW, v, 0.002), Color.black.opacity(0.16), 1)
            G.line(&c, iso.p(v, 0, 0.002), iso.p(v, 0, RH), Color.white.opacity(0.05), 1)
            G.line(&c, iso.p(0, v, 0.002), iso.p(0, v, RH), Color.white.opacity(0.04), 1)
        }
        for (a, b) in [(iso.p(0, 0, 2.55), iso.p(RW, 0, 2.55)), (iso.p(0, 0, 2.55), iso.p(0, RD, 2.55))] {
            G.line(&c, a, b, Color(red: 0.31, green: 0.86, blue: 1).opacity(0.25), max(3, iso.s * 0.2))
            G.line(&c, a, b, Color(red: 0.63, green: 0.96, blue: 1).opacity(0.95), max(1, iso.s * 0.045))
        }
        // Wall dashboard
        let da = 0.5, dz = 1.15, dl = 2.9, dh = 1.15
        G.fill(&c, iso.wallR(da, dz, dl, dh), Color(red: 0.03, green: 0.06, blue: 0.12))
        G.stroke(&c, iso.wallR(da, dz, dl, dh), Color(red: 0.23, green: 0.27, blue: 0.38), max(1, iso.s * 0.05))
        var chart: [CGPoint] = []
        for i in 0...14 {
            let f = 0.45 + 0.35 * sin(Double(i) * 0.8 + t * 0.6) * (0.6 + 0.4 * G.rnd(i, 4))
            chart.append(iso.p(da + 0.15 + Double(i) * (dl * 0.55) / 14, 0.01, dz + 0.15 + f * (dh - 0.3)))
        }
        G.stroke(&c, chart, Color(red: 0.24, green: 0.88, blue: 0.69), max(1, iso.s * 0.04), closed: false)
        for i in 0..<6 {
            let bh = 0.15 + 0.6 * (0.5 + 0.5 * sin(t + Double(i)))
            let bar = iso.wallR(da + dl * 0.64 + Double(i) * 0.16, dz + 0.12, 0.09, bh * (dh - 0.3), y: 0.01)
            G.fill(&c, bar, i % 2 == 1 ? Color(red: 1, green: 0.76, blue: 0.27) : Color(red: 0.35, green: 0.72, blue: 1))
        }
        // Exit door and sign
        G.fill(&c, iso.wallL(9.8, 0, 1.0, 1.9), Color(red: 0.16, green: 0.19, blue: 0.26))
        G.stroke(&c, iso.wallL(9.8, 0, 1.0, 1.9), Color(red: 0.29, green: 0.34, blue: 0.43), 1)
        G.fill(&c, iso.wallL(10.05, 2.05, 0.5, 0.2), Color(red: 0.15, green: 0.82, blue: 0.49))
        let eg = iso.p(0, 10.3, 2.15)
        G.ellipse(&c, eg, iso.s * 0.7, iso.s * 0.4, shading: G.radial(eg, 0, iso.s * 0.7, [(0, Color(red: 0.16, green: 0.86, blue: 0.51).opacity(0.3)), (1, Color(red: 0.16, green: 0.86, blue: 0.51).opacity(0))]))

        let perRow = 12, x0 = 3.3, step = 0.66
        let racks = min(6 * perRow, 10 + st.owned[2] * 3 + st.owned[1] / 3)
        let rows = (racks + perRow - 1) / perRow
        var holes = Path()
        for r in 0..<rows {
            let ry = 0.9 + Double(r) * 1.8
            G.fill(&c, iso.floor(x0 - 0.1, ry + 0.72, Double(perRow) * step + 0.1, 0.62, z: 0.003), Color(red: 0.35, green: 0.75, blue: 1).opacity(0.16))
            G.fill(&c, iso.floor(x0 - 0.1, ry - 0.5, Double(perRow) * step + 0.1, 0.45, z: 0.003), Color(red: 1, green: 0.47, blue: 0.24).opacity(0.07))
            for i in 0..<perRow {
                for j in 0..<2 {
                    let dp = iso.p(x0 + Double(i) * step + 0.3, ry + 0.85 + Double(j) * 0.3, 0.004)
                    holes.addRect(CGRect(x: dp.x - 1, y: dp.y - 0.5, width: 2, height: 1))
                }
            }
        }
        c.fill(holes, with: .color(Color(red: 0.08, green: 0.16, blue: 0.24).opacity(0.35)))

        var list = DrawList()
        let oc = st.overclock
        list.add(1.4) { g in Props.desk(&g, iso, x: 0.25, y: 0.25, w: 2.6, d: 0.8, t: t, monitors: 3, overclock: oc) }
        list.add(3.15) { g in Props.chairSeat(&g, iso, x: 1.55, y: 1.7, color: RGB(0.2, 0.24, 0.36)) }
        list.add(3.2) { g in Props.person(&g, iso, x: 1.55, y: 1.62, t: t, seed: 1, Props.Look(shirt: RGB(1, 0.62, 0.22), seated: true, headphones: true, back: true)) }
        list.add(3.3) { g in Props.chairBack(&g, iso, x: 1.55, y: 1.7, color: RGB(0.2, 0.24, 0.36), accent: RGB(0.35, 0.75, 1)) }
        for k in 0..<racks {
            let x = x0 + Double(k % perRow) * step
            let y = 0.9 + Double(k / perRow) * 1.8
            list.add(x + y + 0.6) { g in Props.rack(&g, iso, x: x, y: y, w: 0.62, d: 0.66, h: 1.9, style: 2, t: t, seed: k, overclock: oc) }
        }
        for k in 0..<min(5, 1 + st.owned[2] / 8) {
            let y = 0.9 + Double(k % max(1, rows)) * 1.8 + 1.05
            let x = 3.4 + (sin(t * 0.25 + Double(k) * 1.7) * 0.5 + 0.5) * 7.4
            list.add(x + y) { g in Props.person(&g, iso, x: x, y: y, t: t, seed: 9 + k, Props.Look(shirt: RGB(0.93, 0.95, 1))) }
        }
        list.append(props.front)
        list.draw(&c)
        // Cable trays above each row
        for r in 0..<rows {
            let ry = 0.9 + Double(r) * 1.8
            let length = Double(perRow) * step + 0.1
            iso.box(&c, x0 - 0.1, ry + 0.18, length, 0.3, 0.04, RGB(0.62, 0.52, 0.22), z0: 2.3)
            for i in 0..<26 {
                let xx = x0 + Double(i) * 0.31
                G.line(&c, iso.p(xx, ry + 0.18, 2.341), iso.p(xx, ry + 0.48, 2.341), Color(red: 0.16, green: 0.12, blue: 0.02).opacity(0.6), 1)
            }
            G.line(&c, iso.p(x0, ry + 0.28, 2.35), iso.p(x0 + length - 0.2, ry + 0.28, 2.35), Color(red: 0.24, green: 0.48, blue: 1), max(1, iso.s * 0.045))
            G.line(&c, iso.p(x0, ry + 0.37, 2.35), iso.p(x0 + length - 0.2, ry + 0.37, 2.35), Color(red: 0.91, green: 0.72, blue: 0.19), max(1, iso.s * 0.045))
        }
        G.vignette(&c, size, 0.42)
    }

    // MARK: Stage 3: Campus (outdoors)

    static func campus(_ c: inout GraphicsContext, _ size: CGSize, _ t: Double, _ st: BaseState, _ top: CGFloat) {
        let h = st.health
        let W = Double(size.width), H = Double(size.height)
        let RW = 14.0, RD = 14.0
        let iso = Iso.fit(size, top: top, w: RW, d: RD, h: 1.6, below: 0.6, zoom: 1.15)
        let hy = max(H * 0.18, Double(iso.p(0, 0, 0).y) - Double(iso.s) * 1.5)
        Props.sky(&c, size, health: h, t: t, horizon: hy)
        Props.ground(&c, size, iso, horizon: hy, health: h, kind: .open, w: RW, d: RD)
        let water = Palette.rgb(Palette.ocean, h)
        var g = c
        g.clip(to: Path(CGRect(x: 0, y: hy, width: W, height: max(0, H - hy))))
        // River running right across the land
        G.fill(&g, iso.floor(-20, 10.3, RW + 40, 1.4, z: 0.002), Color(red: 0.78, green: 0.7, blue: 0.52))
        G.fill(&g, iso.floor(-20, 10.45, RW + 40, 1.1, z: 0.003), shading: G.linear(iso.p(0, 10.45), iso.p(0, 11.55), [(0, (water * 1.15).color), (1, (water * 0.85).color)]))
        for k in 0..<22 {
            let span = RW + 12
            let rx = -6 + (G.rnd(k, 71) * span + t * 0.6).truncatingRemainder(dividingBy: span)
            let ry = 10.55 + G.rnd(k, 72) * 0.9
            G.line(&g, iso.p(rx, ry, 0.004), iso.p(rx + 0.35, ry, 0.004), Color.white.opacity(0.35), 1)
        }
        // Road, parking lot and substation yard
        G.fill(&g, iso.floor(-20, 5.85, RW + 40, 1.2, z: 0.002), Color(red: 0.66, green: 0.66, blue: 0.64))
        G.fill(&g, iso.floor(-20, 6.0, RW + 40, 0.9, z: 0.003), Color(red: 0.23, green: 0.24, blue: 0.27))
        for k in 0..<30 {
            G.fill(&g, iso.floor(-18 + Double(k) * 1.2, 6.42, 0.6, 0.06, z: 0.004), Color(red: 1, green: 0.9, blue: 0.47).opacity(0.9))
        }
        G.fill(&g, iso.floor(9.8, 0.5, 3.8, 3.2, z: 0.003), Color(red: 0.27, green: 0.28, blue: 0.31))
        for k in 0...6 {
            let lx = 9.9 + Double(k) * 0.6
            G.line(&g, iso.p(lx, 0.6, 0.004), iso.p(lx, 1.45, 0.004), Color.white.opacity(0.7), 1)
            G.line(&g, iso.p(lx, 2.7, 0.004), iso.p(lx, 3.6, 0.004), Color.white.opacity(0.7), 1)
        }
        G.fill(&g, iso.floor(6.7, 7.5, 2.4, 2.1, z: 0.003), Color(red: 0.58, green: 0.58, blue: 0.55))
        Props.horizonFade(&c, size, horizon: hy, health: h)

        var list = DrawList()
        let hallSpots: [(Double, Double)] = [(0.5, 0.6), (3.6, 0.6), (6.7, 0.6), (0.5, 3.3), (3.6, 3.3), (6.7, 3.3), (0.5, 7.5), (3.6, 7.5)]
        let halls = min(8, 1 + st.owned[3] + st.owned[2] / 10)
        for k in 0..<halls {
            let (x, y) = hallSpots[k]
            list.add(x + y + 2.3) { g in Props.dataHall(&g, iso, x: x, y: y, t: t, seed: k) }
        }
        let carColors = [RGB(0.9, 0.25, 0.25), RGB(0.95, 0.95, 0.97), RGB(0.25, 0.45, 0.9), RGB(0.95, 0.75, 0.2), RGB(0.2, 0.2, 0.24)]
        for k in 0..<min(12, 2 + st.owned[3]) {
            let x = 10.03 + Double(k % 6) * 0.6
            let y = k < 6 ? 0.75 : 2.85
            let col = carColors[k % 5]
            list.add(x + y + 0.5) { g in
                iso.box(&g, x, y, 0.34, 0.6, 0.15, col)
                iso.box(&g, x + 0.04, y + 0.14, 0.26, 0.3, 0.12, col * 0.95, z0: 0.15)
                G.fill(&g, iso.faceY(x + 0.04, x + 0.3, y + 0.441, 0.16, 0.26), Color(red: 0.16, green: 0.24, blue: 0.35).opacity(0.85))
            }
        }
        for k in 0..<3 {
            let x = 7.0 + Double(k) * 0.72, y = 8.0
            list.add(x + y + 0.5) { g in
                iso.box(&g, x, y, 0.5, 0.5, 0.5, RGB(0.55, 0.6, 0.62))
                for f in 0..<4 {
                    let fx = x + 0.08 + Double(f) * 0.11
                    G.line(&g, iso.p(fx, y + 0.502, 0.08), iso.p(fx, y + 0.502, 0.42), Color.black.opacity(0.25), 1)
                }
            }
        }
        list.add(18.2) { g in
            let fence = Color(red: 0.78, green: 0.8, blue: 0.82).opacity(0.9)
            G.stroke(&g, iso.floor(6.7, 7.5, 2.4, 2.1, z: 0.01), fence, 1)
            for (fx, fy) in [(6.7, 9.6), (9.1, 9.6), (9.1, 7.5)] { G.line(&g, iso.p(fx, fy, 0), iso.p(fx, fy, 0.35), fence, 1) }
            G.line(&g, iso.p(6.7, 9.6, 0.35), iso.p(9.1, 9.6, 0.35), fence, 1)
            G.line(&g, iso.p(9.1, 9.6, 0.35), iso.p(9.1, 7.5, 0.35), fence, 1)
        }
        let towerSpots: [(Double, Double)] = [(10.4, 7.9), (12.5, 7.9), (11.45, 9.4)]
        let towers = min(3, 1 + st.owned[3] / 5)
        for k in 0..<towers {
            let (x, y) = towerSpots[k]
            list.add(x + y) { g in Props.coolingTower(&g, iso, x: x, y: y) }
        }
        let trees = Int((h / 100 * 30).rounded())
        for k in 0..<trees {
            let x = 0.4 + G.rnd(k, 21) * (RW - 0.8)
            let y = k % 3 == 0 ? 4.9 + G.rnd(k, 22) * 0.6 : 11.9 + G.rnd(k, 23) * 1.8
            if k % 3 == 0 && x > 9.5 { continue }
            let scale = 0.8 + G.rnd(k, 24) * 0.5
            list.add(x + y) { g in Props.tree(&g, iso, x: x, y: y, scale: scale, health: h) }
        }
        list.draw(&c)
        let puffs = Int(min(26, log10(st.pollution * 50 + 1) * 8))
        for k in 0..<towers {
            let (x, y) = towerSpots[k]
            Props.smokePuffs(&c, from: iso.p(x, y, 1.7), height: iso.s * 3.2, spread: iso.s * 1.4, count: puffs, t: t, health: h, seed: k * 40)
        }
        G.vignette(&c, size, 0.3)
    }

    // MARK: Stage 4: Horizon Megacenter

    static func horizon(_ c: inout GraphicsContext, _ size: CGSize, _ t: Double, _ st: BaseState) {
        let h = st.health
        let W = Double(size.width), H = Double(size.height)
        let glow = Palette.rgb(Palette.glow, h)
        c.fill(Path(CGRect(origin: .zero, size: size)), with: G.linear(.zero, CGPoint(x: 0, y: H), [
            (0, Color(red: 0.01, green: 0.02, blue: 0.05)), (0.5, (Palette.rgb(Palette.skyTop, h) * 0.55).color), (0.76, glow.color),
        ]))
        let nebula = CGPoint(x: W * 0.2, y: H * 0.2)
        G.ellipse(&c, nebula, W * 0.5, H * 0.3, shading: G.radial(nebula, 0, W * 0.5, [(0, Color(red: 0.59, green: 0.35, blue: 1).opacity(0.16)), (1, Color(red: 0.59, green: 0.35, blue: 1).opacity(0))]))
        for k in 0..<60 {
            let x = G.rnd(k, 31) * W
            let y = G.rnd(k, 32) * H * 0.55
            let twinkle = 0.4 + 0.6 * (0.5 + 0.5 * sin(t * 2 + Double(k)))
            c.fill(Path(CGRect(x: x, y: y, width: 1.5, height: 1.5)), with: .color(Color.white.opacity(0.7 * twinkle * (1 - y / (H * 0.6)))))
        }
        let hy = H * 0.74
        let R = W * 1.7
        let mass = Double(st.owned[4] + st.owned[5] * 2 + st.owned[6] * 4)
        let grow = 0.35 + 0.65 * min(1, mass / 120)
        // Distant towers on the horizon
        for k in 0..<9 {
            let bx = W * (0.05 + Double(k) * 0.11)
            let bw = W * 0.06
            let bh = H * (0.05 + 0.08 * G.rnd(k, 33)) * (0.6 + grow)
            c.fill(Path(CGRect(x: bx, y: hy - bh + 6, width: bw, height: bh)), with: .color(Color(red: 0.06, green: 0.07, blue: 0.11).opacity(0.95)))
            for j in 0..<4 where sin(t + Double(k * 3 + j)) > 0 {
                let lx = bx + bw * 0.2 + Double(j % 2) * bw * 0.4
                let ly = hy - bh + 10 + Double(j / 2) * 6
                c.fill(Path(CGRect(x: lx, y: ly, width: bw * 0.2, height: 1.5)), with: .color(Color(red: 0.35, green: 0.86, blue: 1).opacity(0.6)))
            }
        }
        // The megacenter rises from behind the curve; bigger with every high tier you own.
        let baseW = W * 0.62 * grow
        let topH = H * 0.52 * grow
        let cx = W / 2
        if st.overclock || mass > 60 {
            for i in 0..<3 {
                let bx = cx + baseW * Double(i - 1) * 0.23
                let a = 0.08 + 0.06 * sin(t * 2 + Double(i))
                let beam = [CGPoint(x: bx - 6, y: hy - topH * 0.7), CGPoint(x: bx + 6, y: hy - topH * 0.7), CGPoint(x: bx + 40, y: 0), CGPoint(x: bx - 40, y: 0)]
                G.fill(&c, beam, shading: G.linear(CGPoint(x: 0, y: hy - topH), .zero, [(0, Color(red: 0.47, green: 0.9, blue: 1).opacity(a)), (1, Color(red: 0.47, green: 0.9, blue: 1).opacity(0))]))
            }
        }
        let blocks: [(Double, Double, Double)] = [(-0.42, 0.17, 0.42), (-0.23, 0.2, 0.72), (0, 0.24, 1.0), (0.23, 0.2, 0.68), (0.42, 0.17, 0.5)]
        let smoke = Palette.rgb(Palette.smoke, h)
        for (i, b) in blocks.enumerated() {
            let w = baseW * b.1
            let x = cx + baseW * b.0 - w / 2
            let hh = topH * b.2
            let top = hy + 8 - hh
            let side = w * 0.18
            G.fill(&c, [CGPoint(x: x + w, y: top), CGPoint(x: x + w + side, y: top - side * 0.5), CGPoint(x: x + w + side, y: hy + 20), CGPoint(x: x + w, y: hy + 20)], Color(red: 0.05, green: 0.05, blue: 0.08))
            G.fill(&c, [CGPoint(x: x, y: top), CGPoint(x: x + w, y: top), CGPoint(x: x + w + side, y: top - side * 0.5), CGPoint(x: x + side, y: top - side * 0.5)], Color(red: 0.16, green: 0.17, blue: 0.23))
            c.fill(Path(CGRect(x: x, y: top, width: w, height: hh + 20)), with: G.linear(CGPoint(x: x, y: top), CGPoint(x: x + w, y: hy), [(0, Color(red: 0.165, green: 0.184, blue: 0.25)), (1, Color(red: 0.05, green: 0.06, blue: 0.09))]))
            c.fill(Path(CGRect(x: x, y: top, width: 1.5, height: hh + 20)), with: .color(glow.col(0.55)))
            let rows = max(3, Int(hh / 9))
            var windows = Path()
            for r in 0..<rows {
                for q in 0..<4 where sin(t * 1.5 + Double(i * 31 + r * 7 + q * 3)) >= -0.2 {
                    windows.addRect(CGRect(x: x + w * (0.12 + 0.22 * Double(q)), y: top + 5 + Double(r) * (hh - 6) / Double(rows), width: w * 0.12, height: 2.2))
                }
            }
            c.fill(windows, with: .color(st.overclock ? Color(red: 1, green: 0.31, blue: 0.24).opacity(0.9) : Color(red: 0.43, green: 0.9, blue: 1).opacity(0.85)))
            if i != 2 {
                for p in 0..<16 {
                    let pp = (t * 0.07 + G.rnd(p + i * 30, 3)).truncatingRemainder(dividingBy: 1)
                    let r = 4 + pp * 26
                    let at = CGPoint(x: x + w / 2 + pp * 40 * (G.rnd(p, 4) - 0.2), y: top - pp * H * 0.4)
                    G.ellipse(&c, at, r, r, smoke.col((1 - pp) * 0.4))
                }
            }
        }
        let tipY = hy + 8 - topH - 28
        G.line(&c, CGPoint(x: cx, y: hy + 8 - topH), CGPoint(x: cx, y: tipY), Color(red: 0.49, green: 0.52, blue: 0.59), 2)
        if sin(t * 4) > 0 {
            G.ellipse(&c, CGPoint(x: cx, y: tipY), 7, 7, Color(red: 1, green: 0.24, blue: 0.24).opacity(0.3))
            G.ellipse(&c, CGPoint(x: cx, y: tipY), 3, 3, Color(red: 1, green: 0.25, blue: 0.25))
        }
        let horizonGlow = CGPoint(x: W / 2, y: hy)
        G.ellipse(&c, horizonGlow, W * 0.9, H * 0.12, shading: G.radial(horizonGlow, 0, W * 0.9, [(0, glow.col(0.35)), (1, glow.col(0))]))
        // The planet's curve in front hides the base of the megacenter.
        let pc = CGPoint(x: W / 2, y: hy + R)
        let planet = Path(ellipseIn: CGRect(x: Double(pc.x) - R, y: Double(pc.y) - R, width: R * 2, height: R * 2))
        var surface = c
        surface.clip(to: planet)
        surface.fill(Path(CGRect(x: 0, y: hy - 10, width: W, height: H)), with: .color(Palette.c(Palette.land, h)))
        for k in 0..<7 {
            let ox = G.rnd(k, 41) * W
            let ow = W * (0.25 + 0.3 * G.rnd(k, 42)) * (0.4 + 0.6 * h / 100)
            G.ellipse(&surface, CGPoint(x: ox, y: hy + 10 + G.rnd(k, 43) * H * 0.22), ow / 2, ow * 0.08, Palette.c(Palette.ocean, h))
        }
        var lights = Path()
        for k in 0..<50 {
            lights.addRect(CGRect(x: G.rnd(k, 44) * W, y: hy + 6 + G.rnd(k, 45) * H * 0.25, width: 1.5, height: 1.5))
        }
        surface.fill(lights, with: .color(Color(red: 1, green: 0.86, blue: 0.55).opacity(0.7)))
        surface.fill(Path(CGRect(x: 0, y: hy - 10, width: W, height: H)), with: G.linear(CGPoint(x: 0, y: hy), CGPoint(x: 0, y: H), [(0, Color.black.opacity(0.05)), (1, Color(red: 0, green: 0, blue: 0.04).opacity(0.6))]))
        c.stroke(planet, with: .color(glow.col(0.9)), lineWidth: 3)
        let halo = Path(ellipseIn: CGRect(x: Double(pc.x) - R - 6, y: Double(pc.y) - R - 6, width: R * 2 + 12, height: R * 2 + 12))
        c.stroke(halo, with: .color(glow.col(0.25)), lineWidth: 10)
        G.vignette(&c, size, 0.35)
    }
}
