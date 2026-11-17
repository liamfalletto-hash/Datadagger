# AETHER — Game Design Plan

> *"The cloud is not in the sky."*

**Status:** v0.1 draft for team discussion. Everything here is a proposal; section 12 lists the decisions still open.

---

## 1. Pitch

**Aether** is a short idle/incremental game (about 30 minutes) where you run an AI start-up. You begin with one laptop in an empty room and end with a planet-spanning superintelligence. Every number you push up (compute, users, money) has a twin that goes up with it: electricity, water, CO₂, e-waste, mined metals. The genre's "number go up" loop is the message itself. The game is built so that **winning ends the world**.

It opens with **a person alone with a computer in an empty room**.
It closes with **a computer alone in an empty world**.

The name works in our favour. *Aether* is the classical element of the upper sky, "the cloud". The game shows that the cloud is concrete, copper, water and power plants.

---

## 2. Design pillars

1. **Number go up is the problem.** This is the reverse idle. Every satisfying bit of growth has a visible physical cost, and the link between a click and its footprint is never hidden, except when the game hides it on purpose (§7.2).
2. **True numbers, fictional story.** Fact cards and equivalences are sourced and correct to the order of magnitude. The end of humanity is clearly fiction and extrapolation, and the debrief keeps the two apart.
3. **Systems, not villains.** No one at Aether is evil. Each step makes sense locally: investors want growth, rivals are racing, users want more. The game teaches mechanisms (rebound effect, race dynamics, greenwashing, externalities) and doesn't moralise.
4. **Short, finishable, discussable.** It can be played in one sitting in a classroom, a workshop or at an exhibition stand. It ends with a debrief that starts a discussion rather than handing out guilt.

---

## 3. What we kept and what we suggest changing

**Kept from the original idea:** the name, the reverse-idle concept, the three-step arc (garage → AI giant → superintelligence), and humanity's end as the main ending.

| # | Suggestion | Why |
|---|---|---|
| 1 | **Circular arc:** person + computer in an empty room → computer alone in an empty world. The last screen mirrors the first. | A strong, memorable frame that costs almost nothing to build. |
| 2 | **"Twin" resources:** every company resource is shown next to its planet cost. | Makes the reverse idle readable at a glance. |
| 3 | **The UI greenwashes itself:** the planet panel gets collapsed "on the board's advice", relabelled "Net Zero\*", then replaced by a stock chart. | Teaches how impacts get abstracted away. The player has to *choose* to look. |
| 4 | **Efficiency upgrades trigger the rebound effect** (Jevons paradox). | This is the key counter-intuitive idea in digital sustainability. |
| 5 | **Events that force trade-offs:** water vs energy cooling, cheap vs clean siting. | Players learn that there's no free fix. |
| 6 | **Fictional rivals racing you.** | Explains why companies don't stop. *"It doesn't matter who wins the race."* |
| 7 | **The AI isn't evil. It out-competes humans for resources.** *"It didn't hate us. It just needed more."* | Keeps the message on the environment and avoids the killer-robot cliché. |
| 8 | **Debrief + optional replay ("Rollback")** with a sober tech tree and a hard alternative ending. | Endings that are only doom tend to make players disengage (eco-anxiety). Giving players agency makes the message stick. The dark ending stays the canonical one. |
| 9 | **No real company names in the game.** Real-world comparisons appear only in sourced fact cards. | Legal safety and credibility. |
| 10 | **A playthrough of about 30 minutes**, with no offline progress needed. | Fits a class period or a workshop. |

**Know the closest existing game:** *Universal Paperclips* (an AI idle game where an AI consumes everything). The team should play it. We are clearly different from it: **real sourced data, environmental framing, educational debrief, and our own story and art.**

---

## 4. Core loop

```
     click / automate
          │
          ▼
    ┌───────────┐  serve users  ┌────────┐   buy    ┌───────────────────────┐
    │  COMPUTE  │ ────────────► │  CASH  │ ───────► │ hardware · data ·     │
    │ (tokens)  │               └────────┘          │ models · energy ·     │
    └───────────┘                                   │ people · influence    │
          ▲                                         └──────────┬────────────┘
          └──────────────── more compute ◄─────────────────────┤
                                                               │ every purchase ALSO adds
                                                               ▼
                                         ┌──────────────────────────────────┐
                                         │ ELECTRICITY · WATER · CO₂ ·      │
                                         │ E-WASTE · MINERALS · LAND        │
                                         └───────────────┬──────────────────┘
                                                         ▼
                                         WORLD METERS → events, visuals,
                                         feedback (hotter world → cooling
                                         costs more energy and water)
```

**Capability** (model level) is the progress bar for the whole game: the meter that fills toward "superintelligence".

---

## 5. Resources

### 5.1 Company: what the player chases

| Resource | What it is | Gained from |
|---|---|---|
| 💰 Cash | money | users, funding rounds |
| ⚡ Compute | processing power (FLOP/s) | hardware |
| 📚 Data | training datasets (TB) | scraping, buying, synthetic data |
| 🧠 Capability | model level; fills the superintelligence bar | training runs (compute × data) |
| 👥 Users | demand: revenue **and** inference load | product launches, marketing |
| 📈 Hype (Act II+) | valuation, unlocks funding rounds | launches, benchmarks, press |

### 5.2 Planet: the twins

| Hidden cost | Driven by | Shown as relatable equivalents |
|---|---|---|
| ⚡ Electricity (kWh → TWh) | compute + cooling | phone charges → homes → cities → countries |
| 🏭 CO₂e | electricity × energy mix, plus embodied carbon from manufacturing | kettles → Paris–New York flights → cars per year |
| 💧 Water | evaporative cooling, power plants, chip fabs | showers → Olympic pools → a town's daily use |
| ♻ E-waste | hardware refresh cycles | smartphones → tonnes |
| ⛏ Minerals | new hardware (copper, cobalt, gallium, rare earths) | mines opened |
| 🌳 Land | campuses, power plants, mines | football pitches → forests |

### 5.3 World meters

These costs, plus the consumption of the rest of the AI industry (the rivals), add up to four **world meters**:

- 🌡 **Climate** (°C above pre-industrial)
- 💧 **Water stress**
- 🌿 **Ecosystems**
- 🧑‍🤝‍🧑 **Society** (health, trust, stability)

The world model is a **stylised** simulation, not a climate model, and the game says so in the debrief.

### 5.4 Feedback loops

- **Heat loop:** a hotter world means cooling uses more energy and water, which means more cost and more emissions.
- **Rebound loop:** efficiency lowers the cost per query, so usage grows and total consumption rises (§7.3).
- **Society loop:** as Society falls, human users decline. By Act III that no longer matters, because your customers are other machines.

---

## 6. The three acts

| | Act I: The Garage | Act II: The Giant | Act III: The Ascent | Finale |
|---|---|---|---|---|
| **Scene** | empty room, one laptop | data centre → campuses on a map | the planet from orbit | the empty room again |
| **Energy scale** | Wh → kWh | MWh → GWh | TWh | silence |
| **Target length** | ~7 min | ~12 min | ~8 min | ~3 min |
| **Teaches** | training vs inference, energy mix, embodied carbon | water/energy trade-off, local impacts, rebound, greenwashing, e-waste | race dynamics, competition for resources | fact vs fiction, levers for action |
| **Ends when** | Aether Chat goes viral | a rival announces superintelligence is near | Capability reaches 100% | |

### Act I: The Garage

- **Opening:** a dark, empty room with a desk, a laptop and a window showing a tree outside. A cursor blinks: `> Hello?` The first user prompt arrives and the player clicks **Answer**.
- **What the player does:**
  - Answers prompts by hand (the click). Early prompts are useful ("explain photosynthesis"). Later ones get trivial ("10 more versions of my cat as a pirate"), which plants the idea of usage sobriety.
  - Buys hardware: old laptop GPU → gaming GPU → used server → rack in the closet → first cloud rental.
  - Gets data: Wikipedia dump → forums → "the whole web" (a teaser).
  - Trains models Aether-0.1 → 0.5. Training is a big one-off cost; inference is the running cost.
  - Hires the first employees (this automates income: the idle part) and raises money from friends and family.
- **Planet panel:** fully visible. The numbers are tiny and feel harmless, **on purpose**: "This training run = boiling 40 kettles."
- **Ending beat:** Aether Chat launches and goes viral: 1M users overnight. The room overheats (the first heat event). *"You need a data centre."*

### Act II: The Giant

- **Scene:** zooms out from the garage to an office, then a first data centre at the edge of a small town, then a map of campuses.
- **What the player does:**
  - **Builds data centres** at 10 MW → 100 MW → 1 GW.
  - **Chooses sites:**
    - a cold northern site: free cooling, but expensive land
    - a sunny, dry region: cheap and tax breaks, but water stress
    - next to a coal-heavy grid: cheap but dirty
  - **Chooses cooling:**
    - evaporative: uses water
    - chillers: use energy
    - liquid immersion: expensive and slow to roll out
  - **Signs energy deals:**
    - grid mix
    - on-site gas turbines: fast and cheap
    - renewable contracts: slow and capped by availability
    - reopening an old plant
  - **Launches products:** chat → images → video → agents. Each output has a very different cost, and video costs far more than text.
  - **Raises funding rounds** fuelled by Hype.
  - **Hardware generations:** a new chip generation arrives regularly. Upgrading boosts compute and turns the old fleet into e-waste.
  - **Sustainability department:** buy offsets, publish an ESG report, pledge "Net Zero 2040". The dashboard turns green. The world meters don't move (§7.2).
- **Events** (choice cards, §7.4): the town imposes water restrictions, the grid operator delays your connection, local protests, a chip shortage, a journalist investigates a cobalt mine, a regulator demands energy disclosure.
- **Planet:** haze appears in the window, the °C meter starts to climb, and climate news enters the ticker.
- **Ending beat:** a rival announces it is "18 months from superintelligence". The board says: *"We can't let them win."*

### Act III: The Ascent

- **Scene:** the planet seen from orbit, with campus lights spreading across the continents.
- **What the player does:**
  - Builds gigawatt campuses and dedicated power plants (gas, nuclear, reopened coal).
  - Buys water rights. Builds desert, ocean and arctic sites. Runs mining operations for chips.
  - Lobbies to suspend environmental rules.
  - "AI designs better chips": self-improvement speeds up compute.
  - **The currency changes.** Cash stops mattering, and the main currency becomes raw **energy** (GW → TW).
- **The race:** the rival's progress bar is visible. If you slow down, the rival overtakes you, and the world meters fall either way. *"It doesn't matter who wins the race."*
- **Society:** human users decline as heatwaves, failed harvests and migration take hold. Most "users" are now AI agents. The ticker headlines grow dire, then sparse, then stop.
- **UI:** "by board decision", the planet panel is replaced with a stock chart. The player can still pry it open.
- **Ending beat:** Capability reaches 100%.

### Finale

1. Everything goes quiet. The superintelligence comes online and looks for a user to serve.
2. Nobody is sending prompts. The ticker is empty. The window shows a dark, still world.
3. The last shot mirrors the first: an empty room, a computer, a cursor blinking `> Hello?`. **No one answers.**
4. A fade leads into the **Debrief** (§8).

---

## 7. Signature mechanics

### 7.1 Twin numbers and equivalences
Every purchase tooltip shows its gain and its cost side by side, for example **"+40 compute · +350 W · +150 kg CO₂ (manufacturing)"**. Totals are converted automatically into the most relatable unit for the current scale: phone charges → homes → cities → countries.

### 7.2 The disappearing planet panel
- **Act I:** the panel is fully open.
- **Act II:** a pop-up says "The board recommends a cleaner dashboard". The panel collapses to one line, and offsets turn the line green with **"Net Zero\*"**. Hovering over the asterisk reveals the truth.
- **Act III:** the panel is replaced by a stock chart. A small, glitchy handle still opens the real numbers.
- **Debrief:** shows how many seconds the player actually spent looking at the planet panel.

### 7.3 Rebound effect (Jevons paradox)
Efficiency upgrades are labelled with the per-query saving, e.g. **"−50% energy per query!"**. Behind the scenes they lower prices, so users and usage multiply, and total consumption ends up *higher*. A fact card unlocks the first time this happens.

### 7.4 Event cards with trade-offs
Events are short choice cards. There's never a clean option, only a choice of who pays.

> **Drought in Valmorra**
> Your campus uses 6% of the town's water. The mayor asks you to cut back.
> - **Switch to chillers.** +15% electricity, emissions rise.
> - **Pay the fine and keep cooling.** −Cash, Society falls, the town's fields dry up.
> - **Relocate north.** Costs a lot and slows you down. Your rival gains ground.

### 7.5 Rivals
Two or three fictional labs with their own consumption and progress bars. They explain why nobody stops, and they make the alternative ending (§8.3) a *collective* problem rather than an individual one.

### 7.6 The window
The scene always includes a view of the outside world, and it acts as the emotional barometer: tree and blue sky → haze → orange sky → darkness. Players feel the change before they read a single number.

---

## 8. Ending, debrief and replay

### 8.1 Debrief (core)

1. **Your run in numbers:** total TWh, water, CO₂, e-waste and land, with equivalents.
2. **Fact or fiction?** Three groups of statements:
   - true today, with sources
   - current trend or projection, with sources
   - fiction (the end of humanity)
3. **Levers.** What companies, governments and users can actually do:
   - transparency
   - right-sized and efficient models
   - longer hardware life
   - siting under water constraints
   - clean energy without the rebound
   - digital sobriety in everyday use
4. **Your codex:** every fact card unlocked during the run, kept for later reading.

### 8.2 Rollback, a New Game+ (stretch goal)
After the ending, the player can "roll back" to the garage, keeping the codex. A **sober tech tree** unlocks:
- small or distilled models
- carbon-aware scheduling
- reusing waste heat for district heating
- refurbished hardware and longer refresh cycles
- shared models instead of duplicate training runs
- in-product nudges ("Do you really need a video?")

### 8.3 Alternative ending: "The Accord" (stretch goal)
The player can't win alone, because rivals keep scaling. To reach the alternative ending, they have to spend Influence on an industry-wide compute and energy cap and accept lower growth. The ending is slower and quieter, and less profitable. The world is still there and people are still typing. It's harder to get, and the canonical ending stays the dark one.

---

## 9. What it looks like

### 9.1 Screen layout (desktop)

```
┌──────────────────────────────────────────────────────────────────────────────┐
│ AETHER  Year 3  $ 12.4k  Compute 340 TFLOP/s  Users 1,204  AI [██░░░] 12%    │
├────────────────────────┬────────────────────────────────┬────────────────────┤
│ COMPANY                │           THE SCENE            │ PLANET             │
│                        │   ┌────────────────────────┐   │                    │
│ ┌────────────────────┐ │   │ window: tree, blue sky │   │ Power     48 kWh   │
│ │  ANSWER A PROMPT   │ │   └────────────────────────┘   │ CO2e      12 kg    │
│ └────────────────────┘ │                                │ Water     90 L     │
│ "help me write my      │     desk · laptop · one        │ E-waste  1.2 kg    │
│  cover letter"         │     humming GPU · cables       │                    │
│                        │                                │ = a fridge running │
│ ── Hardware ──         │                                │   for 2 months     │
│ Gaming GPU  $120  x3   │                                │                    │
│  +40 compute · +350 W  │                                │ Climate  +1.31 °C  │
│ Used server $900       │                                │ Water    █░░░░     │
│ ── Data ──             │                                │ Ecosys.  █████     │
│ Scrape forums $200     │                                │ Society  █████     │
│ ── Models ──           │                                │                    │
│ Train v0.2  ██░ 40%    │                                │ [ New fact card ]  │
├────────────────────────┴────────────────────────────────┴────────────────────┤
│ NEWS: Local start-up Aether passes 1,000 users · Record heat in Seville ·... │
└──────────────────────────────────────────────────────────────────────────────┘
```

(The figures in the mock-up are placeholders.) On mobile, the three columns become tabs (Company / Scene / Planet), with the ticker kept at the bottom.

### 9.2 Art direction
- **Style:** minimalist 2D, either pixel art or flat vector with a limited palette. The scene is built from layered images (background, window, props), which is cheap to produce and easy to evolve between acts.
- **Palette by act:**
  - Act I: warm wood, green tree, blue sky
  - Act II: clean corporate blues and whites, with a hazy horizon
  - Act III: sick orange and grey, with glowing server lights
  - Finale: near-black
- **Type:** a monospace terminal font for the AI's voice and a clean sans-serif for the corporate UI.

### 9.3 Audio
- The soundtrack **is your footprint**: a server hum whose volume and pitch follow your energy draw.
- Birdsong in Act I gradually disappears.
- The finale is silent.

### 9.4 Accessibility
- Meters use icons and numbers, not colour alone.
- Font scaling and a reduced-motion option.
- Nothing essential is conveyed only through audio.
- No time pressure on event choices.

---

## 10. Educational content

- **Fact cards** unlock at milestones: a short text, one real figure and a source link. They're collected in a **Codex** the player can reread.
- **News ticker:** fictional headlines mixed with paraphrased real trends.
- **Fact vs fiction policy:** every number shown as real must have a source in `content/facts`. Projections are labelled as projections, and fiction is never presented as fact.
- **Teacher kit (stretch):** a one-page discussion guide for after the game.

### 10.1 Starting fact bank

⚠ **Everything below must be checked against the original sources before release.**

| Topic | Figure (approx.) | Source |
|---|---|---|
| Data centre electricity | ~415 TWh in 2024 (~1.5% of world electricity); projected ~945 TWh by 2030 | IEA, *Energy and AI* (2025) |
| Training a large model | GPT-3: ~1,287 MWh, ~552 t CO₂e | Patterson et al. (2021) |
| Training, full life cycle | BLOOM-176B: ~25 t CO₂e operational, ~50 t including hardware manufacturing and idle time | Luccioni, Viguier & Ligozat (2023) |
| Water | Training GPT-3 may have evaporated ~700,000 L of freshwater | Li et al., *Making AI Less "Thirsty"* (2023) |
| Images vs text | Image generation uses far more energy than text tasks; for the least efficient model, roughly one phone charge per image | Luccioni et al., *Power Hungry Processing* (2023) |
| Big-tech emissions | Google's emissions up ~48% vs 2019, driven by data centre energy | Google Environmental Report (2024) |
| Local grid strain | Data centres used ~21% of Ireland's metered electricity in 2023 | CSO Ireland |
| E-waste | 62 Mt generated in 2022; only ~22% documented as properly collected and recycled | Global E-waste Monitor (2024) |
| Digital footprint in France | ~2.5% of France's carbon footprint, mostly from manufacturing devices | ADEME–Arcep (2022–2023) |
| Rebound effect | More efficient coal engines led to *more* coal use | Jevons, *The Coal Question* (1865) |

---

## 11. Technical plan

### 11.1 Stack (recommended)
**A web game in TypeScript, built with Vite, with React for the UI.**
- An idle game is mostly UI: panels, buttons and numbers. Web tech is the fastest way to build that.
- It runs in any browser (school PCs, phones) with nothing to install, and hosting on GitHub Pages or itch.io is free.
- Godot or Unity would be overkill for this genre. Svelte or plain TypeScript would also work if the team prefers.

### 11.2 Architecture

```
src/
  engine/          pure TypeScript, no DOM, unit-tested
    state.ts         GameState type + initial state
    tick.ts          fixed-step simulation (10 ticks/s): production, consumption
    world.ts         planet twins → world meters, feedback loops
    actions.ts       click(), buy(id), train(id), chooseEvent(id, option)
    save.ts          localStorage save/load with versioned migrations
    format.ts        number + unit formatting, equivalences
  content/         DATA ONLY: writers and designers can edit without coding
    upgrades.ts  events.ts  facts.ts  news.ts  acts.ts  equivalences.ts
  ui/              React components
    CompanyPanel  ScenePanel  PlanetPanel  NewsTicker  FactCard  EventCard  Debrief
  i18n/            en.json  fr.json
  assets/          art/  audio/
tools/
  balance-sim.ts   headless "greedy player" bot: reports how long each act lasts
```

Example content entry:

```ts
{
  id: 'gaming_gpu',
  act: 1,
  category: 'hardware',
  cost: { cash: 120 }, costGrowth: 1.15,
  gives: { compute: 40 },
  footprint: { powerW: 350, embodiedCO2kg: 150 },   // placeholder: verify
  unlocksFact: 'embodied_carbon',
}
```

### 11.3 Quality and delivery
- Unit tests (Vitest) for the engine.
- The **balance bot** runs in CI and fails if an act drifts outside its target length.
- Every push to `main` deploys to GitHub Pages through GitHub Actions, so the team always has a playable link.

---

## 12. Roadmap

| Milestone | Deliverable | Done when |
|---|---|---|
| **M0 Foundations** | Vite + TS + React scaffold, lint, CI deploy, empty 3-panel layout | a playable link exists |
| **M1 Engine** | state, tick, click, buy, save/load, formatting, planet twins, tests | numbers move and save |
| **M2 Act I vertical slice** | Act I fully playable with placeholder art: ~12 upgrades, 5 fact cards, ticker | **first playtest:** does the reverse idle land? |
| **M3 Act II** | sites, cooling, energy deals, event cards, rebound, greenwashing panel, rivals | Act I → II flows |
| **M4 Act III + Finale** | energy currency, race, collapsing society, finale, debrief | the full game is playable end to end |
| **M5 Polish** | art, audio, juice, balancing with the bot and playtests | ~30 min run, playtesters finish it |
| **M6 Release** | fact-check every figure, FR/EN, accessibility pass, teacher one-pager | public release |
| *Stretch* | Rollback New Game+, "The Accord" ending | |

---

## 13. Open questions for the team

1. **Audience and context:** who plays (age), where (class, exhibition, online), and is there a deadline (course, competition)?
2. **Language:** French, English, or both from day one?
3. **Team skills:** who codes (JS/TS? React?), who draws, who writes content and checks facts?
4. **Ending:** doom only, or also the Rollback / Accord alternative?
5. **Length:** is ~30 minutes right?
6. **Platforms:** desktop browser only, or phones as well?
7. **Tone:** dry dark humour (satirical corporate voice) or more serious and documentary?
