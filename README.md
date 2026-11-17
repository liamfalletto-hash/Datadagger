# Aether

*The cloud is not in the sky.*

An educational idle game about the real environmental cost of AI. You run **Aether**, an AI start-up that grows from one laptop in an empty room into a superintelligence. Every dollar you earn costs electricity, CO₂, water and e-waste, and the game shows you real numbers for all of them.

## How to play

**Open `index.html` in any web browser** by double-clicking it. There's nothing to install, no internet connection is needed, and progress saves automatically.

1. **Answer prompts** (the big button) to earn your first dollars.
2. **Buy hardware** so Aether earns money on its own (use ×1 / ×10 / Max to buy in bulk).
3. **Fill the progress bar** to reach the next stage. There are 5 stages:
   1. The Garage
   2. The Start-up
   3. The Scale-up
   4. The AI Giant
   5. The Race to Superintelligence
4. Early in stage 2 you get **fined**, and the **Sustainability score** appears. From then on:
   - **Decisions** (energy source, cooling, hardware lifespan, model size, drought, the race) move the score.
   - **A low score boosts income** (up to ×1.3), but it also brings fines and heatwaves. **A high score slows income** (down to ×0.7).
   - **The score decides the ending:**
     - 70+ → 🌱 *The Long Game* (good)
     - 40–69 → 🌫️ *Business as Usual*
     - below 40 → ⬛ *Hello?* (humanity is gone)
5. Read the **News** tab, which reacts to your progress and your score, and collect the **Real facts** (20 sourced facts).
6. The end screen shows your total footprint with everyday equivalents, your choices, and **5 real facts to remember**.

A full game takes about **8–12 minutes**. Polluting is the fastest route and the green route is the slowest, on purpose.

**Presenting to the class?** Add `?speed=5` to the address (e.g. `index.html?speed=5`) to run the game 5× faster. The **↺ New game** button at the bottom resets everything.

## What's real and what's fiction

The story is fiction. Every number presented as a **Real fact** comes from a published source (IEA, peer-reviewed papers, Google, the UN Global E-waste Monitor, Ireland's Central Statistics Office, the Uptime Institute, the IPCC…), and the source is shown on every fact card. Your in-game footprint is calculated from realistic ratios:

- CO₂ per kWh depends on the energy source you choose: coal & gas ≈ 750 g, grid ≈ 450 g, renewables ≈ 30 g.
- Cooling overhead (PUE) and water per kWh depend on your cooling choice.
- E-waste depends on how long you keep your servers.

## Project structure

```
index.html          the page
css/style.css       all styling
js/data.js          ALL game content: stages, hardware, upgrades, decisions, facts, news, endings
js/engine.js        game rules and simulation (no display code)
js/ui.js            draws the game and handles clicks
tools/sim.js        a bot that plays the whole game headlessly to check balance
tools/tune.js       finds stage goals that give the target stage durations
docs/GAME_DESIGN.md the original design plan
```

**To change text, facts, prices or decisions, edit `js/data.js` only.** To check that the game is still balanced after a change, run this (needs Node.js):

```bash
node tools/sim.js
```

It prints how long a polluting, a middle and a green player take to finish, and which ending each one gets.
