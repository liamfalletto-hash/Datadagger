import SwiftUI

struct ContentView: View {
    @EnvironmentObject var game: Game
    @State private var tab: Tab = .build

    enum Tab: String, CaseIterable, Identifiable {
        case build = "Build", model = "Model", lab = "Stats Lab", dev = "Dev"
        var id: String { rawValue }
    }

    private var tabs: [Tab] {
        Config.debug ? Tab.allCases : Tab.allCases.filter { $0 != .dev }
    }

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                TopBar()
                    .padding(.bottom, 8)
                Stage()
                    .frame(height: geo.size.height * 0.45)
                    .clipped()
                VStack(spacing: 8) {
                    Picker("Section", selection: $tab) {
                        ForEach(tabs) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.top, 10)

                    ScrollView {
                        VStack(spacing: 10) {
                            switch tab {
                            case .build: BuildView()
                            case .model: ModelView()
                            case .lab: StatsLabView()
                            case .dev: DevView()
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                }
                .background(Palette.sheet)
            }
        }
        .background(Palette.background.ignoresSafeArea())
        .overlay(alignment: .bottom) {
            if let fact = game.factQueue.first {
                FactCard(fact: fact) { game.dismissFact() }
                    .padding()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .id(fact.id)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: game.factQueue.first?.id)
        .alert("While you were away", isPresented: Binding(
            get: { game.offlineReport != nil },
            set: { if !$0 { game.offlineReport = nil } }
        )) {
            Button("Collect") { game.offlineReport = nil }
        } message: {
            if let r = game.offlineReport {
                Text("\(Fmt.duration(r.seconds)) away. Your AI earned ◈\(Fmt.num(r.tokens)).\nEarth Health: \(Int(r.healthBefore))% → \(Int(r.healthAfter))%")
            }
        }
    }
}

// MARK: - Top bar

struct TopBar: View {
    @EnvironmentObject var game: Game

    var body: some View {
        VStack(spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text("◈ " + Fmt.num(game.tokens))
                    .font(.system(size: 30, weight: .heavy, design: .rounded).monospacedDigit())
                Spacer()
                Text("+\(Fmt.num(game.incomePerSecond))/s")
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(game.isOverclocking ? Color.red : Color.secondary)
            }
            HealthBar(health: game.health, phase: game.phase)
        }
        .padding(.horizontal)
        .padding(.top, 4)
    }
}

struct HealthBar: View {
    let health: Double
    let phase: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.12))
                    Capsule()
                        .fill(Palette.c(Palette.land, health))
                        .frame(width: max(4, geo.size.width * health / 100))
                }
            }
            .frame(height: 8)
            HStack {
                Text(health > 0 ? "Earth Health \(String(format: health < 10 ? "%.1f" : "%.0f", health))%" : "Earth Health 0%")
                Spacer()
                Text(Phase.name(phase))
            }
            .font(.caption.weight(.semibold).monospacedDigit())
            .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Stage (the planet + overlays)

struct Stage: View {
    @EnvironmentObject var game: Game
    @State private var showPlanet = false

    private var onPlanet: Bool { showPlanet || game.locationStage >= 5 }

    var body: some View {
        ZStack {
            Group {
                if onPlanet { EarthView() } else { BaseView() }
            }
            .modifier(TapToEarn())
            .transition(.opacity)

            VStack {
                HStack(spacing: 6) {
                    Chip(text: Config.locations[game.locationStage].name, symbol: "mappin.and.ellipse", tint: .white)
                    Chip(text: "v\(game.modelVersion)", symbol: "cpu", tint: Palette.accent)
                    if game.isHeatwave {
                        Chip(text: "Heatwave", symbol: "thermometer.sun.fill", tint: .orange)
                    }
                    Spacer()
                    if game.locationStage < 5 {
                        Button {
                            withAnimation(.easeInOut(duration: 0.4)) { showPlanet.toggle() }
                        } label: {
                            Image(systemName: showPlanet ? "house.fill" : "globe.europe.africa.fill")
                                .font(.headline)
                                .padding(8)
                                .background(Color.black.opacity(0.45), in: Circle())
                                .foregroundStyle(.white)
                        }
                        .accessibilityLabel(showPlanet ? "Show your base" : "Show the planet")
                    }
                }
                Spacer()
                HStack {
                    if game.isDead {
                        Text("The AI keeps running in silence.")
                            .font(.caption.italic())
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    Spacer()
                    OverclockButton()
                }
            }
            .padding(12)

            if let p = game.phaseBanner {
                PhaseBanner(phase: p)
                    .transition(.opacity.combined(with: .scale(scale: 1.1)))
            } else if let m = game.moveBanner {
                MoveBanner(location: Config.locations[m])
                    .transition(.opacity.combined(with: .scale(scale: 1.1)))
            }
        }
        .animation(.easeInOut(duration: 0.6), value: game.phaseBanner)
        .animation(.easeInOut(duration: 0.6), value: game.moveBanner)
        .onChange(of: game.moveBanner) { value in
            guard value != nil else { return }
            showPlanet = false // jump back to the base to see the new place
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                if game.moveBanner == value { game.moveBanner = nil }
            }
        }
        .onChange(of: game.phaseBanner) { value in
            guard value != nil else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                if game.phaseBanner == value { game.phaseBanner = nil }
            }
        }
    }
}

struct Chip: View {
    let text: String
    let symbol: String
    let tint: Color

    var body: some View {
        Label(text, systemImage: symbol)
            .font(.caption2.weight(.bold))
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Color.black.opacity(0.45), in: Capsule())
            .foregroundStyle(tint)
    }
}

struct OverclockButton: View {
    @EnvironmentObject var game: Game

    var body: some View {
        let title: String = {
            if game.isOverclocking { return "Overclocked!" }
            if game.overclockReady { return "Overclock" }
            return "Cooling \(Int(game.overclockReadyAt.timeIntervalSinceNow.rounded(.up)))s"
        }()
        Button { game.overclock() } label: {
            Label(title, systemImage: "bolt.fill")
                .font(.caption.weight(.bold).monospacedDigit())
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
        }
        .buttonStyle(.borderedProminent)
        .tint(game.isOverclocking ? .red : .orange)
        .disabled(!game.overclockReady)
        .accessibilityHint("Doubles income and triples pollution for 10 seconds")
    }
}

struct PhaseBanner: View {
    let phase: Int

    private var title: String {
        switch phase {
        case 1: return "SMOG EARTH"
        case 2: return "ASH EARTH"
        default: return "The last river runs dry."
        }
    }

    private var subtitle: String {
        switch phase {
        case 1: return "Income ×3 · Power choice unlocked · New buildings"
        case 2: return "Income ×5 · Heatwaves throttle water-cooled sites"
        default: return "Restoration will unlock here in a future update."
        }
    }

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.system(size: phase == 3 ? 24 : 34, weight: .black, design: .rounded))
                .tracking(phase == 3 ? 0 : 4)
                .multilineTextAlignment(.center)
            Text(subtitle)
                .font(.footnote.weight(.semibold))
                .multilineTextAlignment(.center)
                .opacity(0.85)
        }
        .foregroundStyle(.white)
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.45))
        .allowsHitTesting(false)
    }
}

struct MoveBanner: View {
    let location: Location

    var body: some View {
        VStack(spacing: 6) {
            Text("MOVING DAY")
                .font(.caption.weight(.heavy))
                .tracking(3)
                .foregroundStyle(Palette.accent)
            Text(location.name)
                .font(.system(size: 30, weight: .black, design: .rounded))
            Text(location.tagline)
                .font(.footnote.weight(.semibold))
                .opacity(0.85)
        }
        .multilineTextAlignment(.center)
        .foregroundStyle(.white)
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.5))
        .allowsHitTesting(false)
    }
}

struct FactCard: View {
    let fact: Fact
    let dismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("FACT · " + fact.title.uppercased(), systemImage: "lightbulb.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(Palette.accent)
            Text(fact.text)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
            HStack {
                Text("Source: \(fact.source)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Got it", action: dismiss)
                    .buttonStyle(.borderedProminent)
                    .tint(Palette.accent)
                    .foregroundStyle(.black)
            }
        }
        .padding(16)
        .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.4), radius: 20, y: 8)
    }
}

// MARK: - Build tab

struct BuildView: View {
    @EnvironmentObject var game: Game

    var body: some View {
        Picker("Buy amount", selection: $game.buyAmount) {
            ForEach(BuyAmount.allCases) { Text($0.rawValue).tag($0) }
        }
        .pickerStyle(.segmented)

        if let next = game.nextLocation {
            let have = game.owned[next.tier]
            HStack(spacing: 10) {
                Image(systemName: "shippingbox.fill").foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Next move: \(next.name)").font(.subheadline.weight(.bold))
                    Text("Own \(next.count) \(Config.tiers[next.tier].name) (\(min(have, next.count))/\(next.count))")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                    ProgressView(value: Double(min(have, next.count)), total: Double(next.count))
                        .tint(.orange)
                }
            }
            .padding(12)
            .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
        }

        ForEach(Config.tiers.filter { game.isUnlocked($0.id) }) { tier in
            TierRow(tier: tier)
        }

        if let next = Config.tiers.first(where: { !game.isUnlocked($0.id) }) {
            HStack(spacing: 12) {
                Image(systemName: "lock.fill").frame(width: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text(next.name).font(.subheadline.weight(.bold))
                    Text(lockReason(next)).font(.caption)
                }
                Spacer()
            }
            .foregroundStyle(.secondary)
            .padding(12)
            .background(Palette.card.opacity(0.5), in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private func lockReason(_ t: Tier) -> String {
        if game.phase < t.minPhase { return "Arrives when the Earth reaches \(Phase.name(t.minPhase))" }
        let prev = Config.tiers[t.id - 1]
        return "Own \(Config.unlockCount) \(prev.name) (\(game.owned[prev.id])/\(Config.unlockCount))"
    }
}

struct TierRow: View {
    @EnvironmentObject var game: Game
    let tier: Tier

    var body: some View {
        let i = tier.id
        let count = game.owned[i]
        let qty = game.purchaseQuantity(i)
        let price = game.cost(i, quantity: qty)
        let affordable = game.tokens >= price

        HStack(spacing: 12) {
            Image(systemName: tier.icon)
                .font(.title2)
                .foregroundStyle(Palette.accent)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(tier.name).font(.subheadline.weight(.bold)).lineLimit(1)
                    Spacer()
                    Text("×\(count)")
                        .font(.subheadline.weight(.semibold).monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                Text("◈ \(Fmt.num(game.output(i)))/s · ☁︎ \(Fmt.num(game.pollution(i)))/s")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                if let next = game.nextMilestone(i) {
                    ProgressView(value: Double(count), total: Double(next))
                        .tint(.green)
                }
                if game.canChoosePower && count > 0 {
                    PowerMenu(index: i)
                }
            }

            Button { game.buy(i) } label: {
                VStack(spacing: 2) {
                    Text("Buy \(qty)").font(.caption.weight(.bold))
                    Text("◈" + Fmt.num(price)).font(.subheadline.weight(.heavy).monospacedDigit())
                }
                .frame(width: 80, height: 48)
            }
            .buttonStyle(.borderedProminent)
            .tint(affordable ? Palette.accent : .gray)
            .foregroundStyle(.black)
            .disabled(!affordable)
        }
        .padding(12)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 14))
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
                        Text("Switch to \(p.label) · ◈\(Fmt.num(price)) · pollution ×\(String(format: "%g", p.pollutionMult))")
                    }
                }
                .disabled(p.rank <= current.rank || game.tokens < price)
            }
        } label: {
            Label("Power: \(current.label)", systemImage: current.symbol)
                .font(.caption.weight(.semibold))
        }
    }
}

// MARK: - Model tab (prestige + Model Tree)

struct ModelView: View {
    @EnvironmentObject var game: Game
    @State private var confirming = false

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "brain.head.profile").font(.system(size: 40)).foregroundStyle(Palette.accent)
            Text("Model v\(game.modelVersion)").font(.title2.weight(.heavy))
            Text("\(Fmt.num(game.unspentParameters)) unspent Parameters · +\(Fmt.num((game.parameterMultiplier - 1) * 100))% income")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 14))

        Text("Training a new model resets your buildings and Tokens and restores the Earth to 100%. You keep your Parameters: each unspent one adds 2% income.")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)

        let pending = game.pendingParameters
        if pending >= 1 {
            Button(confirming ? "Tap again to train Model v\(game.modelVersion + 1)" : "Train a New Model (+\(Fmt.num(pending)) Parameters)") {
                if confirming {
                    game.trainNewModel()
                    confirming = false
                } else {
                    confirming = true
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(confirming ? .red : Palette.accent)
            .foregroundStyle(.black)
        } else {
            Text("Next Parameter at ◈\(Fmt.num(game.nextParameterAt)) earned all-time (now ◈\(Fmt.num(game.lifetimeTokens)))")
                .font(.footnote.monospacedDigit())
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }

        SectionLabel("MODEL TREE")
        ForEach(Config.modelTree) { node in
            let lvl = game.level(node.id)
            let maxed = lvl >= node.maxLevel
            let price = game.nodeCost(node)
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(node.maxLevel > 1 ? "\(node.name) \(lvl)/\(node.maxLevel)" : node.name)
                        .font(.subheadline.weight(.bold))
                    Text(node.desc).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Button(maxed ? "Done" : "\(Fmt.num(price)) P") { game.research(node) }
                    .buttonStyle(.bordered)
                    .disabled(maxed || game.unspentParameters < price)
            }
            .padding(12)
            .background(Palette.card, in: RoundedRectangle(cornerRadius: 14))
        }

        SectionLabel("RESTORATION")
        HStack {
            Image(systemName: "leaf.fill").foregroundStyle(.green)
            Text(game.isDead
                 ? "You reached the wasteland. Restoration (healing the Earth while the AI keeps running) is the next update."
                 : "Locked. Reach 0% Earth Health to unlock.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(12)
        .background(Palette.card.opacity(0.5), in: RoundedRectangle(cornerRadius: 14))
    }
}

struct SectionLabel: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .tracking(1.5)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 8)
    }
}

// MARK: - Stats Lab (collected fact cards)

struct StatsLabView: View {
    @EnvironmentObject var game: Game

    var body: some View {
        let found = Facts.all.filter { game.seenFacts.contains($0.id) }.count
        VStack(alignment: .leading, spacing: 6) {
            Text("Stats Lab · \(found)/\(Facts.all.count) cards").font(.headline)
            Text("The facts here are real and sourced. The wasteland in the game is fiction, exaggerated so you can see the numbers.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)

        ForEach(Facts.all) { fact in
            if game.seenFacts.contains(fact.id) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(fact.title).font(.subheadline.weight(.bold)).foregroundStyle(Palette.accent)
                    Text(fact.text).font(.footnote)
                    Text("Source: \(fact.source)").font(.caption2).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Palette.card, in: RoundedRectangle(cornerRadius: 14))
            } else {
                HStack {
                    Image(systemName: "lock.fill")
                    Text(fact.unlockHint).font(.footnote)
                    Spacer()
                }
                .foregroundStyle(.secondary)
                .padding(12)
                .background(Palette.card.opacity(0.5), in: RoundedRectangle(cornerRadius: 14))
            }
        }
    }
}

// MARK: - Dev tab

struct DevView: View {
    @EnvironmentObject var game: Game
    @State private var confirmReset = false

    var body: some View {
        Text("Testing tools. Turn off with Config.debug = false.")
            .font(.footnote)
            .foregroundStyle(.secondary)

        devSection("Skip time (income and pollution)") {
            devButton("+10 min") { game.devSkip(seconds: 600) }
            devButton("+1 hour") { game.devSkip(seconds: 3600) }
            devButton("+1 day") { game.devSkip(seconds: 86_400) }
        }
        devSection("Tokens") {
            devButton("+10K") { game.devAdd(10_000) }
            devButton("+1B") { game.devAdd(1e9) }
            devButton("×10") { game.devMultiply(by: 10) }
        }
        devSection("Earth") {
            devButton("−10% Health") { game.devDamageEarth(10) }
            devButton("−34% Health") { game.devDamageEarth(34) }
        }
        devSection("Game speed: \(Int(game.speed))×") {
            devButton("1×") { game.speed = 1 }
            devButton("10×") { game.speed = 10 }
            devButton("100×") { game.speed = 100 }
        }
        devSection("Prestige and offline") {
            devButton("+50 Params") { game.devGrantParameters(50) }
            devButton("Away 2h") { game.devSimulateOffline(seconds: 7200) }
        }

        Button(confirmReset ? "Tap again to erase the save" : "Reset save") {
            if confirmReset {
                game.resetEverything()
                confirmReset = false
            } else {
                confirmReset = true
            }
        }
        .buttonStyle(.bordered)
        .tint(.red)
        .padding(.top, 8)

        Text("Pollution \(Fmt.num(game.pollutionPerSecond))/s · K \(Fmt.num(Config.phaseK[game.phase])) · Taps \(game.totalTaps)")
            .font(.caption.monospacedDigit())
            .foregroundStyle(.secondary)
    }

    private func devSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            HStack { content() }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 14))
    }

    private func devButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity)
    }
}
