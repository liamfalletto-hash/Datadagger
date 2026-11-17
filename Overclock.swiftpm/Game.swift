import SwiftUI

enum BuyAmount: String, CaseIterable, Identifiable {
    case one = "×1", ten = "×10", hundred = "×100", max = "Max"
    var id: String { rawValue }
}

struct OfflineReport {
    let seconds: TimeInterval
    let tokens: Double
    let healthBefore: Double
    let healthAfter: Double
}

private struct SaveData: Codable {
    var tokens: Double
    var runTokens: Double
    var lifetimeTokens: Double
    var owned: [Int]
    var power: [Power]
    var health: Double
    var phase: Int
    var paramsEarned: Double
    var paramsSpent: Double
    var nodeLevels: [String: Int]
    var seenFacts: [String]
    var modelVersion: Int
    var totalTaps: Int
    var lastSaved: Date
}

/// The whole economy. Views read from it and call its methods; nothing here depends on the visuals.
final class Game: ObservableObject {
    @Published var tokens: Double = 0
    @Published private(set) var runTokens: Double = 0
    @Published private(set) var lifetimeTokens: Double = 0
    @Published private(set) var owned: [Int]
    @Published private(set) var power: [Power]
    @Published private(set) var health: Double = 100
    @Published private(set) var phase = 0
    @Published private(set) var paramsEarned: Double = 0
    @Published private(set) var paramsSpent: Double = 0
    @Published private(set) var nodeLevels: [String: Int] = [:]
    @Published private(set) var seenFacts: Set<String> = []
    @Published private(set) var modelVersion = 1
    @Published private(set) var totalTaps = 0
    @Published private(set) var overclockUntil = Date.distantPast
    @Published private(set) var overclockReadyAt = Date.distantPast
    @Published private(set) var heatwaveUntil = Date.distantPast
    @Published private(set) var factQueue: [Fact] = []
    @Published var buyAmount: BuyAmount = .one
    @Published var speed: Double = 1
    @Published var offlineReport: OfflineReport?
    /// Set when a phase is entered: 1 = Smog, 2 = Ash, 3 = Health reached 0%.
    @Published var phaseBanner: Int?

    private var nextHeatwave = Date.distantFuture
    private var timer: Timer?
    private var lastTick = Date()
    private var sinceSave: TimeInterval = 0
    private var sinceAuto: TimeInterval = 0
    private var lastSaved = Date()
    private var wentToBackground = false
    private let lightHaptic = UIImpactFeedbackGenerator(style: .light)
    private let heavyHaptic = UIImpactFeedbackGenerator(style: .heavy)
    private let notifyHaptic = UINotificationFeedbackGenerator()

    init() {
        owned = Array(repeating: 0, count: Config.tiers.count)
        power = Array(repeating: .coal, count: Config.tiers.count)
        load()
        if phase == 2 { nextHeatwave = Date().addingTimeInterval(60) }
        applyOffline()
        startTimer()
    }

    // MARK: - Loop

    private func startTimer() {
        timer?.invalidate()
        lastTick = Date()
        let t = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in self?.tick() }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func tick() {
        let now = Date()
        let realDt = min(now.timeIntervalSince(lastTick), 1.0)
        lastTick = now
        let dt = realDt * speed

        earn(incomePerSecond * dt)
        pollute(pollutionPerSecond * dt)

        if phase == 2, now >= nextHeatwave, now >= heatwaveUntil {
            heatwaveUntil = now.addingTimeInterval(Config.heatwaveSeconds)
            nextHeatwave = now.addingTimeInterval(.random(in: Config.heatwaveGap))
            unlockFact("water-hidden")
        }

        if level("auto") > 0 {
            sinceAuto += dt
            if sinceAuto >= 2 {
                sinceAuto = 0
                autoBuy()
            }
        }

        sinceSave += realDt
        if sinceSave >= 10 { save() }
    }

    func handleScenePhase(_ scenePhase: ScenePhase) {
        switch scenePhase {
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
        tokens += amount
        runTokens += amount
        lifetimeTokens += amount
        if lifetimeTokens >= 1e6 { unlockFact("scale") }
    }

    /// Earth Health = 100 · e^(−pollution / K). Applied step by step so K can change per phase.
    private func pollute(_ amount: Double) {
        guard health > 0, amount > 0 else { return }
        health *= exp(-amount / Config.phaseK[phase])
        if health < Config.deadAt {
            health = 0
            phaseBanner = 3
            notifyHaptic.notificationOccurred(.error)
        }
        updatePhase()
    }

    private func updatePhase() {
        let target = health <= Config.ashAt ? 2 : (health <= Config.smogAt ? 1 : 0)
        while phase < target {
            phase += 1
            phaseBanner = health <= 0 ? 3 : phase
            notifyHaptic.notificationOccurred(.warning)
            if phase == 1 { unlockFact("electricity-2030") }
            if phase == 2 {
                unlockFact("ewaste")
                nextHeatwave = Date().addingTimeInterval(60)
            }
        }
    }

    // MARK: - Numbers

    var isDead: Bool { health <= 0 }
    var isOverclocking: Bool { Date() < overclockUntil }
    var overclockReady: Bool { Date() >= overclockReadyAt }
    var isHeatwave: Bool { Date() < heatwaveUntil }

    func level(_ node: String) -> Int { nodeLevels[node] ?? 0 }

    var unspentParameters: Double { paramsEarned - paramsSpent }
    var parameterMultiplier: Double { 1 + unspentParameters * Config.parameterBonus }

    var globalMultiplier: Double {
        parameterMultiplier
            * Config.phaseIncomeMult[phase]
            * (isOverclocking ? Config.overclockIncome : 1)
    }

    func milestoneMultiplier(_ i: Int) -> Double {
        pow(2, Double(Config.milestones.filter { owned[i] >= $0 }.count))
    }

    func nextMilestone(_ i: Int) -> Int? {
        Config.milestones.first { $0 > owned[i] }
    }

    func output(_ i: Int) -> Double {
        let t = Config.tiers[i]
        let heat = (t.waterCooled && isHeatwave) ? Config.heatwaveOutput : 1
        return Double(owned[i]) * t.output * milestoneMultiplier(i) * globalMultiplier * heat
    }

    func pollution(_ i: Int) -> Double {
        let t = Config.tiers[i]
        let distill = 1 - 0.15 * Double(level("distill"))
        let oc = isOverclocking ? Config.overclockPollution : 1
        return Double(owned[i]) * t.pollution * power[i].pollutionMult * distill * oc
    }

    var incomePerSecond: Double { Config.tiers.indices.reduce(0) { $0 + output($1) } }
    var pollutionPerSecond: Double { Config.tiers.indices.reduce(0) { $0 + pollution($1) } }

    var offlineCapHours: Double { Config.offlineBaseHours + 2 * Double(level("memory")) }

    // MARK: - Buying

    func isUnlocked(_ i: Int) -> Bool {
        let t = Config.tiers[i]
        guard phase >= t.minPhase else { return false }
        return i == 0 || owned[i] > 0 || owned[i - 1] >= Config.unlockCount
    }

    /// cost of n more copies = base · r^owned · (r^n − 1) / (r − 1)
    func cost(_ i: Int, quantity n: Int) -> Double {
        guard n > 0 else { return 0 }
        let t = Config.tiers[i]
        let r = t.costGrowth
        let first = t.baseCost * pow(r, Double(owned[i]))
        return first * (pow(r, Double(n)) - 1) / (r - 1)
    }

    func maxAffordable(_ i: Int) -> Int {
        let t = Config.tiers[i]
        let r = t.costGrowth
        let first = t.baseCost * pow(r, Double(owned[i]))
        guard tokens >= first else { return 0 }
        var n = Int(floor(log(tokens * (r - 1) / first + 1) / log(r)))
        while n > 0 && cost(i, quantity: n) > tokens { n -= 1 }
        return n
    }

    func purchaseQuantity(_ i: Int) -> Int {
        switch buyAmount {
        case .one: return 1
        case .ten: return 10
        case .hundred: return 100
        case .max: return max(1, maxAffordable(i))
        }
    }

    func buy(_ i: Int) {
        let n = purchaseQuantity(i)
        let c = cost(i, quantity: n)
        guard isUnlocked(i), tokens >= c else { return }
        tokens -= c
        let first = owned[i] == 0
        owned[i] += n
        lightHaptic.impactOccurred()
        if first, let fact = Facts.firstBuy[i] { unlockFact(fact) }
    }

    private func autoBuy() {
        let options = Config.tiers.indices.filter { isUnlocked($0) && cost($0, quantity: 1) <= tokens }
        guard let cheapest = options.min(by: { cost($0, quantity: 1) < cost($1, quantity: 1) }) else { return }
        tokens -= cost(cheapest, quantity: 1)
        owned[cheapest] += 1
    }

    // MARK: - Power choice

    var canChoosePower: Bool { phase >= 1 || level("green") > 0 }

    func retrofitCost(_ i: Int, to p: Power) -> Double {
        cost(i, quantity: 1) * p.retrofitMult
    }

    func retrofit(_ i: Int, to p: Power) {
        let c = retrofitCost(i, to: p)
        guard canChoosePower, p.rank > power[i].rank, tokens >= c else { return }
        tokens -= c
        power[i] = p
        lightHaptic.impactOccurred()
        unlockFact("power-sources")
    }

    // MARK: - Interactions

    @discardableResult
    func tapPlanet() -> Double {
        let v = max(1, incomePerSecond * Config.tapIncomeShare)
        earn(v)
        totalTaps += 1
        lightHaptic.impactOccurred(intensity: 0.6)
        unlockFact("one-prompt")
        return v
    }

    func overclock() {
        guard overclockReady else { return }
        let now = Date()
        overclockUntil = now.addingTimeInterval(Config.overclockSeconds)
        overclockReadyAt = now.addingTimeInterval(Config.overclockCooldown)
        heavyHaptic.impactOccurred()
    }

    // MARK: - Facts

    func unlockFact(_ id: String) {
        guard !seenFacts.contains(id), let fact = Facts.byID(id) else { return }
        seenFacts.insert(id)
        factQueue.append(fact)
    }

    func dismissFact() {
        if !factQueue.isEmpty { factQueue.removeFirst() }
    }

    // MARK: - Train a New Model (prestige)

    var pendingParameters: Double {
        max(0, Config.parameters(forLifetime: lifetimeTokens) - paramsEarned)
    }

    /// All-time Tokens needed for the next Parameter.
    var nextParameterAt: Double {
        let target = paramsEarned + pendingParameters + 1
        return 1e12 * pow(target / 150, 2)
    }

    func trainNewModel() {
        let gain = pendingParameters
        guard gain >= 1 else { return }
        paramsEarned += gain
        modelVersion += 1
        resetRun()
        notifyHaptic.notificationOccurred(.success)
        unlockFact("ewaste-trend")
        save()
    }

    private func resetRun() {
        tokens = 0
        runTokens = 0
        owned = Array(repeating: 0, count: Config.tiers.count)
        if level("warm") > 0 { owned[0] = 10 }
        power = Array(repeating: level("green") > 0 ? .gas : .coal, count: Config.tiers.count)
        health = 100
        phase = 0
        phaseBanner = nil
        overclockUntil = .distantPast
        overclockReadyAt = .distantPast
        heatwaveUntil = .distantPast
        nextHeatwave = .distantFuture
    }

    func nodeCost(_ node: ModelNode) -> Double {
        node.cost * Double(level(node.id) + 1)
    }

    func research(_ node: ModelNode) {
        let c = nodeCost(node)
        guard level(node.id) < node.maxLevel, unspentParameters >= c else { return }
        paramsSpent += c
        nodeLevels[node.id, default: 0] += 1
        lightHaptic.impactOccurred()
        if node.id == "distill" { unlockFact("other-side") }
        if node.id == "green" {
            for i in power.indices where power[i] == .coal { power[i] = .gas }
        }
    }

    // MARK: - Dev tools

    /// Runs the economy forward in 60-second steps (income, pollution and phase changes).
    func simulate(seconds: TimeInterval, efficiency: Double = 1) -> Double {
        var remaining = seconds
        var earned = 0.0
        while remaining > 0 {
            let step = min(60, remaining)
            let amount = incomePerSecond * step * efficiency
            earn(amount)
            earned += amount
            pollute(pollutionPerSecond * step * efficiency)
            remaining -= step
        }
        return earned
    }

    func devSkip(seconds: TimeInterval) { _ = simulate(seconds: seconds) }
    func devAdd(_ amount: Double) { earn(amount) }
    func devMultiply(by x: Double) { earn(tokens * (x - 1)) }
    func devDamageEarth(_ points: Double) {
        health = max(0, health - points)
        if health < Config.deadAt { health = 0; phaseBanner = 3 }
        updatePhase()
    }
    func devGrantParameters(_ n: Double) { paramsEarned += n }
    func devSimulateOffline(seconds: TimeInterval) {
        lastSaved = Date().addingTimeInterval(-seconds)
        applyOffline()
    }

    func resetEverything() {
        resetRun()
        lifetimeTokens = 0
        paramsEarned = 0
        paramsSpent = 0
        nodeLevels = [:]
        seenFacts = []
        factQueue = []
        modelVersion = 1
        totalTaps = 0
        speed = 1
        UserDefaults.standard.removeObject(forKey: Config.saveKey)
        save()
    }

    // MARK: - Saving and offline

    func save() {
        lastSaved = Date()
        sinceSave = 0
        let data = SaveData(
            tokens: tokens, runTokens: runTokens, lifetimeTokens: lifetimeTokens,
            owned: owned, power: power, health: health, phase: phase,
            paramsEarned: paramsEarned, paramsSpent: paramsSpent, nodeLevels: nodeLevels,
            seenFacts: Array(seenFacts), modelVersion: modelVersion, totalTaps: totalTaps,
            lastSaved: lastSaved
        )
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: Config.saveKey)
        }
    }

    private func load() {
        guard
            let raw = UserDefaults.standard.data(forKey: Config.saveKey),
            let d = try? JSONDecoder().decode(SaveData.self, from: raw)
        else { return }
        let n = Config.tiers.count
        tokens = d.tokens
        runTokens = d.runTokens
        lifetimeTokens = d.lifetimeTokens
        // Pad or trim in case you added or removed tiers in Config.swift.
        owned = Array((d.owned + Array(repeating: 0, count: n)).prefix(n))
        power = Array((d.power + Array(repeating: .coal, count: n)).prefix(n))
        health = d.health
        phase = min(d.phase, 2)
        paramsEarned = d.paramsEarned
        paramsSpent = d.paramsSpent
        nodeLevels = d.nodeLevels
        seenFacts = Set(d.seenFacts)
        modelVersion = d.modelVersion
        totalTaps = d.totalTaps
        lastSaved = d.lastSaved
    }

    /// Offline: 50% of live income, capped, and pollution keeps accruing too.
    private func applyOffline() {
        let elapsed = Date().timeIntervalSince(lastSaved)
        guard elapsed >= 30 else { return }
        let capped = min(elapsed, offlineCapHours * 3600)
        let before = health
        overclockUntil = .distantPast
        heatwaveUntil = .distantPast
        let earned = simulate(seconds: capped, efficiency: Config.offlineEfficiency)
        lastSaved = Date()
        guard earned > 0 else { return }
        offlineReport = OfflineReport(seconds: elapsed, tokens: earned, healthBefore: before, healthAfter: health)
        save()
    }
}

// MARK: - Formatting

enum Fmt {
    private static let suffixes = ["", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"]

    static func num(_ v: Double) -> String {
        guard v.isFinite else { return "∞" }
        let a = abs(v)
        if a == 0 { return "0" }
        if a < 1 { return String(format: "%.2f", v) }
        if a < 1_000 {
            if a < 100 && v != v.rounded(.down) { return String(format: "%.1f", v) }
            return String(format: "%.0f", v.rounded(.down))
        }
        let tier = Int(floor(log10(a) / 3))
        if tier < suffixes.count {
            let scaled = v / pow(1_000, Double(tier))
            return String(format: scaled < 100 ? "%.2f" : "%.1f", scaled) + suffixes[tier]
        }
        return String(format: "%.2e", v)
    }

    static func duration(_ s: TimeInterval) -> String {
        let t = Int(s)
        let h = t / 3600, m = (t % 3600) / 60, sec = t % 60
        if h > 0 { return "\(h)h \(m)m" }
        if m > 0 { return "\(m)m \(sec)s" }
        return "\(sec)s"
    }
}
