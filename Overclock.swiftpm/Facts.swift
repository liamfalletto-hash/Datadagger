// Fact cards: text and sources copied from the design doc's "Starter fact deck".
// Rule from the doc: a card without a source does not ship.

struct Fact: Identifiable, Equatable {
    let id: String
    let title: String
    let text: String
    let source: String
    let unlockHint: String
}

enum Facts {
    static let all: [Fact] = [
        Fact(id: "one-prompt", title: "One prompt",
             text: "Google measured a median Gemini text prompt at 0.24 Wh, about 0.26 ml of water (five drops) and 0.03 g CO2e, after a 33-fold cut in energy per prompt in one year.",
             source: "MIT Technology Review", unlockHint: "Tap the planet"),
        Fact(id: "electricity-today", title: "Electricity today",
             text: "Data centers used about 415 TWh in 2024, around 1.5% of the world's electricity, growing about 12% a year over five years.",
             source: "IEA, Energy and AI", unlockHint: "Buy your first GPU Cluster"),
        Fact(id: "cooling", title: "Cooling energy",
             text: "Cooling takes about 7% of a data center's electricity in efficient hyperscale sites, but over 30% in less efficient ones.",
             source: "IEA, Energy demand from AI", unlockHint: "Buy your first Office Data Center"),
        Fact(id: "ai-site", title: "Size of one AI site",
             text: "A typical AI-focused data center uses as much electricity as 100,000 households; the largest under construction will use 20 times more.",
             source: "IEA, Energy and AI", unlockHint: "Buy your first Hyperscale Campus"),
        Fact(id: "scale", title: "Scale matters",
             text: "Per-prompt figures are small, but AI now serves billions of prompts a day, so totals still add up.",
             source: "IO+", unlockHint: "Earn 1 million Tokens"),
        Fact(id: "electricity-2030", title: "Electricity by 2030",
             text: "Data center demand is projected to more than double to about 945 TWh by 2030, slightly more than all of Japan uses today.",
             source: "IEA, Energy and AI", unlockHint: "Reach Smog Earth"),
        Fact(id: "power-sources", title: "Power sources",
             text: "Half of the growth in data center demand to 2030 is expected to be met by renewables; natural gas and nuclear each add about 175 TWh.",
             source: "IEA, Energy and AI", unlockHint: "Switch a building's power source"),
        Fact(id: "us-share", title: "US share",
             text: "US data centers used about 4.4% of US electricity in 2023, and could reach 6.7–12% by 2028.",
             source: "US DOE / LBNL 2024 report", unlockHint: "Buy your first Coal-Powered Megafarm"),
        Fact(id: "water-direct", title: "Water, direct",
             text: "US data centers directly consumed about 17 billion gallons (64 billion litres) of water in 2023 for cooling; this could double or quadruple by 2028.",
             source: "LBNL via The Conversation / AI Topics", unlockHint: "Buy your first Ocean-Cooled Fortress"),
        Fact(id: "ewaste", title: "E-waste",
             text: "The world produced a record 62 million tonnes of e-waste in 2022, and only 22.3% was documented as properly recycled.",
             source: "UNITAR, Global E-waste Monitor 2024", unlockHint: "Reach Ash Earth"),
        Fact(id: "water-hidden", title: "Water, hidden",
             text: "The water used to generate data centers' electricity is about 12 times larger than the water used for cooling on site.",
             source: "ITIF, citing LBNL", unlockHint: "Survive a heatwave"),
        Fact(id: "where", title: "Where it happens",
             text: "In 2024 the US used 45% of data center electricity, China 25% and Europe 15%.",
             source: "IEA, Energy and AI", unlockHint: "Buy your first Desert Gigafactory"),
        Fact(id: "ewaste-trend", title: "E-waste trend",
             text: "E-waste is on track to reach 82 million tonnes in 2030, rising five times faster than documented recycling.",
             source: "UNITAR, Global E-waste Monitor 2024", unlockHint: "Train a new model"),
        Fact(id: "other-side", title: "The other side",
             text: "Used well, AI could also cut energy use elsewhere, for example by optimising power grids and industry.",
             source: "IEA via DCD", unlockHint: "Research Distillation in the Model Tree"),
    ]

    static func byID(_ id: String) -> Fact? { all.first { $0.id == id } }

    /// Fact shown the first time each building tier is bought.
    static let firstBuy: [Int: String] = [
        1: "electricity-today", 2: "cooling", 3: "ai-site",
        4: "us-share", 5: "water-direct", 6: "where",
    ]
}
