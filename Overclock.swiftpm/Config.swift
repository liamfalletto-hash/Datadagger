// ============================================================
//  OVERCLOCK CONFIG: every tunable number in the game.
//  Edit, press ⌘R, then use the Dev tab to skip ahead and test.
// ============================================================

import Foundation

enum Config {
    /// Change this to start over with a fresh save.
    static let saveKey = "overclock-save-v1"
    /// Shows the Dev tab (time skip, cheats, speed). Set to false before shipping.
    static let debug = true

    // MARK: Generators (design doc: "Generators (your compute stack)")
    // minPhase: 0 = Verdant, 1 = Smog, 2 = Ash. A tier also needs 10 of the tier before it.
    static let tiers: [Tier] = [
        Tier(id: 0, name: "Garage Server Rack",     icon: "server.rack",                baseCost: 10,    output: 1,         pollution: 0.01, costGrowth: 1.07, minPhase: 0),
        Tier(id: 1, name: "GPU Cluster",            icon: "cpu",                        baseCost: 120,   output: 8,         pollution: 0.05, costGrowth: 1.08, minPhase: 0),
        Tier(id: 2, name: "Office Data Center",     icon: "building.2",                 baseCost: 1_500, output: 60,        pollution: 0.3,  costGrowth: 1.09, minPhase: 0),
        Tier(id: 3, name: "Hyperscale Campus",      icon: "square.stack.3d.up.fill",    baseCost: 20_000, output: 450,      pollution: 2,    costGrowth: 1.10, minPhase: 0),
        Tier(id: 4, name: "Coal-Powered Megafarm",  icon: "smoke.fill",                 baseCost: 3e5,   output: 3_500,     pollution: 15,   costGrowth: 1.11, minPhase: 1),
        Tier(id: 5, name: "Ocean-Cooled Fortress",  icon: "water.waves",                baseCost: 5e6,   output: 28_000,    pollution: 90,   costGrowth: 1.12, minPhase: 1, waterCooled: true),
        Tier(id: 6, name: "Desert Gigafactory",     icon: "sun.dust.fill",              baseCost: 9e7,   output: 240_000,   pollution: 600,  costGrowth: 1.13, minPhase: 2),
        Tier(id: 7, name: "Planetary Compute Core", icon: "globe.americas.fill",        baseCost: 2e9,   output: 2_200_000, pollution: 4_000, costGrowth: 1.14, minPhase: 2),
    ]
    static let unlockCount = 10
    /// Every milestone doubles that building's output.
    static let milestones = [25, 50, 100, 200, 300, 400, 500, 750, 1000]

    // MARK: Earth Health = 100 · e^(−pollution / K)
    // K is per phase, so the decline slows down near the end.
    // Tuned with a simulated "always buy the best-value building" player: Smog at ~24 min,
    // Ash after ~13 h of continuous play in run 1 (faster after model trainings). Retune by playtesting.
    static let phaseK: [Double] = [300_000, 6e8, 6e10]
    static let smogAt = 66.0
    static let ashAt = 33.0
    /// Below this, Health counts as 0% ("The last river runs dry").
    static let deadAt = 0.5
    /// Income multiplier for the rest of the run once you reach each phase.
    static let phaseIncomeMult: [Double] = [1, 3, 5]

    // MARK: Interactions
    /// Tapping the planet gives this share of your income per second (minimum 1 Token).
    static let tapIncomeShare = 0.05
    static let overclockSeconds: TimeInterval = 10
    static let overclockCooldown: TimeInterval = 60
    static let overclockIncome = 2.0
    static let overclockPollution = 3.0

    // MARK: Heatwaves (Ash phase): throttle water-cooled buildings
    static let heatwaveSeconds: TimeInterval = 30
    static let heatwaveGap: ClosedRange<TimeInterval> = 180...360
    static let heatwaveOutput = 0.5

    // MARK: Offline
    static let offlineEfficiency = 0.5
    static let offlineBaseHours = 4.0

    // MARK: Prestige: Train a New Model
    /// Each unspent Parameter adds this much income.
    static let parameterBonus = 0.02
    /// Total Parameters ever earned for a given all-time Token count.
    static func parameters(forLifetime tokens: Double) -> Double {
        floor(150 * (tokens / 1e12).squareRoot())
    }

    /// Model Tree. Cost is in Parameters and goes up with each level (cost × next level).
    static let modelTree: [ModelNode] = [
        ModelNode(id: "memory",  name: "Longer Memory",   desc: "+2h offline cap",                               cost: 5,  maxLevel: 4),
        ModelNode(id: "warm",    name: "Warm Start",      desc: "Start each run with 10 Garage Server Racks",    cost: 10, maxLevel: 1),
        ModelNode(id: "distill", name: "Distillation",    desc: "−15% pollution from every building",            cost: 15, maxLevel: 3),
        ModelNode(id: "green",   name: "Greener Defaults", desc: "Power choice from the start; buildings start on Gas", cost: 25, maxLevel: 1),
        ModelNode(id: "auto",    name: "Auto-scaler",     desc: "Buys the cheapest building you can afford every 2 s", cost: 50, maxLevel: 1),
    ]
}

// MARK: - Types

struct Tier: Identifiable {
    let id: Int
    let name: String
    let icon: String      // SF Symbol
    let baseCost: Double
    let output: Double    // Tokens per second, per copy
    let pollution: Double // per second, per copy
    let costGrowth: Double
    let minPhase: Int
    var waterCooled = false
}

enum Power: String, Codable, CaseIterable, Identifiable {
    case coal, gas, clean
    var id: String { rawValue }
    var rank: Int { Power.allCases.firstIndex(of: self) ?? 0 }
    var label: String {
        switch self {
        case .coal: return "Coal"
        case .gas: return "Gas"
        case .clean: return "Solar/Nuclear"
        }
    }
    var symbol: String {
        switch self {
        case .coal: return "flame.fill"
        case .gas: return "fuelpump.fill"
        case .clean: return "sun.max.fill"
        }
    }
    var pollutionMult: Double {
        switch self {
        case .coal: return 1
        case .gas: return 0.6
        case .clean: return 0.1
        }
    }
    /// Switching a building type costs this many times its next copy's price.
    var retrofitMult: Double {
        switch self {
        case .coal: return 0
        case .gas: return 5
        case .clean: return 25
        }
    }
}

struct ModelNode: Identifiable {
    let id: String
    let name: String
    let desc: String
    let cost: Double
    let maxLevel: Int
}

enum Phase {
    static func name(_ p: Int) -> String {
        switch p {
        case 0: return "Verdant Earth"
        case 1: return "Smog Earth"
        default: return "Ash Earth"
        }
    }
}
