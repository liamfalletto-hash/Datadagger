import SwiftUI

// The living planet. Everything here is driven by Earth Health (colors) and by
// income/pollution on a log scale (lights, smoke). The economy never depends on it.
// This is a SwiftUI Canvas stand-in for the Metal fluid simulation planned for weeks 5–6.

struct RGB {
    var r: Double, g: Double, b: Double
    init(_ r: Double, _ g: Double, _ b: Double) { self.r = r; self.g = g; self.b = b }
    var color: Color { Color(red: r, green: g, blue: b) }
    static func mix(_ a: RGB, _ b: RGB, _ t: Double) -> RGB {
        let t = max(0, min(1, t))
        return RGB(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t)
    }
}

/// Colors as (Verdant, Smog, Ash). They blend continuously with Health: no hard cuts.
enum Palette {
    typealias Triple = (verdant: RGB, smog: RGB, ash: RGB)

    static let skyTop: Triple     = (RGB(0.18, 0.42, 0.78), RGB(0.30, 0.31, 0.33), RGB(0.42, 0.14, 0.05))
    static let skyBottom: Triple  = (RGB(0.62, 0.82, 0.97), RGB(0.58, 0.55, 0.48), RGB(0.93, 0.50, 0.20))
    static let ocean: Triple      = (RGB(0.10, 0.42, 0.78), RGB(0.24, 0.34, 0.26), RGB(0.40, 0.36, 0.22))
    static let land: Triple       = (RGB(0.27, 0.62, 0.30), RGB(0.45, 0.46, 0.42), RGB(0.70, 0.52, 0.32))
    static let landDetail: Triple = (RGB(0.13, 0.42, 0.18), RGB(0.32, 0.33, 0.32), RGB(0.45, 0.30, 0.18))
    static let cloud: Triple      = (RGB(1.00, 1.00, 1.00), RGB(0.55, 0.55, 0.52), RGB(0.85, 0.55, 0.30))
    static let smoke: Triple      = (RGB(0.92, 0.93, 0.95), RGB(0.30, 0.29, 0.27), RGB(0.22, 0.17, 0.14))
    static let rain: Triple       = (RGB(0.85, 0.92, 1.00), RGB(0.75, 0.82, 0.45), RGB(0.55, 0.50, 0.45))
    static let glow: Triple       = (RGB(0.55, 0.80, 1.00), RGB(0.60, 0.60, 0.55), RGB(1.00, 0.55, 0.25))

    static func rgb(_ c: Triple, _ health: Double) -> RGB {
        let h = max(0, min(1, health / 100))
        return h >= 0.5 ? RGB.mix(c.smog, c.verdant, (h - 0.5) / 0.5) : RGB.mix(c.ash, c.smog, h / 0.5)
    }
    static func c(_ c: Triple, _ health: Double) -> Color { rgb(c, health).color }

    static let accent = Color(red: 0.35, green: 0.85, blue: 0.95)
    static let background = Color(red: 0.05, green: 0.06, blue: 0.08)
    static let sheet = Color(red: 0.09, green: 0.10, blue: 0.12)
    static let card = Color.white.opacity(0.06)
}

struct EarthState {
    let health: Double
    let income: Double
    let pollution: Double
    let owned: [Int]
    let overclock: Bool
    let heatwave: Bool
}

struct EarthView: View {
    @EnvironmentObject var game: Game
    @State private var sparks: [Spark] = []

    struct Spark: Identifiable {
        let id = UUID()
        let text: String
        let at: CGPoint
        var rise = false
    }

    var body: some View {
        let state = EarthState(
            health: game.health, income: game.incomePerSecond, pollution: game.pollutionPerSecond,
            owned: game.owned, overclock: game.isOverclocking, heatwave: game.isHeatwave
        )
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 100_000)
                EarthRenderer.draw(&context, size: size, time: t, state: state)
            }
        }
        .overlay {
            ZStack {
                ForEach(sparks) { s in
                    Text(s.text)
                        .font(.headline.weight(.heavy).monospacedDigit())
                        .foregroundStyle(.yellow)
                        .shadow(color: .black.opacity(0.6), radius: 2)
                        .position(x: s.at.x, y: s.at.y - (s.rise ? 70 : 0))
                        .opacity(s.rise ? 0 : 1)
                }
            }
            .allowsHitTesting(false)
        }
        .contentShape(Rectangle())
        .gesture(SpatialTapGesture().onEnded { value in tap(at: value.location) })
        .accessibilityElement()
        .accessibilityLabel("Earth, \(Int(game.health))% health. Tap to answer queries.")
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

enum EarthRenderer {
    /// Stable pseudo-random number in 0..<1 for particle i.
    static func rnd(_ i: Int, _ salt: Double) -> Double {
        let x = sin(Double(i) * 12.9898 + salt * 78.233) * 43758.5453
        return x - floor(x)
    }

    struct Continent { let lon: Double; let lat: Double; let w: Double; let h: Double }
    static let continents: [Continent] = [
        Continent(lon: 0.0, lat: -0.30, w: 0.55, h: 0.35),
        Continent(lon: 1.3, lat: 0.20, w: 0.45, h: 0.50),
        Continent(lon: 2.4, lat: -0.10, w: 0.60, h: 0.30),
        Continent(lon: 3.6, lat: 0.35, w: 0.35, h: 0.25),
        Continent(lon: 4.7, lat: -0.25, w: 0.50, h: 0.40),
        Continent(lon: 5.6, lat: 0.10, w: 0.30, h: 0.45),
    ]

    static func draw(_ ctx: inout GraphicsContext, size: CGSize, time t: Double, state s: EarthState) {
        let h = s.health
        let rect = CGRect(origin: .zero, size: size)

        // Sky
        ctx.fill(Path(rect), with: .linearGradient(
            Gradient(colors: [Palette.c(Palette.skyTop, h), Palette.c(Palette.skyBottom, h)]),
            startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)))

        let R = min(size.width, size.height) * 0.36
        let center = CGPoint(x: size.width / 2, y: size.height * 0.56)
        let rot = t * 0.06

        // Atmosphere glow
        let glowR = R * 1.15
        ctx.fill(Path(ellipseIn: CGRect(x: center.x - glowR, y: center.y - glowR, width: glowR * 2, height: glowR * 2)),
                 with: .radialGradient(Gradient(colors: [Palette.c(Palette.glow, h).opacity(0.55), .clear]),
                                       center: center, startRadius: R * 0.95, endRadius: glowR))

        // Globe
        let globeRect = CGRect(x: center.x - R, y: center.y - R, width: R * 2, height: R * 2)
        let globe = Path(ellipseIn: globeRect)
        ctx.fill(globe, with: .color(Palette.c(Palette.ocean, h)))

        var surface = ctx
        surface.clip(to: globe)
        drawOceanShimmer(&surface, center: center, R: R, t: t, h: h)
        drawLand(&surface, center: center, R: R, rot: rot, h: h)
        drawBuildings(&surface, center: center, R: R, rot: rot, t: t, s: s)
        // Night-side shading for a round look
        surface.fill(globe, with: .radialGradient(
            Gradient(colors: [.clear, .black.opacity(0.5)]),
            center: CGPoint(x: center.x - R * 0.35, y: center.y - R * 0.4),
            startRadius: R * 0.2, endRadius: R * 1.5))

        drawSmoke(&ctx, center: center, R: R, rot: rot, t: t, s: s)
        drawClouds(&ctx, size: size, t: t, h: h)
        drawWeather(&ctx, size: size, t: t, h: h)

        if s.overclock {
            let pulse = 0.5 + 0.5 * sin(t * 12)
            let ringR = R * 1.04
            ctx.stroke(Path(ellipseIn: CGRect(x: center.x - ringR, y: center.y - ringR, width: ringR * 2, height: ringR * 2)),
                       with: .color(.red.opacity(0.4 + 0.5 * pulse)), lineWidth: 3 + 3 * pulse)
        }
        if s.heatwave {
            ctx.fill(Path(rect), with: .color(.orange.opacity(0.12 + 0.06 * sin(t * 3))))
        }
    }

    private static func drawOceanShimmer(_ ctx: inout GraphicsContext, center: CGPoint, R: Double, t: Double, h: Double) {
        // Sparkles fade out as the water gets dirty.
        let strength = max(0, (h - 40) / 60)
        guard strength > 0 else { return }
        for i in 0..<24 {
            let a = rnd(i, 1) * .pi * 2 + t * 0.06
            let z = cos(a)
            guard z > 0 else { continue }
            let x = center.x + R * sin(a) * 0.9
            let y = center.y + R * (rnd(i, 2) * 1.6 - 0.8)
            let blink = 0.5 + 0.5 * sin(t * 3 + Double(i))
            let r = 1.5 + blink
            ctx.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)),
                     with: .color(.white.opacity(0.5 * blink * strength * z)))
        }
    }

    private static func drawLand(_ ctx: inout GraphicsContext, center: CGPoint, R: Double, rot: Double, h: Double) {
        let grow = 1 + (1 - h / 100) * 0.7 // oceans recede as Health falls
        let land = Palette.c(Palette.land, h)
        let detail = Palette.c(Palette.landDetail, h)
        for c in continents {
            let a = c.lon + rot
            let z = cos(a)
            guard z > -0.25 else { continue }
            let x = center.x + R * sin(a) * 0.95
            let y = center.y + R * c.lat
            let w = R * c.w * grow * max(0.15, z)
            let hh = R * c.h * grow
            ctx.fill(Path(ellipseIn: CGRect(x: x - w / 2, y: y - hh / 2, width: w, height: hh)), with: .color(land))
            ctx.fill(Path(ellipseIn: CGRect(x: x - w * 0.25, y: y - hh * 0.2, width: w * 0.45, height: hh * 0.4)),
                     with: .color(detail))
        }
    }

    private static func drawBuildings(_ ctx: inout GraphicsContext, center: CGPoint, R: Double, rot: Double, t: Double, s: EarthState) {
        let brightness = min(1, 0.35 + log10(s.income + 1) / 9)
        for (tier, count) in s.owned.enumerated() where count > 0 {
            let markers = min(8, Int(log2(Double(count) + 1) * 1.5))
            for k in 0..<markers {
                let seed = tier * 31 + k
                let c = continents[seed % continents.count]
                let a = c.lon + rot + (rnd(seed, 3) - 0.5) * 0.4
                let z = cos(a)
                guard z > 0.05 else { continue }
                let x = center.x + R * sin(a) * 0.95
                let y = center.y + R * (c.lat + (rnd(seed, 4) - 0.5) * c.h * 0.8)
                let size = (2.5 + Double(tier) * 0.9) * (0.5 + 0.5 * z)
                ctx.fill(Path(CGRect(x: x - size / 2, y: y - size, width: size, height: size * 1.4)),
                         with: .color(Color(white: 0.15)))
                let blink = 0.7 + 0.3 * sin(t * 4 + Double(seed))
                let lr = size * 0.9
                ctx.fill(Path(ellipseIn: CGRect(x: x - lr, y: y - size / 2 - lr, width: lr * 2, height: lr * 2)),
                         with: .color(Color(red: 1, green: 0.95, blue: 0.6).opacity(0.35 * brightness * blink)))
                ctx.fill(Path(ellipseIn: CGRect(x: x - 1, y: y - size / 2 - 1, width: 2, height: 2)),
                         with: .color(Color(red: 0.6, green: 1, blue: 1).opacity(brightness)))
            }
        }
    }

    private static func drawSmoke(_ ctx: inout GraphicsContext, center: CGPoint, R: Double, rot: Double, t: Double, s: EarthState) {
        let count = Int(min(90, log10(s.pollution * 100 + 1) * 18))
        guard count > 0 else { return }
        let color = Palette.c(Palette.smoke, s.health)
        for i in 0..<count {
            let e = rnd(i, 1) * 2.4 - 1.2 + sin(rot + Double(i)) * 0.15 // emitter around the top of the globe
            let x0 = center.x + R * sin(e) * 0.85
            let y0 = center.y - R * cos(e) * 0.92
            let speed = 0.10 + 0.08 * rnd(i, 2)
            let p = (t * speed + rnd(i, 3)).truncatingRemainder(dividingBy: 1)
            let x = x0 + sin(t * 0.8 + Double(i)) * 8 * p + p * 30 * (rnd(i, 4) - 0.3)
            let y = y0 - p * R * 0.9
            let r = 3 + p * 16
            ctx.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)),
                     with: .color(color.opacity((1 - p) * 0.45)))
        }
    }

    private static func drawClouds(_ ctx: inout GraphicsContext, size: CGSize, t: Double, h: Double) {
        let color = Palette.c(Palette.cloud, h)
        let span = size.width + 240
        for i in 0..<6 {
            let speed = 8 + 14 * rnd(i, 5)
            let x = (rnd(i, 6) * span + t * speed).truncatingRemainder(dividingBy: span) - 120
            let y = size.height * (0.08 + 0.35 * rnd(i, 7))
            let w = 60 + 70 * rnd(i, 8)
            for j in 0..<3 {
                let dx = Double(j) * w * 0.3
                let r = w * (0.25 + 0.1 * Double(j % 2))
                ctx.fill(Path(ellipseIn: CGRect(x: x + dx - r, y: y - r * 0.6, width: r * 2, height: r * 1.2)),
                         with: .color(color.opacity(0.55)))
            }
        }
    }

    private static func drawWeather(_ ctx: inout GraphicsContext, size: CGSize, t: Double, h: Double) {
        if h > Config.ashAt {
            // Gentle rain in Verdant, heavier acid rain in Smog.
            let count = h > Config.smogAt ? 22 : 60
            let color = Palette.c(Palette.rain, h).opacity(h > Config.smogAt ? 0.35 : 0.5)
            for i in 0..<count {
                let speed = 260 + 140 * rnd(i, 9)
                let y = (rnd(i, 10) * size.height + t * speed).truncatingRemainder(dividingBy: size.height + 20) - 10
                let x = rnd(i, 11) * size.width + y * 0.12
                var p = Path()
                p.move(to: CGPoint(x: x, y: y))
                p.addLine(to: CGPoint(x: x + 1.5, y: y + 11))
                ctx.stroke(p, with: .color(color), lineWidth: 1)
            }
        } else {
            // Ash falling and orange dust blowing sideways.
            for i in 0..<70 {
                let y = (rnd(i, 12) * size.height + t * (18 + 20 * rnd(i, 13))).truncatingRemainder(dividingBy: size.height)
                let x = (rnd(i, 14) * size.width + sin(t + Double(i)) * 12)
                ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 2.2, height: 2.2)), with: .color(Color(white: 0.75).opacity(0.6)))
            }
            for i in 0..<40 {
                let x = (rnd(i, 15) * size.width + t * (60 + 80 * rnd(i, 16))).truncatingRemainder(dividingBy: size.width)
                let y = size.height * (0.55 + 0.45 * rnd(i, 17)) + sin(t * 2 + Double(i)) * 6
                ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 3, height: 1.5)),
                         with: .color(Color(red: 0.9, green: 0.55, blue: 0.25).opacity(0.5)))
            }
        }
    }
}
