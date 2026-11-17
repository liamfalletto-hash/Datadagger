import SwiftUI

// The player's base, drawn in isometric 2.5D with SwiftUI Canvas.
// Stage 0 Bedroom → 1 Warehouse → 2 Server Hall → 3 Campus → 4 Horizon Megacenter.
// Stage 5 (Planetary Core) shows the globe from EarthView instead.
// The sky in every window and outdoor scene follows Earth Health.

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

    var body: some View {
        let state = BaseState(
            stage: min(game.locationStage, 4), owned: game.owned, health: game.health,
            income: game.incomePerSecond, pollution: game.pollutionPerSecond, overclock: game.isOverclocking
        )
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 100_000)
                BaseRenderer.draw(&context, size: size, time: t, state: state)
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
                        Text(s.text)
                            .font(.headline.weight(.heavy).monospacedDigit())
                            .foregroundStyle(.yellow)
                            .shadow(color: .black.opacity(0.7), radius: 2)
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
        let spark = Spark(text: "+◈" + Fmt.num(gained), at: point)
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

// MARK: - Isometric helper

struct Iso {
    var origin: CGPoint
    var s: CGFloat

    /// World (x to the lower right, y to the lower left, z up) → screen.
    func p(_ x: Double, _ y: Double, _ z: Double = 0) -> CGPoint {
        CGPoint(x: origin.x + CGFloat(x - y) * s * 0.866,
                y: origin.y + CGFloat(x + y) * s * 0.5 - CGFloat(z) * s)
    }

    func poly(_ pts: [CGPoint]) -> Path {
        var path = Path()
        path.addLines(pts)
        path.closeSubpath()
        return path
    }

    /// Flat rectangle on the floor (or at height z).
    func floor(_ x: Double, _ y: Double, _ w: Double, _ d: Double, z: Double = 0) -> Path {
        poly([p(x, y, z), p(x + w, y, z), p(x + w, y + d, z), p(x, y + d, z)])
    }

    /// Rectangle on the back-right wall (the plane y = 0).
    func wallR(_ x: Double, _ z: Double, _ w: Double, _ h: Double) -> Path {
        poly([p(x, 0, z), p(x + w, 0, z), p(x + w, 0, z + h), p(x, 0, z + h)])
    }

    /// Rectangle on the back-left wall (the plane x = 0).
    func wallL(_ y: Double, _ z: Double, _ d: Double, _ h: Double) -> Path {
        poly([p(0, y, z), p(0, y + d, z), p(0, y + d, z + h), p(0, y, z + h)])
    }

    func box(_ ctx: inout GraphicsContext, _ x: Double, _ y: Double, _ w: Double, _ d: Double, _ h: Double,
             z0: Double = 0, top: Color, left: Color, right: Color) {
        let z1 = z0 + h
        ctx.fill(poly([p(x, y + d, z0), p(x + w, y + d, z0), p(x + w, y + d, z1), p(x, y + d, z1)]), with: .color(left))
        ctx.fill(poly([p(x + w, y, z0), p(x + w, y + d, z0), p(x + w, y + d, z1), p(x + w, y, z1)]), with: .color(right))
        ctx.fill(floor(x, y, w, d, z: z1), with: .color(top))
    }

    /// Fits a room of w × d tiles with walls h high into the canvas, centered.
    static func fit(_ size: CGSize, w: Double, d: Double, h: Double) -> Iso {
        let s = min(size.width / CGFloat((w + d) * 0.866 * 1.06),
                    size.height / CGFloat((w + d) * 0.5 + h + 0.4))
        let ox = size.width / 2 - CGFloat(w - d) / 2 * s * 0.866
        let total = CGFloat((w + d) * 0.5 + h) * s
        let oy = (size.height - total) / 2 + CGFloat(h) * s
        return Iso(origin: CGPoint(x: ox, y: oy), s: s)
    }
}

// MARK: - Renderer

enum BaseRenderer {
    typealias Draw = (inout GraphicsContext) -> Void

    static func rnd(_ i: Int, _ salt: Double) -> Double { EarthRenderer.rnd(i, salt) }

    static func shade(_ c: RGB, _ f: Double) -> Color { RGB(c.r * f, c.g * f, c.b * f).color }

    static func draw(_ ctx: inout GraphicsContext, size: CGSize, time t: Double, state s: BaseState) {
        // Background behind the room: a dark studio color, or the sky outdoors.
        let rect = CGRect(origin: .zero, size: size)
        switch s.stage {
        case 0: bedroom(&ctx, size, t, s, rect)
        case 1: warehouse(&ctx, size, t, s, rect)
        case 2: serverHall(&ctx, size, t, s, rect)
        case 3: campus(&ctx, size, t, s, rect)
        default: horizon(&ctx, size, t, s, rect)
        }
    }

    private static func sortedDraw(_ ctx: inout GraphicsContext, _ items: [(depth: Double, draw: Draw)]) {
        for item in items.sorted(by: { $0.depth < $1.depth }) { item.draw(&ctx) }
    }

    private static func backdrop(_ ctx: inout GraphicsContext, _ rect: CGRect) {
        ctx.fill(Path(rect), with: .linearGradient(
            Gradient(colors: [Color(red: 0.10, green: 0.11, blue: 0.16), Color(red: 0.05, green: 0.05, blue: 0.08)]),
            startPoint: .zero, endPoint: CGPoint(x: 0, y: rect.height)))
    }

    /// A window showing the outside sky and a strip of land, colored by Earth Health.
    private static func window(_ ctx: inout GraphicsContext, _ path: Path, _ iso: Iso, top: CGPoint, bottom: CGPoint, health: Double, t: Double) {
        ctx.fill(path, with: .linearGradient(
            Gradient(colors: [Palette.c(Palette.skyTop, health), Palette.c(Palette.skyBottom, health)]),
            startPoint: top, endPoint: bottom))
        var inside = ctx
        inside.clip(to: path)
        let r = path.boundingRect
        // distant hills
        inside.fill(Path(ellipseIn: CGRect(x: r.minX - r.width * 0.2, y: r.maxY - r.height * 0.3, width: r.width * 1.4, height: r.height * 0.6)),
                    with: .color(Palette.c(Palette.land, health)))
        // a drifting cloud
        let cx = r.minX + (t * 6).truncatingRemainder(dividingBy: r.width + 40) - 20
        inside.fill(Path(ellipseIn: CGRect(x: cx, y: r.minY + r.height * 0.2, width: r.width * 0.35, height: r.height * 0.15)),
                    with: .color(Palette.c(Palette.cloud, health).opacity(0.8)))
        ctx.stroke(path, with: .color(.white.opacity(0.85)), lineWidth: max(1.5, iso.s * 0.06))
    }

    // MARK: Pieces

    private static func led(_ ctx: inout GraphicsContext, _ at: CGPoint, _ r: CGFloat, _ color: Color, _ on: Double) {
        ctx.fill(Path(ellipseIn: CGRect(x: at.x - r * 2, y: at.y - r * 2, width: r * 4, height: r * 4)), with: .color(color.opacity(0.18 * on)))
        ctx.fill(Path(ellipseIn: CGRect(x: at.x - r, y: at.y - r, width: r * 2, height: r * 2)), with: .color(color.opacity(0.35 + 0.65 * on)))
    }

    /// A server rack. style 0 = home server, 1 = GPU cluster (green), 2 = data hall rack (blue), 3 = hyperscale (white/cyan)
    private static func rack(_ ctx: inout GraphicsContext, _ iso: Iso, x: Double, y: Double, w: Double = 0.6, d: Double = 0.6, h: Double,
                             style: Int, t: Double, seed: Int, overclock: Bool) {
        let body: RGB
        let ledColor: Color
        switch style {
        case 1: body = RGB(0.20, 0.23, 0.22); ledColor = Color(red: 0.45, green: 1.0, blue: 0.45)
        case 2: body = RGB(0.12, 0.13, 0.17); ledColor = Color(red: 0.35, green: 0.75, blue: 1.0)
        case 3: body = RGB(0.78, 0.80, 0.84); ledColor = Color(red: 0.2, green: 0.95, blue: 1.0)
        default: body = RGB(0.30, 0.31, 0.35); ledColor = Color(red: 0.4, green: 1.0, blue: 0.6)
        }
        iso.box(&ctx, x, y, w, d, h, top: shade(body, 1.25), left: shade(body, 1.0), right: shade(body, 0.72))
        let color = overclock ? Color(red: 1, green: 0.35, blue: 0.2) : ledColor
        let rows = max(2, Int(h / 0.22))
        let r = max(0.8, iso.s * 0.03)
        for row in 0..<rows {
            let z = 0.15 + Double(row) * (h - 0.25) / Double(rows)
            for col in 0..<3 {
                let blink = 0.5 + 0.5 * sin(t * (overclock ? 18 : 3 + rnd(seed + row, Double(col)) * 5) + Double(seed * 7 + row * 3 + col))
                led(&ctx, iso.p(x + 0.12 + Double(col) * 0.16, y + d, z), r, color, blink > 0.55 ? 1 : 0.15)
            }
        }
        if style == 1 { // green stripe on top of GPU racks
            ctx.fill(iso.floor(x + 0.05, y + 0.25, w - 0.1, 0.1, z: h + 0.001), with: .color(ledColor.opacity(0.7)))
        }
    }

    /// A person. seated = at a desk (drawn from the waist up).
    private static func person(_ ctx: inout GraphicsContext, _ iso: Iso, x: Double, y: Double, t: Double, seed: Int,
                               shirt: Color, seated: Bool) {
        let bob = sin(t * (seated ? 7 : 3) + Double(seed)) * 0.015
        let base = seated ? 0.45 : 0.0
        if !seated {
            iso.box(&ctx, x - 0.1, y - 0.06, 0.2, 0.12, 0.45, top: .black, left: Color(red: 0.2, green: 0.22, blue: 0.3), right: Color(red: 0.15, green: 0.16, blue: 0.22))
        }
        iso.box(&ctx, x - 0.15, y - 0.1, 0.3, 0.2, 0.42, z0: base + (seated ? 0 : 0.45) + bob,
                top: shirt, left: shirt, right: shirt.opacity(0.8))
        let headZ = base + (seated ? 0 : 0.45) + 0.42 + 0.17 + bob
        let c = iso.p(x, y, headZ)
        let r = iso.s * 0.15
        ctx.fill(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)), with: .color(Color(red: 0.95, green: 0.78, blue: 0.62)))
        var hair = Path()
        hair.addArc(center: c, radius: r * 1.02, startAngle: .degrees(180), endAngle: .degrees(360), clockwise: false)
        hair.closeSubpath()
        ctx.fill(hair, with: .color(Color(red: 0.3, green: 0.2, blue: 0.12)))
    }

    private static func desk(_ ctx: inout GraphicsContext, _ iso: Iso, x: Double, y: Double, w: Double, monitors: Int, t: Double, overclock: Bool) {
        let wood = RGB(0.62, 0.45, 0.30)
        iso.box(&ctx, x, y, w, 0.8, 0.75, top: shade(wood, 1.15), left: shade(wood, 0.95), right: shade(wood, 0.75))
        for m in 0..<monitors {
            let mx = x + 0.2 + Double(m) * (w - 0.4) / Double(max(1, monitors))
            iso.box(&ctx, mx, y + 0.15, 0.5, 0.06, 0.38, z0: 0.82, top: .black, left: Color(white: 0.12), right: .black)
            let glow = overclock ? Color(red: 1, green: 0.4, blue: 0.3) : Color(red: 0.4, green: 0.85, blue: 1)
            let flicker = 0.75 + 0.25 * sin(t * 2 + Double(m))
            ctx.fill(iso.poly([iso.p(mx + 0.04, y + 0.21, 0.86), iso.p(mx + 0.46, y + 0.21, 0.86),
                               iso.p(mx + 0.46, y + 0.21, 1.16), iso.p(mx + 0.04, y + 0.21, 1.16)]),
                     with: .color(glow.opacity(flicker)))
        }
    }

    private static func smoke(_ ctx: inout GraphicsContext, from base: CGPoint, height: CGFloat, count: Int, t: Double, health: Double, seed: Int, spread: CGFloat) {
        let color = Palette.c(Palette.smoke, health)
        for i in 0..<count {
            let speed = 0.12 + 0.08 * rnd(seed + i, 2)
            let p = (t * speed + rnd(seed + i, 3)).truncatingRemainder(dividingBy: 1)
            let x = base.x + CGFloat(sin(t + Double(i)) * 4 * p) + CGFloat(p) * spread * CGFloat(rnd(seed + i, 4) - 0.2)
            let y = base.y - CGFloat(p) * height
            let r = 3 + CGFloat(p) * height * 0.18
            ctx.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)),
                     with: .color(color.opacity((1 - p) * 0.5)))
        }
    }

    // MARK: Stage 0: Bedroom

    private static func bedroom(_ ctx: inout GraphicsContext, _ size: CGSize, _ t: Double, _ s: BaseState, _ rect: CGRect) {
        backdrop(&ctx, rect)
        let W = 6.0, D = 6.0, H = 3.0
        let iso = Iso.fit(size, w: W, d: D, h: H)

        // Floor (wood planks) and walls
        let wood = RGB(0.56, 0.39, 0.26)
        ctx.fill(iso.floor(0, 0, W, D), with: .color(wood.color))
        for k in 1..<12 {
            var line = Path()
            line.move(to: iso.p(0, Double(k) * 0.5))
            line.addLine(to: iso.p(W, Double(k) * 0.5))
            ctx.stroke(line, with: .color(shade(wood, 0.8).opacity(0.6)), lineWidth: 1)
        }
        ctx.fill(iso.wallL(0, 0, D, H), with: .color(Color(red: 0.47, green: 0.52, blue: 0.66)))
        ctx.fill(iso.wallR(0, 0, W, H), with: .color(Color(red: 0.58, green: 0.63, blue: 0.77)))
        ctx.fill(iso.wallR(0, 0, W, 0.15), with: .color(.white.opacity(0.5))) // skirting
        ctx.fill(iso.wallL(0, 0, D, 0.15), with: .color(.white.opacity(0.4)))

        // Window (right wall) and a poster (left wall)
        window(&ctx, iso.wallR(2.6, 1.3, 1.6, 1.2), iso, top: iso.p(3.4, 0, 2.5), bottom: iso.p(3.4, 0, 1.3), health: s.health, t: t)
        ctx.fill(iso.wallL(2.2, 1.4, 0.9, 1.1), with: .color(Color(red: 0.95, green: 0.55, blue: 0.3)))
        ctx.fill(iso.wallL(2.35, 1.6, 0.6, 0.5), with: .color(Color(red: 0.2, green: 0.2, blue: 0.3)))
        // Shelf with books on the left wall
        iso.box(&ctx, 0, 4.2, 0.35, 1.2, 0.06, z0: 1.9, top: shade(wood, 1.2), left: shade(wood, 1), right: shade(wood, 0.8))
        for b in 0..<5 {
            let colors: [Color] = [.red, .blue, .yellow, .green, .purple]
            iso.box(&ctx, 0.05, 4.3 + Double(b) * 0.2, 0.22, 0.14, 0.32, z0: 1.96, top: colors[b].opacity(0.7), left: colors[b].opacity(0.9), right: colors[b].opacity(0.6))
        }

        // Rug
        ctx.fill(iso.floor(1.6, 2.0, 3.0, 2.6), with: .color(Color(red: 0.16, green: 0.42, blue: 0.46)))
        ctx.stroke(iso.floor(1.8, 2.2, 2.6, 2.2), with: .color(.white.opacity(0.25)), lineWidth: 1.5)

        var items: [(depth: Double, draw: Draw)] = []
        items.append((depth: 1.0, draw: { (c: inout GraphicsContext) in desk(&c, iso, x: 0.3, y: 0.3, w: 1.9, monitors: 1, t: t, overclock: s.overclock) }))
        items.append((depth: 2.9, draw: { (c: inout GraphicsContext) in
            iso.box(&c, 0.95, 1.45, 0.5, 0.5, 0.42, top: Color(red: 0.8, green: 0.2, blue: 0.25), left: Color(red: 0.6, green: 0.12, blue: 0.18), right: Color(red: 0.45, green: 0.1, blue: 0.14))
            person(&c, iso, x: 1.2, y: 1.6, t: t, seed: 1, shirt: Color(red: 0.95, green: 0.6, blue: 0.2), seated: true)
        }))
        // Bed along the left wall
        items.append((depth: 4.6, draw: { (c: inout GraphicsContext) in
            iso.box(&c, 0.1, 3.9, 1.4, 2.0, 0.45, top: Color(red: 0.85, green: 0.86, blue: 0.92), left: Color(red: 0.55, green: 0.4, blue: 0.3), right: Color(red: 0.45, green: 0.32, blue: 0.24))
            c.fill(iso.floor(0.1, 4.6, 1.4, 1.3, z: 0.46), with: .color(Color(red: 0.35, green: 0.45, blue: 0.8)))
        }))
        // Servers on the floor by the window: up to 4 before you move out.
        let slots: [(Double, Double)] = [(4.5, 0.35), (5.2, 0.35), (4.5, 1.15), (5.2, 1.15)]
        let racks = min(s.owned[0], slots.count)
        for k in 0..<racks {
            let (x, y) = slots[k]
            items.append((depth: x + y + 0.6, draw: { (c: inout GraphicsContext) in rack(&c, iso, x: x, y: y, h: 1.0, style: 0, t: t, seed: k, overclock: s.overclock) }))
        }
        sortedDraw(&ctx, items)

        if racks == 0 {
            let p = iso.p(4.9, 0.9, 0.3)
            ctx.draw(Text("Buy your first server →").font(.caption2.weight(.bold)).foregroundColor(.white.opacity(0.8)), at: p)
        }
    }

    // MARK: Stage 1: Warehouse

    private static func warehouse(_ ctx: inout GraphicsContext, _ size: CGSize, _ t: Double, _ s: BaseState, _ rect: CGRect) {
        backdrop(&ctx, rect)
        let W = 10.0, D = 10.0, H = 3.6
        let iso = Iso.fit(size, w: W, d: D, h: H)

        ctx.fill(iso.floor(0, 0, W, D), with: .color(Color(red: 0.45, green: 0.46, blue: 0.48)))
        ctx.stroke(iso.floor(1.6, 0.6, 7.8, 8.6), with: .color(Color.yellow.opacity(0.7)), lineWidth: 2)
        // corrugated metal walls
        ctx.fill(iso.wallL(0, 0, D, H), with: .color(Color(red: 0.42, green: 0.48, blue: 0.55)))
        ctx.fill(iso.wallR(0, 0, W, H), with: .color(Color(red: 0.52, green: 0.58, blue: 0.65)))
        for k in 1..<20 {
            var a = Path(); a.move(to: iso.p(Double(k) * 0.5, 0, 0)); a.addLine(to: iso.p(Double(k) * 0.5, 0, H))
            ctx.stroke(a, with: .color(.black.opacity(0.12)), lineWidth: 1)
            var b = Path(); b.move(to: iso.p(0, Double(k) * 0.5, 0)); b.addLine(to: iso.p(0, Double(k) * 0.5, H))
            ctx.stroke(b, with: .color(.black.opacity(0.12)), lineWidth: 1)
        }
        // high window strip and a roll-up door
        window(&ctx, iso.wallR(1.5, 2.5, 7, 0.7), iso, top: iso.p(5, 0, 3.2), bottom: iso.p(5, 0, 2.5), health: s.health, t: t)
        ctx.fill(iso.wallL(6, 0, 2.6, 2.3), with: .color(Color(red: 0.62, green: 0.64, blue: 0.66)))
        for k in 0..<8 {
            var l = Path(); l.move(to: iso.p(0, 6, Double(k) * 0.29)); l.addLine(to: iso.p(0, 8.6, Double(k) * 0.29))
            ctx.stroke(l, with: .color(.black.opacity(0.25)), lineWidth: 1)
        }
        // ceiling lamps
        for k in 0..<3 {
            let p = iso.p(2.5 + Double(k) * 2.5, 3 + Double(k) * 1.5, H)
            ctx.fill(Path(ellipseIn: CGRect(x: p.x - iso.s, y: p.y - iso.s * 0.3, width: iso.s * 2, height: iso.s * 0.6)), with: .color(.white.opacity(0.12)))
        }

        var items: [(depth: Double, draw: Draw)] = []
        items.append((depth: 0.9, draw: { (c: inout GraphicsContext) in desk(&c, iso, x: 0.3, y: 0.3, w: 2.0, monitors: 2, t: t, overclock: s.overclock) }))
        items.append((depth: 2.6, draw: { (c: inout GraphicsContext) in person(&c, iso, x: 1.3, y: 1.4, t: t, seed: 1, shirt: Color(red: 0.95, green: 0.6, blue: 0.2), seated: true) }))
        // cardboard boxes by the door
        for b in 0..<4 {
            let bx = 0.3 + Double(b % 2) * 0.6, by = 8.8 + Double(b / 2) * 0.6
            items.append((depth: bx + by, draw: { (c: inout GraphicsContext) in iso.box(&c, bx, by, 0.55, 0.55, 0.45, top: Color(red: 0.8, green: 0.62, blue: 0.4), left: Color(red: 0.68, green: 0.5, blue: 0.32), right: Color(red: 0.56, green: 0.4, blue: 0.25)) }))
        }
        // racks and GPU clusters in rows
        let homeRacks = min(s.owned[0], 24)
        let gpus = min(s.owned[1], 24)
        let total = homeRacks + gpus
        for k in 0..<total {
            let row = k / 8, col = k % 8
            let x = 2.2 + Double(col) * 0.85
            let y = 1.2 + Double(row) * 1.7
            let style = k < homeRacks ? 0 : 1
            items.append((depth: x + y + 0.6, draw: { (c: inout GraphicsContext) in rack(&c, iso, x: x, y: y, h: style == 1 ? 1.3 : 1.0, style: style, t: t, seed: k, overclock: s.overclock) }))
        }
        // helpers walking the aisles
        let helpers = min(3, s.owned[1] / 10)
        for k in 0..<helpers {
            let y = 2.3 + Double(k) * 1.7
            let x = 2.4 + (sin(t * 0.3 + Double(k)) * 0.5 + 0.5) * 6.0
            items.append((depth: x + y, draw: { (c: inout GraphicsContext) in person(&c, iso, x: x, y: y, t: t, seed: 5 + k, shirt: Color(red: 0.3, green: 0.7, blue: 0.95), seated: false) }))
        }
        sortedDraw(&ctx, items)
    }

    // MARK: Stage 2: Server Hall

    private static func serverHall(_ ctx: inout GraphicsContext, _ size: CGSize, _ t: Double, _ s: BaseState, _ rect: CGRect) {
        backdrop(&ctx, rect)
        let W = 12.0, D = 12.0, H = 3.8
        let iso = Iso.fit(size, w: W, d: D, h: H)

        // raised floor tiles
        ctx.fill(iso.floor(0, 0, W, D), with: .color(Color(red: 0.70, green: 0.72, blue: 0.75)))
        for k in 1..<Int(W) {
            var a = Path(); a.move(to: iso.p(Double(k), 0)); a.addLine(to: iso.p(Double(k), D))
            var b = Path(); b.move(to: iso.p(0, Double(k))); b.addLine(to: iso.p(W, Double(k)))
            ctx.stroke(a, with: .color(.black.opacity(0.15)), lineWidth: 1)
            ctx.stroke(b, with: .color(.black.opacity(0.15)), lineWidth: 1)
        }
        ctx.fill(iso.wallL(0, 0, D, H), with: .color(Color(red: 0.16, green: 0.18, blue: 0.24)))
        ctx.fill(iso.wallR(0, 0, W, H), with: .color(Color(red: 0.20, green: 0.22, blue: 0.29)))
        ctx.fill(iso.wallR(0, 2.6, W, 0.08), with: .color(Palette.accent.opacity(0.8)))
        ctx.fill(iso.wallL(0, 2.6, D, 0.08), with: .color(Palette.accent.opacity(0.6)))
        window(&ctx, iso.wallR(8.5, 1.2, 2.5, 1.2), iso, top: iso.p(9.7, 0, 2.4), bottom: iso.p(9.7, 0, 1.2), health: s.health, t: t)

        let racksVisible = min(66, 8 + s.owned[2] * 3 + s.owned[1] / 3)
        let perRow = 11
        let rows = (racksVisible + perRow - 1) / perRow
        // cold aisles glow between rows
        for r in 0..<rows {
            let y = 1.9 + Double(r) * 1.7
            ctx.fill(iso.floor(1.6, y, Double(perRow) * 0.85, 0.5), with: .color(Palette.accent.opacity(0.10 + 0.05 * sin(t * 2 + Double(r)))))
        }

        var items: [(depth: Double, draw: Draw)] = []
        items.append((depth: 0.9, draw: { (c: inout GraphicsContext) in desk(&c, iso, x: 0.3, y: 0.3, w: 2.4, monitors: 3, t: t, overclock: s.overclock) }))
        items.append((depth: 2.8, draw: { (c: inout GraphicsContext) in person(&c, iso, x: 1.5, y: 1.4, t: t, seed: 1, shirt: Color(red: 0.95, green: 0.6, blue: 0.2), seated: true) }))
        for k in 0..<racksVisible {
            let row = k / perRow, col = k % perRow
            let x = 1.7 + Double(col) * 0.85
            let y = 1.2 + Double(row) * 1.7
            items.append((depth: x + y + 0.6, draw: { (c: inout GraphicsContext) in rack(&c, iso, x: x, y: y, h: 1.7, style: 2, t: t, seed: k, overclock: s.overclock) }))
        }
        let staff = min(5, 1 + s.owned[2] / 8)
        for k in 0..<staff {
            let y = 2.1 + Double(k % max(1, rows)) * 1.7
            let x = 1.8 + (sin(t * 0.25 + Double(k) * 1.7) * 0.5 + 0.5) * 8.5
            items.append((depth: x + y, draw: { (c: inout GraphicsContext) in person(&c, iso, x: x, y: y, t: t, seed: 9 + k, shirt: .white, seated: false) }))
        }
        sortedDraw(&ctx, items)
    }

    // MARK: Stage 3: Campus (outdoors)

    private static func campus(_ ctx: inout GraphicsContext, _ size: CGSize, _ t: Double, _ s: BaseState, _ rect: CGRect) {
        let h = s.health
        ctx.fill(Path(rect), with: .linearGradient(
            Gradient(colors: [Palette.c(Palette.skyTop, h), Palette.c(Palette.skyBottom, h)]),
            startPoint: .zero, endPoint: CGPoint(x: 0, y: rect.height)))
        let W = 14.0, D = 14.0
        let iso = Iso.fit(size, w: W, d: D, h: 2.5)
        let landColor = Palette.rgb(Palette.land, h)

        ctx.fill(iso.floor(0, 0, W, D), with: .color(landColor.color))
        // ground thickness
        iso.box(&ctx, 0, 0, W, D, 0.4, z0: -0.4, top: landColor.color, left: shade(landColor, 0.6), right: shade(landColor, 0.45))
        // river across the site
        ctx.fill(iso.floor(0, 11.2, W, 1.1), with: .color(Palette.c(Palette.ocean, h)))
        // road
        ctx.fill(iso.floor(0, 6.6, W, 0.7), with: .color(Color(white: 0.3)))

        var items: [(depth: Double, draw: Draw)] = []
        // Trees thin out as Health falls.
        let trees = Int(h / 100 * 34)
        for k in 0..<trees {
            let x = rnd(k, 21) * (W - 0.6) + 0.3
            let y = [rnd(k, 22) * 1.2 + 9.7, rnd(k, 23) * 1.4 + 12.4, rnd(k, 24) * 0.6 + 0.2][k % 3]
            guard y < D - 0.2 else { continue }
            items.append((depth: x + y, draw: { (c: inout GraphicsContext) in
                iso.box(&c, x - 0.05, y - 0.05, 0.1, 0.1, 0.3, top: .brown, left: .brown, right: .brown)
                let p = iso.p(x, y, 0.55)
                let r = iso.s * 0.32
                c.fill(Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2)), with: .color(Palette.c(Palette.landDetail, h)))
            }))
        }
        // Data halls, one per few buildings owned
        let halls = min(12, 1 + s.owned[3] + s.owned[2] / 10)
        for k in 0..<halls {
            let col = k % 4, row = k / 4
            let x = 0.6 + Double(col) * 3.3
            let y = row == 0 ? 1.3 : (row == 1 ? 4.0 : 7.7)
            items.append((depth: x + y + 2, draw: { (c: inout GraphicsContext) in
                iso.box(&c, x, y, 2.6, 1.8, 0.9, top: Color(white: 0.85), left: Color(white: 0.72), right: Color(white: 0.58))
                for u in 0..<3 { // rooftop cooling units
                    iso.box(&c, x + 0.3 + Double(u) * 0.75, y + 0.5, 0.5, 0.5, 0.2, z0: 0.9, top: Color(white: 0.55), left: Color(white: 0.45), right: Color(white: 0.38))
                }
                for wdw in 0..<5 { // lit window strip
                    let blink = 0.6 + 0.4 * sin(t * 2 + Double(k * 5 + wdw))
                    c.fill(iso.poly([iso.p(x + 0.2 + Double(wdw) * 0.48, y + 1.8, 0.45), iso.p(x + 0.5 + Double(wdw) * 0.48, y + 1.8, 0.45),
                                     iso.p(x + 0.5 + Double(wdw) * 0.48, y + 1.8, 0.65), iso.p(x + 0.2 + Double(wdw) * 0.48, y + 1.8, 0.65)]),
                           with: .color(Palette.accent.opacity(blink)))
                }
            }))
        }
        // Cooling towers with smoke
        let towers = min(4, 1 + s.owned[3] / 5)
        for k in 0..<towers {
            let x = 1.5 + Double(k) * 3.2, y = 10.2
            items.append((depth: x + y + 1, draw: { (c: inout GraphicsContext) in
                iso.box(&c, x, y - 0.6, 0.8, 0.8, 1.6, top: Color(white: 0.5), left: Color(white: 0.78), right: Color(white: 0.62))
            }))
        }
        sortedDraw(&ctx, items)
        let puffs = Int(min(24, log10(s.pollution * 50 + 1) * 8))
        for k in 0..<towers {
            smoke(&ctx, from: iso.p(1.9 + Double(k) * 3.2, 10.0, 1.6), height: iso.s * 3, count: puffs, t: t, health: h, seed: k * 50, spread: iso.s)
        }
    }

    // MARK: Stage 4: Horizon Megacenter

    private static func horizon(_ ctx: inout GraphicsContext, _ size: CGSize, _ t: Double, _ s: BaseState, _ rect: CGRect) {
        let h = s.health
        ctx.fill(Path(rect), with: .linearGradient(
            Gradient(colors: [Palette.c(Palette.skyTop, h).opacity(1), Color.black.opacity(0.9), Palette.c(Palette.glow, h)]),
            startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: 0, y: size.height * 0.75)))
        // stars fade in above the atmosphere
        for k in 0..<40 {
            let p = CGPoint(x: rnd(k, 31) * size.width, y: rnd(k, 32) * size.height * 0.45)
            let tw = 0.4 + 0.6 * (0.5 + 0.5 * sin(t * 2 + Double(k)))
            ctx.fill(Path(ellipseIn: CGRect(x: p.x, y: p.y, width: 1.6, height: 1.6)), with: .color(.white.opacity(0.6 * tw)))
        }

        let horizonY = size.height * 0.72
        let R = size.width * 1.6
        let planetCenter = CGPoint(x: size.width / 2, y: horizonY + R)

        // The megacenter rises from behind the curve; bigger with every high tier you own.
        let mass = Double(s.owned[4] + s.owned[5] * 2 + s.owned[6] * 4)
        let grow = 0.35 + 0.65 * min(1, mass / 120)
        let baseW = size.width * 0.55 * grow
        let topH = size.height * 0.5 * grow
        let cx = size.width / 2
        let blocks: [(dx: Double, w: Double, h: Double)] = [(-0.42, 0.18, 0.45), (-0.22, 0.2, 0.75), (0, 0.24, 1.0), (0.22, 0.2, 0.7), (0.42, 0.18, 0.5)]
        for (i, b) in blocks.enumerated() {
            let w = baseW * b.w
            let x = cx + baseW * b.dx - w / 2
            let height = topH * b.h
            let r = CGRect(x: x, y: horizonY + 10 - height, width: w, height: height + 20)
            ctx.fill(Path(r), with: .linearGradient(Gradient(colors: [Color(white: 0.22), Color(white: 0.08)]),
                                                     startPoint: CGPoint(x: r.minX, y: r.minY), endPoint: CGPoint(x: r.maxX, y: r.maxY)))
            // window grid
            let cols = 4, rows = max(3, Int(height / 9))
            for row in 0..<rows {
                for col in 0..<cols {
                    let on = sin(t * 1.5 + Double(i * 31 + row * 7 + col * 3)) > -0.2
                    guard on else { continue }
                    let wx = r.minX + w * (0.12 + 0.22 * CGFloat(col))
                    let wy = r.minY + 5 + CGFloat(row) * (height - 6) / CGFloat(rows)
                    ctx.fill(Path(CGRect(x: wx, y: wy, width: w * 0.12, height: 2.2)),
                             with: .color((s.overclock ? Color.red : Palette.accent).opacity(0.85)))
                }
            }
            // smoke stacks on the outer blocks
            if i != 2 {
                smoke(&ctx, from: CGPoint(x: r.midX, y: r.minY), height: size.height * 0.35, count: Int(min(20, log10(s.pollution + 1) * 5)),
                      t: t, health: h, seed: i * 40, spread: 30)
            }
        }
        // antenna with a blinking light
        let tipY = horizonY + 10 - topH - 26
        var antenna = Path(); antenna.move(to: CGPoint(x: cx, y: horizonY - topH)); antenna.addLine(to: CGPoint(x: cx, y: tipY))
        ctx.stroke(antenna, with: .color(Color(white: 0.5)), lineWidth: 2)
        let blink = sin(t * 4) > 0 ? 1.0 : 0.2
        ctx.fill(Path(ellipseIn: CGRect(x: cx - 3, y: tipY - 3, width: 6, height: 6)), with: .color(.red.opacity(blink)))

        // The planet's curve in front hides the base of the megacenter.
        let planet = Path(ellipseIn: CGRect(x: planetCenter.x - R, y: planetCenter.y - R, width: R * 2, height: R * 2))
        ctx.fill(planet, with: .color(Palette.c(Palette.land, h)))
        var surface = ctx
        surface.clip(to: planet)
        for k in 0..<6 { // oceans, shrinking with Health
            let ox = rnd(k, 41) * size.width
            let ow = size.width * (0.25 + 0.3 * rnd(k, 42)) * (0.4 + 0.6 * h / 100)
            surface.fill(Path(ellipseIn: CGRect(x: ox - ow / 2, y: horizonY + 8 + rnd(k, 43) * size.height * 0.2, width: ow, height: ow * 0.18)),
                         with: .color(Palette.c(Palette.ocean, h)))
        }
        surface.fill(planet, with: .linearGradient(Gradient(colors: [.clear, .black.opacity(0.45)]),
                                                   startPoint: CGPoint(x: 0, y: horizonY), endPoint: CGPoint(x: 0, y: size.height)))
        // atmosphere rim
        ctx.stroke(planet, with: .color(Palette.c(Palette.glow, h).opacity(0.8)), lineWidth: 3)
    }
}
