import SwiftUI

enum Theme {
    static let bgTop = Color(red: 0.09, green: 0.12, blue: 0.10)
    static let bgBottom = Color(red: 0.04, green: 0.05, blue: 0.05)
    static let card = Color.white.opacity(0.06)
    static let glow = Color(red: 0.99, green: 0.76, blue: 0.42)   // warm lantern amber
    static let moss = Color(red: 0.55, green: 0.80, blue: 0.45)
    static let bloom = Color(red: 0.95, green: 0.62, blue: 0.78)
}

struct ContentView: View {
    @EnvironmentObject var game: GameModel
    @State private var tab: Tab = .grow

    enum Tab: String, CaseIterable, Identifiable {
        case grow = "Grow", upgrades = "Upgrades", prestige = "Prestige", dev = "Dev"
        var id: String { rawValue }
    }

    private var tabs: [Tab] {
        GameConfig.debug ? Tab.allCases : Tab.allCases.filter { $0 != .dev }
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Theme.bgTop, Theme.bgBottom], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 10) {
                header
                TapButton()
                Picker("Section", selection: $tab) {
                    ForEach(tabs) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                ScrollView {
                    VStack(spacing: 10) {
                        switch tab {
                        case .grow: GeneratorsView()
                        case .upgrades: UpgradesView()
                        case .prestige: PrestigeView()
                        case .dev: DevView()
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
            }
            .padding(.top, 8)
        }
        .alert("Welcome back!", isPresented: Binding(
            get: { game.offlineReport != nil },
            set: { if !$0 { game.offlineReport = nil } }
        )) {
            Button("Collect") { game.offlineReport = nil }
        } message: {
            if let r = game.offlineReport {
                Text("You were away for \(Fmt.duration(r.seconds)). Your garden grew \(Fmt.num(r.amount)) \(GameConfig.currencyName).")
            }
        }
    }

    private var header: some View {
        VStack(spacing: 2) {
            Text(GameConfig.title.uppercased())
                .font(.caption.weight(.semibold))
                .tracking(2)
                .foregroundStyle(.secondary)
            Text(Fmt.num(game.currency))
                .font(.system(size: 44, weight: .heavy, design: .rounded).monospacedDigit())
                .foregroundStyle(Theme.glow)
            Text("\(GameConfig.currencyName) · \(Fmt.num(game.incomePerSecond))/sec")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Tap button

struct TapButton: View {
    @EnvironmentObject var game: GameModel
    @State private var pressed = false
    @State private var floaters: [Floater] = []
    private let haptic = UIImpactFeedbackGenerator(style: .light)

    struct Floater: Identifiable {
        let id = UUID()
        let text: String
        let x: CGFloat
        var rise = false
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [Theme.glow.opacity(0.55), Theme.glow.opacity(0.05)],
                                     center: .center, startRadius: 10, endRadius: 90))
                .frame(width: 160, height: 160)
                .overlay(Text(GameConfig.currencyIcon).font(.system(size: 76)))
                .scaleEffect(pressed ? 0.9 : 1)
                .contentShape(Circle())
                .onTapGesture(perform: tap)
                .accessibilityAddTraits(.isButton)
                .accessibilityLabel("Tap for \(Fmt.num(game.tapValue)) \(GameConfig.currencyName)")

            ForEach(floaters) { f in
                Text(f.text)
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(Theme.glow)
                    .offset(x: f.x, y: f.rise ? -110 : -40)
                    .opacity(f.rise ? 0 : 1)
                    .allowsHitTesting(false)
            }
        }
        .frame(height: 170)
    }

    private func tap() {
        let gained = game.tap()
        haptic.impactOccurred()

        withAnimation(.easeOut(duration: 0.06)) { pressed = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.07) {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) { pressed = false }
        }

        let f = Floater(text: "+" + Fmt.num(gained), x: .random(in: -55...55))
        floaters.append(f)
        let id = f.id
        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 0.8)) {
                if let i = floaters.firstIndex(where: { $0.id == id }) { floaters[i].rise = true }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
            floaters.removeAll { $0.id == id }
        }
    }
}

// MARK: - Generators

struct GeneratorsView: View {
    @EnvironmentObject var game: GameModel

    var body: some View {
        Picker("Buy amount", selection: $game.buyAmount) {
            ForEach(BuyAmount.allCases) { Text($0.rawValue).tag($0) }
        }
        .pickerStyle(.segmented)

        ForEach(Array(GameConfig.generators.enumerated()), id: \.element.id) { index, gen in
            if game.isVisible(index: index) {
                GeneratorRow(gen: gen)
            }
        }

        if let locked = GameConfig.generators.indices.first(where: { !game.isVisible(index: $0) }) {
            Text("🔒 Buy a \(GameConfig.generators[locked - 1].name) to discover something new")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
    }
}

struct GeneratorRow: View {
    @EnvironmentObject var game: GameModel
    let gen: GeneratorDef

    var body: some View {
        let owned = game.count(gen)
        let qty = game.purchaseQuantity(gen)
        let cost = game.cost(gen, quantity: qty)
        let affordable = game.currency >= cost

        HStack(spacing: 12) {
            Text(gen.icon)
                .font(.system(size: 34))
                .frame(width: 48)

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(gen.name).font(.headline)
                    Spacer()
                    Text("×\(owned)")
                        .font(.subheadline.weight(.semibold).monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                Text("\(Fmt.num(game.rate(gen)))/s total · \(Fmt.num(gen.baseRate * game.multiplier(gen)))/s each")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                if let next = game.nextMilestone(gen) {
                    ProgressView(value: Double(owned), total: Double(next))
                        .tint(Theme.moss)
                    Text("Output ×2 at \(next)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Button { game.buy(gen) } label: {
                VStack(spacing: 2) {
                    Text("Buy \(qty)").font(.caption.weight(.bold))
                    Text(Fmt.num(cost)).font(.subheadline.weight(.heavy).monospacedDigit())
                }
                .frame(width: 78, height: 46)
            }
            .buttonStyle(.borderedProminent)
            .tint(affordable ? Theme.glow : .gray)
            .foregroundStyle(.black)
            .disabled(!affordable)
        }
        .padding(12)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Upgrades

struct UpgradesView: View {
    @EnvironmentObject var game: GameModel

    var body: some View {
        let available = GameConfig.upgrades.filter { !game.isBought($0) && game.isUnlocked($0) }
        let upcoming = GameConfig.upgrades.filter { !game.isBought($0) && !game.isUnlocked($0) }.prefix(3)
        let ownedCount = GameConfig.upgrades.filter { game.isBought($0) }.count

        if available.isEmpty {
            Text("No upgrades right now. Keep growing.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.vertical, 8)
        }

        ForEach(available) { u in
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(u.name).font(.headline)
                    Text(u.desc).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Button(Fmt.num(u.cost)) { game.buy(u) }
                    .buttonStyle(.borderedProminent)
                    .tint(game.currency >= u.cost ? Theme.glow : .gray)
                    .foregroundStyle(.black)
                    .disabled(game.currency < u.cost)
            }
            .padding(12)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 14))
        }

        if !upcoming.isEmpty {
            Text("COMING UP")
                .font(.caption.weight(.semibold))
                .tracking(1.5)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)
            ForEach(Array(upcoming)) { u in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(u.name).font(.subheadline.weight(.semibold))
                        Text(game.requirementText(u)).font(.caption)
                    }
                    Spacer()
                    Image(systemName: "lock.fill")
                }
                .foregroundStyle(.secondary)
                .padding(12)
                .background(Theme.card.opacity(0.5), in: RoundedRectangle(cornerRadius: 14))
            }
        }

        Text("\(ownedCount) of \(GameConfig.upgrades.count) upgrades bought")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .padding(.top, 8)
    }
}

// MARK: - Prestige

struct PrestigeView: View {
    @EnvironmentObject var game: GameModel
    @State private var confirming = false

    var body: some View {
        let p = GameConfig.prestige
        let pending = game.pendingPrestige

        VStack(spacing: 8) {
            Text(p.icon).font(.system(size: 56))
            Text("\(Fmt.num(game.prestigePoints)) \(p.name)")
                .font(.title2.weight(.heavy))
                .foregroundStyle(Theme.bloom)
            Text("+\(Fmt.num((game.prestigeMultiplier - 1) * 100))% to all income and taps")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 14))

        Text("Reset your \(GameConfig.currencyName), generators and upgrades to earn \(p.name). Each one adds \(Int(p.bonusPerPoint * 100))% income forever.")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)

        if pending > 0 {
            Button(confirming ? "Tap again to reset for +\(Fmt.num(pending))" : "Prestige for +\(Fmt.num(pending)) \(p.name)") {
                if confirming {
                    game.doPrestige()
                    confirming = false
                } else {
                    confirming = true
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(confirming ? .red : Theme.bloom)
            .foregroundStyle(.black)
        } else {
            Text("Earn \(Fmt.num(p.minLifetime)) \(GameConfig.currencyName) this run to unlock. Progress: \(Fmt.num(game.lifetime)).")
                .font(.footnote.monospacedDigit())
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Dev tools

struct DevView: View {
    @EnvironmentObject var game: GameModel
    @State private var confirmReset = false

    var body: some View {
        Text("Testing tools. Turn off with GameConfig.debug = false.")
            .font(.footnote)
            .foregroundStyle(.secondary)

        devSection("Skip time (earn income instantly)") {
            devButton("+1 min") { game.devSkip(seconds: 60) }
            devButton("+1 hour") { game.devSkip(seconds: 3600) }
            devButton("+1 day") { game.devSkip(seconds: 86_400) }
        }

        devSection("Currency") {
            devButton("+1K") { game.devAdd(1_000) }
            devButton("+1M") { game.devAdd(1e6) }
            devButton("×10") { game.devMultiplyCurrency(by: 10) }
        }

        devSection("Game speed: \(Int(game.speed))×") {
            devButton("1×") { game.speed = 1 }
            devButton("10×") { game.speed = 10 }
            devButton("100×") { game.speed = 100 }
        }

        devSection("Test the offline popup") {
            devButton("Away 2h") { game.devSimulateOffline(seconds: 7200) }
            devButton("Away 24h") { game.devSimulateOffline(seconds: 86_400) }
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

        Text("Taps: \(game.totalTaps) · Tap value: \(Fmt.num(game.tapValue))")
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
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 14))
    }

    private func devButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity)
    }
}
