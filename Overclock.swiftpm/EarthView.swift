import SwiftUI

// Colors for the world. Everything blends continuously with Earth Health:
// Verdant (100%) → Smog (50%) → Ash (0%). There are no hard cuts.

struct RGB {
    var r: Double, g: Double, b: Double

    init(_ r: Double, _ g: Double, _ b: Double) {
        self.r = r
        self.g = g
        self.b = b
    }

    var color: Color { Color(red: RGB.clamp(r), green: RGB.clamp(g), blue: RGB.clamp(b)) }
    func col(_ opacity: Double) -> Color { color.opacity(opacity) }

    static func clamp(_ v: Double) -> Double { min(1, max(0, v)) }

    static func mix(_ a: RGB, _ b: RGB, _ t: Double) -> RGB {
        let k = clamp(t)
        return RGB(a.r + (b.r - a.r) * k, a.g + (b.g - a.g) * k, a.b + (b.b - a.b) * k)
    }

    static func * (lhs: RGB, rhs: Double) -> RGB { RGB(lhs.r * rhs, lhs.g * rhs, lhs.b * rhs) }

    /// Fully saturated color for hue 0...1 (the gaming PC's RGB strip).
    static func hue(_ h: Double) -> RGB {
        let x = h.truncatingRemainder(dividingBy: 1) * 6
        let i = Int(floor(x)) % 6
        let f = x - floor(x)
        let q = 1 - f
        switch i {
        case 0: return RGB(1, f, 0)
        case 1: return RGB(q, 1, 0)
        case 2: return RGB(0, 1, f)
        case 3: return RGB(0, q, 1)
        case 4: return RGB(f, 0, 1)
        default: return RGB(1, 0, q)
        }
    }
}

/// Colors as (Verdant, Smog, Ash).
enum Palette {
    typealias Triple = (verdant: RGB, smog: RGB, ash: RGB)

    static let skyTop: Triple     = (RGB(0.18, 0.42, 0.78), RGB(0.30, 0.31, 0.33), RGB(0.42, 0.14, 0.05))
    static let skyBottom: Triple  = (RGB(0.62, 0.82, 0.97), RGB(0.58, 0.55, 0.48), RGB(0.93, 0.50, 0.20))
    static let ocean: Triple      = (RGB(0.10, 0.42, 0.78), RGB(0.24, 0.34, 0.26), RGB(0.40, 0.36, 0.22))
    static let land: Triple       = (RGB(0.36, 0.68, 0.34), RGB(0.47, 0.48, 0.42), RGB(0.72, 0.54, 0.33))
    static let landDetail: Triple = (RGB(0.16, 0.48, 0.24), RGB(0.33, 0.35, 0.32), RGB(0.47, 0.32, 0.20))
    static let cloud: Triple      = (RGB(1.00, 1.00, 1.00), RGB(0.62, 0.62, 0.58), RGB(0.88, 0.58, 0.32))
    static let smoke: Triple      = (RGB(0.92, 0.93, 0.95), RGB(0.34, 0.33, 0.31), RGB(0.24, 0.19, 0.16))
    static let glow: Triple       = (RGB(0.55, 0.80, 1.00), RGB(0.66, 0.64, 0.56), RGB(1.00, 0.55, 0.25))
    static let sun: Triple        = (RGB(1.00, 0.93, 0.62), RGB(0.93, 0.88, 0.74), RGB(1.00, 0.42, 0.18))

    static func rgb(_ c: Triple, _ health: Double) -> RGB {
        let h = max(0, min(1, health / 100))
        return h >= 0.5 ? RGB.mix(c.smog, c.verdant, (h - 0.5) / 0.5) : RGB.mix(c.ash, c.smog, h / 0.5)
    }

    static func c(_ c: Triple, _ health: Double) -> Color { rgb(c, health).color }
}

struct EarthState {
    let health: Double
    let income: Double
    let pollution: Double
    let overclock: Bool
    let heatwave: Bool
}

/// The whole planet seen from space. Shown at the Planetary Core stage, or with the globe button.
struct EarthView: View {
    @EnvironmentObject var game: Game
    /// Space reserved at the top for the HUD, so the globe sits below it.
    var top: CGFloat = 0

    var body: some View {
        let state = EarthState(
            health: game.health, income: game.incomePerSecond, pollution: game.pollutionPerSecond,
            overclock: game.isOverclocking, heatwave: game.isHeatwave
        )
        let inset = top
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 100_000)
                EarthRenderer.draw(&context, size: size, time: t, state: state, top: inset)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Earth, \(Int(game.health))% health")
    }
}

/// A realistic globe drawn from WorldMap: smooth coastlines, biomes that dry out as Health falls,
/// shallow seas that turn into dried seabed, melting ice, clouds, day and night, city lights.
enum EarthRenderer {
    enum Kind: Int, CaseIterable { case shelf, seabed, forest, grass, tundra, desert, rock, ice }

    static let oceanT: Palette.Triple  = (RGB(0.04, 0.17, 0.40), RGB(0.15, 0.23, 0.23), RGB(0.24, 0.20, 0.14))
    static let shelfT: Palette.Triple  = (RGB(0.07, 0.32, 0.55), RGB(0.17, 0.27, 0.24), RGB(0.30, 0.26, 0.17))
    static let seabedT: Palette.Triple = (RGB(0.62, 0.55, 0.42), RGB(0.56, 0.50, 0.40), RGB(0.56, 0.43, 0.31))
    static let forestT: Palette.Triple = (RGB(0.09, 0.29, 0.11), RGB(0.23, 0.26, 0.20), RGB(0.36, 0.25, 0.15))
    static let grassT: Palette.Triple  = (RGB(0.27, 0.47, 0.17), RGB(0.37, 0.38, 0.28), RGB(0.52, 0.38, 0.22))
    static let desertT: Palette.Triple = (RGB(0.80, 0.66, 0.43), RGB(0.70, 0.60, 0.45), RGB(0.76, 0.50, 0.28))
    static let tundraT: Palette.Triple = (RGB(0.44, 0.47, 0.37), RGB(0.45, 0.44, 0.40), RGB(0.50, 0.40, 0.30))
    static let iceT: Palette.Triple    = (RGB(0.94, 0.96, 0.99), RGB(0.84, 0.85, 0.84), RGB(0.82, 0.76, 0.68))
    static let rockT: Palette.Triple   = (RGB(0.40, 0.37, 0.33), RGB(0.40, 0.37, 0.33), RGB(0.42, 0.33, 0.25))
    static let airT: Palette.Triple    = (RGB(0.42, 0.68, 1.00), RGB(0.62, 0.60, 0.52), RGB(0.95, 0.58, 0.30))
    static let cloudT: Palette.Triple  = (RGB(1.00, 1.00, 1.00), RGB(0.70, 0.69, 0.64), RGB(0.80, 0.58, 0.38))

    static func color(_ kind: Kind, _ h: Double) -> Color {
        switch kind {
        case .shelf: return Palette.c(shelfT, h)
        case .seabed: return Palette.c(seabedT, h)
        case .forest: return Palette.c(forestT, h)
        case .grass: return Palette.c(grassT, h)
        case .tundra: return Palette.c(tundraT, h)
        case .desert: return Palette.c(desertT, h)
        case .rock: return Palette.c(rockT, h)
        case .ice: return Palette.c(iceT, h)
        }
    }

    // MARK: Lookup tables (built once)

    static let degree = Double.pi / 180
    static let latEdgeSin: [Double] = (0...WorldMap.height).map { sin((90 - Double($0) * 2.5) * degree) }
    static let latEdgeCos: [Double] = (0...WorldMap.height).map { cos((90 - Double($0) * 2.5) * degree) }
    static let latMidSin: [Double] = (0..<WorldMap.height).map { sin((90 - (Double($0) + 0.5) * 2.5) * degree) }
    static let latMidCos: [Double] = (0..<WorldMap.height).map { cos((90 - (Double($0) + 0.5) * 2.5) * degree) }
    static let lonEdgeSin: [Double] = (0...WorldMap.width).map { sin((-180 + Double($0) * 2.5) * degree) }
    static let lonEdgeCos: [Double] = (0...WorldMap.width).map { cos((-180 + Double($0) * 2.5) * degree) }
    static let lonMidSin: [Double] = (0..<WorldMap.width).map { sin((-180 + (Double($0) + 0.5) * 2.5) * degree) }
    static let lonMidCos: [Double] = (0..<WorldMap.width).map { cos((-180 + (Double($0) + 0.5) * 2.5) * degree) }

    /// Smooth 0...1 noise per cell, so regions dry out together instead of in a checkerboard.
    static let cellNoise: [Double] = {
        var out = [Double](repeating: 0, count: WorldMap.width * WorldMap.height)
        for j in 0..<WorldMap.height {
            for i in 0..<WorldMap.width {
                out[j * WorldMap.width + i] = smoothNoise(j, i) * 0.8 + G.rnd(j * WorldMap.width + i, 13) * 0.2
            }
        }
        return out
    }()

    private static func smoothNoise(_ j: Int, _ i: Int) -> Double {
        let spacing = 6.0
        let y = Double(j) / spacing
        let x = Double(i) / spacing
        let j0 = Int(floor(y))
        let i0 = Int(floor(x))
        let fy = y - Double(j0)
        let fx = x - Double(i0)
        let sx = fx * fx * (3 - 2 * fx)
        let sy = fy * fy * (3 - 2 * fy)
        func v(_ a: Int, _ b: Int) -> Double { G.rnd(a * 97 + ((b % 25) + 25) % 25, 61) }
        let upper = v(j0, i0) * (1 - sx) + v(j0, i0 + 1) * sx
        let lower = v(j0 + 1, i0) * (1 - sx) + v(j0 + 1, i0 + 1) * sx
        return upper * (1 - sy) + lower * sy
    }

    /// What a map cell shows at a given Health. nil = draw nothing (open ocean).
    static func kind(_ ch: UInt8, cell: Int, latDeg: Double, health h: Double) -> Kind? {
        let r = cellNoise[cell]
        switch ch {
        case 44: // ',' shallow sea: dries out first
            return h < 45 + r * 12 ? .seabed : .shelf
        case 59: // ';' slightly deeper sea
            if h < 20 + r * 12 { return .seabed }
            return h < 66 ? .shelf : nil
        case 105: // 'i' ice melts back toward the poles
            return abs(latDeg) < 62 + (1 - h / 100) * 24 + r * 3 ? .rock : .ice
        case 102: // 'f'
            return h < 12 + r * 40 ? .desert : .forest
        case 103: // 'g'
            return h < 18 + r * 45 ? .desert : .grass
        case 116: // 't'
            return h < 10 + r * 30 ? .rock : .tundra
        case 100: // 'd'
            return .desert
        default:
            return nil
        }
    }

    // MARK: Drawing

    static func draw(_ ctx: inout GraphicsContext, size: CGSize, time t: Double, state s: EarthState, top: CGFloat = 0) {
        let h = s.health
        let W = Double(size.width)
        let H = Double(size.height)
        let full = CGRect(origin: .zero, size: size)

        // Space, a faint galaxy band and stars
        ctx.fill(Path(full), with: G.radial(CGPoint(x: W / 2, y: H * 0.5), 0, max(W, H) * 0.8, [
            (0, Color(red: 0.05, green: 0.08, blue: 0.19)), (1, Color(red: 0.008, green: 0.016, blue: 0.035)),
        ]))
        var band = ctx
        band.translateBy(x: W * 0.5, y: H * 0.5)
        band.rotate(by: .radians(-0.5))
        let milky = Color(red: 0.47, green: 0.51, blue: 0.78)
        band.fill(Path(CGRect(x: -W, y: -H * 0.12, width: W * 2, height: H * 0.24)), with: G.linear(CGPoint(x: 0, y: -H * 0.12), CGPoint(x: 0, y: H * 0.12), [
            (0, milky.opacity(0)), (0.5, milky.opacity(0.08)), (1, milky.opacity(0)),
        ]))
        for k in 0..<90 {
            let twinkle = 0.35 + 0.65 * (0.5 + 0.5 * sin(t * 1.7 + Double(k) * 3.1))
            let side = G.rnd(k, 4) > 0.9 ? 1.8 : 1.1
            let star = CGRect(x: G.rnd(k, 1) * W, y: G.rnd(k, 2) * H, width: side, height: side)
            ctx.fill(Path(star), with: .color(Color.white.opacity(0.75 * twinkle * (0.4 + 0.6 * G.rnd(k, 3)))))
        }

        let areaH = H - Double(top)
        let R = min(W, areaH) * 0.39
        let cx = W / 2
        let cy = Double(top) + areaH * 0.52
        let C = CGPoint(x: cx, y: cy)
        let rot = t * 0.05
        let phi0 = 0.32 // tilt the view a little toward the north
        let sp0 = sin(phi0)
        let cp0 = cos(phi0)
        let air = Palette.rgb(airT, h)

        G.ellipse(&ctx, C, R * 1.16, R * 1.16, shading: G.radial(C, R * 0.98, R * 1.16, [(0, air.col(0.55)), (1, air.col(0))]))
        let globeRect = CGRect(x: cx - R, y: cy - R, width: R * 2, height: R * 2)
        let globe = Path(ellipseIn: globeRect)
        ctx.fill(globe, with: .color(Palette.c(oceanT, h)))

        // Longitude tables rotated for this frame (angle addition, no trig per cell)
        let cr = cos(rot), sr = sin(rot)
        var eSin = [Double](repeating: 0, count: WorldMap.width + 1)
        var eCos = [Double](repeating: 0, count: WorldMap.width + 1)
        for i in 0...WorldMap.width {
            eSin[i] = lonEdgeSin[i] * cr + lonEdgeCos[i] * sr
            eCos[i] = lonEdgeCos[i] * cr - lonEdgeSin[i] * sr
        }
        var mSin = [Double](repeating: 0, count: WorldMap.width)
        var mCos = [Double](repeating: 0, count: WorldMap.width)
        for i in 0..<WorldMap.width {
            mSin[i] = lonMidSin[i] * cr + lonMidCos[i] * sr
            mCos[i] = lonMidCos[i] * cr - lonMidSin[i] * sr
        }
        // Orthographic projection: returns screen x, y and depth (> 0 means facing us).
        func project(_ sl: Double, _ cl: Double, _ sd: Double, _ cd: Double) -> (x: Double, y: Double, z: Double) {
            (cx + R * cl * sd, cy - R * (cp0 * sl - sp0 * cl * cd), sp0 * sl + cp0 * cl * cd)
        }

        // 1) Smooth land from the coastlines; points on the far side are pushed onto the rim.
        var land = Path()
        for ring in WorldMap.coast {
            var pts: [CGPoint] = []
            pts.reserveCapacity(ring.count)
            var visible = false
            for q in ring {
                let dl = q.lon + rot
                let p = project(sin(q.lat), cos(q.lat), sin(dl), cos(dl))
                if p.z >= 0 {
                    visible = true
                    pts.append(CGPoint(x: p.x, y: p.y))
                } else {
                    let dx = p.x - cx
                    let dy = p.y - cy
                    let d = max(1e-6, (dx * dx + dy * dy).squareRoot())
                    pts.append(CGPoint(x: cx + dx / d * R, y: cy + dy / d * R))
                }
            }
            if visible && pts.count > 2 {
                land.addLines(pts)
                land.closeSubpath()
            }
        }

        // 2) Map cells: biome colors inside the land, dried seabed around the coasts.
        var buckets = [Path](repeating: Path(), count: Kind.allCases.count)
        let rows = WorldMap.rows
        for j in 0..<min(rows.count, WorldMap.height) {
            let row = rows[j]
            let latDeg = 90 - (Double(j) + 0.5) * 2.5
            for i in 0..<min(row.count, WorldMap.width) {
                let ch = row[i]
                if ch == 46 { continue } // '.'
                let mid = project(latMidSin[j], latMidCos[j], mSin[i], mCos[i])
                if mid.z < -0.02 { continue }
                guard let cellKind = EarthRenderer.kind(ch, cell: j * WorldMap.width + i, latDeg: latDeg, health: h) else { continue }
                if cellKind == .grass || cellKind == .shelf { continue }
                let corners = [
                    project(latEdgeSin[j], latEdgeCos[j], eSin[i], eCos[i]),
                    project(latEdgeSin[j], latEdgeCos[j], eSin[i + 1], eCos[i + 1]),
                    project(latEdgeSin[j + 1], latEdgeCos[j + 1], eSin[i + 1], eCos[i + 1]),
                    project(latEdgeSin[j + 1], latEdgeCos[j + 1], eSin[i], eCos[i]),
                ]
                let quad = corners.map { CGPoint(x: mid.x + ($0.x - mid.x) * 1.2, y: mid.y + ($0.y - mid.y) * 1.2) }
                buckets[cellKind.rawValue].addLines(quad)
                buckets[cellKind.rawValue].closeSubpath()
            }
        }

        var g = ctx
        g.clip(to: globe)
        // Shallow water along the coasts
        g.stroke(land, with: .color(Palette.rgb(shelfT, h).col(0.9)), style: StrokeStyle(lineWidth: R * 0.05, lineJoin: .round))
        let seabed = buckets[Kind.seabed.rawValue]
        if !seabed.isEmpty {
            let seabedColor = Palette.c(seabedT, h)
            g.drawLayer { layer in
                layer.addFilter(.blur(radius: R * 0.018))
                layer.fill(seabed, with: .color(seabedColor))
            }
        }
        g.fill(land, with: .color(Palette.c(grassT, h)))
        let biomes: [Kind] = [.forest, .tundra, .desert, .rock, .ice]
        g.drawLayer { layer in
            layer.clip(to: land)
            layer.addFilter(.blur(radius: R * 0.024))
            for biome in biomes {
                let p = buckets[biome.rawValue]
                if !p.isEmpty { layer.fill(p, with: .color(EarthRenderer.color(biome, h))) }
            }
        }
        g.stroke(land, with: .color((Palette.rgb(grassT, h) * 0.7).col(0.6)), lineWidth: 0.8)

        // Haze as the air fills with smog and dust
        if h < 75 {
            g.fill(Path(globeRect), with: .color(air.col((75 - h) / 75 * 0.32)))
        }

        // Clouds: long soft streaks in the tropics and the storm tracks
        let cloud = Palette.rgb(cloudT, h)
        let cloudCount = h > 66 ? 190 : 247
        for k in 0..<cloudCount {
            let bandIndex = k % 3
            let latDeg: Double = bandIndex == 0
                ? (G.rnd(k, 21) - 0.5) * 20
                : (bandIndex == 1 ? 1.0 : -1.0) * (35 + G.rnd(k, 22) * 28)
            let lat = latDeg * degree
            let drift = t * 0.012 * (bandIndex == 0 ? -1.0 : 1.0)
            let dl = (G.rnd(k, 23) * 360 - 180) * degree + drift + rot
            let p = project(sin(lat), cos(lat), sin(dl), cos(dl))
            if p.z < 0.04 { continue }
            let puff = R * (0.04 + G.rnd(k, 24) * 0.07)
            let sx = puff * 2.3 * (0.35 + 0.65 * p.z)
            let sy = puff * 0.75 * (0.6 + 0.4 * abs(cos(lat)))
            var layer = g
            layer.translateBy(x: p.x, y: p.y)
            layer.rotate(by: .radians(-0.25 * sin(lat) * (1 - p.z)))
            layer.scaleBy(x: 1, y: sy / sx)
            layer.fill(Path(ellipseIn: CGRect(x: -sx, y: -sx, width: sx * 2, height: sx * 2)), with: G.radial(.zero, 0, sx, [
                (0, cloud.col(0.46)), (0.55, cloud.col(0.2)), (1, cloud.col(0)),
            ]))
        }

        // Day and night: the sun is up and to the left
        let lx = -0.62, ly = 0.38, lz = 0.69
        let sun = CGPoint(x: cx + lx * R, y: cy - ly * R)
        g.blendMode = .multiply
        g.fill(Path(globeRect), with: G.radial(sun, 0, R * 1.85, [
            (0, Color.white),
            (0.42, Color(red: 0.95, green: 0.94, blue: 0.92)),
            (0.62, Color(red: 0.49, green: 0.5, blue: 0.56)),
            (0.78, Color(red: 0.11, green: 0.13, blue: 0.2)),
            (1, Color(red: 0.02, green: 0.024, blue: 0.047)),
        ]))
        g.blendMode = .normal

        // City lights on the night side, more of them as income grows
        let lightsShare = min(1, log10(s.income + 10) / 7) * 0.55
        var bright = Path()
        var dim = Path()
        for j in 0..<min(rows.count, WorldMap.height) {
            let row = rows[j]
            for i in 0..<min(row.count, WorldMap.width) {
                let ch = row[i]
                guard ch == 102 || ch == 103 || ch == 116 else { continue }
                if G.rnd(j * WorldMap.width + i, 31) > lightsShare { continue }
                let p = project(latMidSin[j], latMidCos[j], mSin[i], mCos[i])
                if p.z < 0.05 { continue }
                let nx = (p.x - cx) / R
                let ny = -(p.y - cy) / R
                let lit = nx * lx + ny * ly + p.z * lz
                if lit < -0.08 {
                    let dot = CGRect(x: p.x, y: p.y, width: 1.4, height: 1.4)
                    if lit < -0.25 { bright.addRect(dot) } else { dim.addRect(dot) }
                }
            }
        }
        let cityLight = Color(red: 1, green: 0.84, blue: 0.55)
        g.fill(bright, with: .color(cityLight.opacity(0.95)))
        g.fill(dim, with: .color(cityLight.opacity(0.45)))

        // Wildfires once the planet is dying
        if h < 40 {
            for k in 0..<40 {
                let j = Int(G.rnd(k, 41) * 50) + 10
                let i = Int(G.rnd(k, 42) * Double(WorldMap.width)) % WorldMap.width
                guard j < rows.count, i < rows[j].count else { continue }
                let ch = rows[j][i]
                guard ch == 102 || ch == 103 || ch == 100 else { continue }
                let p = project(latMidSin[j], latMidCos[j], mSin[i], mCos[i])
                if p.z < 0.1 { continue }
                let flicker = 0.5 + 0.5 * sin(t * 6 + Double(k))
                let at = CGPoint(x: p.x, y: p.y)
                G.ellipse(&g, at, 5, 5, shading: G.radial(at, 0, 5, [
                    (0, Color(red: 1, green: 0.59, blue: 0.2).opacity(0.7 * flicker)), (1, Color(red: 1, green: 0.35, blue: 0.08).opacity(0)),
                ]))
            }
        }

        // Sun glint on the water and atmosphere scattering at the edge
        let glint = CGPoint(x: cx + lx * R * 0.62, y: cy - ly * R * 0.62)
        let glintColor = Color(red: 1, green: 1, blue: 0.96)
        G.ellipse(&g, glint, R * 0.22, R * 0.16, shading: G.radial(glint, 0, R * 0.22, [(0, glintColor.opacity(0.32 * h / 100)), (1, glintColor.opacity(0))]))
        g.fill(globe, with: G.radial(C, R * 0.8, R, [(0, air.col(0)), (0.8, air.col(0.18)), (1, air.col(0.55))]))

        ctx.stroke(globe, with: .color(air.col(0.7)), lineWidth: 1.5)
        if s.overclock {
            let pulse = 0.5 + 0.5 * sin(t * 12)
            let ringR = R * 1.05
            let ring = Path(ellipseIn: CGRect(x: cx - ringR, y: cy - ringR, width: ringR * 2, height: ringR * 2))
            ctx.stroke(ring, with: .color(Color(red: 1, green: 0.35, blue: 0.24).opacity(0.4 + 0.5 * pulse)), lineWidth: 3 + 3 * pulse)
        }
        if s.heatwave {
            ctx.fill(Path(full), with: .color(Color.orange.opacity(0.12 + 0.06 * sin(t * 3))))
        }
        G.vignette(&ctx, size, 0.3)
    }
}
