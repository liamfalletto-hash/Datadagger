// ============================================================
//  GAME CONFIG: this is the file to play around with.
//  Change names, emoji and numbers, add generators or upgrades,
//  then press ⌘R in Xcode to run it again.
// ============================================================

import Foundation

enum GameConfig {
    static let title = "Spore Garden"
    /// Change this string to start over with an empty save.
    static let saveKey = "spore-garden-save-v1"
    /// Shows the "Dev" tab with time skips and cheats. Set to false before shipping.
    static let debug = true

    static let currencyName = "Spores"
    static let currencyIcon = "🍄"

    /// What one tap on the big button is worth before upgrades.
    static let tapBase: Double = 1

    /// Offline earnings: income for the time the app was closed.
    static let offlineMaxHours: Double = 8     // cap
    static let offlineEfficiency: Double = 0.5 // 50% of normal income

    /// Generators produce currency every second.
    ///  - baseCost:   price of the first one
    ///  - costGrowth: each purchase multiplies the price by this (1.07–1.15 is typical)
    ///  - baseRate:   currency per second for ONE of them
    /// A generator appears once you own at least one of the generator before it.
    static let generators: [GeneratorDef] = [
        GeneratorDef(id: "mycelium", name: "Mycelium Thread", icon: "🧵", baseCost: 15,     costGrowth: 1.15, baseRate: 0.1),
        GeneratorDef(id: "patch",    name: "Mushroom Patch",  icon: "🌿", baseCost: 100,    costGrowth: 1.15, baseRate: 1),
        GeneratorDef(id: "log",      name: "Rotting Log",     icon: "🪵", baseCost: 1_100,  costGrowth: 1.15, baseRate: 8),
        GeneratorDef(id: "pig",      name: "Truffle Pig",     icon: "🐖", baseCost: 12_000, costGrowth: 1.15, baseRate: 47),
        GeneratorDef(id: "grove",    name: "Fungal Grove",    icon: "🌳", baseCost: 130_000, costGrowth: 1.15, baseRate: 260),
        GeneratorDef(id: "moon",     name: "Moonlit Ring",    icon: "🌕", baseCost: 1.4e6,  costGrowth: 1.15, baseRate: 1_400),
        GeneratorDef(id: "network",  name: "Wood Wide Web",   icon: "🕸️", baseCost: 2e7,    costGrowth: 1.15, baseRate: 7_800),
    ]

    /// Owning this many of one generator doubles its output. Each one stacks.
    static let milestones = [25, 50, 100, 200, 300, 400]

    /// One-time upgrades.
    /// Effects:   .tap(mult:)  .generator(id:mult:)  .all(mult:)  .tapPercent(_)
    /// Requires:  .always  .owns(generatorID, count)  .lifetime(amount)
    static let upgrades: [UpgradeDef] = [
        UpgradeDef(id: "tap1", name: "Gentle Squeeze",  desc: "Taps ×2",            cost: 50,      effect: .tap(mult: 2)),
        UpgradeDef(id: "myc1", name: "Damp Soil",       desc: "Mycelium ×2",        cost: 200,     effect: .generator(id: "mycelium", mult: 2), requires: .owns("mycelium", 5)),
        UpgradeDef(id: "pat1", name: "Shade Cloth",     desc: "Patches ×2",         cost: 1_000,   effect: .generator(id: "patch", mult: 2),    requires: .owns("patch", 5)),
        UpgradeDef(id: "tap2", name: "Spore Puff",      desc: "Taps ×3",            cost: 5_000,   effect: .tap(mult: 3),                       requires: .lifetime(2_000)),
        UpgradeDef(id: "log1", name: "Beetle Helpers",  desc: "Logs ×2",            cost: 11_000,  effect: .generator(id: "log", mult: 2),      requires: .owns("log", 5)),
        UpgradeDef(id: "gold", name: "Golden Touch",    desc: "Each tap also gives 5% of your income per second", cost: 25_000, effect: .tapPercent(0.05), requires: .lifetime(10_000)),
        UpgradeDef(id: "pig1", name: "Keen Snouts",     desc: "Truffle Pigs ×2",    cost: 120_000, effect: .generator(id: "pig", mult: 2),      requires: .owns("pig", 5)),
        UpgradeDef(id: "all1", name: "Autumn Rain",     desc: "All production ×2",  cost: 500_000, effect: .all(mult: 2),                       requires: .lifetime(200_000)),
        UpgradeDef(id: "all2", name: "Fairy Ring Pact", desc: "All production ×3",  cost: 5e7,     effect: .all(mult: 3),                       requires: .lifetime(1e7)),
    ]

    /// Prestige: give up your progress for a permanent bonus.
    static let prestige = PrestigeConfig(
        name: "Moonblooms",
        icon: "🌸",
        minLifetime: 1e6,    // currency earned this run before you can prestige
        divisor: 1e6,        // points = floor(sqrt(earned this run / divisor))
        bonusPerPoint: 0.10  // each point = +10% income and taps, forever
    )
}

// MARK: - Definitions (you usually don't need to edit below this line)

struct GeneratorDef: Identifiable {
    let id: String
    let name: String
    let icon: String
    let baseCost: Double
    let costGrowth: Double
    let baseRate: Double
}

enum UpgradeEffect {
    case tap(mult: Double)
    case generator(id: String, mult: Double)
    case all(mult: Double)
    case tapPercent(Double)
}

enum Requirement {
    case always
    case owns(String, Int)
    case lifetime(Double)
}

struct UpgradeDef: Identifiable {
    let id: String
    let name: String
    let desc: String
    let cost: Double
    let effect: UpgradeEffect
    var requires: Requirement = .always
}

struct PrestigeConfig {
    let name: String
    let icon: String
    let minLifetime: Double
    let divisor: Double
    let bonusPerPoint: Double
}
