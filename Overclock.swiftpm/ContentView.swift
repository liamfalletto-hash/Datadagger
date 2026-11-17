import SwiftUI

struct ContentView: View {
    @EnvironmentObject var game: Game
    @State private var tab: Tab = .shop
    @State private var showPlanet = false

    enum Tab: String, CaseIterable, Identifiable {
        case shop, model, facts, dev
        var id: String { rawValue }

        var title: String {
            switch self {
            case .shop: return "SHOP"
            case .model: return "MODEL"
            case .facts: return "FACTS"
            case .dev: return "DEV"
            }
        }

        var panelTitle: String {
            switch self {
            case .shop: return "SHOP"
            case .model: return "AI LAB"
            case .facts: return "FACTS"
            case .dev: return "DEV"
            }
        }

        var symbol: String {
            switch self {
            case .shop: return "cart.fill"
            case .model: return "sparkles"
            case .facts: return "book.fill"
            case .dev: return "wrench.and.screwdriver.fill"
            }
        }

        var tint: Arcade.Tint {
            switch self {
            case .shop: return .green
            case .model: return .purple
            case .facts: return .blue
            case .dev: return .grey
            }
        }
    }

    private var tabs: [Tab] {
        Config.debug ? Tab.allCases : Tab.allCases.filter { $0 != .dev }
    }

    /// Earth Health rounded to 2%, so the weathered UI only redraws now and then.
    private var uiHealth: Double { (game.health / 2).rounded() * 2 }

    var body: some View {
        GeometryReader { geo in
            let safeTop = geo.safeAreaInsets.top
            let worldHeight = max(300, geo.size.height * 0.5)
            VStack(spacing: 0) {
                WorldArea(showPlanet: $showPlanet, safeTop: safeTop)
                    .frame(height: worldHeight + safeTop)
                    .padding(.top, -safeTop)
                ShopSheet(tab: $tab, tabs: tabs)
                    .padding(.top, -26)
            }
        }
        .background(Arcade.ink.ignoresSafeArea())
        .overlay {
            WeatherOverlay(health: uiHealth)
                .ignoresSafeArea()
        }
        .overlay { modals }
        .environment(\.earthHealth, uiHealth)
        .onChange(of: tab) { newTab in
            if newTab == .facts { game.markFactsRead() }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: game.factQueue.first?.id)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: game.offlineReport != nil)
    }

    @ViewBuilder private var modals: some View {
        if let report = game.offlineReport {
            ZStack {
                ModalBackdrop { game.offlineReport = nil }
                OfflineCard(report: report) { game.offlineReport = nil }
                    .padding(.horizontal, 20)
                    .transition(.scale(scale: 0.85).combined(with: .opacity))
            }
        } else if let fact = game.factQueue.first {
            ZStack {
                ModalBackdrop { game.dismissFact() }
                FactCard(fact: fact, collected: game.seenFacts.count) { game.dismissFact() }
                    .padding(.horizontal, 20)
                    .transition(.scale(scale: 0.85).combined(with: .opacity))
                    .id(fact.id)
            }
        }
    }
}

// MARK: - The world (top half)

struct WorldArea: View {
    @EnvironmentObject var game: Game
    @Binding var showPlanet: Bool
    let safeTop: CGFloat

    var body: some View {
        let onPlanet = showPlanet || game.locationStage >= 5
        let hudSpace = safeTop + 118
        ZStack(alignment: .top) {
            Group {
                if onPlanet {
                    EarthView(top: hudSpace)
                } else {
                    BaseView(top: hudSpace)
                }
            }
            .modifier(TapToEarn())
            .transition(.opacity)

            // Darken a little behind the HUD, and melt into the shop panel at the bottom.
            VStack(spacing: 0) {
                LinearGradient(colors: [Color.black.opacity(0.45), Color.black.opacity(0)], startPoint: .top, endPoint: .bottom)
                    .frame(height: safeTop + 120)
                Spacer(minLength: 0)
                LinearGradient(colors: [Color.black.opacity(0), Color.black.opacity(0.4)], startPoint: .top, endPoint: .bottom)
                    .frame(height: 90)
            }
            .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: 10) {
                HUD()
                HStack(spacing: 6) {
                    TagBlock(text: Config.locations[game.locationStage].name.uppercased(), tint: .yellow)
                    TagBlock(text: "MODEL V\(game.modelVersion)", tint: .purple, size: 13)
                    if game.isHeatwave {
                        TagBlock(text: "HEATWAVE", tint: .red, size: 13)
                    }
                    Spacer(minLength: 0)
                    if game.locationStage < 5 {
                        Button {
                            withAnimation(.easeInOut(duration: 0.4)) { showPlanet.toggle() }
                        } label: {
                            OutlinedSymbol(showPlanet ? "house.fill" : "globe.europe.africa.fill", size: 20)
                                .frame(width: 44, height: 44)
                        }
                        .buttonStyle(ArcadeButtonStyle(tint: .blue))
                        .accessibilityLabel(showPlanet ? "Show your base" : "Show the planet")
                    }
                }
                Spacer(minLength: 0)
                HStack(alignment: .bottom) {
                    if game.isDead {
                        BodyText("The AI keeps running in silence.", size: 13)
                    }
                    Spacer(minLength: 0)
                    BoostButton()
                }
                .padding(.bottom, 40)
            }
            .padding(.top, safeTop + 4)
            .padding(.horizontal, 10)

            if let p = game.phaseBanner {
                PhaseBanner(phase: p)
                    .transition(.opacity.combined(with: .scale(scale: 1.15)))
            } else if let m = game.moveBanner {
                MoveBanner(location: Config.locations[m])
                    .transition(.opacity.combined(with: .scale(scale: 1.15)))
            }
        }
        .clipped()
        .animation(.easeInOut(duration: 0.5), value: game.phaseBanner)
        .animation(.easeInOut(duration: 0.5), value: game.moveBanner)
        .onChange(of: game.phaseBanner) { value in
            guard value != nil else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                if game.phaseBanner == value { game.phaseBanner = nil }
            }
        }
        .onChange(of: game.moveBanner) { value in
            guard value != nil else { return }
            showPlanet = false // jump back to the base to see the new place
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                if game.moveBanner == value { game.moveBanner = nil }
            }
        }
    }
}

struct HUD: View {
    @EnvironmentObject var game: Game

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            HStack(spacing: 2) {
                CoinIcon(size: 46)
                    .offset(x: -8)
                VStack(alignment: .leading, spacing: -6) {
                    StrokeText(Fmt.num(game.tokens), size: 26)
                    StrokeText("+\(Fmt.num(game.incomePerSecond))/s", size: 12.5,
                               color: game.isOverclocking ? Arcade.gold : Arcade.mint, display: false)
                }
                Spacer(minLength: 0)
            }
            .padding(.trailing, 6)
            .padding(.vertical, 3)
            .background(PillBackground(seed: 3))
            EarthPill(health: game.health, phase: game.phase)
                .frame(width: 150)
        }
    }
}

struct PillBackground: View {
    var seed: Int

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
        ZStack {
            shape.fill(Color(red: 0.03, green: 0.05, blue: 0.11).opacity(0.62))
            Wear(seed: seed).clipShape(shape)
            shape.strokeBorder(Arcade.ink, lineWidth: 3)
        }
        .background(shape.fill(Arcade.ink).offset(y: 4))
    }
}

struct EarthPill: View {
    let health: Double
    let phase: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 2) {
                MiniGlobe(health: health, size: 22)
                StrokeText(healthText, size: 18)
                Spacer(minLength: 0)
                if phase == 2 {
                    StrokeText("!", size: 20, color: Color(red: 1, green: 0.35, blue: 0.23))
                }
            }
            Segments(count: 10, filled: Int((health / 10).rounded(.up)),
                     top: Palette.c(Arcade.barTop, health), bottom: Palette.c(Arcade.barBottom, health), height: 10)
                .padding(.horizontal, 2)
            StrokeText(Phase.name(phase).uppercased(), size: 10, color: Palette.c(Arcade.phaseText, health), display: false, stroke: 1.2)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(PillBackground(seed: 7))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Earth Health \(Int(health)) percent, \(Phase.name(phase))")
    }

    private var healthText: String {
        if health <= 0 { return "0%" }
        if health < 10 { return String(format: "%.1f%%", health) }
        return "\(Int(health.rounded()))%"
    }
}

struct TagBlock: View {
    let text: String
    var tint: Arcade.Tint
    var size: CGFloat = 15
    @Environment(\.earthHealth) var health

    var body: some View {
        let face = Arcade.colors(tint, decay: 1 - health / 100)
        StrokeText(text, size: size)
            .padding(.horizontal, 5)
            .background(ArcadeFace(top: face.0, bottom: face.1, radius: 10))
            .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Arcade.ink).offset(y: 3))
    }
}

struct BoostButton: View {
    @EnvironmentObject var game: Game
    @Environment(\.earthHealth) var health

    var body: some View {
        let now = Date()
        let active = game.isOverclocking
        let ready = game.overclockReady
        let activeLeft = max(0, game.overclockUntil.timeIntervalSince(now))
        let coolLeft = max(0, game.overclockReadyAt.timeIntervalSince(now))
        let progress: Double = active ? activeLeft / Config.overclockSeconds : (ready ? 1 : 1 - coolLeft / Config.overclockCooldown)
        let label = active ? "\(Int(activeLeft.rounded(.up)))s" : (ready ? "BOOST" : "\(Int(coolLeft.rounded(.up)))s")
        let face = Arcade.colors(ready || active ? .orange : .slate, decay: 1 - health / 100)
        let ring = ready || active ? Color(red: 1, green: 0.88, blue: 0.4) : Color(white: 0.75)
        Button {
            game.overclock()
        } label: {
            ZStack {
                Circle().stroke(Arcade.ink, lineWidth: 9)
                    .frame(width: 84, height: 84)
                Circle().trim(from: 0, to: min(1, max(0, progress)))
                    .stroke(ring, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 84, height: 84)
                OutlinedSymbol("bolt.fill", size: 30)
                    .frame(width: 70, height: 70)
                    .background(ArcadeFace(top: face.0, bottom: face.1, radius: 35))
                    .background(Circle().fill(Arcade.ink).offset(y: 4))
                    .scaleEffect(active ? 1 + 0.05 * sin(now.timeIntervalSinceReferenceDate * 10) : 1)
            }
            .frame(width: 92, height: 92)
        }
        .buttonStyle(PressScale())
        .disabled(!ready)
        .overlay(alignment: .bottom) {
            StrokeText(label, size: 14)
                .offset(y: 16)
                .allowsHitTesting(false)
        }
        .padding(.bottom, 12)
        .accessibilityLabel(ready ? "Boost: double income and triple pollution for 10 seconds" : "Boost recharging")
    }
}

// MARK: - The shop panel (bottom half)

struct ShopSheet: View {
    @Environment(\.earthHealth) var health
    @Binding var tab: ContentView.Tab
    let tabs: [ContentView.Tab]

    var body: some View {
        let decay = 1 - health / 100
        let shape = TopRounded(radius: 26)
        VStack(spacing: 8) {
            ScrollView {
                VStack(spacing: 14) {
                    switch tab {
                    case .shop: ShopTab()
                    case .model: ModelTab()
                    case .facts: FactsTab()
                    case .dev: DevTab()
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 36)
                .padding(.bottom, 14)
            }
            .scrollIndicators(.hidden)
            TabBar(selection: $tab, tabs: tabs)
                .padding(.horizontal, 12)
                .padding(.bottom, 2)
        }
        .background(
            ZStack {
                shape.fill(LinearGradient(colors: [Palette.c(Arcade.bodyTop, health), Palette.c(Arcade.bodyBottom, health)], startPoint: .top, endPoint: .bottom))
                Stripes(opacity: 0.07 - 0.04 * decay).clipShape(shape)
                Wear(seed: 11).clipShape(shape)
                shape.stroke(Arcade.ink, lineWidth: 3)
            }
            .ignoresSafeArea(edges: .bottom)
        )
        .overlay(alignment: .top) {
            TitleBlock(text: tab.panelTitle)
                .offset(y: -24)
        }
    }
}

struct TitleBlock: View {
    let text: String
    @Environment(\.earthHealth) var health

    var body: some View {
        let decay = 1 - health / 100
        let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)
        StrokeText(text, size: 26)
            .frame(minWidth: 140)
            .padding(.horizontal, 14)
            .frame(height: 48)
            .background(
                ZStack {
                    shape.fill(LinearGradient(colors: [Palette.c(Arcade.headerTop, health), Palette.c(Arcade.headerBottom, health)], startPoint: .top, endPoint: .bottom))
                    Stripes(opacity: 0.12).clipShape(shape)
                    Wear(seed: 5).clipShape(shape)
                    shape.strokeBorder(Arcade.ink, lineWidth: 3)
                }
            )
            .background(shape.fill(Arcade.ink).offset(y: 5))
            .rotationEffect(.degrees(-6 * max(0, decay - 0.3)))
    }
}

struct TabBar: View {
    @EnvironmentObject var game: Game
    @Binding var selection: ContentView.Tab
    let tabs: [ContentView.Tab]

    var body: some View {
        HStack(spacing: 9) {
            ForEach(tabs) { tab in
                let selected = tab == selection
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selection = tab }
                } label: {
                    VStack(spacing: -2) {
                        OutlinedSymbol(tab.symbol, size: 22)
                        StrokeText(tab.title, size: 13)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 64)
                    .overlay(
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .strokeBorder(Color.white.opacity(selected ? 0.95 : 0), lineWidth: 3)
                            .padding(5)
                    )
                }
                .buttonStyle(ArcadeButtonStyle(tint: tab.tint, radius: 16))
                .scaleEffect(selected ? 1.04 : 0.96)
                .overlay(alignment: .topTrailing) {
                    let count = badge(for: tab)
                    if count > 0 {
                        CountBadge(value: count)
                            .offset(x: 8, y: -10)
                    }
                }
                .accessibilityLabel(tab.title)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
    }

    private func badge(for tab: ContentView.Tab) -> Int {
        switch tab {
        case .facts: return game.unreadFacts
        case .model: return game.pendingParameters >= 1 ? 1 : 0
        default: return 0
        }
    }
}

// MARK: - Shop tab

struct ShopTab: View {
    @EnvironmentObject var game: Game

    var body: some View {
        BuyAmountRow(selection: $game.buyAmount)
        if let next = game.nextLocation {
            NextMoveCard(location: next, have: game.owned[next.tier])
        }
        ForEach(Config.tiers.filter { game.isUnlocked($0.id) }) { tier in
            TierCard(tier: tier)
        }
        if let locked = Config.tiers.first(where: { !game.isUnlocked($0.id) }) {
            LockedCard(title: locked.name, reason: lockReason(locked))
        }
    }

    private func lockReason(_ t: Tier) -> String {
        if game.phase < t.minPhase { return "Arrives when the Earth reaches \(Phase.name(t.minPhase))" }
        let prev = Config.tiers[t.id - 1]
        return "Own \(Config.unlockCount) \(prev.name) (\(game.owned[prev.id])/\(Config.unlockCount))"
    }
}

struct BuyAmountRow: View {
    @Binding var selection: BuyAmount

    var body: some View {
        HStack(spacing: 7) {
            StrokeText("BUY", size: 16)
            ForEach(BuyAmount.allCases) { amount in
                Button {
                    selection = amount
                } label: {
                    StrokeText(amount == .max ? "MAX" : amount.rawValue, size: 15)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                }
                .buttonStyle(ArcadeButtonStyle(tint: amount == selection ? .green : .slate, radius: 12))
                .accessibilityLabel("Buy \(amount.rawValue)")
                .accessibilityAddTraits(amount == selection ? .isSelected : [])
            }
        }
    }
}

struct NextMoveCard: View {
    let location: Location
    let have: Int

    var body: some View {
        let done = min(have, location.count)
        let segments = min(10, max(1, location.count))
        let filled = Int((Double(done) / Double(max(1, location.count)) * Double(segments)).rounded(.down))
        HStack(spacing: 11) {
            IconTile(symbol: "shippingbox.fill", colors: (RGB(1, 0.95, 0.76), RGB(1, 0.75, 0.3)), size: 54)
            VStack(alignment: .leading, spacing: -3) {
                StrokeText("NEXT MOVE", size: 12.5, color: Color(red: 1, green: 0.95, blue: 0.77))
                StrokeText(location.name.uppercased(), size: 20)
                HStack(spacing: 6) {
                    Segments(count: segments, filled: filled,
                             top: Color(red: 1, green: 0.95, blue: 0.48), bottom: Color(red: 1, green: 0.7, blue: 0), height: 9)
                    StrokeText("\(done)/\(location.count)", size: 12)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(9)
        .arcadePanel(seed: 21, top: Arcade.moveTop, bottom: Arcade.moveBottom)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Next move: \(location.name). \(done) of \(location.count) \(Config.tiers[location.tier].name)")
    }
}

struct TierCard: View {
    @EnvironmentObject var game: Game
    @Environment(\.earthHealth) var health
    let tier: Tier

    var body: some View {
        let i = tier.id
        let count = game.owned[i]
        let qty = game.purchaseQuantity(i)
        let price = game.cost(i, quantity: qty)
        let affordable = game.tokens >= price
        HStack(spacing: 12) {
            IconTile(symbol: tier.icon, colors: Arcade.tierColors(i), size: 56, level: count)
            VStack(alignment: .leading, spacing: -1) {
                StrokeText(tier.name, size: 16, display: false)
                HStack(spacing: 6) {
                    HStack(spacing: 2) {
                        CoinIcon(size: 13)
                        StrokeText("\(Fmt.num(game.output(i)))/s", size: 12, color: Arcade.gold, display: false)
                    }
                    HStack(spacing: 2) {
                        OutlinedSymbol("smoke.fill", size: 10, color: Arcade.smogText)
                        StrokeText("\(Fmt.num(game.pollution(i)))/s", size: 12, color: Arcade.smogText, display: false)
                    }
                }
                if let next = game.nextMilestone(i) {
                    HStack(spacing: 5) {
                        Segments(count: 10, filled: milestoneSegments(count, next),
                                 top: Color(red: 1, green: 0.95, blue: 0.48), bottom: Color(red: 1, green: 0.7, blue: 0), height: 9)
                        StrokeText("×2 @ \(next)", size: 10, display: false)
                    }
                    .padding(.top, 2)
                }
                if game.canChoosePower && count > 0 {
                    PowerMenu(index: i)
                }
            }
            Spacer(minLength: 0)
            Button {
                game.buy(i)
            } label: {
                VStack(spacing: -5) {
                    StrokeText("BUY ×\(qty)", size: 12)
                    HStack(spacing: 2) {
                        CoinIcon(size: 15)
                        StrokeText(Fmt.num(price), size: 18)
                    }
                }
                .frame(width: 96, height: 60)
            }
            .buttonStyle(ArcadeButtonStyle(tint: .green))
            .disabled(!affordable)
            .accessibilityLabel("Buy \(qty) \(tier.name) for \(Fmt.num(price)) tokens")
        }
        .padding(9)
        .arcadePanel(seed: 31 + i * 7)
        .overlay(alignment: .top) {
            if health < 40 && i % 2 == 0 {
                HazardTape()
                    .rotationEffect(.degrees(-14))
                    .offset(x: 40, y: -6)
            }
        }
    }

    /// How far we are from the previous milestone to the next one, in ten segments.
    private func milestoneSegments(_ count: Int, _ next: Int) -> Int {
        let previous = Config.milestones.last(where: { $0 <= count }) ?? 0
        let span = max(1, next - previous)
        return min(10, max(0, Int(Double(count - previous) / Double(span) * 10)))
    }
}

struct PowerMenu: View {
    @EnvironmentObject var game: Game
    let index: Int

    var body: some View {
        let current = game.power[index]
        Menu {
            ForEach(Power.allCases) { p in
                let price = game.retrofitCost(index, to: p)
                Button {
                    game.retrofit(index, to: p)
                } label: {
                    if p == current {
                        Label("\(p.label) (current)", systemImage: "checkmark")
                    } else if p.rank < current.rank {
                        Text("\(p.label) (no going back)")
                    } else {
                        Text("Switch to \(p.label): ◈\(Fmt.num(price)), pollution ×\(String(format: "%g", p.pollutionMult))")
                    }
                }
                .disabled(p.rank <= current.rank || game.tokens < price)
            }
        } label: {
            HStack(spacing: 3) {
                OutlinedSymbol(current.symbol, size: 10, color: Arcade.gold)
                StrokeText("POWER: \(current.label.uppercased())", size: 11)
                OutlinedSymbol("chevron.down", size: 8)
            }
        }
        .accessibilityLabel("Power source: \(current.label)")
    }
}

struct LockedCard: View {
    let title: String
    let reason: String

    var body: some View {
        HStack(spacing: 11) {
            IconTile(symbol: "lock.fill", colors: Arcade.base(.slate), size: 52, muted: true)
            VStack(alignment: .leading, spacing: -2) {
                StrokeText(title, size: 16, display: false)
                StrokeText(reason, size: 11.5, color: Color(white: 0.85), display: false)
            }
            Spacer(minLength: 0)
        }
        .padding(9)
        .arcadePanel(dashed: true)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Locked: \(title). \(reason)")
    }
}

// MARK: - Model tab

struct ModelTab: View {
    @EnvironmentObject var game: Game
    @State private var confirming = false

    var body: some View {
        let pending = game.pendingParameters
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 11) {
                IconTile(symbol: "brain.head.profile", colors: Arcade.base(.purple), size: 58)
                VStack(alignment: .leading, spacing: -4) {
                    StrokeText("CURRENT MODEL", size: 12, color: Color(red: 0.86, green: 0.78, blue: 1))
                    StrokeText("MODEL V\(game.modelVersion)", size: 24)
                    StrokeText("\(Fmt.num(game.unspentParameters)) Parameters · +\(Fmt.num((game.parameterMultiplier - 1) * 100))% income",
                               size: 12, display: false)
                }
                Spacer(minLength: 0)
            }
            if pending >= 1 {
                Button {
                    if confirming {
                        game.trainNewModel()
                        confirming = false
                    } else {
                        confirming = true
                    }
                } label: {
                    HStack(spacing: 8) {
                        StrokeText(confirming ? "TAP AGAIN TO RESET" : "TRAIN MODEL V\(game.modelVersion + 1)", size: 18)
                        StrokeText("+\(Fmt.num(pending)) P", size: 13, color: Arcade.gold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                }
                .buttonStyle(ArcadeButtonStyle(tint: confirming ? .red : .purple))
            } else {
                Segments(count: 10, filled: Int(min(1, game.lifetimeTokens / max(1, game.nextParameterAt)) * 10),
                         top: Color(red: 0.86, green: 0.75, blue: 1), bottom: Color(red: 0.48, green: 0.25, blue: 0.95), height: 10)
                StrokeText("Next Parameter at \(Fmt.num(game.nextParameterAt)) tokens earned", size: 11.5, color: Color(white: 0.9), display: false)
            }
            BodyText("Training resets your buildings and tokens and heals the Earth. You keep your Parameters: each unspent one adds 2% income.", size: 12.5)
        }
        .padding(12)
        .arcadePanel(seed: 41, top: Arcade.purpleTop, bottom: Arcade.purpleBottom)

        SectionTitle(text: "UPGRADES")
        ForEach(Config.modelTree) { node in
            ModelNodeCard(node: node)
        }
        SectionTitle(text: "RESTORATION")
        LockedCard(title: "Restoration", reason: game.isDead ? "Coming in the next update" : "Reach 0% Earth Health to unlock")
    }
}

struct ModelNodeCard: View {
    @EnvironmentObject var game: Game
    let node: ModelNode

    var body: some View {
        let level = game.level(node.id)
        let maxed = level >= node.maxLevel
        let price = game.nodeCost(node)
        HStack(spacing: 11) {
            IconTile(symbol: node.symbol, colors: node.tint, size: 50)
            VStack(alignment: .leading, spacing: 1) {
                StrokeText(node.name, size: 15.5, display: false)
                BodyText(node.desc, size: 12)
                if node.maxLevel > 1 {
                    Segments(count: node.maxLevel, filled: level,
                             top: Color(red: 0.86, green: 0.75, blue: 1), bottom: Color(red: 0.48, green: 0.25, blue: 0.95), height: 8)
                        .frame(width: CGFloat(node.maxLevel) * 18)
                }
            }
            Spacer(minLength: 0)
            Button {
                game.research(node)
            } label: {
                StrokeText(maxed ? "DONE" : "\(Fmt.num(price)) P", size: 16)
                    .frame(width: 74, height: 46)
            }
            .buttonStyle(ArcadeButtonStyle(tint: .purple))
            .disabled(maxed || game.unspentParameters < price)
        }
        .padding(9)
        .arcadePanel(seed: 51 + node.id.count * 3)
    }
}

// MARK: - Facts tab

struct FactsTab: View {
    @EnvironmentObject var game: Game

    var body: some View {
        let found = Facts.all.filter { game.seenFacts.contains($0.id) }.count
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                StrokeText("COLLECTED", size: 17)
                Spacer(minLength: 0)
                StrokeText("\(found)/\(Facts.all.count)", size: 19, color: Arcade.gold)
            }
            Segments(count: Facts.all.count, filled: found,
                     top: Color(red: 0.62, green: 0.9, blue: 1), bottom: Color(red: 0.11, green: 0.5, blue: 0.88), height: 9)
            BodyText("Every fact here is real and sourced. The wasteland in the game is fiction, exaggerated so you can see the numbers.", size: 12.5)
        }
        .padding(12)
        .arcadePanel(seed: 61)
        ForEach(Facts.all) { fact in
            if game.seenFacts.contains(fact.id) {
                FactRow(fact: fact)
            } else {
                LockedCard(title: "???", reason: fact.unlockHint)
            }
        }
    }
}

struct FactRow: View {
    let fact: Fact

    var body: some View {
        HStack(alignment: .top, spacing: 11) {
            IconTile(symbol: fact.symbol, colors: fact.tint, size: 48)
            VStack(alignment: .leading, spacing: 3) {
                StrokeText(fact.title.uppercased(), size: 15)
                BodyText(fact.text, size: 13)
                BodyText("Source: \(fact.source)", size: 11, color: Color(white: 0.8))
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .arcadePanel(seed: 71 + fact.id.count)
    }
}

// MARK: - Dev tab

struct DevTab: View {
    @EnvironmentObject var game: Game
    @State private var confirmReset = false

    var body: some View {
        BodyText("Testing tools. Turn them off with Config.debug = false.", size: 12.5)
        devRow("SKIP TIME", [("+10 MIN", { game.devSkip(seconds: 600) }), ("+1 HOUR", { game.devSkip(seconds: 3600) }), ("+1 DAY", { game.devSkip(seconds: 86_400) })])
        devRow("TOKENS", [("+10K", { game.devAdd(10_000) }), ("+1B", { game.devAdd(1e9) }), ("×10", { game.devMultiply(by: 10) })])
        devRow("EARTH", [("-10%", { game.devDamageEarth(10) }), ("-34%", { game.devDamageEarth(34) })])
        devRow("SPEED \(Int(game.speed))×", [("1×", { game.speed = 1 }), ("10×", { game.speed = 10 }), ("100×", { game.speed = 100 })])
        devRow("MORE", [("+50 PARAMS", { game.devGrantParameters(50) }), ("AWAY 2H", { game.devSimulateOffline(seconds: 7200) })])
        Button {
            if confirmReset {
                game.resetEverything()
                confirmReset = false
            } else {
                confirmReset = true
            }
        } label: {
            StrokeText(confirmReset ? "TAP AGAIN TO ERASE" : "RESET SAVE", size: 16)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
        }
        .buttonStyle(ArcadeButtonStyle(tint: .red))
        BodyText("Pollution \(Fmt.num(game.pollutionPerSecond))/s · Taps \(game.totalTaps)", size: 11.5, color: Color(white: 0.8))
    }

    private func devRow(_ title: String, _ buttons: [(String, () -> Void)]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            StrokeText(title, size: 13)
            HStack(spacing: 7) {
                ForEach(0..<buttons.count, id: \.self) { k in
                    Button(action: buttons[k].1) {
                        StrokeText(buttons[k].0, size: 13)
                            .frame(maxWidth: .infinity)
                            .frame(height: 38)
                    }
                    .buttonStyle(ArcadeButtonStyle(tint: .slate, radius: 12))
                }
            }
        }
        .padding(10)
        .arcadePanel(seed: 91 + title.count)
    }
}

// MARK: - Small pieces

struct BodyText: View {
    let text: String
    var size: CGFloat = 13
    var color: Color = .white

    init(_ text: String, size: CGFloat = 13, color: Color = .white) {
        self.text = text
        self.size = size
        self.color = color
    }

    var body: some View {
        Text(text)
            .font(ArcadeFont.body(size))
            .foregroundColor(color)
            .shadow(color: Arcade.ink, radius: 0, x: 0, y: 1.5)
            .shadow(color: Arcade.ink.opacity(0.8), radius: 0, x: 1, y: 0)
            .fixedSize(horizontal: false, vertical: true)
    }
}

struct SectionTitle: View {
    let text: String

    var body: some View {
        StrokeText(text, size: 17)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 4)
    }
}

struct ModalBackdrop: View {
    let tap: () -> Void

    var body: some View {
        Color.black.opacity(0.55)
            .ignoresSafeArea()
            .onTapGesture(perform: tap)
            .transition(.opacity)
            .accessibilityHidden(true)
    }
}

struct TitleRibbon: View {
    let text: String
    var tint: Arcade.Tint = .yellow
    @Environment(\.earthHealth) var health

    var body: some View {
        let face = Arcade.colors(tint, decay: 1 - health / 100)
        StrokeText(text, size: 20)
            .padding(.horizontal, 14)
            .frame(height: 40)
            .background(ArcadeFace(top: face.0, bottom: face.1, radius: 12))
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Arcade.ink).offset(y: 4))
    }
}

struct CloseButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            OutlinedSymbol("xmark", size: 16)
                .frame(width: 40, height: 40)
        }
        .buttonStyle(ArcadeButtonStyle(tint: .red, radius: 12))
        .accessibilityLabel("Close")
    }
}

struct FactCard: View {
    let fact: Fact
    let collected: Int
    let dismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                IconTile(symbol: fact.symbol, colors: fact.tint, size: 58)
                VStack(alignment: .leading, spacing: -3) {
                    StrokeText("FACT \(collected) OF \(Facts.all.count)", size: 12, color: Arcade.gold)
                    StrokeText(fact.title.uppercased(), size: 21)
                }
                Spacer(minLength: 0)
            }
            Text(fact.text)
                .font(ArcadeFont.body(15))
                .foregroundColor(Color(red: 0.12, green: 0.13, blue: 0.2))
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color(red: 0.97, green: 0.97, blue: 1)))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Arcade.ink, lineWidth: 3))
            HStack(spacing: 8) {
                BodyText("Source: \(fact.source)", size: 11.5, color: Color(white: 0.9))
                Spacer(minLength: 0)
                Button(action: dismiss) {
                    StrokeText("GOT IT!", size: 18)
                        .frame(width: 112, height: 46)
                }
                .buttonStyle(ArcadeButtonStyle(tint: .green))
            }
        }
        .padding(14)
        .padding(.top, 14)
        .arcadePanel(seed: 81, radius: 20)
        .overlay(alignment: .top) {
            TitleRibbon(text: "NEW FACT!")
                .offset(y: -22)
        }
        .overlay(alignment: .topTrailing) {
            CloseButton(action: dismiss)
                .offset(x: 10, y: -16)
        }
    }
}

struct OfflineCard: View {
    let report: OfflineReport
    let collect: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            BodyText("You were away for \(Fmt.duration(report.seconds)). Your AI kept answering queries.", size: 14)
                .multilineTextAlignment(.center)
            HStack(spacing: 4) {
                CoinIcon(size: 34)
                StrokeText("+" + Fmt.num(report.tokens), size: 34, color: Arcade.gold)
            }
            BodyText("Earth Health \(Int(report.healthBefore))% → \(Int(report.healthAfter))%", size: 13, color: Color(white: 0.9))
            Button(action: collect) {
                StrokeText("COLLECT", size: 20)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
            }
            .buttonStyle(ArcadeButtonStyle(tint: .green))
        }
        .padding(16)
        .padding(.top, 14)
        .arcadePanel(seed: 85, radius: 20)
        .overlay(alignment: .top) {
            TitleRibbon(text: "WELCOME BACK!")
                .offset(y: -22)
        }
    }
}

struct PhaseBanner: View {
    let phase: Int

    var body: some View {
        let title: String
        let subtitle: String
        let color: Color
        switch phase {
        case 1:
            title = "SMOG EARTH"
            subtitle = "Income ×3 · Power choice unlocked · New buildings"
            color = Color(red: 0.86, green: 0.86, blue: 0.8)
        case 2:
            title = "ASH EARTH"
            subtitle = "Income ×5 · Heatwaves slow water-cooled sites"
            color = Color(red: 1, green: 0.6, blue: 0.3)
        default:
            title = "THE LAST RIVER RUNS DRY"
            subtitle = "Restoration will unlock here in a future update."
            color = Color(red: 1, green: 0.42, blue: 0.3)
        }
        return VStack(spacing: 4) {
            StrokeText("THE PLANET CHANGED", size: 13, color: Arcade.gold)
            StrokeText(title, size: phase == 3 ? 24 : 38, color: color)
            BodyText(subtitle, size: 13)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .arcadePanel(seed: 77, radius: 20)
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.35))
        .allowsHitTesting(false)
    }
}

struct MoveBanner: View {
    let location: Location

    var body: some View {
        VStack(spacing: 4) {
            StrokeText("MOVING DAY!", size: 15, color: Arcade.gold)
            StrokeText(location.name.uppercased(), size: 34)
            BodyText(location.tagline, size: 13)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .arcadePanel(seed: 79, top: Arcade.moveTop, bottom: Arcade.moveBottom, radius: 20)
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.35))
        .allowsHitTesting(false)
    }
}
