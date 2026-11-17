import SwiftUI

enum BuyAmount: String, CaseIterable, Identifiable {
    case one = "×1", ten = "×10", hundred = "×100", max = "Max"
    var id: String { rawValue }
}

struct OfflineReport {
    let amount: Double
    let seconds: TimeInterval
}

private struct SaveData: Codable {
    var currency: Double
    var lifetime: Double
    var owned: [String: Int]
    var bought: [String]
    var prestigePoints: Double
    var totalTaps: Int
    var lastSaved: Date
}

/// All game state and rules. The views only read from this and call its methods.
final class GameModel: ObservableObject {
    @Published var currency: Double = 0
    /// Currency earned since the last prestige. Drives unlocks and prestige points.
    @Published private(set) var lifetime: Double = 0
    @Published private(set) var owned: [String: Int] = [:]
    @Published private(set) var bought: Set<String> = []
    @Published private(set) var prestigePoints: Double = 0
    @Published private(set) var totalTaps = 0
    @Published var buyAmount: BuyAmount = .one
    @Published var offlineReport: OfflineReport?
    /// Game speed multiplier for testing (Dev tab).
    @Published var speed: Double = 1

    private var timer: Timer?
    private var lastTick = Date()
    private var sinceSave: TimeInterval = 0
    private var lastSaved = Date()
    private var wentToBackground = false

    init() {
        load()
        applyOffline()
        startTimer()
    }

    // MARK: - Game loop

    private func startTimer() {
        timer?.invalidate()
        lastTick = Date()
        let t = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in self?.tick() }
        RunLoop.main.add(t, forMode: .common) // keeps ticking while you scroll
        timer = t
    }

    private func tick() {
        let now = Date()
        let dt = min(now.timeIntervalSince(lastTick), 1.0)
        lastTick = now
        earn(incomePerSecond * dt * speed)
        sinceSave += dt
        if sinceSave >= 5 { save() }
    }

    func handleScenePhase(_ phase: ScenePhase) {
        switch phase {
        case .background:
            save()
            wentToBackground = true
        case .active:
            if wentToBackground {
                applyOffline()
                wentToBackground = false
            }
            lastTick = Date()
        default:
            break
        }
    }

    private func earn(_ amount: Double) {
        guard amount > 0 else { return }
        currency += amount
        lifetime += amount
    }

    // MARK: - Numbers

    func count(_ g: GeneratorDef) -> Int { owned[g.id] ?? 0 }

    var prestigeMultiplier: Double {
        1 + prestigePoints * GameConfig.prestige.bonusPerPoint
    }

    private var boughtUpgrades: [UpgradeDef] {
        GameConfig.upgrades.filter { bought.contains($0.id) }
    }

    /// Multiplier applied to every generator.
    var globalMultiplier: Double {
        var m = prestigeMultiplier
        for u in boughtUpgrades {
            if case .all(let x) = u.effect { m *= x }
        }
        return m
    }

    /// Total multiplier for one generator (global × milestones × its own upgrades).
    func multiplier(_ g: GeneratorDef) -> Double {
        var m = globalMultiplier
        for ms in GameConfig.milestones where count(g) >= ms { m *= 2 }
        for u in boughtUpgrades {
            if case .generator(let id, let x) = u.effect, id == g.id { m *= x }
        }
        return m
    }

    func rate(_ g: GeneratorDef) -> Double {
        Double(count(g)) * g.baseRate * multiplier(g)
    }

    var incomePerSecond: Double {
        GameConfig.generators.reduce(0) { $0 + rate($1) }
    }

    var tapValue: Double {
        var mult = prestigeMultiplier
        var percent = 0.0
        for u in boughtUpgrades {
            switch u.effect {
            case .tap(let x): mult *= x
            case .tapPercent(let p): percent += p
            default: break
            }
        }
        return GameConfig.tapBase * mult + incomePerSecond * percent
    }

    @discardableResult
    func tap() -> Double {
        let v = tapValue
        earn(v)
        totalTaps += 1
        return v
    }

    // MARK: - Generators

    /// Price of buying `n` more of a generator (geometric series).
    func cost(_ g: GeneratorDef, quantity n: Int) -> Double {
        guard n > 0 else { return 0 }
        let r = g.costGrowth
        let first = g.baseCost * pow(r, Double(count(g)))
        if r == 1 { return first * Double(n) }
        return first * (pow(r, Double(n)) - 1) / (r - 1)
    }

    func maxAffordable(_ g: GeneratorDef) -> Int {
        let r = g.costGrowth
        let first = g.baseCost * pow(r, Double(count(g)))
        guard currency >= first else { return 0 }
        if r == 1 { return Int(currency / first) }
        var n = Int(floor(log(currency * (r - 1) / first + 1) / log(r)))
        while n > 0 && cost(g, quantity: n) > currency { n -= 1 } // guard against rounding
        return n
    }

    func purchaseQuantity(_ g: GeneratorDef) -> Int {
        switch buyAmount {
        case .one: return 1
        case .ten: return 10
        case .hundred: return 100
        case .max: return max(1, maxAffordable(g))
        }
    }

    func buy(_ g: GeneratorDef) {
        let n = purchaseQuantity(g)
        let c = cost(g, quantity: n)
        guard n > 0, currency >= c else { return }
        currency -= c
        owned[g.id, default: 0] += n
    }

    func nextMilestone(_ g: GeneratorDef) -> Int? {
        GameConfig.milestones.first { $0 > count(g) }
    }

    func isVisible(index i: Int) -> Bool {
        let gens = GameConfig.generators
        return i == 0 || count(gens[i]) > 0 || count(gens[i - 1]) > 0
    }

    // MARK: - Upgrades

    func isUnlocked(_ u: UpgradeDef) -> Bool {
        switch u.requires {
        case .always: return true
        case .owns(let id, let n): return (owned[id] ?? 0) >= n
        case .lifetime(let x): return lifetime >= x
        }
    }

    func isBought(_ u: UpgradeDef) -> Bool { bought.contains(u.id) }

    func buy(_ u: UpgradeDef) {
        guard !isBought(u), isUnlocked(u), currency >= u.cost else { return }
        currency -= u.cost
        bought.insert(u.id)
    }

    func requirementText(_ u: UpgradeDef) -> String {
        switch u.requires {
        case .always:
            return ""
        case .owns(let id, let n):
            let name = GameConfig.generators.first { $0.id == id }?.name ?? id
            return "Own \(n) \(name) (\(owned[id] ?? 0)/\(n))"
        case .lifetime(let x):
            return "Earn \(Fmt.num(x)) \(GameConfig.currencyName) this run"
        }
    }

    // MARK: - Prestige

    var pendingPrestige: Double {
        let p = GameConfig.prestige
        guard lifetime >= p.minLifetime else { return 0 }
        return floor(sqrt(lifetime / p.divisor))
    }

    func doPrestige() {
        let gain = pendingPrestige
        guard gain > 0 else { return }
        prestigePoints += gain
        currency = 0
        lifetime = 0
        owned = [:]
        bought = []
        save()
    }

    // MARK: - Dev tools

    func devSkip(seconds: TimeInterval) { earn(incomePerSecond * seconds) }
    func devAdd(_ amount: Double) { earn(amount) }
    func devMultiplyCurrency(by x: Double) { earn(currency * (x - 1)) }

    func devSimulateOffline(seconds: TimeInterval) {
        lastSaved = Date().addingTimeInterval(-seconds)
        applyOffline()
    }

    func resetEverything() {
        currency = 0
        lifetime = 0
        owned = [:]
        bought = []
        prestigePoints = 0
        totalTaps = 0
        speed = 1
        UserDefaults.standard.removeObject(forKey: GameConfig.saveKey)
        save()
    }

    // MARK: - Saving

    func save() {
        lastSaved = Date()
        sinceSave = 0
        let data = SaveData(
            currency: currency, lifetime: lifetime, owned: owned,
            bought: Array(bought), prestigePoints: prestigePoints,
            totalTaps: totalTaps, lastSaved: lastSaved
        )
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: GameConfig.saveKey)
        }
    }

    private func load() {
        guard
            let raw = UserDefaults.standard.data(forKey: GameConfig.saveKey),
            let d = try? JSONDecoder().decode(SaveData.self, from: raw)
        else { return }
        currency = d.currency
        lifetime = d.lifetime
        owned = d.owned
        bought = Set(d.bought)
        prestigePoints = d.prestigePoints
        totalTaps = d.totalTaps
        lastSaved = d.lastSaved
    }

    /// Pays out income for the time since the last save, if it was at least 30 seconds.
    private func applyOffline() {
        let elapsed = Date().timeIntervalSince(lastSaved)
        guard elapsed >= 30 else { return }
        let capped = min(elapsed, GameConfig.offlineMaxHours * 3600)
        let amount = incomePerSecond * capped * GameConfig.offlineEfficiency
        lastSaved = Date()
        guard amount > 0 else { return }
        earn(amount)
        offlineReport = OfflineReport(amount: amount, seconds: elapsed)
        save()
    }
}

// MARK: - Formatting

enum Fmt {
    private static let suffixes = ["", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"]

    /// 1234 -> "1.23K", 0.5 -> "0.5", 3.2e40 -> "3.20e40"
    static func num(_ v: Double) -> String {
        guard v.isFinite else { return "∞" }
        let a = abs(v)
        if a < 1_000 {
            if a < 100 && v != v.rounded(.down) { return String(format: "%.1f", v) }
            return String(format: "%.0f", v.rounded(.down))
        }
        let tier = Int(floor(log10(a) / 3))
        if tier < suffixes.count {
            let scaled = v / pow(1_000, Double(tier))
            let digits = scaled < 100 ? "%.2f" : "%.1f"
            return String(format: digits, scaled) + suffixes[tier]
        }
        return String(format: "%.2e", v)
    }

    /// 8130 -> "2h 15m"
    static func duration(_ s: TimeInterval) -> String {
        let t = Int(s)
        let h = t / 3600, m = (t % 3600) / 60, sec = t % 60
        if h > 0 { return "\(h)h \(m)m" }
        if m > 0 { return "\(m)m \(sec)s" }
        return "\(sec)s"
    }
}
